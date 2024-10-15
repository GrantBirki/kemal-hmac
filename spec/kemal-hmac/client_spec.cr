require "../spec_helper"

describe "Kemal::Hmac::Client" do
  it "successfully generates a client instance" do
    client = Kemal::Hmac::Client.new("test", "test")
    client.should_not be_nil
  end

  it "successfully generates a client instance with a custom algorithm" do
    client = Kemal::Hmac::Client.new("test", "test", "SHA512")
    client.should_not be_nil
  end

  it "should raise an exception if the client name is invalid" do
    begin
      Kemal::Hmac::Client.new("te#!sT", "test", "SHA512")
    rescue e : Kemal::Hmac::InvalidFormatError
      e.message.should eq("client name must only contain letters, numbers, -, or _")
    end
  end

  it "should generate the proper HMAC headers" do
    client = Kemal::Hmac::Client.new("test-client", "super-secret")
    headers = client.generate_headers("/api/path")

    headers["hmac-client"].should eq("test-client")
    headers["hmac-timestamp"].should match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    headers["hmac-token"].should match(/[a-f0-9]{64}/)

    Time.parse_iso8601(headers["hmac-timestamp"]).should_not be_nil
  end
end
