class Booking < ApplicationRecord
  STATUSES = %w[booked cancelled completed no_show].freeze
  CANCELLATION_WINDOW = 2.hours

  belongs_to :member
  belongs_to :coach_schedule

  has_one :coach, through: :coach_schedule

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :consumed, inclusion: { in: [true, false] }

  validate :booking_validations, on: :create
  validate :member_and_coach_active, on: :create

  scope :by_member, ->(member_id) { where(member_id: member_id) }
  scope :by_coach, ->(coach_id) do
    joins(:coach_schedule).where(coach_schedules: { coach_id: coach_id })
  end
  scope :by_date, ->(date) do
    joins(:coach_schedule).where(coach_schedules: { date: date })
  end
  scope :upcoming, -> do
    joins(:coach_schedule).where('coach_schedules.date >= ?', Date.current)
  end
  scope :past, -> do
    joins(:coach_schedule).where('coach_schedules.date < ?', Date.current)
  end
  scope :booked, -> { where(status: 'booked') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :consumed, -> { where(consumed: true) }
  scope :not_consumed, -> { where(consumed: false) }
  scope :order_by_time, -> do
    joins(:coach_schedule).order('coach_schedules.date ASC, coach_schedules.start_time ASC')
  end

  def booked?
    status == 'booked'
  end

  def cancelled?
    status == 'cancelled'
  end

  def can_cancel?
    return false unless booked?
    coach_schedule.can_cancel?
  end

  def cancellation_deadline
    coach_schedule.cancellation_deadline
  end

  def cancel!
    raise CancellationTooLateError unless can_cancel?

    transaction do
      update!(status: 'cancelled')

      if consumed?
        member.refund_session!
        update!(consumed: false)
      end
    end

    true
  end

  def force_cancel!
    return if cancelled?

    transaction do
      update!(status: 'cancelled')

      if consumed? && member.prepaid?
        member.refund_session!
      end
    end

    true
  end

  def mark_as_consumed!
    return if consumed?

    transaction do
      update!(consumed: true)
      member.consume_session!
    end

    true
  end

  def complete!
    return unless booked?

    transaction do
      update!(status: 'completed')
      mark_as_consumed! unless consumed?
    end

    true
  end

  def mark_as_no_show!
    return unless booked?

    transaction do
      update!(status: 'no_show')
      mark_as_consumed! unless consumed?
    end

    true
  end

  private

  def booking_validations
    return unless member && coach_schedule

    validate_slot_available
    validate_member_eligibility
  end

  def validate_slot_available
    if coach_schedule.full?
      raise SlotFullError
    end

    if coach_schedule.past?
      raise PastDateError, '不能预约过去的时段'
    end

    unless coach_schedule.available?
      raise ApiError.new('该时段不可预约', status: 422, code: 'slot_unavailable')
    end
  end

  def validate_member_eligibility
    eligibility = member.booking_eligibility

    unless eligibility[:eligible]
      case eligibility[:reason]
      when 'member_inactive'
        raise MemberInactiveError
      when 'insufficient_sessions'
        raise InsufficientSessionsError
      when 'card_expired'
        raise CardExpiredError
      when 'invalid_card_type'
        raise InvalidCardTypeError
      else
        raise ApiError.new(eligibility[:message], status: 422, code: eligibility[:reason])
      end
    end
  end

  def member_and_coach_active
    return unless member && coach_schedule && coach_schedule.coach

    raise MemberInactiveError unless member.active?
    raise CoachInactiveError unless coach_schedule.coach.active?
  end
end
