require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Checkit
  class Application < Rails::Application
    config.load_defaults 7.1
    config.generators.system_tests = nil
    config.time_zone = "UTC"
  end
end
