require "../spec_helper"

describe "Kemal::Hmac" do
  #   it "goes to next handler with correct credentials" do
  #     hmac_handler = Kemal::Hmac::Handler.new()
  #     request = HTTP::Request.new(
  #       "GET",
  #       "/",
  #       headers: HTTP::Headers{"foo" => "bar"},
  #     )

  #     io, context = create_request_and_return_io_and_context(hmac_handler, request)
  #     response = HTTP::Client::Response.from_io(io, decompress: false)
  #     response.status_code.should eq 404
  #     context.kemal_authorized_client?.should eq("serdar")
  #   end

  it "returns 401 when a header is provided but it is not for hmac auth" do
    hmac_handler = Kemal::Hmac::Handler.new
    request = HTTP::Request.new(
      "GET",
      "/",
      headers: HTTP::Headers{"x-no-hmac-auth-whoops" => "foobar"},
    )
    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.headers["missing-hmac-headers"].should eq "HTTP_X_HMAC_CLIENT,HTTP_X_HMAC_TIMESTAMP,HTTP_X_HMAC_TOKEN"
    context.kemal_authorized_client?.should eq(nil)
  end

  it "returns 401 when no headers are provided at all" do
    hmac_handler = Kemal::Hmac::Handler.new
    request = HTTP::Request.new(
      "GET",
      "/"
    )
    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.headers["missing-hmac-headers"].should eq "HTTP_X_HMAC_CLIENT,HTTP_X_HMAC_TIMESTAMP,HTTP_X_HMAC_TOKEN"
    context.kemal_authorized_client?.should eq(nil)
  end

  it "returns 401 when only the client hmac header is provided" do
    hmac_handler = Kemal::Hmac::Handler.new
    request = HTTP::Request.new(
      "GET",
      "/",
      headers: HTTP::Headers{"HTTP_X_HMAC_CLIENT" => "octo-client"},
    )
    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.headers["missing-hmac-headers"].should eq "HTTP_X_HMAC_TIMESTAMP,HTTP_X_HMAC_TOKEN"
    context.kemal_authorized_client?.should eq(nil)
  end
end
