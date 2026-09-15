class SocialMessagingApiClient
  class Error < StandardError; end

  def self.upsert_user(uuid:, name:, lastname:, full_name:)
    response = connection.put(user_path(uuid)) do |req|
      req.body = { name: name, lastname: lastname, fullName: full_name }
    end

    raise Error, "upsert failed: #{response.status}" unless response.success?
  end

  def self.delete_user(uuid:)
    response = connection.delete(user_path(uuid))

    raise Error, "delete failed: #{response.status}" unless response.success? || response.status == 404
  end

  def self.user_path(uuid)
    "/api/v1/internal/users/#{uuid}"
  end
  private_class_method :user_path

  def self.connection
    Faraday.new(url: ENV.fetch("SOCIAL_MESSAGING_API_URL")) do |f|
      f.request :json
      f.headers["Authorization"] = "Bearer #{Api::V1::JsonWebToken.encode}"
      f.adapter Faraday.default_adapter
    end
  end
  private_class_method :connection
end
