# frozen_string_literal: true

puts "Seeding users..."

users_seed = [
  {
    full_name: "Admin1",
    email: "admin1@kyrastay.local",
    password: "Password123!",
    phone_number: "081111111111",
    role: :admin,
    account_status: :active,
  },
  {
    full_name: "Owner1",
    email: "owner1@kyrastay.local",
    password: "Password123!",
    phone_number: "082222222222",
    role: :owner,
    account_status: :active,
  },
  {
    full_name: "Owner2",
    email: "owner2@kyrastay.local",
    password: "Password123!",
    phone_number: "083333333333",
    role: :owner,
    account_status: :active,
  },
  {
    full_name: "Tenant1",
    email: "tenant1@kyrastay.local",
    password: "Password123!",
    phone_number: "084444444444",
    role: :tenant,
    account_status: :active,
  },
  {
    full_name: "Tenant2",
    email: "tenant2@kyrastay.local",
    password: "Password123!",
    phone_number: "085555555555",
    role: :tenant,
    account_status: :active,
  },
  {
    full_name: "Tenant Nonaktif",
    email: "tenant3@kyrastay.local",
    password: "Password123!",
    phone_number: "086666666666",
    role: :tenant,
    account_status: :inactive,
  },
]

users = {}
users_seed.each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  user.assign_attributes(attrs.except(:email, :password))
  user.password = attrs[:password]
  user.save!
  users[attrs[:email]] = user
end

admin = users.fetch("admin1@kyrastay.local")
owners = [
  users.fetch("owner1@kyrastay.local"),
  users.fetch("owner2@kyrastay.local"),
]
tenants = [users.fetch("tenant1@kyrastay.local"), users.fetch("tenant2@kyrastay.local")]

puts "Seeding properties..."

properties_seed = [
  {
    name: "Kinara Signature Kost",
    description: "Kost eksklusif dekat pusat kota dengan fasilitas lengkap",
    address: "Jl. Merdeka No. 10, Bandung",
    property_type: "kost",
    condition: "excellent",
    rules: "Don't smoke",
    facilities: ["wifi", "parking_area", "kitchen", "cctv", "security_24h"],
    owner: owners[0],
  },
  {
    name: "Kinara Urban Residence",
    description: "Hunian modern untuk profesional muda",
    address: "Jl. Asia Afrika No. 99, Bandung",
    property_type: "apartment",
    condition: "good",
    rules: "No pets after 10 PM",
    facilities: ["wifi", "elevator", "gym", "laundry", "balcony"],
    owner: owners[1],
  },
  {
    name: "Kinara Green House",
    description: "Rumah nyaman dengan taman hijau",
    address: "Jl. Dago Atas No. 21, Bandung",
    property_type: "house",
    condition: "fair",
    rules: "Keep noise low after 9 PM",
    facilities: ["wifi", "garden", "pet_friendly", "kitchen"],
    owner: owners[0],
  },
]

properties = properties_seed.map do |attrs|
  property = Property.find_or_initialize_by(name: attrs[:name])
  property.assign_attributes(
    user: attrs[:owner],
    description: attrs[:description],
    address: attrs[:address],
    property_type: attrs[:property_type],
    condition: attrs[:condition],
    rules: attrs[:rules],
    facilities: attrs[:facilities],
  )
  property.save!
  property
end

puts "Seeding units..."

units = []
properties.each_with_index do |property, property_index|
  unit_templates = [
    {
      name: "Unit #{property_index + 1}01",
      unit_type: "standard",
      people_allowed: 1,
      price: 2_500_000,
    },
    {
      name: "Unit #{property_index + 1}02",
      unit_type: "deluxe",
      people_allowed: 2,
      price: 3_500_000,
    },
    {
      name: "Unit #{property_index + 1}03",
      unit_type: "exclusive",
      people_allowed: 2,
      price: 4_500_000,
    },
  ]

  unit_templates.each do |template|
    unit = Unit.find_or_initialize_by(property: property, name: template[:name])
    unit.assign_attributes(
      unit_type: template[:unit_type],
      status: :vacant,
      people_allowed: template[:people_allowed],
      price: template[:price],
    )
    unit.save!
    units << unit
  end
end

puts "Seeding leases..."

leases_seed = [
  {
    unit: units[0],
    tenant: tenants[0],
    start_date: Date.current.beginning_of_month,
    end_date: Date.current.next_month.end_of_month,
    lease_status: :active,
    payment_status: :paid,
  },
  {
    unit: units[1],
    tenant: tenants[1],
    start_date: Date.current.beginning_of_month,
    end_date: Date.current.next_month.end_of_month,
    lease_status: :active,
    payment_status: :unpaid,
  },
]

leases = leases_seed.map do |attrs|
  lease = Lease.find_or_initialize_by(
    unit: attrs[:unit],
    tenant: attrs[:tenant],
    start_date: attrs[:start_date],
  )
  lease.assign_attributes(
    end_date: attrs[:end_date],
    lease_status: attrs[:lease_status],
    payment_status: attrs[:payment_status],
  )
  lease.save!
  attrs[:unit].update!(status: :occupied)
  lease
end

units[2].update!(status: :maintenance)

puts "Seeding maintenance requests..."

