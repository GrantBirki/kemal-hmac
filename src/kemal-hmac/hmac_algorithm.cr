module Kemal::Hmac
  MD4       = 0
  MD5       = 1
  RIPEMD160 = 2
  SHA1      = 3
  SHA224    = 4
  SHA256    = 5
  SHA384    = 6
  SHA512    = 7

  def self.algorithm(algorithm : String) : OpenSSL::Algorithm
    OpenSSL::Algorithm.new(algorithms(algorithm))
  end

  def self.algorithms(algorithm) : Int32
    case algorithm
    when "MD4"
      MD4
    when "MD5"
      MD5
    when "RIPEMD160"
      RIPEMD160
    when "SHA1"
      SHA1
    when "SHA224"
      SHA224
    when "SHA256"
      SHA256
    when "SHA384"
      SHA384
    when "SHA512"
      SHA512
    else
      SHA256
    end
  end
end
