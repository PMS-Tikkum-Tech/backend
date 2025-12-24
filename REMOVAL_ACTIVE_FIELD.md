# Removal of `active` Field - Documentation

## Date: December 24, 2025

## Summary
Menghapus semua referensi ke `active` field dari codebase karena sekarang menggunakan **hard delete** (destroy) bukan soft delete.

---

## Background
**Before**: User menggunakan soft delete dengan field `active` (boolean)
**Now**: User menggunakan hard delete dengan `destroy!`

**Impact**: Field `active` sudah tidak relevan dan harus dihapus dari:
- Model
- Input validations
- Controller params
- Presenter responses
- Filter options

---

## Files Modified

### 1. **app/models/user.rb**
**Status**: ✅ Already clean (no `active` field usage)

**Existing Scope**:
```ruby
# Removed: scope :active, -> { where(active: true) }
# Now using: User.all (hard delete approach)
```

---

### 2. **app/presenters/auth_presenter.rb**
**Line 41**: Removed `active` field from response

**Before**:
```ruby
def self.user_data(user, current_user = nil)
  data = {
    id: user.id,
    email: user.email,
    first_name: user.first_name,
    last_name: user.last_name,
    full_name: user.full_name,
    phone: current_user&.admin? ? user.phone : nil,
    role: user.role,
    active: user.active,  # ❌ REMOVED
    profile_photo_url: user.profile_photo_url,
    created_at: user.created_at.iso8601
  }
```

**After**:
```ruby
def self.user_data(user, current_user = nil)
  data = {
    id: user.id,
    email: user.email,
    first_name: user.first_name,
    last_name: user.last_name,
    full_name: user.full_name,
    phone: current_user&.admin? ? user.phone : nil,
    role: user.role,
    # active: user.active, ← REMOVED
    profile_photo_url: user.profile_photo_url,
    created_at: user.created_at.iso8601
  }
```

---

### 3. **app/inputs/auth_input.rb**
**Changes**: Removed all `active` attr_accessor and validations

**Before**:
```ruby
# Update user attributes
attr_accessor :active, :remove_profile_photo

# Filter attributes
attr_accessor :search, :page, :per_page, :role_filter, :active_filter

# Update user validations
validates :active, inclusion: { in: [true, false] },
                   allow_nil: true, on: :update

# Update params
def self.update_params(params)
  input = new(params.slice(:first_name, :last_name, :phone, :active,
                           :profile_photo, :remove_profile_photo))
  input.context = :update
  input
end

# Filter params
def self.filter_params(params)
  new(params.slice(:search, :page, :per_page,
                   :role_filter, :active_filter))
end

# To update params
def to_update_params
  params = {
    first_name: first_name,
    last_name: last_name,
    phone: phone,
    active: active  # ❌ REMOVED
  }.compact
  # ...
end

# To filter params
def to_filter_params
  {
    search: search,
    page: page&.to_i || 1,
    per_page: [per_page&.to_i || 20, 100].min,
    role: role_filter,
    active: active_filter  # ❌ REMOVED
  }.compact
end
```

**After**:
```ruby
# Update user attributes
attr_accessor :remove_profile_photo  # active removed

# Filter attributes
attr_accessor :search, :page, :per_page, :role_filter  # active_filter removed

# NO active validation (completely removed)

# Update params
def self.update_params(params)
  input = new(params.slice(:first_name, :last_name, :phone,
                           :profile_photo, :remove_profile_photo))
  input.context = :update
  input
end

# Filter params
def self.filter_params(params)
  new(params.slice(:search, :page, :per_page, :role_filter))
end

# To update params
def to_update_params
  params = {}

  # Add fields if present (all optional for PATCH)
  params[:first_name] = first_name if first_name
  params[:last_name] = last_name if last_name
  params[:phone] = phone if phone
  # active field completely removed

  params[:profile_photo] = profile_photo if profile_photo
  params[:remove_profile_photo] = remove_profile_photo if remove_profile_photo

  params
end

# To filter params
def to_filter_params
  {
    search: search,
    page: page&.to_i || 1,
    per_page: [per_page&.to_i || 20, 100].min,
    role: role_filter
    # active_filter removed
  }.compact
end
```

---

