require "../../src/kemal-hmac"
require "crest"
require "http/client"
require "spec"

# before running the test, check if the server is running up to 10 times
0.upto(10) do
  begin
    response = Crest.get("http://localhost:3000/")
    break if response.status == 401
  rescue
    puts "Server not ready, retrying in 1 second"
    sleep 1.seconds
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

    response.status.should eq 200
    response.body.should contain "Hi, my_crest_client!"
  end
end

describe "http/client" do
  it "successfully sends a request with HMAC auth with the http-client to the http-client endpoint" do
    client = Kemal::Hmac::Client.new("my_standard_client", "my_secret")

    path = "/http-client"

    headers = HTTP::Headers.new
    client.generate_headers(path).each do |key, value|
      headers.add(key, value)
    end

    response = HTTP::Client.get("https://example.com#{path}", headers: headers)

    response.status.should eq 200
    response.body.should contain "Hi, my_standard_client!"
  end
end
