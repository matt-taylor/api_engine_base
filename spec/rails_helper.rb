ENV["RAILS_ENV"] = "test"

if ENV["CI"] == "true"
  require "simplecov"
  # Needs to be loaded prior to application start
  SimpleCov.start do
    load_profile "rails" # load_adapter < 0.8
    enable_coverage :branch
    add_filter "rails_app/"
    add_group "Services","app/services"
    add_group "Configuration","lib/command_tower/configuration"
  end
end

require File.expand_path("../rails_app/config/environment.rb", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in <#{Rails.env}> mode!") unless Rails.env.test?
require "rspec/rails"

# Add additional requires below this line. Rails is not loaded until this point!
require "pry"
require "null_logger"
require "rails-controller-testing"
Rails::Controller::Testing.install
require "database_cleaner/active_record"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.around do |example|
    if example.metadata[:with_rbac_setup]
      CommandTower::Authorization::Role.roles_reset!
      CommandTower::Authorization::Entity.entities_reset!
      CommandTower::Authorization.mapped_controllers_reset!
      CommandTower::Authorization.default_defined!

      example.run

      CommandTower::Authorization::Role.roles_reset!
      CommandTower::Authorization::Entity.entities_reset!
      CommandTower::Authorization.mapped_controllers_reset!
    else
      example.run
    end
  end

  config.around do |example|
    if example.metadata[:with_rbac_zero]
      CommandTower::Authorization::Role.roles_reset!
      CommandTower::Authorization::Entity.entities_reset!
      CommandTower::Authorization.mapped_controllers_reset!

      example.run

      CommandTower::Authorization::Role.roles_reset!
      CommandTower::Authorization::Entity.entities_reset!
      CommandTower::Authorization.mapped_controllers_reset!
    else
      example.run
    end
  end

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.filter_rails_from_backtrace!

  require "command_tower/spec_helper"
  config.include CommandTower::SpecHelper

  require "timecop"
  config.before(:each) do
    DatabaseCleaner.start
    Rails.cache.clear
    Timecop.freeze(Time.zone.now)
  end

  config.after(:each) do
    DatabaseCleaner.clean
    Timecop.return
  end
end
