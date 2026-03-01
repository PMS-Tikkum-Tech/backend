# frozen_string_literal: true

class AuthInput
  include BaseInput

  attr_accessor :email, :password

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true

  def self.from_params(params)
    new(
      email: params[:email],
      password: params[:password],
    )
  end

  def to_h
    {
      email: email.to_s.downcase.strip,
      password: password,
    }
  end
end
