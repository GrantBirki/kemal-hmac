require "../../src/kemal-hmac"
require "crest"
require "http/client"
require "http/web_socket"
require "spec"

describe "websocket" do
  it "successfully sends a websocket request to the server with HMAC auth" do
    hmac_client = Kemal::Hmac::Client.new("my_ws_client", "my_secret_3")

    path = "/websocket"

    headers = HTTP::Headers.new
    hmac_client.generate_headers(path).each do |key, value|
      headers.add(key, value)
    end

    # Open websocket connection
    ws = HTTP::WebSocket.new(
      URI.parse("ws://localhost:3000/websocket"),
      headers: headers
    )

    response = ""

    # Set callback
    ws.on_message do |msg|
      response = msg
    end

    ws.run
    ws.close

    response.should eq "websocket success"
  end

  it "does not provide HMAC headers and fails the websocket request" do
    hmac_client = Kemal::Hmac::Client.new("my_ws_client", "invalid_secret")

    path = "/websocket"

    headers = HTTP::Headers.new
    hmac_client.generate_headers(path).each do |key, value|
      headers.add(key, value)
    end

    begin
      ws = HTTP::WebSocket.new(
        URI.parse("ws://localhost:3000/websocket"),
        headers: headers
      )
    rescue ex : Socket::Error
      ex.message.not_nil!.should contain "Handshake got denied. Status code was 401."
    end
  end

  it "does not provide the correct HMAC headers and fails the websocket request" do
    begin
      ws = HTTP::WebSocket.new(
        URI.parse("ws://localhost:3000/websocket"),
        headers: HTTP::Headers.new
      )
    rescue ex : Socket::Error
      ex.message.not_nil!.should contain "Handshake got denied. Status code was 401."
    end
  end
end

describe "All HTTP Methods" do
  ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"].each do |method|
    it "successfully validates a #{method} request" do
      hmac_client = Kemal::Hmac::Client.new("my_standard_client", "my_secret_2")

      path = "/catch-all"

      headers = HTTP::Headers.new
      hmac_client.generate_headers(path).each do |key, value|
        headers.add(key, value)
      end

      request = HTTP::Request.new(
        method,
        path,
        headers: headers,
      )

      uri = URI.parse("http://localhost:3000")
      http_client = HTTP::Client.new(uri)

      response = http_client.exec(request)

      response.status_code.should eq 200
      response.body.should contain "Hi, my_standard_client! Welcome to catch-all"
    end
  end
end

describe "crest" do
  it "successfully sends a request with HMAC auth with the crest client to the crest-client endpoint" do
    client = Kemal::Hmac::Client.new("my_crest_client", "my_secret")

    path = "/crest-client"

    response = Crest.get(
      "http://localhost:3000#{path}",
      headers: client.generate_headers(path)
    )

    response.status_code.should eq 200
    response.body.should contain "Hi, my_crest_client!"
  end

  it "successfully sends a request with HMAC auth with the crest client to the crest-client endpoint with query string params" do
    client = Kemal::Hmac::Client.new("my_crest_client", "my_secret")

    path = "/crest-client"

    response = Crest.get(
      "http://localhost:3000#{path}",
      headers: client.generate_headers(path)
    )

    response.status_code.should eq 200
    response.body.should contain "Hi, my_crest_client!"
  end

  it "fails to send a request with HMAC auth with the crest client to the crest-client endpoint" do
    client = Kemal::Hmac::Client.new("my_crest_client", "incorrect_secret")

    path = "/crest-client?foo=bar&q=baz&operation=1/2"

    begin
      Crest.get(
        "http://localhost:3000#{path}",
        headers: client.generate_headers(path)
      )
    rescue ex : Crest::Unauthorized
      ex.response.status_code.should eq 401
      ex.response.body.should contain "Unauthorized: HMAC token does not match"
    end
  end

  it "fails to send a request with HMAC auth to an endpoint using the POST HTTP verb" do
    client = Kemal::Hmac::Client.new("my_crest_client", "incorrect_secret")

    path = "/submit"

    begin
      Crest.post(
        "http://localhost:3000#{path}",
        headers: client.generate_headers(path)
      )
    rescue ex : Crest::Unauthorized
      ex.response.status_code.should eq 401
      ex.response.body.should contain "Unauthorized: HMAC token does not match"
    end
  end

  it "successfully sends a request with HMAC auth with the crest client an endpoint using the POST HTTP verb" do
    client = Kemal::Hmac::Client.new("my_crest_client", "my_secret")

    path = "/submit"

    response = Crest.post(
      "http://localhost:3000#{path}",
      headers: client.generate_headers(path)
    )

    response.status_code.should eq 200
    response.body.should contain "Hi, my_crest_client! I got your POST request"
  end
