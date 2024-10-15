# kemal-hmac

[![test](https://github.com/GrantBirki/kemal-hmac/actions/workflows/test.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/test.yml) [![build](https://github.com/GrantBirki/kemal-hmac/actions/workflows/build.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/build.yml) [![lint](https://github.com/GrantBirki/kemal-hmac/actions/workflows/lint.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/lint.yml) [![acceptance](https://github.com/GrantBirki/kemal-hmac/actions/workflows/acceptance.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/acceptance.yml) [![coverage](./docs/assets/coverage.svg)](./docs/assets/coverage.svg)

HMAC middleware for Crystal's [kemal](https://github.com/kemalcr/kemal) framework

## About

Why should I use HMAC in a client/server system with kemal? Here are some of the benefits:

- **Data Integrity**: HMAC ensures that the data hasn't been tampered with during transit
- **Authentication**: Verifies the identity of the sender, providing a level of trust in the communication
- **Keyed Security**: Uses a secret key for hashing, making it more secure than simple hash functions
- **Protection Against Replay Attacks**: By incorporating timestamps, HMAC helps prevent the replay of old messages

This readme will be broken up into two parts. The first part will cover how to use the server middleware in a kemal application. The second part will cover how to use the client to communicate with a server that uses the middleware.

## Quick Start ⭐

### Installation

Simply add the shard to your `shard.yml` file:

```yaml
dependencies:
  kemal-hmac:
    github: grantbirki/kemal-hmac
```

### Basic Example

The most basic example possible enabling HMAC authentication for all routes in a kemal application:

```crystal
require "kemal"
require "kemal-hmac"

hmac_auth({"my_client" => ["my_secret"]})

get "/" do |env|
  "Hi, %s! You passed HMAC auth" % env.kemal_authorized_client?
end

Kemal.run
```

## Server Usage

First, you must require the `kemal-hmac` shard in your kemal application and call it:

```crystal
# file: hmac_server.cr
require "kemal"
require "kemal-hmac"

# Initialize the HMAC middleware with the client name that will be sending requests to this server and a secret
# Note: You can use more than one client name and secret pair. You can also use multiple secrets for the same client name (helps with key rotation)
hmac_auth({"my_client" => ["my_secret"]})

# Now all endpoints are protected with HMAC authentication
# env.kemal_authorized_client? will return the client name that was used to authenticate the request
get "/" do |env|
  "Hi, %s! You sent a request that was successfully verified with HMAC auth" % env.kemal_authorized_client?
end

Kemal.run

# $ crystal run hmac_server.cr
# [development] Kemal is ready to lead at http://0.0.0.0:3000
```

In a new terminal, you can send a request into the kemal server and verify that HMAC authentication is working:

```crystal
# file: client_test.cr
require "kemal-hmac"  # <-- import the kemal-hmac shard
require "http/client" # <-- here we will just use the crystal standard library

# Initialize the HMAC client
client = Kemal::Hmac::Client.new("my_client", "my_secret")

# Generate the HMAC headers for the desired path
path = "/"
headers = HTTP::Headers.new
client.generate_headers(path).each do |key, value|
  headers.add(key, value)
end

# Make the HTTP request with the generated headers to the server that uses `kemal-hmac` for authentication
response = HTTP::Client.get("http://localhost:3000#{path}", headers)

# Handle the response
if response.status_code == 200
  puts "Success: #{response.body}"
else
  puts "Error: #{response.status_code}"
end

# $ crystal run client_test.cr
# Success: Hi, my_client! You sent a request that was successfully verified with HMAC auth
```

### Authentication for specific routes

The `Kemal::Hmac::Handler` inherits from `Kemal::Handler` and it is therefore easy to create a custom handler that adds HMAC authentication to specific routes instead of all routes.

```crystal
# file: hmac_server.cr
require "kemal"
require "kemal-hmac"

class CustomAuthHandler < Kemal::Hmac::Handler
  only ["/admin", "/api"] # <-- only protect the /admin and /api routes
  
  def call(context)
    return call_next(context) unless only_match?(context)
    super
  end
end

# Initialize the HMAC middleware with the custom handler
Kemal.config.hmac_handler = CustomAuthHandler
add_handler CustomAuthHandler.new({"my_client" => ["my_secret"]})

# The root (/) endpoint is not protected by HMAC authentication in this example
get "/" do |env|
  "hello world"
end

# The /admin endpoint is protected by HMAC authentication in this example
get "/admin" do |env|
  "Hi, %s! You sent a request that was successfully verified with HMAC auth to the /admin endpoint" % env.kemal_authorized_client?
end

Kemal.run

# $ crystal run hmac_server.cr
# [development] Kemal is ready to lead at http://0.0.0.0:3000
```

### `kemal_authorized_client?`

When a request is made to a protected route, the `kemal_authorized_client?` method is available on the `env` object. This method returns the client name that was used to authenticate the request if the request was successfully verified with HMAC authentication. Otherwise, it returns `nil`.

```crystal
get "/admin" do |env|
  "Hi, %s! You sent a request that was successfully verified with HMAC auth" % env.kemal_authorized_client?
end
```

### Environment Variable Configuration

The `kemal-hmac` server middleware can be configured completely through environment variables. For example, if you had the following environment variables set:

```bash
export MY_CLIENT_HMAC_SECRET_BLUE="my_secret_1"
export MY_CLIENT_HMAC_SECRET_GREEN="my_secret_2"
```

Then simply calling `hmac_auth()` in your kemal application will automatically configure the middleware with the client names and secrets from the environment variables. Here is how it works:

1. When the `hmac_auth()` method is called with no arguments, the middleware will look for environment variables that start with the client name in all caps and end with `HMAC_SECRET_BLUE` or `HMAC_SECRET_GREEN` (these are called the `HMAC_KEY_SUFFIX_LIST` and can be further configured with environment variables as well). For example, if the client name is `my_client`, the middleware will look for an environment variable called `MY_CLIENT_HMAC_SECRET_BLUE` or `MY_CLIENT_HMAC_SECRET_GREEN`.
2. If one or more matching secrets are found for the client name, the middleware will be configured with the client name and the secrets.
3. The client name and secrets will be used to generate the HMAC token for incoming requests.
4. The first matching secret for the client that successfully generates a valid HMAC token will be used to authenticate the request.

Here is an example passing no params into `hmac_auth()` and letting it self-hydrate from the environment variables:

```crystal
# file: hmac_server.cr
require "kemal"
require "kemal-hmac"

# Initialize the HMAC middleware with no params so it can self-hydrate from the environment variables
hmac_auth()

# Now all endpoints are protected with HMAC authentication
get "/" do |env|
  "Hi, %s! You sent a request that was successfully verified with HMAC auth using environment variables" % env.kemal_authorized_client?
end
```

## Configuration

This section goes into detail on the configuration options available for the `kemal-hmac` middleware and the client utility.

### Global Environment Variables

These environment variables can be set globally for the `kemal-hmac` middleware and the client utility to change the default behavior.

| Environment Variable | Default Value | Description |
| -------------------- | ------------- | ----------- |
| `HMAC_CLIENT_HEADER` | `hmac-client` | The name of the header that contains the client name |
| `HMAC_TIMESTAMP_HEADER` | `hmac-timestamp` | The name of the header that contains the iso8601 timestamp |
| `HMAC_TOKEN_HEADER` | `hmac-token` | The name of the header that contains the HMAC token |
| `HMAC_TIMESTAMP_SECOND_WINDOW` | `30` | The number of seconds before and after the current time that a timestamp is considered valid - helps with clock drift |
| `HMAC_REJECTED_CODE` | `401` | The status code to return when a request is rejected |
| `HMAC_REJECTED_MESSAGE_PREFIX` | `Unauthorized:` | The prefix to add to the response body when a request is rejected |
| `HMAC_KEY_SUFFIX_LIST` | `HMAC_SECRET_BLUE,HMAC_SECRET_GREEN` | A comma-separated list of key suffixes to use for looking up secrets in the environment. Using a blue/green pattern is best for key rotation |
| `HMAC_KEY_DELIMITER` | `_` | The delimiter to use for separating the client name from the key suffix in the environment variable name |
| `HMAC_ALGORITHM` | `SHA256` | The algorithm to use for generating the HMAC token. See [here](./src/kemal-hmac/hmac_algorithm.cr) for all supported algorithms |

### Direct Middleware Configuration

Passing in configuration options directly to the `hmac_auth` method is the most explicit way to configure the `kemal-hmac` middleware and these options take precedence over the environment variables.

```crystal
# A very verbose example of how to configure the middleware
# file: hmac_server.cr

require "kemal"
require "kemal-hmac"

hmac_auth(
  hmac_secrets: {"my_client" => ["my_secret_blue", "my_secret_green"], "my_other_client" => ["my_other_secret"]},
  hmac_client_header: "hmac-client",
  hmac_timestamp_header: "hmac-timestamp",
  hmac_token_header: "hmac-token",
  timestamp_second_window: 30,
  rejected_code: 401,
  rejected_message_prefix: "Unauthorized:",
  hmac_key_suffix_list: ["HMAC_SECRET_BLUE", "HMAC_SECRET_GREEN"],
  hmac_key_delimiter: "_",
  hmac_algorithm: "SHA256"
)

# ... kemal logic here
```

## Client Usage

The `Kemal::Hmac::Client` class is designed to facilitate making HTTP requests to a remote server that uses HMAC (Hash-based Message Authentication Code) authentication implemented by this same shard. This class helps generate the necessary HMAC headers required for authenticating requests.

Here are some examples of the relevant headers that are generated by the `Kemal::Hmac::Client` class:

```ini
hmac-client = "client-name-sending-request-to-the-server"
hmac-timestamp = "2024-10-15T05:10:36Z"
hmac-token = "LongHashHere
```

### Initialization

To initialize the `Kemal::Hmac::Client` class, you need to provide the client name, secret, and optionally, the algorithm used to generate the HMAC token. The default algorithm is SHA256.

```crystal
require "kemal-hmac"

client = Kemal::Hmac::Client.new("my_client", "my_secret")
```

You can also specify a different algorithm:

```crystal
require "kemal-hmac"

client = Kemal::Hmac::Client.new("my_client", "my_secret", "SHA512")
```

### Generating HMAC Headers

The generate_headers method generates the necessary HMAC headers for a given HTTP path. These headers can then be included in your HTTP request to the server.

```crystal
require "kemal-hmac"

client = Kemal::Hmac::Client.new("my_client", "my_secret")
hmac_headers = client.generate_headers("/api/path")
```

### Example: Making an HTTP Request

Here is a complete example of how to use the `Kemal::Hmac::Client` class to make an HTTP request to a remote server that uses `kemal-hmac` for authentication.

```crystal
# Example using crystal's standard library for making HTTP requests with "http/client"

require "kemal-hmac" # <-- import the kemal-hmac shard
require "http/client" # <-- here we will just use the crystal standard library

# Initialize the HMAC client
client = Kemal::Hmac::Client.new("my_client", "my_secret")

# Generate the HMAC headers for the desired path
path = "/" # <-- can be any request path you like
headers = HTTP::Headers.new
# loop over the generated headers and add them to the HTTP headers
client.generate_headers(path).each do |key, value|
  headers.add(key, value)
end

# Make the HTTP request with the generated headers to the server that uses `kemal-hmac` for authentication
response = HTTP::Client.get("https://example.com#{path}", headers: headers)

# Handle the response
if response.status_code == 200
  puts "Success: #{response.body}"
else
  puts "Error: #{response.status_code}"
end
```

### Example: Making an HTTP Request with the `crest` shard

Here is a complete example of how to use the `Kemal::Hmac::Client` class to make an HTTP request to a remote server that uses `kemal-hmac` for authentication. This example uses the popular `crest` library for making HTTP requests.

```crystal
# Example using the popular `crest` library for making HTTP requests

require "kemal-hmac" # <-- import the kemal-hmac shard
require "crest"      # <-- here we will use the popular `crest` library

# Initialize the HMAC client
client = Kemal::Hmac::Client.new("my_client", "my_secret")

path = "/"

# Make the HTTP request with the generated headers to the server that uses `kemal-hmac` for authentication (using the `crest` library)
response = Crest.get(
  "http://localhost:3000#{path}",
  headers: client.generate_headers(path)
)

# Handle the response
if response.status_code == 200
  puts "Success: #{response.body}"
else
  puts "Error: #{response.status_code}"
end
```

## Generating an HMAC secret

To generate an HMAC secret, you can use the following command for convenience:

```bash
openssl rand -hex 32
```
