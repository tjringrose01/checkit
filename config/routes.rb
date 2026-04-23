Rails.application.routes.draw do
  get "/up", to: "health#show"

  resource :session, only: [ :new, :create, :destroy ]
  resource :password_change, only: [ :edit, :update ]

  root "dashboard#show"
end
