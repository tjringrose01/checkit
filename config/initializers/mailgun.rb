require Rails.root.join("app/services/mailgun_delivery_method")

ActionMailer::Base.add_delivery_method :mailgun_api, MailgunDeliveryMethod
