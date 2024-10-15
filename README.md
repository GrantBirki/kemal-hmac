# kemal-hmac

[![test](https://github.com/GrantBirki/kemal-hmac/actions/workflows/test.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/test.yml) [![build](https://github.com/GrantBirki/kemal-hmac/actions/workflows/build.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/build.yml) [![lint](https://github.com/GrantBirki/kemal-hmac/actions/workflows/lint.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/lint.yml) [![acceptance](https://github.com/GrantBirki/kemal-hmac/actions/workflows/acceptance.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/acceptance.yml) [![coverage](./docs/assets/coverage.svg)](./docs/assets/coverage.svg)

HMAC middleware for Crystal's [kemal](https://github.com/kemalcr/kemal) framework

## About

Why should I use HMAC in a client/server system with kemal? Here are some of the benefits:

- **Data Integrity**: HMAC ensures that the data hasn't been tampered with during transit
- **Authentication**: Verifies the identity of the sender, providing a level of trust in the communication
- **Keyed Security**: Uses a secret key for hashing, making it more secure than simple hash functions
- **Protection Against Replay Attacks**: By incorporating timestamps, HMAC helps prevent the replay of old messages

This readme will be broken up into two parts. The first part will cover how to use the middleware in a kemal application. The second part will cover how to use the client to communicate with a service that uses the middleware.

## Client Usage

Headers:

```ini
hmac-client = "client-name-sending-request-to-the-server"
hmac-timestamp = "2024-10-15T05:10:36Z"
hmac-token = "LongHashHere
```

The `Kemal::Hmac::Client` class is designed to facilitate making HTTP requests to a remote server that uses HMAC (Hash-based Message Authentication Code) authentication implemented by this same shard. This class helps generate the necessary HMAC headers required for authenticating requests.

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
require "kemal-hmac" # <-- import the kemal-hmac shard
require "http/client" # <-- here we will just use the crystal standard library

# Initialize the HMAC client
client = Kemal::Hmac::Client.new("my_client", "my_secret")

# Generate the HMAC headers for the desired path
path = "/"
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

### Conclusion

The `Kemal::Hmac::Client` class simplifies the process of making authenticated HTTP requests to a server that has implemented the `kemal-hmac` shard for HMAC authentication. By following the examples provided, you can easily integrate any Crystal application with a `kemal-hmac` server.

## Generating an HMAC secret

To generate an HMAC secret, you can use the following command for convenience:

```bash
openssl rand -hex 32
```
