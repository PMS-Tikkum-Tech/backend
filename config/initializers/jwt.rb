# frozen_string_literal: true

# JWT Configuration
# Set secret key from environment with fallback for development
JWT_SECRET_KEY = ENV.fetch(
  'JWT_SECRET_KEY',
  'fallback_secret_key_change_in_production_min_32_chars'
)

# Token expiration times
JWT_ACCESS_TOKEN_EXPIRATION = 1.hour
JWT_REFRESH_TOKEN_EXPIRATION = 7.days
