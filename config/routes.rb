Rails.application.routes.draw do
  get "/up", to: "health#show"

  resource :session, only: [ :new, :create, :destroy ]
  resource :password_change, only: [ :edit, :update ]
  resources :checklist_items, only: [] do
    resource :completion, only: [ :update ], controller: "checklist_item_completions"
  end
  namespace :admin do
    root "dashboard#show"
    resources :checklists, except: [ :show ] do
      resources :checklist_items, except: [ :index, :show ]
      resource :checklist_item_import, only: [ :create ]
    end
    resources :users, only: [] do
      member do
        patch :unlock
      end
    end
  end

  root "dashboard#show"
end
