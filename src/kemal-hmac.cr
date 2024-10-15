require "base64"
require "kemal"
require "./kemal-hmac/**"

module Kemal
  module Hmac
    class InvalidFormatError < Exception; end

    KEY_VALIDATION_REGEX = /^[A-Z0-9][A-Z0-9_-]+[A-Z0-9]$/
    ALGORITHM            = algorithm(ENV.fetch("HMAC_ALGORITHM", "SHA256").upcase)
  end
end

# Helper method to easily add HMAC auth support to a kemal app
# See the README for more details or the source file: src/kemal-hmac/handler.cr 
def hmac_auth(
  hmac_client_header : String? = nil,
  hmac_timestamp_header : String? = nil,
  hmac_token_header : String? = nil,
  timestamp_second_window : Int32? = nil,
  rejected_code : Int32? = nil,
  rejected_message_prefix : String? = nil,
  hmac_key_suffix_list : Array(String)? = nil,
  hmac_key_delimiter : String? = nil,
  hmac_secrets : Hash(String, Array(String)) = {} of String => Array(String)
 )
  add_handler Kemal.config.hmac_handler.new(
    hmac_client_header: hmac_client_header,
    hmac_timestamp_header: hmac_timestamp_header,
    hmac_token_header: hmac_token_header,
    timestamp_second_window: timestamp_second_window,
    rejected_code: rejected_code,
    rejected_message_prefix: rejected_message_prefix,
    hmac_key_suffix_list: hmac_key_suffix_list,
    hmac_key_delimiter: hmac_key_delimiter,
    hmac_secrets: hmac_secrets,
  )
end
