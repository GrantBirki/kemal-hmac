require "spec"
require "../src/kemal-hmac"

class SpecAuthHandler < Kemal::Hmac::Handler
  only ["/api"]

  def call(context)
    return call_next(context) unless only_match?(context)
    super
  end
end

def create_request_and_return_io_and_context(handler, request)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  handler.call(context)
  response.close
  io.rewind
  {io, context}
end
