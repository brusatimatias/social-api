module Api
  module V1
    module Auth
      class AuthenticationController < Api::V1::ApplicationController
        skip_before_action :authenticate_user!, only: %i[register login]

        def register
          user = User.new(user_params)

          if user.save
            render json: Api::V1::Response.success(
              data: { user: user, token: issue_token(user) }
            ), status: :created
          else
            render json: Api::V1::Response.error(user.errors.full_messages), status: :unprocessable_entity
          end
        end

        def login
          user = User.find_by(email: login_params[:email].to_s.strip.downcase)

          if user&.authenticate(login_params[:password])
            render json: Api::V1::Response.success(
              data: { user: user, token: issue_token(user) }
            )
          else
            render json: Api::V1::Response.error("Invalid email or password"), status: :unauthorized
          end
        end

        def logout
          RevokedToken.create!(
            user: current_user,
            jti: decoded_token["jti"],
            expires_at: Time.at(decoded_token["exp"])
          )

          render json: Api::V1::Response.success(data: { message: "Logged out" })
        end

        def me
          render json: Api::V1::Response.success(data: current_user)
        end

        def update
          if current_user.update(user_params)
            render json: Api::V1::Response.success(data: current_user)
          else
            render json: Api::V1::Response.error(
              current_user.errors.full_messages
            ), status: :unprocessable_entity
          end
        end

        def destroy
          if current_user.destroy
            render json: Api::V1::Response.success(data: current_user)
          else
            render json: Api::V1::Response.error(
              current_user.errors.full_messages
            ), status: :unprocessable_entity
          end
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
