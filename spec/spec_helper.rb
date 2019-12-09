require "bundler/setup"
require "declarative_policy"
require 'active_record'
require "byebug"
require "database_cleaner"

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib'))
MODELS = File.join(File.dirname(__FILE__), 'models')
$LOAD_PATH.unshift(MODELS)
SUPPORT = File.join(File.dirname(__FILE__), 'support')
Dir[File.join(SUPPORT, '*.rb')].reject { |filename| filename =~ /_seed.rb$/ }.sort.each { |file| require file }
POLICIES = File.join(File.dirname(__FILE__), 'policies')
$LOAD_PATH.unshift(POLICIES)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

ActiveRecord::Migration.verbose = false

Dir[File.join(MODELS, '*.rb')].sort.each do |filename|
  name = File.basename(filename, '.rb')
  autoload name.camelize.to_sym, name
end

Dir[File.join(POLICIES, '*.rb')].sort.each do |filename|
  name = File.basename(filename, '.rb')
  autoload name.camelize.to_sym, name
end

require File.join(SUPPORT, 'sqlite_seed.rb')

RSpec.configure do |config|
  config.before(:suite) do
    Support::SqliteSeed.setup_db
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
    Support::SqliteSeed.seed_db
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
