require "net/http"

class MailgunDeliveryMethod
  class DeliveryError < StandardError; end

  def initialize(values)
    @api_key = values.fetch(:api_key)
    @domain = values.fetch(:domain)
    @base_url = values.fetch(:base_url)
  end

  def deliver!(mail)
    request = Net::HTTP::Post.new(endpoint)
    request.basic_auth("api", api_key)
    request.set_form(form_fields_for(mail), "multipart/form-data")

    response = Net::HTTP.start(endpoint.hostname, endpoint.port, use_ssl: endpoint.scheme == "https") do |http|
      http.request(request)
    end

    return response if response.is_a?(Net::HTTPSuccess)

    raise DeliveryError, "Mailgun delivery failed: #{response.code} #{response.body}"
  end

  private

  attr_reader :api_key, :domain, :base_url

  def endpoint
    normalized_base_url = base_url.to_s.sub(%r{/*\z}, "").sub(%r{/v3\z}, "")
    URI.parse("#{normalized_base_url}/v3/#{domain}/messages")
  end

  def form_fields_for(mail)
    fields = [ [ "from", Array(mail.from).first ] ]
    add_recipient_fields(fields, "to", mail.to)
    add_recipient_fields(fields, "cc", mail.cc)
    add_recipient_fields(fields, "bcc", mail.bcc)
    fields << [ "subject", mail.subject.to_s ]

    text_body = mail.text_part&.decoded || mail.body.decoded
    html_body = mail.html_part&.decoded

    fields << [ "text", text_body ] if text_body.present?
    fields << [ "html", html_body ] if html_body.present?
    fields
  end

  def add_recipient_fields(fields, field_name, recipients)
    Array(recipients).compact.each do |recipient|
      fields << [ field_name, recipient ]
    end
  end
end
