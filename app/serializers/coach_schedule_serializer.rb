class CoachScheduleSerializer < ActiveModel::Serializer
  attributes :id, :coach_id, :coach_name, :date, :start_time, :end_time,
             :status, :max_bookings, :current_bookings_count, :available_slots,
             :is_full, :is_past, :can_cancel, :cancellation_deadline,
             :bookings

  def coach_name
    object.coach&.name
  end

  def current_bookings_count
    object.current_bookings_count
  end

  def available_slots
    object.available_slots
  end

  def is_full
    object.full?
  end

  def is_past
    object.past?
  end

  def can_cancel
    object.can_cancel?
  end

  def cancellation_deadline
    object.cancellation_deadline.iso8601
  end

  def bookings
    if instance_options[:include_bookings]
      object.bookings.booked.map do |booking|
        {
          id: booking.id,
          member_id: booking.member_id,
          member_name: booking.member&.name,
          status: booking.status,
          consumed: booking.consumed
        }
      end
    end
  end
end
