class CoachSchedule < ApplicationRecord
  STATUSES = %w[available unavailable].freeze

  belongs_to :coach
  has_many :bookings, dependent: :destroy

  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :max_bookings, presence: true, numericality: { only_integer: true, greater_than: 0 }

  validate :time_range_valid
  validate :coach_schedule_no_conflict, on: :create
  validate :coach_schedule_no_conflict_on_update, on: :update
  validate :not_past_date, on: :create

  scope :for_week, ->(date = Date.current) do
    week_start = date.beginning_of_week
    week_end = date.end_of_week
    where(date: week_start..week_end)
  end

  scope :for_date, ->(date) { where(date: date) }
  scope :available, -> { where(status: 'available') }
  scope :by_coach, ->(coach_id) { where(coach_id: coach_id) }
  scope :order_by_time, -> { order(:date, :start_time) }

  def available?
    status == 'available'
  end

  def full?
    current_bookings_count >= max_bookings
  end

  def current_bookings_count
    bookings.where(status: 'booked').count
  end

  def available_slots
    max_bookings - current_bookings_count
  end

  def start_datetime
    DateTime.parse("#{date} #{start_time}")
  end

  def end_datetime
    DateTime.parse("#{date} #{end_time}")
  end

  def can_cancel?(current_time = Time.current)
    start_datetime - current_time >= 2.hours
  end

  def cancellation_deadline
    start_datetime - 2.hours
  end

  def past?
    end_datetime < Time.current
  end

  def self.batch_create_weekly_schedule(coach_id, week_date, time_slots)
    coach = Coach.find(coach_id)
    week_start = week_date.beginning_of_week

    created_schedules = []
    errors = []

    time_slots.each do |slot|
      day_offset = slot[:day_of_week].to_i
      date = week_start + day_offset.days
      start_time = slot[:start_time]
      end_time = slot[:end_time]
      max_bookings = slot[:max_bookings] || 1

      schedule = new(
        coach: coach,
        date: date,
        start_time: start_time,
        end_time: end_time,
        max_bookings: max_bookings,
        status: 'available'
      )

      if schedule.save
        created_schedules << schedule
      else
        errors << { slot: slot, errors: schedule.errors.full_messages }
      end
    end

    { created: created_schedules, errors: errors }
  end

  private

  def time_range_valid
    return unless start_time && end_time

    if end_time <= start_time
      raise InvalidTimeRangeError
    end
  end

  def coach_schedule_no_conflict
    return unless coach && date && start_time && end_time

    if coach.has_schedule_conflict?(date, start_time, end_time)
      raise CoachScheduleConflictError
    end
  end

  def coach_schedule_no_conflict_on_update
    return unless coach && date && start_time && end_time

    if coach.has_schedule_conflict?(date, start_time, end_time, id)
      raise CoachScheduleConflictError
    end
  end

  def not_past_date
    return unless date

    if date < Date.current
      raise PastDateError
    end
  end
end