### 4. **app/controllers/api/v1/auth_controller.rb**
**Lines 145-152**: Removed `active` from permitted params

**Before**:
```ruby
def user_params
  params.require(:user).permit(:email, :password, :first_name,
                               :last_name, :phone, :role, :active,  # ❌
                               :profile_photo, :remove_profile_photo)
end

def filter_params
  params.permit(:search, :page, :per_page, :role, :active)  # ❌
end
```

**After**:
```ruby
def user_params
  params.fetch(:user, {}).permit(:email, :password, :first_name,
                                 :last_name, :phone, :role,
                                 :profile_photo, :remove_profile_photo)
end

def filter_params
  params.permit(:search, :page, :per_page, :role)
end
```

---

## Bonus Fix: Role Filter Bug

### Problem
Filter `role=owner` tidak bekerja - admin user tetap muncul

### Root Cause
Scope `by_role` tidak menggunakan symbol conversion

### Solution
**File**: `app/models/user.rb:29`

**Before**:
```ruby
scope :by_role, ->(role) { where(role: roles[role]) }
```

**After**:
```ruby
scope :by_role, ->(role) { where(role: roles[role.to_sym]) if role.present? }
```

**Why Fix**:
1. `role` parameter comes as string: `"owner"` or `"admin"`
2. Rails enum expects symbol: `:owner` or `:admin`
3. Need to convert: `roles[role.to_sym]`
4. Added safety check: `if role.present?`

---

## API Changes

### Before (with `active` field)

**Response**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "admin@rukita-clone.com",
    "first_name": "System",
    "last_name": "Administrator",
    "full_name": "System Administrator",
    "phone": null,
    "role": "admin",
    "active": true,  // ❌ REMOVED
    "profile_photo_url": null,
    "created_at": "2025-12-24T03:03:29Z"
  }
}
```

**Request** (update):
```json
{
  "user": {
    "first_name": "John",
    "active": false  // ❌ REMOVED - no longer supported
  }
}
```

**Request** (filter):
```
GET /api/v1/users?role=owner&active=true  // ❌ active filter removed
```

---

### After (without `active` field)

**Response**:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "admin@rukita-clone.com",
    "first_name": "System",
    "last_name": "Administrator",
    "full_name": "System Administrator",
    "phone": null,
    "role": "admin",
    // active field removed
    "profile_photo_url": null,
    "created_at": "2025-12-24T03:03:29Z"
  }
}
```

**Request** (update):
```json
{
  "user": {
    "first_name": "John"
    // active field not supported
  }
}
```

**Request** (filter):
```
GET /api/v1/users?role=owner  // ✅ active filter removed
```

---

## Testing

### Test 1: Filter by Role (Owner)
```bash
curl -X GET "http://localhost:3000/api/v1/users?role=owner" \
  -H "Authorization: Bearer <admin_token>"
```

**Expected**: Only users with role `owner` (admin users excluded)

**Before Fix**: Returns all users including admin ❌
**After Fix**: Returns only owner users ✅

---

### Test 2: Create User
```bash
curl -X POST "http://localhost:3000/api/v1/users" \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "Test123456",
      "first_name": "Test",
      "last_name": "User",
      "role": "owner"
      // NO active field
    }
  }'
```

**Expected**: User created successfully ✅

---

### Test 3: Update User
```bash
curl -X PATCH "http://localhost:3000/api/v1/users/2" \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "first_name": "Updated Name"
      // NO active field needed
    }
  }'
```

**Expected**: User updated successfully ✅

---

### Test 4: Delete User (Hard Delete)
```bash
curl -X DELETE "http://localhost:3000/api/v1/users/2" \
  -H "Authorization: Bearer <admin_token>"
```

**Expected**: User permanently deleted from database ✅
- Can recreate user with same email ✅
- No `active: false` record left behind ✅

---

## Database Schema Note

### Current Schema (Still Has `active` Column)
```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR NOT NULL UNIQUE,
  password_digest VARCHAR NOT NULL,
  first_name VARCHAR NOT NULL,
  last_name VARCHAR,
  phone VARCHAR,
  role INTEGER NOT NULL DEFAULT 0, -- 0=owner, 1=admin
  active BOOLEAN DEFAULT true NOT NULL, -- ⚠️ Still exists but unused
  refresh_token VARCHAR UNIQUE,
  refresh_token_expires_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Future Migration (Optional)
Untuk benar-benar menghapus field `active` dari database:

```ruby
# db/migrate/[timestamp]_remove_active_from_users.rb
class RemoveActiveFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :active, :boolean
  end
