namespace :social_messaging_api do
  desc "Sync every active user to social-messaging-api (backfill)"
  task sync_users: :environment do
    count = 0

    User.find_each do |user|
      SocialMessagingApiClient.upsert_user(
        uuid: user.uuid, name: user.name, lastname: user.lastname, full_name: user.full_name
      )
      count += 1
    end

    puts "Synced #{count} user(s)."
  end
end
