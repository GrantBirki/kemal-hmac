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
    HMAC_REJECTED_CODE           = ENV.fetch("HMAC_REJECTED_CODE", 401).to_i
    HMAC_REJECTED_MESSAGE_PREFIX = ENV.fetch("HMAC_REJECTED_MESSAGE_PREFIX", "Unauthorized:")
    HMAC_KEY_SUFFIX_LIST         = ENV.fetch("HMAC_KEY_SUFFIX_LIST", "HMAC_SECRET_BLUE,HMAC_SECRET_GREEN").split(",").map(&.strip)
    HMAC_KEY_DELIMITER           = ENV.fetch("HMAC_KEY_DELIMITER", "_")

    # initialize the Kemal::Hmac::Handler
    # note: "BLUE" and "GREEN" in this context are two different secrets for the same client. This is a common pattern to allow for key rotation without downtime.
    # examples:
    #  hmac_client_header: "HTTP_X_HMAC_CLIENT"
    #  hmac_timestamp_header: "HTTP_X_HMAC_TIMESTAMP"
    #  hmac_token_header: "HTTP_X_HMAC_TOKEN"
    #  timestamp_second_window: 30
    #  rejected_code: 401
    #  rejected_message_prefix: "Unauthorized:"
    #  hmac_key_suffix_list: ["HMAC_SECRET_BLUE", "HMAC_SECRET_GREEN"] - only used for env variable lookups
    #  hmac_key_delimiter: "_" - only used for env variable lookups
    #  hmac_secrets: {"cool-client-service" => ["BLUE_SECRET", "GREEN_SECRET"]} - explicitly set secrets for one or many clients
    def initialize(
      hmac_client_header : String? = nil,
      hmac_timestamp_header : String? = nil,
      hmac_token_header : String? = nil,
      timestamp_second_window : Int32? = nil,
      rejected_code : Int32? = nil,
      rejected_message_prefix : String? = nil,
      hmac_key_suffix_list : Array(String)? = nil,
      hmac_key_delimiter : String? = nil,
      hmac_secrets : Hash(String, Array(String)) = {} of String => Array(String),
    )
      @hmac_client_header = hmac_client_header || HMAC_CLIENT_HEADER
      @hmac_timestamp_header = hmac_timestamp_header || HMAC_TIMESTAMP_HEADER
      @hmac_token_header = hmac_token_header || HMAC_TOKEN_HEADER
      @timestamp_second_window = timestamp_second_window || HMAC_TIMESTAMP_SECOND_WINDOW
      @rejected_code = rejected_code || HMAC_REJECTED_CODE
      @rejected_message_prefix = rejected_message_prefix || HMAC_REJECTED_MESSAGE_PREFIX
      @hmac_key_suffix_list = hmac_key_suffix_list || HMAC_KEY_SUFFIX_LIST
      @hmac_key_delimiter = hmac_key_delimiter || HMAC_KEY_DELIMITER

      @required_hmac_headers = [
        @hmac_client_header,
        @hmac_timestamp_header,
        @hmac_token_header,
      ]

      @secrets_cache = hmac_secrets
    end

    def call(context)
      headers = load_hmac_headers(context)
      missing_headers, empty_headers = validate_hmac_headers(headers)

      # if any of the required headers are missing, reject the request
      unless missing_headers.empty?
        context.response.status_code = @rejected_code
        context.response.headers["missing-hmac-headers"] = missing_headers.join(",")
        context.response.print "#{@rejected_message_prefix} missing required hmac headers"
        return
      end

      # if any of the required headers are empty, reject the request
      unless empty_headers.empty?
        context.response.status_code = @rejected_code
        context.response.headers["empty-hmac-headers"] = empty_headers.join(",")
        context.response.print "#{@rejected_message_prefix} empty required hmac headers"
        return
      end

      # extract required hmac values from the request
      client = headers[@hmac_client_header].not_nil!
      timestamp = headers[@hmac_timestamp_header].not_nil!
      token = headers[@hmac_token_header].not_nil!

      timestamp_result = recent_timestamp?(timestamp, @timestamp_second_window)

      unless timestamp_result[:valid]
        context.response.status_code = @rejected_code
        context.response.print "#{@rejected_message_prefix} #{timestamp_result[:message]}"
        return
      end

      # attempt to load the secrets for the given client
      client_secrets = load_secrets(client)

      # reject the request if no secrets are found for the given client
      unless client_secrets.any?
        context.response.status_code = @rejected_code
        context.response.print "#{@rejected_message_prefix} no secrets found for client: #{client}"
        return
      end

      context.kemal_authorized_client = client
    end

    # Load the secrets for the given client
    # Returns an array of strings (secrets) with all posible secrets for the given client (BLUE + GREEN)
    def load_secrets(client : String) : Array(String)
      key = client.upcase

      # before doing a full lookup, check the cache first
      if @secrets_cache.has_key?(key)
        return @secrets_cache[key]
      end

      unless KEY_VALIDATION_REGEX.match(key)
        raise ArgumentError.new("client name must only contain letters, numbers, or _")
      end

      # if we make it here, check the environment variables
      client_secrets = @hmac_key_suffix_list.map do |suffix|
        env_key = [key, suffix].join(@hmac_key_delimiter).upcase
        ENV.fetch(env_key, nil)
      end.compact

      # if client_secrets is not empty, add it to the cache
      if !client_secrets.empty?
        @secrets_cache[key] = client_secrets
      end

      return client_secrets
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

    # If any of the required headers are missing or empty, return the missing or empty headers
    def validate_hmac_headers(headers : Hash(String, String?)) : Array(Array(String))
      missing_headers = headers.select { |_, v| v.nil? }.keys
      empty_headers = headers.select { |_, v| v.try(&.empty?) }.keys

      return [missing_headers, empty_headers]
    end
  end
end
