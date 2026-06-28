class MemberSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone, :card_type, :remaining_sessions,
             :monthly_start_date, :monthly_end_date, :status,
             :created_at, :updated_at, :eligibility, :bookings

  def eligibility
    object.booking_eligibility
  end

  def bookings
    if instance_options[:include_bookings]
      object.bookings.order(created_at: :desc).limit(10).map do |booking|
        BookingSerializer.new(booking).serializable_hash[:data][:attributes]
      end
    end
  end
end
