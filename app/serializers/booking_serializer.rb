class BookingSerializer < ActiveModel::Serializer
  attributes :id, :member_id, :member_name, :coach_schedule_id,
             :coach_id, :coach_name, :date, :start_time, :end_time,
             :status, :consumed, :can_cancel, :cancellation_deadline,
             :created_at, :updated_at, :member, :coach_schedule

  def member_name
    object.member&.name
  end

  def coach_id
    object.coach_schedule&.coach_id
  end

  def coach_name
    object.coach_schedule&.coach&.name
  end

  def date
    object.coach_schedule&.date
  end

  def start_time
    object.coach_schedule&.start_time&.strftime('%H:%M')
  end

  def end_time
    object.coach_schedule&.end_time&.strftime('%H:%M')
  end

  def can_cancel
    object.can_cancel?
  end

  def cancellation_deadline
    object.cancellation_deadline.iso8601 if object.coach_schedule
  end

  def member
    if instance_options[:include_details]
      {
        id: object.member&.id,
        name: object.member&.name,
        phone: object.member&.phone,
        card_type: object.member&.card_type
      }
    end
  end

  def coach_schedule
    if instance_options[:include_details]
      {
        id: object.coach_schedule&.id,
        date: object.coach_schedule&.date,
        start_time: object.coach_schedule&.start_time&.strftime('%H:%M'),
        end_time: object.coach_schedule&.end_time&.strftime('%H:%M'),
        max_bookings: object.coach_schedule&.max_bookings,
        current_bookings_count: object.coach_schedule&.current_bookings_count
      }
    end
  end
end
