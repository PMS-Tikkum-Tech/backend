# Hard Delete Implementation - Authentication Module

## Overview
Implemented hard delete for users instead of soft delete to resolve duplicate email issues when recreating user accounts.

## Problem Statement
When using soft delete (setting `active: false`), the user record remained in the database with the same email, causing duplicate email validation errors when trying to recreate a user with the same email address.

## Solution
Changed from soft delete to hard delete using `user.destroy!` to permanently remove the user record from the database.

## Changes Made

### 1. AuthService (app/services/auth_service.rb)
**Line 147-158**: Updated `delete_user` method
```ruby
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
```

**Line 18**: Changed `User.active.find_by` to `User.find_by` in login method
**Line 79**: Changed `User.active` to `User.all` in list_users method
**Line 108**: Changed `User.active.find` to `User.find` in show_user method
**Line 118**: Changed `User.active.find` to `User.find` in update_user method

### 2. BaseController (app/controllers/concerns/base_controller.rb)
**Line 82**: Changed `User.active.find_by` to `User.find_by` in current_user method
```ruby
@current_user = User.find_by(id: decoded[0]['user_id'])
```

### 3. AuthController (app/controllers/api/v1/auth_controller.rb)
**Line 119**: Changed `User.active.find` to `User.find` in set_user method
```ruby
def set_user
  @user = User.find(params[:id])
rescue ActiveRecord::RecordNotFound
  render_not_found('User not found')
end
```

**Line 113**: Updated response message to "User deleted permanently"

### 4. User Model (app/models/user.rb)
**Removed**:
- `scope :active` (line 29 in original file)
- `maybe_clean_profile_photo` callback method (lines 74-80 in original file)

These were no longer needed since we're using hard delete instead of soft delete.

## Testing Results

### Test Workflow:
1. ✅ Created user with email "harddelete@test.com" (ID: 5)
2. ✅ Deleted user ID 5 using `DELETE /api/v1/users/5`
3. ✅ Successfully recreated user with same email "harddelete@test.com" (ID: 6)
4. ✅ Verified in database: User ID 5 no longer exists (hard delete confirmed)

### Database Verification:
```
Total users: 5
ID: 6, Email: harddelete@test.com, Role: owner
ID: 1-4: Other users

User ID 5 does not exist (HARD DELETE SUCCESS)
```

## API Endpoint

### Delete User (Hard Delete)
```
DELETE /api/v1/users/:id
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "message": "User deleted permanently"
}
```

## Benefits
1. ✅ No duplicate email errors when recreating users
2. ✅ Cleaner database (no orphaned inactive records)
3. ✅ Simpler code (no need for `active` field management)
4. ✅ Matches user's explicit requirement for hard delete

## Notes
- The `active` column still exists in the database schema but is no longer used
- A migration could be created to remove the `active` column if desired
- All user queries now work directly with User model without `.active` scope
- Admin-only authorization for delete operation still enforced via UserPolicy

## Implementation Date
December 24, 2025
