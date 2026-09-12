Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :register, to: "authentication#register"
        post :login, to: "authentication#login"
        get :me, to: "authentication#me"
      end

      resources :users
      resources :posts
      resources :comments
      resources :likes, only: %i[index show create destroy]
      resources :followers, only: %i[create destroy]
    end
  end
end
