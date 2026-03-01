# frozen_string_literal: true

class RevokedToken < ApplicationRecord
  belongs_to :user

  validates :jti, presence: true, uniqueness: true
  validates :exp, presence: true

  scope :active, -> { where("exp > ?", Time.current) }
end
