require "base64"
require "kemal"
require "./kemal-hmac/**"

module Kemal
  module Hmac
    KEY_VALIDATION_REGEX = /^[A-Z0-9][A-Z0-9_-]+[A-Z0-9]$/
    ALGORITHM = algorithm(ENV.fetch("HMAC_ALGORITHM", "SHA256").upcase)
  end
end

# Helper to easily add HTTP Basic Auth support.
def hmac_auth(hmac_client_header : String? = nil, hmac_timestamp_header : String? = nil, hmac_token_header : String? = nil)
  add_handler Kemal.config.hmac_handler.new(
    hmac_client_header: hmac_client_header,
    hmac_timestamp_header: hmac_timestamp_header,
    hmac_token_header: hmac_token_header
  )
end
