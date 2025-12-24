# Postman Collection - Authentication Module API

Base URL: `http://localhost:3000`

---

## 1. AUTHENTICATION ENDPOINTS

### 1.1 Login (All Roles)
**Endpoint:** `POST /api/v1/auth/login`

**Description:** Login untuk Admin dan Owner (User). Mengembalikan JWT access token dan refresh token.

**Headers:**
```
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "email": "admin@rukita-clone.com",
  "password": "Admin@123456"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "email": "admin@rukita-clone.com",
      "first_name": "System",
      "last_name": "Administrator",
      "full_name": "System Administrator",
      "phone": null,
      "role": "admin",
      "active": true,
      "profile_photo_url": null,
      "created_at": "2024-12-23T23:45:31Z"
    },
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "abc123-def456-ghi789",
    "expires_at": "2024-12-24T00:45:31Z"
  }
}
```

**Response Error (401):**
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

---

### 1.2 Get Current User Profile
**Endpoint:** `GET /api/v1/auth/me`

**Description:** Mendapatkan profile user yang sedang login. Membutuhkan JWT token.

**Headers:**
```
Authorization: Bearer {{jwt_token}}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Profile retrieved",
  "data": {
    "id": 1,
    "email": "admin@rukita-clone.com",
    "first_name": "System",
    "last_name": "Administrator",
    "full_name": "System Administrator",
    "phone": null,
    "role": "admin",
    "active": true,
    "profile_photo_url": null,
    "created_at": "2024-12-23T23:45:31Z"
  }
}
```

---

### 1.3 Logout
**Endpoint:** `DELETE /api/v1/auth/logout`

**Description:** Logout dan revoke refresh token.

**Headers:**
```
Authorization: Bearer {{jwt_token}}
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "refresh_token": "abc123-def456-ghi789"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

---

## 2. USER MANAGEMENT ENDPOINTS (ADMIN ONLY)

### 2.1 List Users (Admin Only)
**Endpoint:** `GET /api/v1/users`

**Description:** Mendapatkan semua users dengan pagination dan filter. Hanya Admin.

**Headers:**
```
Authorization: Bearer {{admin_jwt_token}}
```

**Query Parameters:**
```
page: 1                    (default: 1)
per_page: 20               (default: 20, max: 100)
role: admin|owner          (optional, filter by role)
active: true|false         (optional, filter by active status)
search: keyword            (optional, search in name/email)
```

**Example:**
```
GET /api/v1/users?page=1&per_page=10&role=owner&active=true&search=john
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Users retrieved",
  "data": {
    "users": [
      {
        "id": 2,
        "email": "john.doe@example.com",
        "first_name": "John",
        "last_name": "Doe",
        "full_name": "John Doe",
        "phone": "+628123456789",
        "role": "owner",
        "active": true,
        "profile_photo_url": "/rails/active_storage/blobs/...",
        "created_at": "2024-12-23T23:50:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 50
    }
  }
}
```

---

### 2.2 Get User Detail (Admin or Self)
**Endpoint:** `GET /api/v1/users/:id`

**Description:** Mendapatkan detail user berdasarkan ID. Admin bisa lihat semua user, Owner hanya bisa lihat dirinya sendiri.

**Headers:**
```
Authorization: Bearer {{jwt_token}}
```

**URL Parameter:**
```
id: 1 (user ID)
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "User retrieved",
  "data": {
    "id": 1,
    "email": "admin@rukita-clone.com",
    "first_name": "System",
    "last_name": "Administrator",
    "full_name": "System Administrator",
    "phone": "+628987654321",
    "role": "admin",
    "active": true,
    "profile_photo_url": "/rails/active_storage/blobs/...",
    "created_at": "2024-12-23T23:45:31Z"
  }
}
```

---

### 2.3 Create User (Admin Only)
**Endpoint:** `POST /api/v1/users`

**Description:** Membuat user baru (Admin atau Owner). Hanya Admin yang bisa create.

**Headers:**
```
Authorization: Bearer {{admin_jwt_token}}
```

**Body (multipart/form-data) - Without Profile Photo:**
```
user[email]: owner@example.com
user[password]: Owner12345
user[first_name]: John
user[last_name]: Doe
user[phone]: +628123456789
user[role]: owner
```

**Body (multipart/form-data) - With Profile Photo:**
```
user[email]: owner@example.com
user[password]: Owner12345
user[first_name]: John
user[last_name]: Doe
user[phone]: +628123456789
user[role]: owner
user[profile_photo]: [select file - JPG/PNG, max 5MB]
```

**Body (raw JSON) - Without Photo:**
```json
{
  "user": {
    "email": "owner@example.com",
    "password": "Owner12345",
    "first_name": "John",
    "last_name": "Doe",
    "phone": "+628123456789",
    "role": "owner"
  }
}
```

**Response Success (201):**
```json
{
  "success": true,
  "message": "User created",
  "data": {
    "id": 2,
    "email": "owner@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "full_name": "John Doe",
    "phone": "+628123456789",
    "role": "owner",
    "active": true,
    "profile_photo_url": null,
    "created_at": "2024-12-23T23:50:00Z"
  }
}
```

**Response Error (422):**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    "Email has already been taken",
    "Password is too short (minimum is 8 characters)"
  ]
}
```

