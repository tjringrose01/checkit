Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.require_master_key = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.log_level = :info
  config.log_tags = [ :request_id ]
  config.active_support.report_deprecations = false
  config.active_storage.service = :local
  config.force_ssl = false
  config.secret_key_base = ENV["SECRET_KEY_BASE"] if ENV["SECRET_KEY_BASE"].present?
end
