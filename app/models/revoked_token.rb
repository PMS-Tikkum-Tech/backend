# frozen_string_literal: true

class RevokedToken < ApplicationRecord
  belongs_to :user
  validates :jti, presence: true, uniqueness: true
  validates :exp, presence: true

  # Check if token is expired
  def expired?
    exp < Time.current
  end

  # Clean up expired tokens (can be called periodically)
  def self.cleanup_expired
    where('exp < ?', Time.current).delete_all
  end
end
