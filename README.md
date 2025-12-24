# PMS-Tikkum-Tech API

Property Management System API untuk Rukita Clone dengan Clean Architecture.

## Prerequisites

Sebelum memulai, pastikan sudah terinstall:

### 1. PostgreSQL
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib libpq-dev

# macOS (dengan Homebrew)
brew install postgresql
brew services start postgresql

# Verifikasi instalasi
psql --version
# Should output: psql (PostgreSQL) 14.x or higher
```

### 2. Ruby Version Manager (rbenv)
```bash
# Install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Tambahkan ke .bashrc
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install ruby-build
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Verifikasi instalasi
rbenv --version
```

### 3. Ruby 3.1.6
```bash
# Install Ruby 3.1.6
rbenv install 3.1.6

# Set sebagai global version
rbenv global 3.1.6

# Verifikasi
ruby --version
# Should output: ruby 3.1.6p

gem --version
# Should output: 3.x.x
```

### 4. Bundler
```bash
# Install bundler
gem install bundler

# Verifikasi
bundle --version
# Should output: Bundler version 2.x.x
```

### 5. Node.js & Yarn (untuk assets)
```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install -g yarn

# macOS
brew install node
brew install yarn

# Verifikasi
node --version
yarn --version
```

---

## Installation Steps

### Step 1: Clone Repository
```bash
cd /path/to/your/workspace
git clone <repository-url>
cd PMS-Tikkum-Tech
```

### Step 2: Install Ruby Dependencies
```bash
# Install semua gems
bundle install

# Verifikasi instalasi berhasil
bundle show rails
# Should show: Rails 7.1.4
```

### Step 3: Setup Environment Variables
```bash
# Copy file environment template
cp .env.example .env

# Edit .env file
nano .env
# ATAU
vim .env
# ATAU
code .env
```

**Isi `.env` dengan:**
```bash
# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=pms_tikkum_tech_development

# Rails Secret
SECRET_KEY_BASE=<generate_with_rails_secret>
JWT_SECRET_KEY=<generate_random_string_min_32_chars>

# AWS S3 (untuk file upload) - Optional untuk development
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=ap-southeast-1
AWS_BUCKET=your_bucket_name
```

**Generate SECRET_KEY_BASE:**
```bash
rails secret
# Copy output ke SECRET_KEY_BASE di .env
```

### Step 4: Setup Database
```bash
# Buat database development & test
rails db:create

# Jalankan migrations
rails db:migrate

# Seed data (admin user)
rails db:seed

# Verifikasi database
rails db
# Masuk ke PostgreSQL console
# \l (list databases)
# \q (quit)
```

### Step 5: Prepare Folders
```bash
# Pastikan folder yang di-ignore sudah dibuat
mkdir -p log storage tmp

# Restart server jika sudah jalan
```

---

## Running the Server

### Development Server
```bash
# Jalankan server
rails server

# ATAU dengan port custom
rails server -p 3000

# ATAU di background
rails server -d
```

**Server akan berjalan di:** `http://localhost:3000`

### Cek Server Berjalan
```bash
# Test health endpoint (jika ada)
curl http://localhost:3000/api/v1/health

# ATAU test login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@rukita-clone.com","password":"Admin@123456"}'
```

---

## Default Users

Setelah `rails db:seed`, admin user dibuat otomatis:

**Admin User:**
- Email: `admin@rukita-clone.com`
- Password: `Admin@123456`
- Role: `admin`

**Login untuk dapat token:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@rukita-clone.com",
    "password": "Admin@123456"
  }'
```
---

## Database Management

### Reset Database (Hati-hati: Hapus semua data!)
```bash
# Drop, create, migrate, seed
rails db:drop db:create db:migrate db:seed
```

### Reset Tanpa Drop Data
```bash
# Rollback dan migrasi ulang
rails db:rollback
rails db:migrate

# ATAU reset semua migrations
rails db:reset
```

### View Database Data
```bash
# Masuk ke Rails console
rails console

