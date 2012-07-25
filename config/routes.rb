require 'api_constraints'

UKTradeTariff::Application.routes.draw do
  namespace :api, defaults: {format: 'json'}, path: "/" do
    # How (or even if) API versioning will be implemented is still an open question. We can defer
    # the choice until we need to expose the API to clients which we don't control.
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :sections, only: [:index, :show], constraints: { id: /\d{1,2}/ }
      resources :chapters, only: [:show], constraints: { id: /\d{2}/ }
      resources :headings, only: [:show], constraints: { id: /\d{4}/ }
      resources :commodities, only: [:show, :update], constraints: { id: /\d{12}/ }

      post "search" => "search#search", via: :post, as: :search
    end
  end

  match "/stats", to: 'home#stats'

  root to: 'home#show'

  match '*path', to: 'home#not_found'
end
