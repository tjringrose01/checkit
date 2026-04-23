class HealthController < ApplicationController
  def show
    render json: { status: "ok", service: "checkit" }
  end
end
