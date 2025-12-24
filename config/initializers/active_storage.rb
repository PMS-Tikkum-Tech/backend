# frozen_string_literal: true

# Active Storage Configuration
# For Contabo + Coolify deployment with S3-compatible storage

Rails.application.config.after_initialize do
  # For development: use local storage
  # For production: configure S3-compatible storage (Contabo object storage)

  if Rails.env.production?
    # Configure S3-compatible storage for Contabo/Coolify
    ActiveStorage::Service.configurations[:contabo] = {
      service: 'S3',
      access_key_id: ENV['S3_ACCESS_KEY_ID'],
      secret_access_key: ENV['S3_SECRET_ACCESS_KEY'],
      region: ENV['S3_REGION'] || 'us-east-1',
      bucket: ENV['S3_BUCKET'],
      endpoint: ENV['S3_ENDPOINT']
    }

    # Use Contabo S3 for all variants
    ActiveStorage::Blob.service = ActiveStorage::Service.configure(
      :contabo,
      { contabo: ActiveStorage::Service.configurations[:contabo] }
    )
  end
end
