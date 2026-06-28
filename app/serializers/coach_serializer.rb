class CoachSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone, :specialty, :status,
             :created_at, :updated_at, :schedules

  def schedules
    if instance_options[:include_schedules]
      object.schedules_for_week(Date.current).map do |schedule|
        CoachScheduleSerializer.new(schedule).serializable_hash[:data][:attributes]
      end
    end
  end
end
