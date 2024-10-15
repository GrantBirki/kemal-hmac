require "kemal"
require "../../src/kemal-hmac"

hmac_auth({"my_crest_client" => ["my_secret"], "my_standard_client" => ["my_secret_1", "my_secret_2"]})

get "/" do |env|
  "Hi, %s! You sent a request that was successfully verified with HMAC auth" % env.kemal_authorized_client?
end

get "/http-client" do |env|
  "Hi, %s! You sent a request that was successfully verified with HMAC auth for the http-client" % env.kemal_authorized_client?
end

get "/crest-client" do |env|
  "Hi, %s! You sent a request that was successfully verified with HMAC auth for the crest-client" % env.kemal_authorized_client?
end

Kemal.run
