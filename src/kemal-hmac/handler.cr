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
    HMAC_CLIENT_HEADER           = ENV.fetch("HMAC_CLIENT_HEADER", "HTTP_X_HMAC_CLIENT")
    HMAC_TIMESTAMP_HEADER        = ENV.fetch("HMAC_TIMESTAMP_HEADER", "HTTP_X_HMAC_TIMESTAMP")
    HMAC_TOKEN_HEADER            = ENV.fetch("HMAC_TOKEN_HEADER", "HTTP_X_HMAC_TOKEN")
    HMAC_TIMESTAMP_SECOND_WINDOW = ENV.fetch("HMAC_TIMESTAMP_SECOND_WINDOW", 30).to_i
    HMAC_REJECTED_MESSAGE_PREFIX = ENV.fetch("HMAC_REJECTED_MESSAGE_PREFIX", "Unauthorized:")

    def initialize(
      hmac_client_header : String? = nil,
      hmac_timestamp_header : String? = nil,
      hmac_token_header : String? = nil,
      timestamp_second_window : Int32? = nil,
      rejected_message_prefix : String? = nil
    )
      @hmac_client_header = hmac_client_header || HMAC_CLIENT_HEADER
      @hmac_timestamp_header = hmac_timestamp_header || HMAC_TIMESTAMP_HEADER
      @hmac_token_header = hmac_token_header || HMAC_TOKEN_HEADER
      @timestamp_second_window = timestamp_second_window || HMAC_TIMESTAMP_SECOND_WINDOW
      @rejected_message_prefix = rejected_message_prefix || HMAC_REJECTED_MESSAGE_PREFIX
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
        context.response.print "#{@rejected_message_prefix} missing required hmac headers"
        return
      end

      timestamp_result = recent_timestamp?(headers[@hmac_timestamp_header].not_nil!, @timestamp_second_window)

      unless timestamp_result[:valid]
        context.response.status_code = 401
        context.response.print "#{@rejected_message_prefix} #{timestamp_result[:message]}"
        return
      end

      context.kemal_authorized_client = headers[@hmac_client_header]
    end

    # Check if the timestamp is within the last `seconds` seconds and not in the future
    # Timestamps should only be in UTC
    # iso8601 format: 2022-09-27 18:00:00.000
    # Used to protect against replay attacks
    def recent_timestamp?(timestamp : String, seconds : Int32) : {valid: Bool, message: String}
      begin
        request_time = Time.parse_iso8601(timestamp)
      rescue e : Time::Format::Error
        return {valid: false, message: "Timestamp isn't a valid ISO8601 string: '#{timestamp}' - Example: YYYY-MM-DDTHH:MM:SSZ"}
      end

      lower_bound = Time.utc - seconds.seconds
      upper_bound = Time.utc + seconds.seconds

      valid = lower_bound < request_time && request_time < upper_bound

      if !valid
        return {valid: false, message: "Timestamp is too old or in the future (ensure it's in UTC)"}
      end

      return {valid: valid, message: "Timestamp is valid"}
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
  end
end
