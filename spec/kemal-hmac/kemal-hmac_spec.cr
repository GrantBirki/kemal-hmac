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

    hmac_client = Kemal::Hmac::Client.new(client, "octo-secret-green", "SHA256")
    headers = hmac_client.generate_headers("/api")

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "hmac-client"    => headers["hmac-client"],
        "hmac-timestamp" => headers["hmac-timestamp"],
        "hmac-token"     => headers["hmac-token"],
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
    context.kemal_authorized_client?.should eq(client)
  end

  it "uses a custom handler and correct HMAC auth and the request flows through successfully with query string params" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
    )

    hmac_client = Kemal::Hmac::Client.new(client, "octo-secret-green", "SHA256")
    headers = hmac_client.generate_headers("/api")

    request = HTTP::Request.new(
      "GET",
      "/api?foo=bar&moon=star",
      headers: HTTP::Headers{
        "hmac-client"    => headers["hmac-client"],
        "hmac-timestamp" => headers["hmac-timestamp"],
        "hmac-token"     => headers["hmac-token"],
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
    context.kemal_authorized_client?.should eq(client)
  end

  it "uses a custom handler and correct HMAC auth and the request flows through successfully with query string params incorrecty in the client" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
    )

    hmac_client = Kemal::Hmac::Client.new(client, "octo-secret-green", "SHA256")
    headers = hmac_client.generate_headers("/api?cat=dog&moon=star&q=1")

    request = HTTP::Request.new(
      "GET",
      "/api?foo=bar&moon=star",
      headers: HTTP::Headers{
        "hmac-client"    => headers["hmac-client"],
        "hmac-timestamp" => headers["hmac-timestamp"],
        "hmac-token"     => headers["hmac-token"],
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
    context.kemal_authorized_client?.should eq(client)
  end

  it "uses a custom handler and explicit hmac algo successfully" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
      hmac_algorithm: "SHA256"
    )

    hmac_client = Kemal::Hmac::Client.new(client, "octo-secret-green", "SHA256")
    headers = hmac_client.generate_headers("/api")

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "hmac-client"    => headers["hmac-client"],
        "hmac-timestamp" => headers["hmac-timestamp"],
        "hmac-token"     => headers["hmac-token"],
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
    context.kemal_authorized_client?.should eq(client)
  end

  it "uses a custom handler and explicit hmac algo for both the client and the server successfully" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
      hmac_algorithm: "SHA512"
    )

    hmac_client = Kemal::Hmac::Client.new(client, "octo-secret-green", "SHA512")
    headers = hmac_client.generate_headers("/api")

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "hmac-client"    => headers["hmac-client"],
        "hmac-timestamp" => headers["hmac-timestamp"],
        "hmac-token"     => headers["hmac-token"],
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
    context.kemal_authorized_client?.should eq(client)
  end

  it "uses a custom handler and explicit hmac algo and fails due to a mismatch hmac algo" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
      hmac_algorithm: "SHA512"
    )

    hmac_client = Kemal::Hmac::Client.new(client, "octo-secret-green", "SHA256")
    headers = hmac_client.generate_headers("/api")

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "hmac-client"    => headers["hmac-client"],
        "hmac-timestamp" => headers["hmac-timestamp"],
        "hmac-token"     => headers["hmac-token"],
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: HMAC token does not match"
    context.kemal_authorized_client?.should eq(nil)
  end

  it "uses a custom handler and correct HMAC auth and the request flows through successfully using the green secret" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
    )

    hmac_client = Kemal::Hmac::Client.new(client, "octo-secret-green", "SHA256")
    headers = hmac_client.generate_headers("/api")

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "hmac-client"    => headers["hmac-client"],
        "hmac-timestamp" => headers["hmac-timestamp"],
        "hmac-token"     => headers["hmac-token"],
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
    context.kemal_authorized_client?.should eq(client)
  end

  it "fails when multiple of the required HMAC headers are an empty string" do
    client = "valid-octo-client"
    hmac_handler = SpecAuthHandler.new(
      hmac_secrets: {client => ["octo-secret-blue", "octo-secret-green"]},
    )

    hmac_client = Kemal::Hmac::Client.new(client, "octo-secret-green", "SHA256")
    headers = hmac_client.generate_headers("/api")

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "hmac-client"    => headers["hmac-client"],
        "hmac-timestamp" => "",
        "hmac-token"     => "",
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: empty required hmac headers"
    context.kemal_authorized_client?.should eq(nil)
    context.response.headers["empty-hmac-headers"].should eq "hmac-timestamp,hmac-token"
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
        "hmac-client"    => client,
        "hmac-timestamp" => timestamp,
        "hmac-token"     => hmac_token,
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
        "hmac-client"    => client,
        "hmac-timestamp" => timestamp,
        "hmac-token"     => hmac_token,
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
        "hmac-client"    => client,
        "hmac-timestamp" => timestamp,
        "hmac-token"     => hmac_token,
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
        "hmac-client"    => "octo-client-with-no-secrets",
        "hmac-timestamp" => Time::Format::ISO_8601_DATE_TIME.format(Time.utc),
        "hmac-token"     => "octo-token",
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
      enable_env_lookup: true
    )
    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "hmac-client"    => "octo-client-&-bad-secret",
        "hmac-timestamp" => Time::Format::ISO_8601_DATE_TIME.format(Time.utc),
        "hmac-token"     => "octo-token",
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
    response.headers["missing-hmac-headers"].should eq "hmac-client,hmac-timestamp,hmac-token"
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
    response.headers["missing-hmac-headers"].should eq "hmac-client,hmac-timestamp,hmac-token"
    response.body.should contain "Unauthorized: missing required hmac headers"
    context.kemal_authorized_client?.should eq(nil)
  end

  it "returns 401 when only the client hmac header is provided" do
    hmac_handler = Kemal::Hmac::Handler.new
    request = HTTP::Request.new(
      "GET",
      "/",
      headers: HTTP::Headers{"hmac-client" => "octo-client"},
    )
    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.headers["missing-hmac-headers"].should eq "hmac-timestamp,hmac-token"
    response.body.should contain "Unauthorized: missing required hmac headers"
    context.kemal_authorized_client?.should eq(nil)
  end

  it "returns 401 when the timestamp is not a valid ISO8601 string" do
    hmac_handler = Kemal::Hmac::Handler.new
    request = HTTP::Request.new(
      "GET",
      "/",
      headers: HTTP::Headers{
        "hmac-client"    => "octo-client",
        "hmac-timestamp" => Time.utc.to_s,
        "hmac-token"     => "octo-token",
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
        "hmac-client"    => "octo-client",
        "hmac-timestamp" => Time::Format::ISO_8601_DATE_TIME.format(Time.utc + 100.seconds),
        "hmac-token"     => "octo-token",
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
        "hmac-client"    => "octo-client",
        "hmac-timestamp" => Time::Format::ISO_8601_DATE_TIME.format(Time.utc - 100.seconds),
        "hmac-token"     => "octo-token",
      },
    )
    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: Timestamp is too old or in the future (ensure it's in UTC)"
    context.kemal_authorized_client?.should eq(nil)
  end

  it "successfully flows through and passes when fetching secrets from the ENV" do
    client = "Octo1-Client_prod"
    secret = "super-secret"
    hmac_handler = Kemal::Hmac::Handler.new(enable_env_lookup: true)
    hmac_client = Kemal::Hmac::Client.new(client, secret, "SHA256")
    headers = hmac_client.generate_headers("/api")

    ENV["#{client.upcase}_HMAC_SECRET_BLUE"] = "unset"
    ENV["#{client.upcase}_HMAC_SECRET_GREEN"] = secret

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "hmac-client"    => headers["hmac-client"],
        "hmac-timestamp" => headers["hmac-timestamp"],
        "hmac-token"     => headers["hmac-token"],
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
    context.kemal_authorized_client?.should eq(client)
  end

  it "fails to flow through when fetching secrets from the env since it is disabled by default" do
    client = "Octo1-Client_prod"
    secret = "super-secret"
    hmac_handler = Kemal::Hmac::Handler.new
    hmac_client = Kemal::Hmac::Client.new(client, secret, "SHA256")
    headers = hmac_client.generate_headers("/api")

    ENV["#{client.upcase}_HMAC_SECRET_BLUE"] = "unset"
    ENV["#{client.upcase}_HMAC_SECRET_GREEN"] = secret

    request = HTTP::Request.new(
      "GET",
      "/api",
      headers: HTTP::Headers{
        "hmac-client"    => headers["hmac-client"],
        "hmac-timestamp" => headers["hmac-timestamp"],
        "hmac-token"     => headers["hmac-token"],
      },
    )

    io, context = create_request_and_return_io_and_context(hmac_handler, request)
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 401
    response.body.should contain "Unauthorized: no secrets found for client: Octo1-Client_prod"
    context.kemal_authorized_client?.should eq(nil)
  end
end
