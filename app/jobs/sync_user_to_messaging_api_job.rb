class SyncUserToMessagingApiJob < ApplicationJob
  UPSERT = "upsert".freeze
  DELETE = "delete".freeze

  queue_as :default

  retry_on SocialMessagingApiClient::Error, Faraday::ConnectionFailed, wait: :polynomially_longer, attempts: 5

  def perform(action, uuid, attributes = {})
    case action
    when UPSERT then SocialMessagingApiClient.upsert_user(uuid: uuid, **attributes.symbolize_keys)
    when DELETE then SocialMessagingApiClient.delete_user(uuid: uuid)
    end
  end
end
