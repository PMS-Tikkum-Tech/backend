# frozen_string_literal: true

class UserPresenter
  def self.as_json(user)
    {
      id: user.id,
      full_name: user.full_name,
      email: user.email,
      phone_number: user.phone_number,
      emergency_contact_name: user.emergency_contact_name,
      emergency_contact_number: user.emergency_contact_number,
      relationship: user.relationship,
      nik: user.nik,
      role: user.role,
      account_status: user.account_status,
      profile_picture_url: user.profile_picture_url,
      created_at: user.created_at&.iso8601,
      updated_at: user.updated_at&.iso8601
    }
  end

  def self.collection(users)
    users.map { |user| as_json(user) }
  end
end
