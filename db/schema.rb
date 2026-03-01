# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2026_02_27_110000) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "communication_recipients", force: :cascade do |t|
    t.bigint "communication_id", null: false
    t.bigint "tenant_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "sent_at"
    t.text "failed_reason"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["communication_id", "tenant_id"], name: "idx_communication_recipients_unique", unique: true
    t.index ["communication_id"], name: "index_communication_recipients_on_communication_id"
    t.index ["status"], name: "index_communication_recipients_on_status"
    t.index ["tenant_id"], name: "index_communication_recipients_on_tenant_id"
  end

  create_table "communications", force: :cascade do |t|
    t.bigint "property_id"
    t.bigint "created_by_id", null: false
    t.integer "audience_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "subject", null: false
    t.text "message", null: false
    t.datetime "scheduled_at", null: false
    t.datetime "sent_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["audience_type"], name: "index_communications_on_audience_type"
    t.index ["created_by_id"], name: "index_communications_on_created_by_id"
    t.index ["property_id"], name: "index_communications_on_property_id"
    t.index ["scheduled_at"], name: "index_communications_on_scheduled_at"
    t.index ["status"], name: "index_communications_on_status"
  end

  create_table "financial_transactions", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "unit_id"
    t.bigint "created_by_id", null: false
    t.integer "category", default: 0, null: false
    t.date "transaction_date", null: false
    t.decimal "amount", precision: 14, scale: 2, null: false
    t.text "description", null: false
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["category"], name: "index_financial_transactions_on_category"
    t.index ["created_by_id"], name: "index_financial_transactions_on_created_by_id"
    t.index ["property_id", "transaction_date"], name: "idx_financial_transactions_property_date"
    t.index ["property_id"], name: "index_financial_transactions_on_property_id"
    t.index ["transaction_date"], name: "index_financial_transactions_on_transaction_date"
    t.index ["unit_id"], name: "index_financial_transactions_on_unit_id"
  end

  create_table "leases", force: :cascade do |t|
    t.bigint "unit_id", null: false
    t.bigint "tenant_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "lease_status", default: 0, null: false
    t.integer "payment_status", default: 1, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["lease_status"], name: "index_leases_on_lease_status"
    t.index ["payment_status"], name: "index_leases_on_payment_status"
    t.index ["tenant_id", "lease_status"], name: "index_leases_on_tenant_id_and_lease_status"
    t.index ["tenant_id"], name: "index_leases_on_tenant_id"
    t.index ["unit_id"], name: "index_leases_on_unit_id"
  end

  create_table "log_activities", force: :cascade do |t|
    t.bigint "admin_id", null: false
    t.string "action", null: false
    t.string "module_name", null: false
    t.text "description", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["action"], name: "index_log_activities_on_action"
    t.index ["admin_id"], name: "index_log_activities_on_admin_id"
    t.index ["created_at"], name: "index_log_activities_on_created_at"
    t.index ["module_name"], name: "index_log_activities_on_module_name"
  end

  create_table "maintenance_requests", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "unit_id", null: false
    t.bigint "tenant_id", null: false
    t.bigint "assigned_to_id"
    t.string "issue", null: false
    t.string "category", null: false
    t.text "description"
    t.integer "priority", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.date "requested_date"
    t.date "repair_date"
    t.string "visiting_hours"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["assigned_to_id"], name: "index_maintenance_requests_on_assigned_to_id"
    t.index ["category"], name: "index_maintenance_requests_on_category"
    t.index ["priority"], name: "index_maintenance_requests_on_priority"
    t.index ["property_id"], name: "index_maintenance_requests_on_property_id"
    t.index ["requested_date"], name: "index_maintenance_requests_on_requested_date"
    t.index ["status"], name: "index_maintenance_requests_on_status"
    t.index ["tenant_id"], name: "index_maintenance_requests_on_tenant_id"
    t.index ["unit_id"], name: "index_maintenance_requests_on_unit_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "unit_id", null: false
    t.bigint "tenant_id", null: false
    t.bigint "lease_id"
    t.string "invoice_id", null: false
    t.string "xendit_invoice_id"
    t.integer "status", default: 0, null: false
    t.decimal "amount", precision: 14, scale: 2, null: false
    t.date "due_date", null: false
    t.datetime "paid_at"
    t.string "payment_method"
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["due_date"], name: "index_payments_on_due_date"
    t.index ["invoice_id"], name: "index_payments_on_invoice_id", unique: true
    t.index ["lease_id"], name: "index_payments_on_lease_id"
    t.index ["property_id", "status"], name: "idx_payments_property_status"
    t.index ["property_id"], name: "index_payments_on_property_id"
    t.index ["status"], name: "index_payments_on_status"
    t.index ["tenant_id"], name: "index_payments_on_tenant_id"
    t.index ["unit_id"], name: "index_payments_on_unit_id"
    t.index ["xendit_invoice_id"], name: "index_payments_on_xendit_invoice_id", unique: true
  end

  create_table "properties", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.text "address", null: false
    t.string "property_type", null: false
    t.string "condition", null: false
    t.jsonb "facilities", default: [], null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "rules", default: "", null: false
    t.index ["condition"], name: "index_properties_on_condition"
    t.index ["name"], name: "index_properties_on_name"
    t.index ["property_type"], name: "index_properties_on_property_type"
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "revoked_tokens", force: :cascade do |t|
    t.string "jti", null: false
    t.bigint "user_id", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["exp"], name: "index_revoked_tokens_on_exp"
    t.index ["jti"], name: "index_revoked_tokens_on_jti", unique: true
    t.index ["user_id"], name: "index_revoked_tokens_on_user_id"
  end

  create_table "units", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.string "name", null: false
    t.string "unit_type", null: false
    t.integer "status", default: 0, null: false
    t.integer "people_allowed", default: 1, null: false
    t.decimal "price", precision: 14, scale: 2, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_units_on_name"
    t.index ["property_id"], name: "index_units_on_property_id"
    t.index ["status"], name: "index_units_on_status"
    t.index ["unit_type"], name: "index_units_on_unit_type"
  end

  create_table "users", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "phone_number"
    t.integer "role", default: 2, null: false
    t.integer "account_status", default: 0, null: false
    t.string "refresh_token"
    t.datetime "refresh_token_expires_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "emergency_contact_name"
    t.bigint "emergency_contact_number"
    t.string "relationship"
    t.bigint "nik"
    t.index ["account_status"], name: "index_users_on_account_status"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["refresh_token"], name: "index_users_on_refresh_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "communication_recipients", "communications"
  add_foreign_key "communication_recipients", "users", column: "tenant_id"
  add_foreign_key "communications", "properties"
  add_foreign_key "communications", "users", column: "created_by_id"
  add_foreign_key "financial_transactions", "properties"
  add_foreign_key "financial_transactions", "units"
  add_foreign_key "financial_transactions", "users", column: "created_by_id"
  add_foreign_key "leases", "units"
  add_foreign_key "leases", "users", column: "tenant_id"
  add_foreign_key "log_activities", "users", column: "admin_id"
  add_foreign_key "maintenance_requests", "properties"
  add_foreign_key "maintenance_requests", "units"
  add_foreign_key "maintenance_requests", "users", column: "assigned_to_id"
  add_foreign_key "maintenance_requests", "users", column: "tenant_id"
  add_foreign_key "payments", "leases"
  add_foreign_key "payments", "properties"
  add_foreign_key "payments", "units"
  add_foreign_key "payments", "users", column: "tenant_id"
  add_foreign_key "properties", "users"
  add_foreign_key "revoked_tokens", "users"
  add_foreign_key "units", "properties"
end
