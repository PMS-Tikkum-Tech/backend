# Quick Testing Guide - Authentication Module

## Default Credentials

**Admin:**
- Email: `admin@rukita-clone.com`
- Password: `Admin@123456`

**Test Owner (perlu dibuat dulu):**
- Email: `owner@example.com`
- Password: `Owner12345`

---

## Quick cURL Commands

### 1. Login as Admin
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@rukita-clone.com","password":"Admin@123456"}'
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {...},
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "...",
    "expires_at": "..."
  }
}
```

### 2. Create Owner User (Admin Only)
```bash
# Ganti YOUR_ADMIN_JWT_TOKEN dengan token dari login
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

### 3. Login as Owner
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@example.com","password":"Owner12345"}'
```

### 4. Get Current User (Me)
```bash
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 5. List All Users (Admin Only)
```bash
curl -X GET "http://localhost:3000/api/v1/users?page=1&per_page=10" \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN"
```

### 6. Get User Detail
```bash
curl -X GET http://localhost:3000/api/v1/users/2 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 7. Update User
```bash
curl -X PUT http://localhost:3000/api/v1/users/2 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "first_name": "John Updated",
      "phone": "+628999999999"
    }
  }'
```

### 8. Upload Profile Photo
```bash
curl -X PUT http://localhost:3000/api/v1/users/2 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "user[first_name]=John With Photo" \
  -F "user[profile_photo]=@/path/to/photo.jpg"
```

### 9. Delete User (Soft Delete - Admin Only)
```bash
curl -X DELETE http://localhost:3000/api/v1/users/2 \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN"
```

### 10. Logout
```bash
curl -X DELETE http://localhost:3000/api/v1/auth/logout \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"YOUR_REFRESH_TOKEN"}'
```

---

## Import ke Postman

### Cara 1: Import JSON Collection
1. Buka Postman
2. Klik "Import" di pojok kiri atas
3. Pilih tab "File"
4. Upload file: `postman_collection.json`
5. Collection akan muncul di sidebar kiri

### Cara 2: Import dari Documentation
1. Buka Postman
2. Klik "Import"
3. Pilih tab "Raw Text"
4. Copy dan paste isi dari `POSTMAN_COLLECTION.md`
5. Klik "Continue" lalu "Import"

---

## Setup Postman Variables

Setelah import, setup variables di Postman:

### Environment Variables:
```
base_url           = http://localhost:3000
jwt_token          = (auto-set dari login)
admin_jwt_token    = (auto-set dari admin login)
refresh_token      = (auto-set dari login)
```

### Auto-Save Token Script (Test Tab):
```javascript
if (pm.response.code === 200) {
    const response = pm.response.json();
    if (response.success && response.data && response.data.token) {
        pm.environment.set('jwt_token', response.data.token);
        if (response.data.user.role === 'admin') {
            pm.environment.set('admin_jwt_token', response.data.token);
        }
        pm.environment.set('refresh_token', response.data.refresh_token);
    }
}
```

---

## Test Scenarios

### Scenario 1: Admin Flow
1. ✅ Login as Admin → Simpan `admin_jwt_token`
2. ✅ Create Owner User → User baru created
3. ✅ List All Users → Lihat semua users
4. ✅ Filter Users by Role → Lihat hanya owners
5. ✅ Get User Detail → Lihat detail user
6. ✅ Update User → Update data user
7. ✅ Upload User Photo → Upload profile photo
8. ✅ Soft Delete User → Deactivate user

### Scenario 2: Owner Flow
1. ✅ Login as Owner → Simpan `jwt_token`
2. ✅ Get Me → Lihat profile sendiri
3. ✅ Update Own Profile → Update data sendiri
4. ✅ Upload Own Photo → Upload photo sendiri
5. ❌ List All Users → 403 Forbidden
6. ❌ Create User → 403 Forbidden
7. ❌ Delete User → 403 Forbidden
8. ❌ View Other User → 403 Forbidden

---

## HTTP Status Codes

- **200 OK** - Request successful
- **201 Created** - Resource created successfully
- **401 Unauthorized** - Authentication failed or missing
- **403 Forbidden** - Authorization failed (not allowed)
- **404 Not Found** - Resource not found
- **422 Unprocessable Entity** - Validation error
- **500 Internal Server Error** - Server error

---

## Tips Testing

### 1. Use Postman Environments
Buat environment "Development" dengan variable `base_url` untuk mudah switch antara local & production

### 2. Save Responses
Postman bisa save example responses untuk dokumentasi

### 3. Collection Runner
Gunakan Collection Runner untuk automated testing sequence

### 4. Pre-request Scripts
Gunakan untuk auto-generate test data atau timestamps

### 5. Test Scripts
Add assertions di Tests tab:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has success=true", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.success).to.eql(true);
});
```

---

## Common Issues & Solutions

### Issue: "Authentication failed"
**Solution:** Check JWT token, pastikan belum expired (1 hour)

### Issue: "Not authorized to perform this action"
**Solution:** Check role, pastikan Admin untuk CRUD users

### Issue: "User not found"
**Solution:** Check user ID, pastikan user masih active

### Issue: "Validation failed"
**Solution:** Check input format, min password 8 chars, email format

### Issue: Profile photo upload fail
**Solution:** Check file size (max 5MB) dan format (PNG/JPG/JPEG)

---

## File Locations

- **Postman Collection JSON**: `postman_collection.json`
- **Detailed Documentation**: `POSTMAN_COLLECTION.md`
- **This Quick Guide**: `TESTING_GUIDE.md`

---

## Start Testing

1. Start Rails server: `rails s`
2. Open Postman
3. Import collection
4. Login as Admin
5. Create Owner user
6. Test all endpoints!

Happy Testing! 🚀
