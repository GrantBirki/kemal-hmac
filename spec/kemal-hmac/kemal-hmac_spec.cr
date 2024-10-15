require "../spec_helper"

describe "Kemal::Hmac" do
  it "uses a custom handler with path matching and sends a request to an endpoint that does not require hmac auth" do
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {"octo-client" => ["octo-secret-blue", "octo-secret-green"]},
    )
    request = HTTP::Request.new(
      "GET",
      "/health"
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
    context.kemal_authorized_client?.should be nil
  end

  it "uses a custom handler and correct HMAC auth and the request flows through successfully" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
    )

    timestamp = Time::Format::ISO_8601_DATE_TIME.format(Time.utc)
    hmac_token = Kemal::Hmac::Token.new(client, "/api", timestamp).hexdigest("octo-secret-blue")

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "HTTP_X_HMAC_CLIENT"    => client,
        "HTTP_X_HMAC_TIMESTAMP" => timestamp,
        "HTTP_X_HMAC_TOKEN"     => hmac_token,
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
    context.kemal_authorized_client?.should eq(client)
  end

  it "uses a custom handler and correct HMAC auth and the request flows through successfully using the green secret" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
    )

    timestamp = Time::Format::ISO_8601_DATE_TIME.format(Time.utc)
    hmac_token = Kemal::Hmac::Token.new(client, "/api", timestamp).hexdigest("octo-secret-green")

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "HTTP_X_HMAC_CLIENT"    => client,
        "HTTP_X_HMAC_TIMESTAMP" => timestamp,
        "HTTP_X_HMAC_TOKEN"     => hmac_token,
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
    context.kemal_authorized_client?.should eq(client)
  end

  it "rejects the request when the HMAC token does not match exactly" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
    )

    timestamp = Time::Format::ISO_8601_DATE_TIME.format(Time.utc)
    hmac_token = Kemal::Hmac::Token.new(client, "/api", timestamp).hexdigest("octoo-secret-blue")

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "HTTP_X_HMAC_CLIENT"    => client,
        "HTTP_X_HMAC_TIMESTAMP" => timestamp,
        "HTTP_X_HMAC_TOKEN"     => hmac_token,
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: HMAC token does not match"
    context.kemal_authorized_client?.should be nil
  end

  it "rejects the request when the HMAC token does not match exactly due to a different path" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
    )

    timestamp = Time::Format::ISO_8601_DATE_TIME.format(Time.utc)
    hmac_token = Kemal::Hmac::Token.new(client, "/api", timestamp).hexdigest("octo-secret-blue")

    request = HTTP::Request.new(
      "GET",
      "/secure",
      headers: HTTP::Headers{
        "HTTP_X_HMAC_CLIENT"    => client,
        "HTTP_X_HMAC_TIMESTAMP" => timestamp,
        "HTTP_X_HMAC_TOKEN"     => hmac_token,
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: HMAC token does not match"
    context.kemal_authorized_client?.should be nil
  end

  it "rejects the request when the HMAC token does not match exactly since the timestamp is different" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
    )

    timestamp = Time::Format::ISO_8601_DATE_TIME.format(Time.utc + 1.second)
    hmac_token = Kemal::Hmac::Token.new(client, "/api", timestamp).hexdigest("octoo-secret-blue")

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "HTTP_X_HMAC_CLIENT"    => client,
        "HTTP_X_HMAC_TIMESTAMP" => timestamp,
        "HTTP_X_HMAC_TOKEN"     => hmac_token,
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: HMAC token does not match"
    context.kemal_authorized_client?.should be nil
  end

  it "uses a custom handler and fails due to no matching client secrets" do
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {} of String => Array(String),
    )
    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "HTTP_X_HMAC_CLIENT"    => "octo-client-with-no-secrets",
        "HTTP_X_HMAC_TIMESTAMP" => Time::Format::ISO_8601_DATE_TIME.format(Time.utc),
        "HTTP_X_HMAC_TOKEN"     => "octo-token",
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: no secrets found for client: octo-client-with-no-secrets"
    context.kemal_authorized_client?.should be nil
  end

  it "uses a custom handler and fails due to a failed secret regex match" do
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {} of String => Array(String),
    )
    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "HTTP_X_HMAC_CLIENT"    => "octo-client-&-bad-secret",
        "HTTP_X_HMAC_TIMESTAMP" => Time::Format::ISO_8601_DATE_TIME.format(Time.utc),
        "HTTP_X_HMAC_TOKEN"     => "octo-token",
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: client name must only contain letters, numbers, -, or _"
    context.kemal_authorized_client?.should be nil
  end

  it "calls the hmac_auth helper method without errors" do
    hmac_auth[0].to_s.should contain "Kemal::Hmac::Handler"
  end

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
    response.body.should contain "Unauthorized: missing required hmac headers"
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
    response.body.should contain "Unauthorized: missing required hmac headers"
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
    response.body.should contain "Unauthorized: missing required hmac headers"
    context.kemal_authorized_client?.should eq(nil)
  end

  it "returns 401 when the timestamp is not a valid ISO8601 string" do
    hmac_handler = Kemal::Hmac::Handler.new
    request = HTTP::Request.new(
      "GET",
      "/",
      headers: HTTP::Headers{
        "HTTP_X_HMAC_CLIENT"    => "octo-client",
        "HTTP_X_HMAC_TIMESTAMP" => Time.utc.to_s,
        "HTTP_X_HMAC_TOKEN"     => "octo-token",
      },
    )
    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: Timestamp isn't a valid ISO8601 string"
    context.kemal_authorized_client?.should eq(nil)
  end

  it "returns 401 when the timestamp is too far in the future" do
    hmac_handler = Kemal::Hmac::Handler.new
    request = HTTP::Request.new(
      "GET",
      "/",
      headers: HTTP::Headers{
        "HTTP_X_HMAC_CLIENT"    => "octo-client",
        "HTTP_X_HMAC_TIMESTAMP" => Time::Format::ISO_8601_DATE_TIME.format(Time.utc + 100.seconds),
        "HTTP_X_HMAC_TOKEN"     => "octo-token",
      },
    )
    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: Timestamp is too old or in the future (ensure it's in UTC)"
    context.kemal_authorized_client?.should eq(nil)
  end

  it "returns 401 when the timestamp is too far in the past" do
    hmac_handler = Kemal::Hmac::Handler.new
    request = HTTP::Request.new(
      "GET",
      "/",
      headers: HTTP::Headers{
        "HTTP_X_HMAC_CLIENT"    => "octo-client",
        "HTTP_X_HMAC_TIMESTAMP" => Time::Format::ISO_8601_DATE_TIME.format(Time.utc - 100.seconds),
        "HTTP_X_HMAC_TOKEN"     => "octo-token",
      },
    )
    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: Timestamp is too old or in the future (ensure it's in UTC)"
    context.kemal_authorized_client?.should eq(nil)
  end
end
