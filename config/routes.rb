Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :register, to: "authentication#register"
        post :login, to: "authentication#login"
        delete :logout, to: "authentication#logout"
        get :me, to: "authentication#me"
        patch :me, to: "authentication#update"
        delete :me, to: "authentication#destroy"
      end

      get :feed, to: "feed#index"

      resources :users, only: [] do
        get :followers, on: :collection
        get :following, on: :collection
        post :follow, on: :member
        delete :follow, on: :member, action: :unfollow
      end

      resources :posts, only: %i[index show create update destroy] do
        resources :comments, only: %i[create update destroy]
        resources :likes, only: %i[create destroy]
      end
    end
  end
end
