require "test_helper"
require "base64"

class MailgunDeliveryMethodTest < ActiveSupport::TestCase
  test "posts email payload to the configured mailgun endpoint" do
    delivery_method = MailgunDeliveryMethod.new(
      api_key: "key-test",
      domain: "mg.example.com",
      base_url: "https://api.mailgun.net"
    )
    mail = Mail.new(
      from: "postmaster@mg.example.com",
      to: "recipient@example.com",
      subject: "Hello",
      body: "Plain body"
    )

    request_capture = nil
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.instance_variable_set(:@read, true)

    original_start = Net::HTTP.method(:start)

    Net::HTTP.define_singleton_method(:start) do |host, port, use_ssl:, &block|
      http = Object.new
      http.define_singleton_method(:request) do |request|
        request_capture = request
        response
      end
      block.call(http)
    end

    begin
      delivery_method.deliver!(mail)
    ensure
      Net::HTTP.define_singleton_method(:start, original_start)
    end

    assert_equal "api.mailgun.net", request_capture.uri.host
    assert_equal "/v3/mg.example.com/messages", request_capture.uri.path
    assert_equal "Basic #{Base64.strict_encode64('api:key-test')}", request_capture["authorization"]
    assert_includes request_capture["content-type"], "multipart/form-data"
  end
end
