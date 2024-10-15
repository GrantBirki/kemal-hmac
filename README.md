# kemal-hmac

[![test](https://github.com/GrantBirki/kemal-hmac/actions/workflows/test.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/test.yml) [![build](https://github.com/GrantBirki/kemal-hmac/actions/workflows/build.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/build.yml) [![lint](https://github.com/GrantBirki/kemal-hmac/actions/workflows/lint.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/lint.yml) [![acceptance](https://github.com/GrantBirki/kemal-hmac/actions/workflows/acceptance.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/acceptance.yml) [![coverage](./docs/assets/coverage.svg)](./docs/assets/coverage.svg)

HMAC middleware for Crystal's [kemal](https://github.com/kemalcr/kemal) framework

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
