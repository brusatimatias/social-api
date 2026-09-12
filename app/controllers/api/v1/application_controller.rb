module Api
  module V1
    class ApplicationController < ::ApplicationController
      private

      def authenticate_user!
        return if current_user

        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def current_user
        return @current_user if defined?(@current_user)

        @current_user = User.find_by(id: decoded_token["sub"]) if decoded_token
      end

      def issue_token(user)
        JWT.encode(
          { sub: user.id, exp: 24.hours.from_now.to_i },
          Rails.application.secret_key_base,
          "HS256"
        )
      end

      def decoded_token
        return @decoded_token if defined?(@decoded_token)

        token = request.headers["Authorization"].to_s.split(" ").last
        @decoded_token = JWT.decode(
          token,
          Rails.application.secret_key_base,
          true,
          algorithm: "HS256"
        ).first
      rescue JWT::DecodeError
        @decoded_token = nil
      end
    end
  end
end