# Di console:
User.all
User.count
User.find_by(email: "admin@rukita-clone.com")
exit
```

### View PostgreSQL Directly
```bash
# Masuk ke psql
psql -d pms_tikkum_tech_development

# Di psql:
\dt                    # List tables
\d users               # Describe users table
SELECT * FROM users;   # Select all users
\q                     # Quit
```

---

## Project Structure (Clean Architecture)

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── concerns/
│   │   └── base_controller.rb
│   └── api/
│       └── v1/
│           └── auth_controller.rb        # Auth + Users endpoints
├── models/
│   └── user.rb                           # User model with validations
├── inputs/
│   └── auth_input.rb                     # Input/DTO & validations
├── services/
│   ├── concerns/
│   │   └── base_service.rb
│   └── auth_service.rb                   # Business logic
├── presenters/
│   ├── concerns/
│   │   └── base_presenter.rb
│   └── auth_presenter.rb                 # Response formatting
└── policies/
    └── user_policy.rb                    # Authorization rules
```

---

## Technologies Used

- **Ruby**: 3.1.6
- **Rails**: 7.1.4
- **PostgreSQL**: 14.x
- **Authentication**: JWT (devise_token_auth replaced)
- **Authorization**: Pundit
- **File Upload**: Active Storage + AWS S3
- **Pagination**: Kaminari
- **Testing**: RSpec (ready to use)

---

## Development Workflow

### 1. Pull Latest Code
```bash
git pull origin main
```

### 2. Install Dependencies (if Gemfile berubah)
```bash
bundle install
```

### 3. Run Migrations (if ada migration baru)
```bash
rails db:migrate
```

### 4. Restart Server
```bash
# Jika server jalan, matikan dulu
kill $(cat tmp/pids/server.pid)

# Jalankan server
rails server
```

---

## Deployment

### Environment Variables di Production
```bash
# Di server production
export RAILS_ENV=production
export SECRET_KEY_BASE=<generated_secret>
export JWT_SECRET_KEY=<generated_jwt_secret>
export DATABASE_URL=postgresql://user:pass@localhost/db_name
```

### Deployment Steps
```bash
# 1. Pull code
git pull origin main

# 2. Install dependencies
bundle install --without development test

# 3. Setup database
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails db:seed

# 4. Precompile assets
RAILS_ENV=production rails assets:precompile

# 5. Start server
rails server -e production
```

---

## Common Commands

### Rails Console
```bash
rails console           # Development console
rails console -e production  # Production console
```

### Routes
```bash
rails routes            # List all routes
rails routes | grep auth  # Filter routes
```

### Database
```bash
rails db:migrate        # Run migrations
rails db:rollback       # Rollback last migration
rails db:seed           # Seed database
rails db:reset          # Drop, create, migrate, seed
```

### Testing
```bash
bundle exec rspec        # Run all tests
bundle exec rspec spec/  # Run tests in spec/
```

### Gems
```bash
bundle install           # Install gems
bundle update            # Update gems
bundle outdated          # Check outdated gems
```

---

## Useful Tips

### Cek Rails Environment
```bash
rails runner "puts Rails.env"
rails runner "puts Rails.version"
```

### Cek Database Connection
```bash
rails runner "ActiveRecord::Base.connection.current_database"
```

### Cek PostgreSQL Version
```bash
psql --version
```

### Kill Rails Server
```bash
# Cari PID
cat tmp/pids/server.pid

# Kill dengan PID
kill -9 <PID>

# ATAU kill all ruby processes
pkill -9 ruby

# ATAU kill process di port 3000
lsof -ti:3000 | xargs kill -9
```

---

## Support & Contact

### Documentation
- Backend Team: hasanabdurrahman12345@gmail.com


### Issues
Jika ada masalah:
1. Cek Troubleshooting section
2. Cek error log di `log/development.log`
3. Cek Rails console error message

---

## License

[Your License Here]

---

**Last Updated**: December 24, 2025
