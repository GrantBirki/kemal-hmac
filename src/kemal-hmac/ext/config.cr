require "../handler"

module Kemal
  class Config
    property hmac_handler : Kemal::Hmac::Handler.class = Kemal::Hmac::Handler
  end
end
