require "kemal"

module Kemal::Hmac
  # This middleware adds hmac support to your application.
  # Returns 401 "Unauthorized" with wrong credentials.
  #
  # ```
  # hmac_auth "todo"
  # # hmac_auth ["todo1", "todo2"]
  # ```
  #
  # `HTTP::Server::Context#authorized_hmac_client` is set when the client is
  # authorized.
  class Handler < Kemal::Handler
    HMAC_CLIENT_HEADER    = ENV.fetch("HMAC_CLIENT_HEADER", "HTTP_X_HMAC_CLIENT")
    HMAC_TIMESTAMP_HEADER = ENV.fetch("HMAC_TIMESTAMP_HEADER", "HTTP_X_HMAC_TIMESTAMP")
    HMAC_TOKEN_HEADER     = ENV.fetch("HMAC_TOKEN_HEADER", "HTTP_X_HMAC_TOKEN")

    def initialize(hmac_client_header : String? = nil, hmac_timestamp_header : String? = nil, hmac_token_header : String? = nil)
      @hmac_client_header = hmac_client_header || HMAC_CLIENT_HEADER
      @hmac_timestamp_header = hmac_timestamp_header || HMAC_TIMESTAMP_HEADER
      @hmac_token_header = hmac_token_header || HMAC_TOKEN_HEADER
      @required_hmac_headers = [
        @hmac_client_header,
        @hmac_timestamp_header,
        @hmac_token_header,
      ]
    end

    def call(context)
      headers = load_hmac_headers(context)
      missing_headers = missing_hmac_headers(headers)

      # if any of the required headers are missing, return 401
      unless missing_headers.empty?
        context.response.status_code = 401
        context.response.headers["missing-hmac-headers"] = missing_headers.join(",")
        context.response.print "Unauthorized"
        return
      end

      context.kemal_authorized_client = headers[@hmac_client_header]
    end

    # Load the required headers from the request for hmac authentication
    def load_hmac_headers(context) : Hash(String, String?)
      @required_hmac_headers.each_with_object({} of String => String?) do |name, hash|
        hash[name] = context.request.headers.fetch(name, nil)
      end
    end

    # If any of the required headers are missing, return the missing headers
    def missing_hmac_headers(headers : Hash(String, String?)) : Array(String)
      headers.select { |_, v| v.nil? }.keys
    end

    def authorize?(value) : String?
      username, password = Base64.decode_string(value[BASIC.size + 1..-1]).split(":")
      @credentials.authorize?(username, password)
    end
  end
end
