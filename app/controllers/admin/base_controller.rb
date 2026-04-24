module Admin
  class BaseController < ApplicationController
    before_action :require_authentication
    before_action :require_password_change
    before_action :require_admin
  end
end
