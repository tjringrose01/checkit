require "test_helper"

class BootstrapAdminSeedTest < ActiveSupport::TestCase
  setup do
    User.delete_all
    @original_password = ENV["BOOTSTRAP_ADMIN_PASSWORD"]
    ENV["BOOTSTRAP_ADMIN_PASSWORD"] = "BootstrapPass123"
  end

  teardown do
    ENV["BOOTSTRAP_ADMIN_PASSWORD"] = @original_password
  end

  test "seed creates the initial admin account" do
    load Rails.root.join("db/seeds.rb")
    admin = User.find_by(user_id: "admin")

    assert_not_nil admin
    assert_equal "admin", admin.role
    assert admin.must_change_password?
    assert admin.authenticate("BootstrapPass123")
  end

  test "seed is idempotent for the admin account" do
    2.times { load Rails.root.join("db/seeds.rb") }

    assert_equal 1, User.where(user_id: "admin").count
  end

  test "seed does nothing when bootstrap password is not configured" do
    ENV.delete("BOOTSTRAP_ADMIN_PASSWORD")

    load Rails.root.join("db/seeds.rb")

    assert_nil User.find_by(user_id: "admin")
  end
end
