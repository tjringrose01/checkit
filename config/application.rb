require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Checkit
  class Application < Rails::Application
    config.load_defaults 7.1
    config.generators.system_tests = nil
    config.time_zone = "UTC"
    config.x.mailgun.api_key = ENV["MAILGUN_API_KEY"]
    config.x.mailgun.domain = ENV["MAILGUN_DOMAIN"]
    config.x.mailgun.base_url = ENV.fetch("MAILGUN_BASE_URL", "https://api.mailgun.net")
    config.x.mailgun.from_address =
      ENV["MAILGUN_FROM_ADDRESS"].presence || begin
        domain = config.x.mailgun.domain
        "postmaster@#{domain}" if domain.present?
      end
    config.x.mailgun.enabled =
      config.x.mailgun.api_key.present? &&
      config.x.mailgun.domain.present? &&
      config.x.mailgun.from_address.present?
  end
end
