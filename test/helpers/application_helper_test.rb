require "test_helper"

class ApplicationHelperTest < ActiveSupport::TestCase
  test "build footer metadata uses configured build values" do
    helper = ApplicationController.helpers

    with_env(
      "APP_NAME" => "Checkit",
      "APP_BUILD_ENVIRONMENT" => "dev",
      "APP_BUILD_NUMBER" => "99",
      "APP_BUILD_TIMESTAMP" => "2026-04-26T00:00:00Z",
      "APP_GIT_SHA" => "abcdef1234567890"
    ) do
      assert_equal "dev-99", helper.build_identifier
      assert_equal "Commit abcdef123456", helper.version_or_revision_label
      assert_equal [
        "Checkit",
        "Copyright #{Time.current.year}",
        "Dev Environment",
        "Build dev-99"
      ], helper.footer_metadata
      assert_match "Built", helper.footer_build_timestamp
      assert_match "data-local-datetime", helper.footer_build_timestamp
    end
  end

  test "build footer prefers application version over git sha when available" do
    helper = ApplicationController.helpers

    with_env(
      "APP_VERSION" => "v1.2.3",
      "APP_GIT_SHA" => "abcdef1234567890"
    ) do
      assert_equal "Version v1.2.3", helper.version_or_revision_label
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