---

### 2.4 Update User (Admin or Self)
**Endpoint:** `PUT /api/v1/users/:id` atau `PATCH /api/v1/users/:id`

**Description:** Update user data. Admin bisa update semua user, Owner hanya bisa update dirinya sendiri.

**Headers:**
```
Authorization: Bearer {{jwt_token}}
```

**Body (multipart/form-data) - Without Photo:**
```
user[first_name]: John Updated
user[last_name]: Doe Updated
user[phone]: +628987654321
user[active]: true
```

**Body (multipart/form-data) - With New Profile Photo:**
```
user[first_name]: John Updated
user[last_name]: Doe Updated
user[phone]: +628987654321
user[active]: true
user[profile_photo]: [select new photo file]
```

**Body (multipart/form-data) - Remove Profile Photo:**
```
user[first_name]: John Updated
user[last_name]: Doe Updated
user[phone]: +628987654321
user[remove_profile_photo]: true
```

**Body (raw JSON) - Basic Update:**
```json
{
  "user": {
    "first_name": "John Updated",
    "last_name": "Doe Updated",
    "phone": "+628987654321",
    "active": true
  }
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "User updated",
  "data": {
    "id": 2,
    "email": "owner@example.com",
    "first_name": "John Updated",
    "last_name": "Doe Updated",
    "full_name": "John Updated Doe Updated",
    "phone": "+628987654321",
    "role": "owner",
    "active": true,
    "profile_photo_url": "/rails/active_storage/blobs/...",
    "created_at": "2024-12-23T23:50:00Z"
  }
}
```

---

### 2.5 Delete User (Admin Only)
**Endpoint:** `DELETE /api/v1/users/:id`

**Description:** Soft delete user (set active: false). Hanya Admin.

**Headers:**
```
Authorization: Bearer {{admin_jwt_token}}
```

**URL Parameter:**
```
id: 2 (user ID to delete)
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "User deleted",
  "data": {
    "id": 2,
    "email": "owner@example.com",
    "active": false,
    ...
  }
}
```

---

## 3. POSTMAN VARIABLES

Untuk memudahkan testing, setup Postman Variables:

### Collection Variables:
```
base_url: http://localhost:3000
admin_email: admin@rukita-clone.com
admin_password: Admin@123456
jwt_token: {{auto-generated from login}}
admin_jwt_token: {{auto-generated from admin login}}
owner_email: owner@example.com
owner_password: Owner12345
```

### Pre-request Script for Login:
```javascript
// Auto-set jwt_token after login
if (pm.response.code === 200) {
    const response = pm.response.json();
    if (response.data && response.data.token) {
        pm.environment.set("jwt_token", response.data.token);

        // Set admin_jwt_token if role is admin
        if (response.data.user.role === "admin") {
            pm.environment.set("admin_jwt_token", response.data.token);
        }
    }
}
```

---

## 4. TESTING SCENARIOS

### Scenario 1: Admin Login & Create Owner
**Step 1:** Login as Admin
```
POST /api/v1/auth/login
Body: {"email": "admin@rukita-clone.com", "password": "Admin@123456"}
→ Save jwt_token as admin_jwt_token
```

