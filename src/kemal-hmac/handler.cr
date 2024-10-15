require "kemal"
require "./token"
require "crypto/subtle"

module Kemal::Hmac
  # This middleware adds hmac support to your application.
  # Returns 401 "Unauthorized" with wrong credentials.
  #
  # ```
  # hmac_auth({"my_client" => ["my_secret"]})
  # ```
  #
  # `HTTP::Server::Context#authorized_hmac_client?` is set when the client is
  # authorized.
  class Handler < Kemal::Handler
    @hmac_algorithm : OpenSSL::Algorithm

    # initialize the Kemal::Hmac::Handler
    # note: "BLUE" and "GREEN" in this context are two different secrets for the same client. This is a common pattern to allow for key rotation without downtime.
    # examples:
    #  hmac_secrets: {"cool-client-service" => ["BLUE_SECRET", "GREEN_SECRET"]} - explicitly set secrets for one or many clients
    #  hmac_client_header: "HTTP_X_HMAC_CLIENT"
    #  hmac_timestamp_header: "HTTP_X_HMAC_TIMESTAMP"
    #  hmac_token_header: "HTTP_X_HMAC_TOKEN"
    #  timestamp_second_window: 30
    #  rejected_code: 401
    #  rejected_message_prefix: "Unauthorized:"
    #  hmac_key_suffix_list: ["HMAC_SECRET_BLUE", "HMAC_SECRET_GREEN"] - only used for env variable lookups
    #  hmac_key_delimiter: "_" - only used for env variable lookups
    #  hmac_algorithm: "SHA256"
    #  enable_env_lookup: true (this value is set to false by default)
    def initialize(
      hmac_secrets : Hash(String, Array(String)) = {} of String => Array(String),
      hmac_client_header : String? = nil,
      hmac_timestamp_header : String? = nil,
      hmac_token_header : String? = nil,
      timestamp_second_window : Int32? = nil,
      rejected_code : Int32? = nil,
      rejected_message_prefix : String? = nil,
      hmac_key_suffix_list : Array(String)? = nil,
      hmac_key_delimiter : String? = nil,
      hmac_algorithm : String? = nil,
      enable_env_lookup : Bool = false,
    )
      @hmac_client_header = hmac_client_header || HMAC_CLIENT_HEADER
      @hmac_timestamp_header = hmac_timestamp_header || HMAC_TIMESTAMP_HEADER
      @hmac_token_header = hmac_token_header || HMAC_TOKEN_HEADER
      @timestamp_second_window = timestamp_second_window || HMAC_TIMESTAMP_SECOND_WINDOW
      @rejected_code = rejected_code || HMAC_REJECTED_CODE
      @rejected_message_prefix = rejected_message_prefix || HMAC_REJECTED_MESSAGE_PREFIX
      @hmac_key_suffix_list = hmac_key_suffix_list || HMAC_KEY_SUFFIX_LIST
      @hmac_key_delimiter = hmac_key_delimiter || HMAC_KEY_DELIMITER
      @hmac_algorithm = fetch_hmac_algorithm(hmac_algorithm)
      @enable_env_lookup = enable_env_lookup

      @required_hmac_headers = [
        @hmac_client_header,
        @hmac_timestamp_header,
        @hmac_token_header,
      ]

      @secrets_cache = hmac_secrets
      @secrets_cache = normalize_client_hash(@secrets_cache)
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

      # validate the timestamp
      timestamp_result = recent_timestamp?(timestamp, @timestamp_second_window)

      # reject the request if the timestamp is not valid
      unless timestamp_result[:valid]
        context.response.status_code = @rejected_code
        context.response.print "#{@rejected_message_prefix} #{timestamp_result[:message]}"
        return
      end

      # attempt to load the secrets for the given client
      begin
        client_secrets = load_secrets(client)
      rescue ex : InvalidFormatError
        context.response.status_code = @rejected_code
        context.response.print "#{@rejected_message_prefix} #{ex.message}"
        return
      end

      # reject the request if no secrets are found for the given client
      if client_secrets.empty?
        context.response.status_code = @rejected_code
        context.response.print "#{@rejected_message_prefix} no secrets found for client: #{client}"
        return
      end

      token_valid = false
      client_secrets.each do |secret|
        token_valid = valid_token?(token, secret, client, context.request.path, timestamp)
        break if token_valid
      end

      # if no valid token was found, reject the request
      unless token_valid
        context.response.status_code = @rejected_code
        context.response.print "#{@rejected_message_prefix} HMAC token does not match"
        return
      end

      # if we make it here, the request is valid so set the authorized client on the context
      context.kemal_authorized_client = client
      return call_next(context)
    end

    # Check the request token by building our own with our known metadata and secret
    # :param request_token: token provided in request
    # :param secret: secret used to build token
    # :param client: client name used to build token
    # :param path: path used to build token
    # :param timestamp: timestamp used to build token
    # :return: True if token matches, False otherwise
    def valid_token?(request_token, secret, client, path, timestamp)
      token = Kemal::Hmac::Token.new(client, path, timestamp, @hmac_algorithm)
      Crypto::Subtle.constant_time_compare(token.hexdigest(secret), request_token)
    end

    # A helper method to upcase all the keys in a dictionary
    # This ensures that client names passed in via headers exactly match the keys in the secrets cache
    def normalize_client_hash(dict : Hash(String, Array(String))) : Hash(String, Array(String))
      dict.each_with_object({} of String => Array(String)) do |(k, v), new_dict|
        new_dict[k.upcase] = v
      end
    end

    def fetch_hmac_algorithm(algorithm : String?) : OpenSSL::Algorithm
      determined_hmac_algorithm : OpenSSL::Algorithm
      if algorithm.nil?
        determined_hmac_algorithm = ALGORITHM
      else
        determined_hmac_algorithm = Kemal::Hmac.algorithm(algorithm.upcase) || ALGORITHM
      end

      return determined_hmac_algorithm
    end

    # Load the secrets for the given client
    # Returns an array of strings (secrets) with all posible secrets for the given client (BLUE + GREEN)
    def load_secrets(client : String) : Array(String)
      key = client.upcase

      # before doing a full lookup, check the cache first
      if @secrets_cache.has_key?(key)
        return @secrets_cache[key]
      end

      # exit early if env lookups are explicitly disabled
      return [] of String unless @enable_env_lookup

      unless KEY_VALIDATION_REGEX.match(key)
        raise InvalidFormatError.new("client name must only contain letters, numbers, -, or _")
      end

      # if we make it here, check the environment variables
      client_secrets = @hmac_key_suffix_list.compact_map do |suffix|
        env_key = [key, suffix].join(@hmac_key_delimiter).upcase
        ENV.fetch(env_key, nil)
      end

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
