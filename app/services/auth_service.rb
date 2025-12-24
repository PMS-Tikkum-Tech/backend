# frozen_string_literal: true

# Unified AuthService for authentication and user management
# Handles login, me, logout, and CRUD operations for users
class AuthService
  include BaseService

  attr_reader :current_user

  def initialize(current_user: nil, params: {}, filters: {})
    @current_user = current_user
    @params = params
    @filters = filters
  end

  # Authentication methods
  def login
    user = User.find_by(email: @params[:email])
    return failure(['Invalid credentials'], 'Authentication failed') unless user
    return failure(['Invalid credentials'], 'Authentication failed') unless
            user.authenticate(@params[:password])

    tokens = generate_tokens(user)

    # Update refresh token without triggering validations
    user.update_column(:refresh_token, tokens[:refresh_token])
    user.update_column(:refresh_token_expires_at, tokens[:refresh_expires_at])

    success({ user: user, **tokens }, 'Login successful')
  rescue StandardError => e
    Rails.logger.error "Login error: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    failure([e.message], 'Login failed')
  end

  def me
    success(@current_user, 'Profile retrieved')
  end

  def logout(refresh_token)
    # Add current JWT token to blacklist
    token = @params[:token] # Will be set by controller
    add_token_to_blacklist(token, @current_user) if token

    # Clear refresh token
    @current_user.update(refresh_token: nil,
                         refresh_token_expires_at: nil)
    success(nil, 'Logout successful')
  rescue StandardError => e
    Rails.logger.error "Logout error: #{e.message}"
    failure([e.message], 'Logout failed')
  end

  # User CRUD methods
  def create_user
    authorize!(:create, User)
    input = AuthInput.create_params(@params)
    if input.invalid?(:create)
      return failure(input.errors.full_messages,
                     'Validation failed')
    end

    user_params = input.to_create_params

    # Handle profile photo separately
    profile_photo = user_params.delete(:profile_photo)

    user = User.create!(user_params)

    # Attach profile photo if provided
    user.profile_photo.attach(profile_photo) if profile_photo

    success(user, 'User created successfully')
  rescue StandardError => e
    failure([e.message], 'Failed to create user')
  end

  def list_users
    authorize!(:index, User)

    users = User.all
    users = users.by_role(@filters[:role]) if @filters[:role]
    users = apply_search(users) if @filters[:search]

    paginated_users = users.page(@filters[:page])
                           .per(@filters[:per_page])

    success({
              users: paginated_users,
              pagination: pagination_metadata(paginated_users)
            }, 'Users retrieved successfully')
  rescue StandardError => e
    failure([e.message], 'Failed to retrieve users')
  end

  def show_user(id)
    user = User.find(id)
    authorize!(:show, user)
    success(user, 'User retrieved successfully')
  rescue ActiveRecord::RecordNotFound
    failure(['User not found'], 'User not found')
  rescue StandardError => e
    failure([e.message], 'Failed to retrieve user')
  end

  def update_user(id)
    user = User.find(id)
    authorize!(:update, user)

    input = AuthInput.update_params(@params)
    if input.invalid?(:update)
      return failure(input.errors.full_messages,
                     'Validation failed')
    end

    user_params = input.to_update_params

    # Handle profile photo separately
    profile_photo = user_params.delete(:profile_photo)
    remove_profile_photo = user_params.delete(:remove_profile_photo)

    # Update user attributes
    user.update!(user_params)

    # Attach new profile photo if provided
    if profile_photo
      user.profile_photo.attach(profile_photo)
    elsif remove_profile_photo
      # Remove only if explicitly requested via flag
      user.profile_photo.purge if user.profile_photo.attached?
    end

    success(user, 'User updated successfully')
  rescue ActiveRecord::RecordNotFound
    failure(['User not found'], 'User not found')
  rescue StandardError => e
    failure([e.message], 'Failed to update user')
  end

  def delete_user(id)
    user = User.find(id)
    authorize!(:destroy, user)

    # Hard delete - destroy user permanently from database
    user.destroy!
    success(user, 'User deleted permanently')
  rescue ActiveRecord::RecordNotFound
    failure(['User not found'], 'User not found')
  rescue StandardError => e
    failure([e.message], 'Failed to delete user')
  end

  private

  # Authorization helper
  def authorize!(action, record)
    policy = UserPolicy.new(@current_user, record)
    return if policy.public_send("#{action}?")

    raise Pundit::NotAuthorizedError,
          "not allowed to #{action} this #{record.class.name}"
  end

  # Apply search filter (DRY - reusable)
  def apply_search(scope)
    search_term = "%#{@filters[:search]}%"
    scope.where('first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?',
               search_term, search_term, search_term)
  end

  # Build pagination metadata (DRY - reusable)
  def pagination_metadata(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count
    }
  end

  # Generate JWT tokens with jti for blacklisting
  def generate_tokens(user)
    jti = SecureRandom.uuid
    payload = {
      jti: jti,
      user_id: user.id,
      email: user.email,
      role: user.role,
      exp: 1.hour.from_now.to_i
    }

    refresh_token = SecureRandom.uuid
    refresh_expires_at = 7.days.from_now

    {
      token: JWT.encode(payload, ENV.fetch('JWT_SECRET_KEY', nil), 'HS256'),
      refresh_token: refresh_token,
      refresh_expires_at: refresh_expires_at,
      expires_at: payload[:exp],
      jti: jti
    }
  end

  # Add JWT token to blacklist
  def add_token_to_blacklist(token, user)
    decoded = JWT.decode(token, ENV.fetch('JWT_SECRET_KEY', nil), true, { algorithm: 'HS256' })
    payload = decoded[0]

    RevokedToken.create!(
      jti: payload['jti'],
      user_id: user.id,
      exp: Time.at(payload['exp'])
    )
  rescue JWT::DecodeError => e
    Rails.logger.error "Failed to decode token for blacklisting: #{e.message}"
  end
end
