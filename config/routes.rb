Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :register, to: "authentication#register"
        post :login, to: "authentication#login"
        get :me, to: "authentication#me"
      end

      resources :users, only: %i[index show update destroy] do
        get :followers, on: :member
        get :following, on: :member
        post :follow, on: :member
        delete :follow, on: :member, action: :unfollow
      end

      resources :posts, only: %i[index show create update destroy] do
        resources :comments, only: %i[index create update destroy]
        resources :likes, only: %i[index create destroy]
      end
    end
  end
end
