source "https://rubygems.org"

ruby "3.1.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.4"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.5.4"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.4.2"

# Authentication & Authorization
gem "devise", "~> 4.9.3"
gem "devise_token_auth", git: "https://github.com/lynndylanhurley/devise_token_auth.git"
gem "pundit", "~> 2.3.1"
gem "jwt", "~> 2.7.1"

# Environment variables
gem "dotenv-rails", "~> 2.8.1"

# File Upload (Active Storage with S3)
gem "aws-sdk-s3", "~> 1.141.0"
gem "fog-aws", "~> 3.1.0"

# Background Jobs
gem "sidekiq", "~> 7.2.2"
gem "sidekiq-cron", "~> 1.9.0"
gem "redis", "~> 5.4.1"

# API Documentation (TODO: Add later when compatible version found)
# gem "rswag", "~> 2.6.0"

# Production Monitoring
gem "lograge", "~> 0.14.0"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]

  # Testing Framework
  gem "rspec-rails", "~> 6.1.2"
  gem "factory_bot_rails", "~> 6.2.0"
  gem "faker", "~> 3.2.3"
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  gem "error_highlight", ">= 0.4.0", platforms: [:ruby]

  # Code Style & Security
  gem "rubocop", "~> 1.60.2", require: false
  gem "rubocop-rails", "~> 2.24.1", require: false
  gem "brakeman", "~> 6.1.2", require: false
end

