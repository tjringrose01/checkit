class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.configuration.x.mailgun.from_address || "no-reply@example.invalid" }
  layout nil
end
