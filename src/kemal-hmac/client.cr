require "./token"

module Kemal::Hmac
  class Client
    # :param client: the client name which will be sending HTTP requests to the server using HMAC auth (String)
    # :param secret: the secret used to generate the HMAC token in relation to the client (String)
    # # :param algorithm: the algorithm used to generate the HMAC token (String) - defaults to SHA256
    def initialize(client : String, secret : String, algorithm : String? = "SHA256")
      @client = client
      @secret = secret
      algo = (algorithm || ENV.fetch("HMAC_ALGORITHM", "SHA256")).upcase
      @algorithm = Kemal::Hmac.algorithm(algo)

      unless KEY_VALIDATION_REGEX.match(@client.upcase)
        raise InvalidFormatError.new("client name must only contain letters, numbers, -, or _")
      end
    end

    # A public helper method to generate the HMAC headers for a given path
    # Use this method to get pre-filled headers to send with your request to the server
    # :param path: the path (HTTP path) to generate the headers for (String) - e.g. "/api/path"
    # :return: a Hash of the HMAC headers
    def generate_headers(path : String) : Hash(String, String)
      timestamp = Time::Format::ISO_8601_DATE_TIME.format(Time.utc)
      hmac_token = Kemal::Hmac::Token.new(@client, path, timestamp).hexdigest(@secret)

      return {
        HMAC_CLIENT_HEADER    => @client,
        HMAC_TIMESTAMP_HEADER => timestamp,
        HMAC_TOKEN_HEADER     => hmac_token,
      }
    end
  end
end
