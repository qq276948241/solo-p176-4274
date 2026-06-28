class Member < ApplicationRecord
  CARD_TYPES = %w[prepaid monthly].freeze
  STATUSES = %w[active inactive].freeze

  has_many :bookings, dependent: :destroy

  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true
  validates :card_type, presence: true, inclusion: { in: CARD_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :remaining_sessions, presence: true, if: -> { card_type == 'prepaid' }
  validates :monthly_start_date, :monthly_end_date, presence: true, if: -> { card_type == 'monthly' }

  validate :monthly_date_range, if: -> { card_type == 'monthly' && monthly_start_date && monthly_end_date }

  scope :active, -> { where(status: 'active') }
  scope :prepaid, -> { where(card_type: 'prepaid') }
  scope :monthly, -> { where(card_type: 'monthly') }

  def prepaid?
    card_type == 'prepaid'
  end

  def monthly?
    card_type == 'monthly'
  end

  def active?
    status == 'active'
  end

  def can_book?
    return false unless active?

    if prepaid?
      remaining_sessions.to_i > 0
    elsif monthly?
      monthly_card_valid?
    else
      false
    end
  end

  def monthly_card_valid?
    return false unless monthly?
    return false unless monthly_start_date && monthly_end_date

    today = Date.current
    today >= monthly_start_date && today <= monthly_end_date
  end

  def consume_session!
    raise MemberInactiveError unless active?

    if prepaid?
      raise InsufficientSessionsError unless remaining_sessions.to_i > 0
      decrement!(:remaining_sessions)
    elsif monthly?
      raise CardExpiredError unless monthly_card_valid?
    else
      raise InvalidCardTypeError
    end
  end

  def refund_session!
    if prepaid?
      increment!(:remaining_sessions)
    end
  end

  def booking_eligibility
    return { eligible: false, reason: 'member_inactive', message: '会员状态异常' } unless active?

    if prepaid?
      if remaining_sessions.to_i > 0
        { eligible: true, type: 'prepaid', remaining: remaining_sessions }
      else
        { eligible: false, reason: 'insufficient_sessions', message: '次卡次数不足' }
      end
    elsif monthly?
      if monthly_card_valid?
        { eligible: true, type: 'monthly', valid_until: monthly_end_date }
      else
        { eligible: false, reason: 'card_expired', message: '月卡已过期' }
      end
    else
      { eligible: false, reason: 'invalid_card_type', message: '无效的卡类型' }
    end
  end

  private

  def monthly_date_range
    if monthly_end_date < monthly_start_date
      errors.add(:monthly_end_date, '必须晚于开始日期')
    end
  end
end
