Rails.application.routes.draw do
  root "health#show"
  get "/up", to: "health#show"
end
