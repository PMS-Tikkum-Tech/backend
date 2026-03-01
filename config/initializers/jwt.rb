# frozen_string_literal: true

JWT_SECRET_KEY = ENV.fetch(
  "JWT_SECRET_KEY",
  "replace_with_secure_secret_in_production_please_change_this",
)
JWT_ACCESS_TOKEN_EXPIRATION = 1.hour
JWT_REFRESH_TOKEN_EXPIRATION = 7.days
