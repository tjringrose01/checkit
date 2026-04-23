class DashboardController < ApplicationController
  before_action :require_authentication
  before_action :require_password_change

  def show; end
end
