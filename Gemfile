source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Specify your gem's dependencies in declarative_policy.gemspec
gemspec

gem 'rails', github: 'rails'
gem 'rspec'
gem 'sqlite3'
gem 'byebug'
gem 'database_cleaner'