end

describe "http/client" do
  it "successfully sends a request with HMAC auth with the http-client to the http-client endpoint" do
    client = Kemal::Hmac::Client.new("my_standard_client", "my_secret_2")

    path = "/http-client"

    headers = HTTP::Headers.new
    client.generate_headers(path).each do |key, value|
      headers.add(key, value)
    end

    response = HTTP::Client.get("http://localhost:3000#{path}", headers: headers)

    response.status_code.should eq 200
    response.body.should contain "Hi, my_standard_client!"
  end

  it "successfully sends a request with HMAC auth with the http-client to an endpoint using the POST HTTP verb" do
    client = Kemal::Hmac::Client.new("my_standard_client", "my_secret_2")

    path = "/submit"

    headers = HTTP::Headers.new
    client.generate_headers(path).each do |key, value|
      headers.add(key, value)
    end

    response = HTTP::Client.post("http://localhost:3000#{path}", headers: headers)

    response.status_code.should eq 200
    response.body.should contain "Hi, my_standard_client! I got your POST request"
  end

  it "successfully sends a request with HMAC auth with the http-client to the http-client endpoint with query string params" do
    client = Kemal::Hmac::Client.new("my_standard_client", "my_secret_2")

    path = "/http-client?foo=bar&q=baz&operation=1/2"

    headers = HTTP::Headers.new
    client.generate_headers(path).each do |key, value|
      headers.add(key, value)
    end

    response = HTTP::Client.get("http://localhost:3000#{path}", headers: headers)

    response.status_code.should eq 200
    response.body.should contain "Hi, my_standard_client!"
  end

  it "fails to send a request with HMAC auth with the http-client to the http-client endpoint" do
    client = Kemal::Hmac::Client.new("my_standard_client", "bad_secret")

    path = "/http-client"

    headers = HTTP::Headers.new
    client.generate_headers(path).each do |key, value|
      headers.add(key, value)
    end

    response = HTTP::Client.get("http://localhost:3000#{path}", headers: headers)

    response.status_code.should eq 401
    response.body.should contain "Unauthorized: HMAC token does not match"
  end

  it "fails to send a request with HMAC auth with the http-client to the http-client endpoint due to an unknown client" do
    client = Kemal::Hmac::Client.new("unknown_client", "_")

    path = "/http-client"

    headers = HTTP::Headers.new
    client.generate_headers(path).each do |key, value|
      headers.add(key, value)
    end

    response = HTTP::Client.get("http://localhost:3000#{path}", headers: headers)

    response.status_code.should eq 401
    response.body.should contain "Unauthorized: no secrets found for client: unknown_client"
  end

  it "fails to send a request with HMAC auth with the http-client to the http-client endpoint due to a path mismatch" do
    client = Kemal::Hmac::Client.new("my_standard_client", "my_secret_2")

    path = "/http-client"

    headers = HTTP::Headers.new
    client.generate_headers(path).each do |key, value|
      headers.add(key, value)
    end

    response = HTTP::Client.get("http://localhost:3000/", headers: headers)

    response.status_code.should eq 401
    response.body.should contain "Unauthorized: HMAC token does not match"
  end
end
