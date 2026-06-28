class Coach < ApplicationRecord
  STATUSES = %w[active inactive].freeze

  has_many :coach_schedules, dependent: :destroy
  has_many :bookings, through: :coach_schedules

  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where(status: 'active') }
  scope :by_specialty, ->(specialty) { where('specialty LIKE ?', "%#{specialty}%") }

  def active?
    status == 'active'
  end

  def schedules_for_week(date = Date.current)
    week_start = date.beginning_of_week
    week_end = date.end_of_week
    coach_schedules.where(date: week_start..week_end).order(:date, :start_time)
  end

  def has_schedule_conflict?(date, start_time, end_time, exclude_id = nil)
    schedule = coach_schedules.where(date: date, start_time: start_time, end_time: end_time)
    schedule = schedule.where.not(id: exclude_id) if exclude_id
    schedule.exists?
  end

  def available_slots_for_date(date)
    coach_schedules
      .where(date: date, status: 'available')
      .where('coach_schedules.id NOT IN (
        SELECT coach_schedule_id FROM bookings
        WHERE bookings.status = ?
      )', 'booked')
      .order(:start_time)
  end
end
