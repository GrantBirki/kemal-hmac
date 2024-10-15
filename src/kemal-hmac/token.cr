require "openssl"
require "openssl/hmac"

module Kemal::Hmac
  class Token
    DELIMITER = "|"

    # :param subject: the subject of the token (String)
    # :param resource: the resource of the token (String)
    # :param timestamp: the timestamp of the token (String)
    def initialize(subject : String, resource : String, timestamp : String)
      @subject = subject
      @resource = resource
      @timestamp = timestamp
    end

    # Build an HMAC token with the given secret
    # :param secret: the secret used to build token
    # :return: HMAC token (hexdigest)
    def hexdigest(secret : String) : String
      OpenSSL::HMAC.hexdigest(ALGORITHM, secret, message)
    end

    private def message : String
      [@subject.downcase, @resource.downcase, @timestamp].join(DELIMITER)
    end
  end
end
