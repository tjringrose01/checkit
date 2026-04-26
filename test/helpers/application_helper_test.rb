require "test_helper"

class ApplicationHelperTest < ActiveSupport::TestCase
  test "build footer metadata uses configured build values" do
    helper = Class.new { include ApplicationHelper }.new

    with_env(
      "APP_NAME" => "Checkit",
      "APP_BUILD_ENVIRONMENT" => "dev",
      "APP_BUILD_NUMBER" => "99",
      "APP_BUILD_TIMESTAMP" => "2026-04-26T00:00:00Z"
    ) do
      assert_equal "dev-99", helper.build_identifier
      assert_includes helper.footer_metadata, "Build dev-99"
      assert_includes helper.footer_metadata, "Built 2026-04-26T00:00:00Z"
    end
  end

  private

  def with_env(values)
    previous = {}
    values.each do |key, value|
      previous[key] = ENV[key]
      ENV[key] = value
    end

    yield
  ensure
    values.each_key do |key|
      ENV[key] = previous[key]
    end
  end
end
