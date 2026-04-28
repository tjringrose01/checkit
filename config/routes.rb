Rails.application.routes.draw do
  get "/up", to: "health#show"

  resource :session, only: [ :new, :create, :destroy ]
  resource :registration, only: [ :new, :create ]
  resource :password_reset_request, only: [ :new, :create ]
  resource :password_reset_verification, only: [ :show, :create ] do
    patch :resend
  end
  resource :password_reset, only: [ :edit, :update ]
  resource :email_verification, only: [ :show, :create ] do
    patch :resend
  end
  resource :password_change, only: [ :edit, :update ]
  resources :checklists, only: [ :show ], controller: "dashboard" do
    resource :reset, only: [ :update ], controller: "checklist_resets"
  end
  resources :checklist_items, only: [] do
    resource :completion, only: [ :update ], controller: "checklist_item_completions"
  end
  namespace :admin do
    root "dashboard#show"
    resources :checklists do
      resources :checklist_items, except: [ :index, :show ]
      resource :checklist_item_import, only: [ :create ]
    end
    resources :users, only: %i[index show destroy] do
      member do
        patch :enable
        patch :disable
        patch :unlock
        patch :update_profile
        patch :reset_password
        patch :update_role
      end
    end
  end

  root "dashboard#index"
end
