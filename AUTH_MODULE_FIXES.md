# Authentication Module Fixes - Documentation

## Overview
Dokumentasi perbaikan pada Authentication Module untuk mengatasi bug pagination dan fleksibilitas update user.

## Date: December 24, 2025

---

## Summary of Changes

### 1. **Added Pagination Support (Kaminari)**
**Problem**: Error `undefined method 'page' for #<ActiveRecord::Relation>`

**Solution**: Added `kaminari` gem for pagination support

**Files Modified**:
- `Gemfile` - Added `gem 'kaminari', '~> 1.2'`

**Installation**:
```bash
bundle install
```

---

### 2. **Made User Params Optional (PATCH Semantics)**
**Problem**: API required all fields even when updating single field

**Solution**: Changed from `require(:user)` to `fetch(:user, {})`

**Files Modified**:
- `app/controllers/api/v1/auth_controller.rb` (line 128-132)
- `app/inputs/auth_input.rb` (line 38-41)

**Before**:
```ruby
# Controller
params.require(:user).permit(:email, :password, :first_name, ...)

# Input
validates :first_name, presence: true, on: :update
```

**After**:
```ruby
# Controller
params.fetch(:user, {}).permit(:email, :password, :first_name, ...)

# Input
# All fields are optional for update (PATCH semantics)
# No more first_name validation on update
```

---

### 3. **Flexible Profile Photo Update**
**Problem**: Cannot update only profile photo or only single field

**Solution**: Made all fields optional and handled profile photo separately

**Files Modified**:
- `app/services/auth_service.rb` (lines 127-141)

**Logic**:
```ruby
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
```

---

## API Usage Examples

### Get Users with Pagination

**Request**:
```bash
GET /api/v1/users?page=1&per_page=10
Authorization: Bearer <admin_token>
```

**Response**:
```json
{
  "success": true,
  "message": "Users retrieved",
  "data": {
    "users": [
      {
        "id": 1,
        "email": "admin@rukita-clone.com",
        "first_name": "System",
        "last_name": "Administrator",
        "full_name": "System Administrator",
        "phone": null,
        "role": "admin",
        "active": true,
        "profile_photo_url": null,
        "created_at": "2025-12-24T02:27:44Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 1,
      "total_count": 5
    }
  }
}
```

### Get Users with Filters

**Request**:
```bash
GET /api/v1/users?role=owner&active=true&page=1&per_page=20
Authorization: Bearer <admin_token>
```

**Query Parameters**:
- `page` (integer) - Page number (default: 1)
- `per_page` (integer) - Items per page (default: 20, max: 100)
- `role` (string) - Filter by role: `admin` or `owner`
- `active` (boolean) - Filter by active status: `true` or `false`
- `search` (string) - Search in first_name, last_name, or email

---

### Update User - Single Field

**Request**: Update only first_name
```bash
PATCH /api/v1/users/2
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "user": {
    "first_name": "Jane Updated"
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "User updated",
  "data": {
    "id": 2,
    "email": "jane.smith@example.com",
    "first_name": "Jane Updated",
    "last_name": "Smith",
    "full_name": "Jane Updated Smith",
    "phone": "+628987654321",
    "role": "owner",
    "active": true,
    "profile_photo_url": null,
    "created_at": "2025-12-24T02:28:59Z"
  }
}
```

---

### Update User - Upload Profile Photo

**Request**: Upload profile photo only
```bash
PATCH /api/v1/users/2
Authorization: Bearer <admin_token>
Content-Type: multipart/form-data

user[profile_photo]=<file>
```

**Or as JSON (if base64 encoded)**:
```json
{
  "user": {
    "profile_photo": "<base64_encoded_file>"
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "User updated",
  "data": {
    "id": 2,
    "email": "jane.smith@example.com",
    "first_name": "Jane",
    "last_name": "Smith",
    "full_name": "Jane Smith",
    "phone": "+628987654321",
    "role": "owner",
    "active": true,
    "profile_photo_url": "https://storage.googleapis.com/...",
    "created_at": "2025-12-24T02:28:59Z"
  }
}
```

---

### Update User - Remove Profile Photo

**Request**: Remove profile photo
```bash
PATCH /api/v1/users/2
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "user": {
    "remove_profile_photo": true
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "User updated",
  "data": {
    "id": 2,
    "email": "jane.smith@example.com",
    "first_name": "Jane",
    "last_name": "Smith",
    "full_name": "Jane Smith",
    "phone": "+628987654321",
    "role": "owner",
    "active": true,
    "profile_photo_url": null,
    "created_at": "2025-12-24T02:28:59Z"
  }
}
```

