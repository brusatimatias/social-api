module Api
  module V1
    module Auth
      class AuthenticationController < Api::V1::ApplicationController
        before_action :authenticate_user!, only: :me

        def register
          user = User.new(user_params)

          if user.save
            render json: { user: user, token: issue_token(user) }, status: :created
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def login
          user = User.find_by(email: login_params[:email].to_s.strip.downcase)

          if user&.authenticate(login_params[:password])
            render json: { user: user, token: issue_token(user) }
          else
            render json: { error: "Invalid email or password" }, status: :unauthorized
          end
        end

        def me
          render json: current_user
        end

        private

        def user_params
          params.require(:user).permit(
            :name,
            :lastname,
            :email,
            :password,
            :password_confirmation
          )
        end

        def login_params
          params.require(:auth).permit(:email, :password)
        end
      end
    end
  end
end
