namespace :revoked_tokens do
  desc "Delete revoked token records past their original JWT expiry (safe to run periodically, e.g. via cron)"
  task purge_expired: :environment do
    count = RevokedToken.expired.delete_all
    puts "Purged #{count} expired revoked token(s)."
  end
end
