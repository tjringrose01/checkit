require Rails.root.join("app/services/mailgun_delivery_method")

ActionMailer::Base.add_delivery_method :mailgun_api, MailgunDeliveryMethod

if Rails.configuration.x.mailgun.enabled
  ActionMailer::Base.mailgun_api_settings = {
    api_key: Rails.configuration.x.mailgun.api_key,
    domain: Rails.configuration.x.mailgun.domain,
    base_url: Rails.configuration.x.mailgun.base_url
  }
end
