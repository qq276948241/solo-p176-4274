class Token < ApplicationRecord
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :valid, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def valid?
    !expired?
  end

  def self.authenticate(token_string)
    token = find_by(token: token_string)
    return nil unless token

    if token.expired?
      raise TokenExpiredError
    end

    token
  end

  def self.generate(description = nil, duration = 30.days)
    token_string = SecureRandom.hex(32)
    expires_at = Time.current + duration

    create!(
      token: token_string,
      expires_at: expires_at,
      description: description
    )
  end

  def refresh!(duration = 30.days)
    update!(expires_at: Time.current + duration)
    self
  end

  def revoke!
    update!(expires_at: Time.current - 1.second)
    self
  end
end