---

### Update User - Multiple Fields

**Request**: Update multiple fields at once
```bash
PATCH /api/v1/users/2
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "user": {
    "first_name": "Jane",
    "last_name": "Doe",
    "phone": "+628123456789"
  }
}
```

---

## Test Scenarios

### Scenario 1: Pagination Works
```bash
# Get first page
curl -X GET "http://localhost:3000/api/v1/users?page=1&per_page=10" \
  -H "Authorization: Bearer <token>"

# Get second page
curl -X GET "http://localhost:3000/api/v1/users?page=2&per_page=10" \
  -H "Authorization: Bearer <token>"
```

**Expected**: Returns paginated results with pagination metadata

---

### Scenario 2: Filter by Role
```bash
curl -X GET "http://localhost:3000/api/v1/users?role=owner" \
  -H "Authorization: Bearer <token>"
```

**Expected**: Returns only users with role `owner`

---

### Scenario 3: Update Single Field (first_name)
```bash
curl -X PATCH "http://localhost:3000/api/v1/users/2" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"user":{"first_name":"New Name"}}'
```

**Expected**: Updates only `first_name`, other fields unchanged

---

### Scenario 4: Update Only Profile Photo
```bash
curl -X PATCH "http://localhost:3000/api/v1/users/2" \
  -H "Authorization: Bearer <token>" \
  -F "user[profile_photo]=@path/to/photo.jpg"
```

**Expected**: Uploads new profile photo, other fields unchanged

---

### Scenario 5: Remove Profile Photo
```bash
curl -X PATCH "http://localhost:3000/api/v1/users/2" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"user":{"remove_profile_photo":true}}'
```

**Expected**: Profile photo removed, `profile_photo_url` becomes `null`

---

### Scenario 6: Update with Empty Body
```bash
curl -X PATCH "http://localhost:3000/api/v1/users/2" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: No changes, returns current user data

---

## Technical Details

### Pagination with Kaminari

**Model Setup** (optional):
```ruby
# app/models/user.rb
class User < ApplicationRecord
  paginates_per 20 # Default per page
  max_paginates_per 100 # Maximum per page
end
```

**Service Layer**:
```ruby
# app/services/auth_service.rb
def list_users
  users = User.all
  users = users.by_role(@filters[:role]) if @filters[:role]

  # Pagination
  paginated_users = users
    .page(@filters[:page])
    .per(@filters[:per_page])

  success({
    users: paginated_users,
    pagination: {
      current_page: paginated_users.current_page,
      total_pages: paginated_users.total_pages,
      total_count: paginated_users.total_count
    }
  }, 'Users retrieved successfully')
end
```

---

### Flexible Update Logic

**Controller** (app/controllers/api/v1/auth_controller.rb):
```ruby
def user_params
  # Use fetch instead of require to make params optional
  params.fetch(:user, {}).permit(
    :email, :password, :first_name, :last_name,
    :phone, :role, :active,
    :profile_photo, :remove_profile_photo
  )
end
```

**Input** (app/inputs/auth_input.rb):
```ruby
# No first_name validation on update
# All fields are optional
```

**Service** (app/services/auth_service.rb):
```ruby
def update_user(id)
  user = User.find(id)
  authorize!(:update, user)

  input = AuthInput.update_params(@params)
  return failure(input.errors.full_messages,
                 'Validation failed') if input.invalid?(:update)

  user_params = input.to_update_params

  # Handle profile photo separately
  profile_photo = user_params.delete(:profile_photo)
  remove_profile_photo = user_params.delete(:remove_profile_photo)

  # Update user attributes (only non-nil fields)
  user.update!(user_params)

  # Attach new profile photo if provided
  if profile_photo
    user.profile_photo.attach(profile_photo)
  elsif remove_profile_photo
    # Remove only if explicitly requested
    user.profile_photo.purge if user.profile_photo.attached?
  end

  success(user, 'User updated successfully')
