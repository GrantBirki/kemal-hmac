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

post "/submit" do |env|
  "Hi, %s! I got your POST request" % env.kemal_authorized_client?
end

# catch-all routes for all other requests and methods
# ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
get "/catch-all" do |env|
  "Hi, %s! Welcome to catch-all" % env.kemal_authorized_client?
end

post "/catch-all" do |env|
  "Hi, %s! Welcome to catch-all" % env.kemal_authorized_client?
end

put "/catch-all" do |env|
  "Hi, %s! Welcome to catch-all" % env.kemal_authorized_client?
end

patch "/catch-all" do |env|
  "Hi, %s! Welcome to catch-all" % env.kemal_authorized_client?
end

delete "/catch-all" do |env|
  "Hi, %s! Welcome to catch-all" % env.kemal_authorized_client?
end

options "/catch-all" do |env|
  "Hi, %s! Welcome to catch-all" % env.kemal_authorized_client?
end

Kemal.run
