require "../../src/kemal-hmac"
require "crest"
require "http/client"
require "spec"

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

  it "fails to send a request with HMAC auth with the crest client to the crest-client endpoint" do
    client = Kemal::Hmac::Client.new("my_crest_client", "incorrect_secret")

    path = "/crest-client"

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
