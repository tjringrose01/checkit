bootstrap_password = ENV["BOOTSTRAP_ADMIN_PASSWORD"].to_s

if bootstrap_password.empty?
  warn "Skipping bootstrap admin seed because BOOTSTRAP_ADMIN_PASSWORD is not set."
  return
end

admin = User.find_or_initialize_by(user_id: "admin")

admin.email = "admin@example.com" if admin.email.blank?
admin.role = "admin"
admin.must_change_password = true

if admin.new_record?
  admin.password = bootstrap_password
  admin.password_confirmation = bootstrap_password
end

admin.save!
