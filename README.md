# kemal-hmac

[![test](https://github.com/GrantBirki/kemal-hmac/actions/workflows/test.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/test.yml) [![build](https://github.com/GrantBirki/kemal-hmac/actions/workflows/build.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/build.yml) [![lint](https://github.com/GrantBirki/kemal-hmac/actions/workflows/lint.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/lint.yml) [![acceptance](https://github.com/GrantBirki/kemal-hmac/actions/workflows/acceptance.yml/badge.svg)](https://github.com/GrantBirki/kemal-hmac/actions/workflows/acceptance.yml) [![coverage](./docs/assets/coverage.svg)](./docs/assets/coverage.svg)

HMAC middleware for Crystal's [kemal](https://github.com/kemalcr/kemal) framework

## Usage

### Client

Headers:

```ini
HTTP_X_HMAC_CLIENT = "client-name-sending-request-to-the-server"
HTTP_X_HMAC_TIMESTAMP = "2024-10-15T05:10:36Z"
HTTP_X_HMAC_TOKEN = "LongHashHere
```
