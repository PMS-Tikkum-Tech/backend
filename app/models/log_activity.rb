# frozen_string_literal: true

class LogActivity < ApplicationRecord
  belongs_to :admin,
             class_name: "User",
             inverse_of: :admin_log_activities

  validates :action, inclusion: { in: ["create", "update", "delete"] }
  validates :module_name, presence: true
  validates :description, presence: true

  scope :by_module, ->(module_name) { where(module_name: module_name) }
  scope :by_admin, ->(admin_id) { where(admin_id: admin_id) }
  scope :by_action, ->(action) { where(action: action) }
end