**Step 2:** Create Owner User
```
POST /api/v1/users
Header: Authorization: Bearer {{admin_jwt_token}}
Body: {
  "user": {
    "email": "owner1@example.com",
    "password": "Owner12345",
    "first_name": "Jane",
    "last_name": "Smith",
    "phone": "+628123456789",
    "role": "owner"
  }
}
```

**Step 3:** List All Users
```
GET /api/v1/users
Header: Authorization: Bearer {{admin_jwt_token}}
Query: ?page=1&per_page=10
```

---

### Scenario 2: Owner Login & Update Profile
**Step 1:** Login as Owner
```
POST /api/v1/auth/login
Body: {"email": "owner1@example.com", "password": "Owner12345"}
→ Save jwt_token
```

**Step 2:** Get Own Profile
```
GET /api/v1/auth/me
Header: Authorization: Bearer {{jwt_token}}
```

**Step 3:** Update Own Profile
```
PUT /api/v1/users/{{owner_id}}
Header: Authorization: Bearer {{jwt_token}}
Body: {
  "user": {
    "first_name": "Jane Updated",
    "phone": "+628999999999"
  }
}
```

**Step 4:** Upload Profile Photo
```
PUT /api/v1/users/{{owner_id}}
Header: Authorization: Bearer {{jwt_token}}
Content-Type: multipart/form-data
Body:
  user[first_name]: Jane With Photo
  user[profile_photo]: [select JPG/PNG file]
```

---

### Scenario 3: Test Authorization
**Step 1:** Owner tries to list all users (Should fail - 403)
```
GET /api/v1/users
Header: Authorization: Bearer {{owner_jwt_token}}
→ Expected: 403 Unauthorized
```

**Step 2:** Owner tries to create user (Should fail - 403)
```
POST /api/v1/users
Header: Authorization: Bearer {{owner_jwt_token}}
Body: {...}
→ Expected: 403 Unauthorized
```

**Step 3:** Owner tries to view other user (Should fail - 403)
```
GET /api/v1/users/1
Header: Authorization: Bearer {{owner_jwt_token}}
→ Expected: 403 Unauthorized (if user_id != current_user.id)
```

---

## 5. EXAMPLE cURL COMMANDS

### Login as Admin:
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@rukita-clone.com",
    "password": "Admin@123456"
  }'
```

### Create Owner User (with JWT):
```bash
curl -X POST http://localhost:3000/api/v1/users \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "owner@example.com",
      "password": "Owner12345",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+628123456789",
      "role": "owner"
    }
  }'
```

### Update User with Profile Photo:
```bash
curl -X PUT http://localhost:3000/api/v1/users/2 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "user[first_name]=John Updated" \
  -F "user[phone]=+628987654321" \
  -F "user[profile_photo]=@/path/to/photo.jpg"
```

---

## 6. ERROR RESPONSES

### 401 Unauthorized:
```json
{
  "success": false,
  "message": "Unauthorized"
}
```

### 403 Forbidden:
```json
{
  "success": false,
  "message": "You are not authorized to perform this action"
}
```

### 404 Not Found:
```json
{
  "success": false,
  "message": "User not found"
}
```

### 422 Validation Error:
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    "Email can't be blank",
    "Password is too short (minimum is 8 characters)"
  ]
}
```

### 500 Internal Server Error:
```json
{
  "success": false,
  "message": "An unexpected error occurred",
  "errors": ["Error details..."]
}
```

---

## NOTES:

1. **JWT Token**: Valid untuk 1 jam, gunakan refresh token untuk mendapatkan token baru
2. **Profile Photo**: Max 5MB, format PNG/JPG/JPEG saja
3. **Soft Delete**: Delete user tidak menghapus data, hanya set active: false
4. **Password**: Min 8 characters
5. **Role**:
   - `admin` = Full access
   - `owner` = Limited access (only own profile)
6. **Phone**: Optional field
7. **Pagination**: Default 20 per page, max 100

---

## IMPORT TO POSTMAN:

Copy collection ini ke Postman:
1. Buka Postman
2. Click "Import"
3. Paste raw text atau upload file ini
4. Collection akan terbuat dengan semua endpoints

Happy Testing! 🚀