maintenance_seed = [
  {
    property: properties[0],
    unit: units[0],
    tenant: tenants[0],
    assigned_to: admin,
    issue: "Air kamar mandi bocor",
    category: "plumbing",
    description: "Kran wastafel menetes sejak kemarin malam",
    priority: :high,
    status: :assigned,
    requested_date: Date.current - 2,
    repair_date: Date.current + 1,
    visiting_hours: "09:00-12:00",
  },
  {
    property: properties[0],
    unit: units[1],
    tenant: tenants[1],
    assigned_to: nil,
    issue: "Lampu utama mati",
    category: "electrical",
    description: "Lampu kamar tidak menyala meskipun sudah diganti",
    priority: :medium,
    status: :unassigned,
    requested_date: Date.current - 1,
    repair_date: nil,
    visiting_hours: nil,
  },
  {
    property: properties[1],
    unit: units[3],
    tenant: tenants[0],
    assigned_to: admin,
    issue: "AC tidak dingin",
    category: "hvac",
    description: "AC hanya keluar angin dan sangat berisik",
    priority: :low,
    status: :in_progress,
    requested_date: Date.current,
    repair_date: Date.current + 2,
    visiting_hours: "13:00-16:00",
  },
]

maintenance_seed.each do |attrs|
  request = MaintenanceRequest.find_or_initialize_by(
    issue: attrs[:issue],
    unit: attrs[:unit],
    tenant: attrs[:tenant],
  )
  request.assign_attributes(attrs)
  request.save!
end

puts "Seeding financial transactions..."

financial_seed = [
  {
    property: properties[0],
    unit: units[0],
    created_by: admin,
    category: :income,
    transaction_date: Date.current - 3,
    amount: 3_500_000,
    description: "Pembayaran sewa bulanan Unit 101",
    notes: "Transfer bank BCA",
  },
  {
    property: properties[0],
    unit: nil,
    created_by: admin,
    category: :expense,
    transaction_date: Date.current - 2,
    amount: 750_000,
    description: "Perbaikan instalasi listrik area lobi",
    notes: "Vendor internal",
  },
  {
    property: properties[1],
    unit: units[3],
    created_by: admin,
    category: :income,
    transaction_date: Date.current - 1,
    amount: 4_000_000,
    description: "Pembayaran sewa bulanan Unit 201",
    notes: "Transfer virtual account",
  },
]

financial_seed.each do |attrs|
  transaction = FinancialTransaction.find_or_initialize_by(
    property: attrs[:property],
    unit: attrs[:unit],
    transaction_date: attrs[:transaction_date],
    description: attrs[:description],
  )
  transaction.assign_attributes(attrs)
  transaction.save!
end

puts "Seeding payments..."

payments_seed = [
  {
    invoice_id: "INV-SEED-001",
    property: properties[0],
    unit: units[0],
    tenant: tenants[0],
    lease: leases[0],
    status: :paid,
    amount: 3_500_000,
    due_date: Date.current - 5,
    paid_at: DateTime.current - 3,
    payment_method: "bank_transfer",
    description: "Tagihan sewa Unit 101",
    xendit_invoice_id: "xnd-INV-SEED-001",
  },
  {
    invoice_id: "INV-SEED-002",
    property: properties[0],
    unit: units[1],
    tenant: tenants[1],
    lease: leases[1],
    status: :waiting,
    amount: 3_500_000,
    due_date: Date.current + 5,
    paid_at: nil,
    payment_method: nil,
    description: "Tagihan sewa Unit 102",
    xendit_invoice_id: nil,
  },
]

payments_seed.each do |attrs|
  payment = Payment.find_or_initialize_by(invoice_id: attrs[:invoice_id])
  payment.assign_attributes(attrs)
  payment.save!
end

puts "Seeding communications..."

communication_seed = [
  {
    subject: "Info Maintenance Lift",
    message: "Akan ada maintenance lift gedung A pukul 10:00-12:00.",
    property: properties[0],
    created_by: admin,
    audience_type: :all_tenants,
    status: :sent,
    scheduled_at: Time.current + 1.day,
    sent_at: Time.current,
    tenant_ids: tenants.map(&:id),
  },
  {
    subject: "Pemberitahuan Tagihan",
    message: "Mohon melakukan pembayaran sebelum tanggal jatuh tempo.",
    property: properties[0],
    created_by: admin,
    audience_type: :some_tenants,
    status: :scheduled,
    scheduled_at: Time.current + 2.days,
    sent_at: nil,
    tenant_ids: [tenants[1].id],
  },
]

communication_seed.each do |attrs|
  communication = Communication.find_or_initialize_by(
    subject: attrs[:subject],
    created_by: attrs[:created_by],
  )

  communication.assign_attributes(
    property: attrs[:property],
    audience_type: attrs[:audience_type],
    status: attrs[:status],
    message: attrs[:message],
    scheduled_at: attrs[:scheduled_at],
    sent_at: attrs[:sent_at],
  )
  communication.save!

  communication.communication_recipients.where.not(
    tenant_id: attrs[:tenant_ids],
  ).destroy_all

  attrs[:tenant_ids].each do |tenant_id|
    recipient = communication.communication_recipients.find_or_initialize_by(
      tenant_id: tenant_id,
    )
    recipient.status = communication.sent? ? :sent : :scheduled
    recipient.sent_at = communication.sent? ? communication.sent_at : nil
    recipient.save!
  end
end

puts "Seeding log activities..."

[
  {
    action: "create",
    module_name: "Property",
    description: "Created property: #{properties[0].name}",
  },
  {
    action: "update",
    module_name: "Maintenance",
    description: "Updated maintenance request assignment",
  },
  {
    action: "create",
    module_name: "Financial",
    description: "Created manual income transaction",
  },
  {
    action: "update",
    module_name: "Payment",
    description: "Updated payment status for invoice INV-SEED-001",
  },
].each do |attrs|
  LogActivity.find_or_create_by!(
    admin: admin,
    action: attrs[:action],
    module_name: attrs[:module_name],
    description: attrs[:description],
  )
end

puts "Seed completed."
