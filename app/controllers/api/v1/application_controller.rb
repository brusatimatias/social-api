module Api
  module V1
    class ApplicationController < ::ApplicationController
      before_action :authenticate_user!
      rescue_from ActionController::ParameterMissing, with: :render_parameter_error
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from Posts::FeedQuery::InvalidPagination, with: :render_pagination_error

      private

      def authenticate_user!
        return if current_user

        render json: Api::V1::Response.error("Unauthorized"), status: :unauthorized
      end

      def render_parameter_error(error)
        render json: Api::V1::Response.error(error.message), status: :bad_request
      end

      def render_not_found
        render json: Api::V1::Response.error("Resource not found"), status: :not_found
      end

      def render_pagination_error(error)
        render json: Api::V1::Response.error(error.message), status: :bad_request
      end

      def current_user
        return @current_user if defined?(@current_user)

        @current_user = User.find_by(id: decoded_token["sub"]) if decoded_token
      end

      def issue_token(user)
        JWT.encode(
          { sub: user.id, jti: SecureRandom.uuid, exp: 24.hours.from_now.to_i },
          Rails.application.secret_key_base,
          "HS256"
        )
      end

      def decoded_token
        return @decoded_token if defined?(@decoded_token)

        token = request.headers["Authorization"].to_s.split(" ").last
        payload = JWT.decode(
          token,
          Rails.application.secret_key_base,
          true,
          algorithm: "HS256"
        ).first

        @decoded_token = RevokedToken.exists?(jti: payload["jti"]) ? nil : payload
      rescue JWT::DecodeError
        @decoded_token = nil
      end
    end
  end
end
