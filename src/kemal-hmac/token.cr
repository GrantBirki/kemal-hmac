require "openssl"
require "openssl/hmac"

module Kemal::Hmac
  class Token
    # `subject` the subject of the token (String)
    # `resource` the resource of the token (String)
    # `timestamp` the timestamp of the token (String)
    def initialize(subject : String, resource : String, timestamp : String, algorithm : OpenSSL::Algorithm? = nil)
      @subject = subject
      @resource = resource
      @timestamp = timestamp
      @algorithm = algorithm || ALGORITHM
    end

    # Build an HMAC token with the given secret
    # `secret` the secret used to build token
    # returns HMAC token (hexdigest)
    def hexdigest(secret : String) : String
      OpenSSL::HMAC.hexdigest(@algorithm, secret, message)
    end

    private def message : String
      [@subject.downcase, @resource.downcase, @timestamp].join(HMAC_KEY_DELIMITER)
    end
  end
end
