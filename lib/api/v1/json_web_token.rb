module Api
  module V1
    class JsonWebToken
      ALGORITHM = "HS256".freeze
      EXPIRATION = 24.hours

      def self.secret
        ENV.fetch("SECRET_KEY_BASE") { Rails.application.secret_key_base }
      end

      def self.encode(user)
        JWT.encode(
          { sub: user.id, uuid: user.uuid, jti: SecureRandom.uuid, exp: EXPIRATION.from_now.to_i },
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
    end
  end
end