end
```

**Note**: Migration ini OPSIONAL dan bisa dilakukan nanti. Field `active` masih ada di database tapi sudah tidak digunakan di code (legacy column).

---

## Breaking Changes

### API Response Format
**Breaking**: Yes - `active` field removed from all user responses

**Impact**:
- Frontend code yang membaca `data.active` akan error
- Harus update frontend untuk tidak mengexpect field `active`

**Migration**:
```javascript
// Before
if (user.active) { ... }

// After - remove check or use different logic
// User exists = active, user deleted = not found
if (user) { ... }
```

---

### API Request Format
**Breaking**: Yes - `active` field no longer accepted

**Impact**:
- Frontend yang mengirim `active: false` akan diabaikan
- Filter `?active=true` sudah tidak bekerja

**Migration**:
```javascript
// Before - soft delete approach
await api.updateUser(userId, { active: false })

// After - hard delete approach
await api.deleteUser(userId)  // Use DELETE endpoint
```

---

## Rollback Plan

Jika ada masalah, berikut cara rollback:

### 1. Revert Code Changes
```bash
git revert <commit-hash>
```

### 2. Restore `active` Field in Code
- Tambah kembali `active` ke AuthPresenter
- Tambah kembali `active` ke AuthInput
- Tambah kembali `active` ke AuthController

### 3. Switch Back to Soft Delete
- Ubah `user.destroy!` → `user.update!(active: false)`
- Tambah kembali scope `User.active`
- Update semua query untuk menggunakan `User.active`

---

## Deployment Checklist

- [ ] Code changes deployed
- [ ] Frontend updated to remove `active` field usage
- [ ] Frontend updated to handle hard delete
- [ ] API documentation updated
- [ ] Test suite updated
- [ ] Staging tested
- [ ] Backend team notified
- [ ] Frontend team notified

---

## Performance Impact

### Positive Impact
- ✅ Simpler queries (no `WHERE active = true` filter)
- ✅ Smaller response size (1 less field)
- ✅ Fewer database writes (no soft delete updates)

### No Negative Impact
- ✅ Query performance same or better
- ✅ No additional indexes needed
- ✅ No schema locking (if keeping legacy column)

---

## Security Considerations

### Soft Delete vs Hard Delete

**Soft Delete (Before)**:
- ✅ Audit trail preserved
- ✅ Can recover deleted users
- ❌ Email uniqueness issues
- ❌ Database bloat over time

**Hard Delete (Now)**:
- ✅ Clean email uniqueness
- ✅ No database bloat
- ✅ Simpler code
- ❌ No audit trail for deleted users
- ❌ Cannot recover deleted users

### Recommendation
If audit trail is needed, consider:
1. Separate `deleted_users` table with archived data
2. Use database triggers/logic to copy before delete
3. Application-level audit logging

---

## FAQ

### Q: Why remove `active` field?
**A**: Because we switched to hard delete. Soft delete (setting `active: false`) caused duplicate email issues when trying to recreate users.

### Q: Can I still see deleted users?
**A**: No. With hard delete, users are permanently removed from database.

### Q: What happens to existing `active: false` users?
**A**: They still exist in database but are not accessible via API (no `.active` scope).

### Q: Should I run migration to remove `active` column?
**A**: Optional. Field `active` can stay as legacy column. Code doesn't use it anymore.

### Q: How do I filter "active" users now?
**A**: All users in database are "active". Deleted users don't exist. Just query all users: `GET /api/v1/users`

### Q: Can I soft delete a user temporarily?
**A**: No. Use hard delete only. If you need temporary suspension, add a separate `suspended` field.

---

## Related Documentation
- `HARD_DELETE_IMPLEMENTATION.md` - Original hard delete implementation
- `AUTH_MODULE_FIXES.md` - General authentication fixes

---

**End of Documentation**

Last Updated: December 24, 2025
