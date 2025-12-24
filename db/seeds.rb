# frozen_string_literal: true

# Database Seed file for Authentication Module
# Creates default admin user for the system

puts 'Creating default admin user...'

admin = User.find_or_create_by!(email: 'admin@rukita-clone.com') do |u|
  u.password = 'Admin@123456'
  u.first_name = 'System'
  u.last_name = 'Administrator'
  u.role = :admin
  u.active = true
end

puts "✓ Admin user created: #{admin.email}"
puts "✓ Password: Admin@123456"
puts ''
puts 'You can now login with these credentials.'
puts ''
puts 'API Endpoints:'
puts '  POST   /api/v1/auth/login'
puts '  GET    /api/v1/auth/me'
puts '  DELETE /api/v1/auth/logout'
puts '  GET    /api/v1/users'
puts '  POST   /api/v1/users'
puts '  GET    /api/v1/users/:id'
puts '  PUT    /api/v1/users/:id'
puts '  DELETE /api/v1/users/:id'
