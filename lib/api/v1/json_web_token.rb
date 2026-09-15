module Api
  module V1
    class JsonWebToken
      ALGORITHM = "HS256".freeze
      EXPIRATION = 24.hours

      def self.encode(user = nil)
        JWT.encode(
          data_to_encode(user),
          secret,
          ALGORITHM
        )
      end

      def self.decode(token)
        payload = JWT.decode(
          token,
          secret,
          true,
          algorithm: ALGORITHM
        ).first

        RevokedToken.exists?(jti: payload["jti"]) ? nil : payload
      rescue JWT::DecodeError
        nil
      end

      def self.secret
        ENV.fetch("SECRET_KEY_BASE") { Rails.application.secret_key_base }
      end

      def self.data_to_encode(user)
        return { service: "social-api" } if user.blank?

        { sub: user.id, uuid: user.uuid, jti: SecureRandom.uuid, exp: EXPIRATION.from_now.to_i }
      end

      private_class_method :secret, :data_to_encode
    end
  end
end
