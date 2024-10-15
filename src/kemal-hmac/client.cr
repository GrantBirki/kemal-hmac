require "./token"

module Kemal::Hmac
  class Client
    def initialize(client : String, secret : String, algorithm : String? = "SHA256")
      @client = client.upcase
      @secret = secret
      algo = (algorithm || ENV.fetch("HMAC_ALGORITHM", "SHA256")).upcase
      @algorithm = Kemal::Hmac.algorithm(algo)

      unless KEY_VALIDATION_REGEX.match(@client)
        raise InvalidSecretError.new("client name must only contain letters, numbers, -, or _")
      end
    end

    def generate_headers(path : String)
      timestamp = Time::Format::ISO_8601_DATE_TIME.format(Time.utc)
      hmac_token = Kemal::Hmac::Token.new(@client, path, timestamp).hexdigest(@secret)

      return {
        "hmac-client"    => @client,
        "hmac-timestamp" => timestamp,
        "hmac-token"     => hmac_token,
      }
    end
  end
end
