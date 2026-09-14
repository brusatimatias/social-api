ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
require "rspec/rails"

abort("The Rails environment is running in production mode!") if Rails.env.production?

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.global_fixtures = :all
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before { ActiveStorage::Current.url_options = { protocol: "http", host: "test.host", port: nil } }

  config.include Module.new {
    def auth_headers(user = users(:one))
      token = JWT.encode(
        { sub: user.id, exp: 24.hours.from_now.to_i },
        Rails.application.secret_key_base,
        "HS256"
      )

      { "Authorization" => "Bearer #{token}" }
    end
  }, type: :request
end