end
```

---

## Edge Cases Handled

### 1. Update with No Fields
**Request**: `PATCH /api/v1/users/2` with empty body `{}`

**Result**: No validation error, returns current user data unchanged

---

### 2. Update with Only profile_photo
**Request**: `{"user": {"profile_photo": "<file>"}}`

**Result**: Only profile photo updated, other fields unchanged

---

### 3. Remove Photo When No Photo Exists
**Request**: `{"user": {"remove_profile_photo": true}}`

**Result**: No error, operation completes successfully

---

### 4. Pagination Beyond Available Data
**Request**: `GET /api/v1/users?page=999`

**Result**: Returns empty array with valid pagination metadata

---

## Validation Rules

### Create User (POST /api/v1/users)
- `email`: required, valid format, unique
- `password`: required, min 8 characters
- `first_name`: required
- `role`: optional, must be `admin` or `owner` (default: `owner`)

### Update User (PATCH /api/v1/users/:id)
- ALL fields are optional
- `email`: if provided, must be valid format and unique
- `password`: if provided, must be min 8 characters
- `role`: if provided, must be `admin` or `owner`
- `active`: if provided, must be `true` or `false`
- `profile_photo`: if provided, will be attached
- `remove_profile_photo`: if `true`, removes existing photo

---

## Permissions

### Who Can Update Users?
- **Admin**: Can update any user
- **Owner**: Can only update themselves

### Who Can See Users?
- **Admin**: Can list all users with filters
- **Owner**: Cannot list users (403 Forbidden)

---

## Common Errors

### Error 1: Missing Authentication
```json
{
  "success": false,
  "message": "Unauthorized",
  "errors": ["Authentication required"]
}
```

**Solution**: Include valid JWT token in Authorization header

---

### Error 2: Insufficient Permissions
```json
{
  "success": false,
  "message": "Unauthorized",
  "errors": ["You are not authorized to perform this action"]
}
```

**Solution**: Ensure user has proper role (admin for CRUD operations)

---

### Error 3: User Not Found
```json
{
  "success": false,
  "message": "Resource not found",
  "errors": ["User not found"]
}
```

**Solution**: Verify user ID exists

---

### Error 4: Validation Failed
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": ["Email has already been taken"]
}
```

**Solution**: Check validation rules and ensure data uniqueness

---

## Performance Considerations

### Pagination
- Always use pagination for large datasets
- Default: 20 items per page
- Maximum: 100 items per page
- Avoid `per_page` values > 100

### Filtering
- Filters are applied at database level (efficient)
- Available filters: `role`, `active`, `search`
- Search uses ILIKE (case-insensitive) with `%` wildcard

### Profile Photo Upload
- Uses Active Storage with S3
- Max file size: 5MB
- Supported formats: PNG, JPG, JPEG
- Validation happens on attachment

---

## Testing Checklist

Before deploying to production, verify:

- [ ] Pagination works correctly
- [ ] Filters work correctly (role, active, search)
- [ ] Update single field works
- [ ] Update multiple fields works
- [ ] Update with empty body works
- [ ] Profile photo upload works
- [ ] Profile photo removal works
- [ ] Permissions are enforced correctly
- [ ] Error messages are clear
- [ ] Response format is consistent

---

## Migration Notes

### For Existing API Consumers

**Breaking Change**: None - all changes are backward compatible

**New Features**:
- Pagination metadata in response
- Optional fields in update
- Flexible profile photo handling

**Recommended Actions**:
1. Update API clients to handle pagination
2. Update API clients to send only fields that need updating
3. Update API clients to use new profile photo removal method

---

## Deployment Steps

1. **Add Gem**:
   ```bash
   # Add to Gemfile
   gem 'kaminari', '~> 1.2'

   # Install
   bundle install
   ```

2. **Deploy Code**:
   - Deploy updated files to server
   - Restart Rails server

3. **Verify**:
   - Run test suite
   - Manual testing with Postman/cURL
   - Monitor logs for errors

4. **Communicate**:
   - Notify FE team of pagination support
   - Update API documentation
   - Share test scenarios

---

## Support & Troubleshooting

### Issues with Pagination
**Symptom**: `undefined method 'page'`

**Solution**:
```bash
bundle install
rails server restart
```

---

### Issues with Profile Photo
**Symptom**: Profile photo not uploading

**Check**:
1. S3 credentials in `.env`
2. Active Storage configuration
3. File size and format
4. Rails logs for errors

---

### Issues with Update
**Symptom**: Validation error when updating

**Check**:
1. Request format (JSON vs multipart)
2. Field names (must be nested under `user`)
3. Permission headers (Authorization)

---

## Related Files

### Files Modified
1. `Gemfile` - Added kaminari
2. `app/controllers/api/v1/auth_controller.rb` - Made params optional
3. `app/inputs/auth_input.rb` - Removed first_name validation on update
4. `app/services/auth_service.rb` - Enhanced profile photo logic

### Files Referenced
1. `app/models/user.rb` - User model with relations
2. `app/policies/user_policy.rb` - Authorization rules
3. `app/presenters/auth_presenter.rb` - Response formatting

---

**End of Documentation**

For questions or issues, contact: Backend Team
Last Updated: December 24, 2025
