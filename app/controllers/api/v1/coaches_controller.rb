class Api::V1::CoachesController < ApplicationController
  def index
    scope = Coach.all
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.by_specialty(params[:specialty]) if params[:specialty].present?
    scope = scope.where('name LIKE ?', "%#{params[:keyword]}%") if params[:keyword].present?
    scope = scope.order(created_at: :desc)

    render_success(
      data: ActiveModelSerializers::SerializableResource.new(scope, each_serializer: CoachSerializer),
      status: 200
    )
  end

  def show
    coach = Coach.find(params[:id])
    render_success(
      data: CoachSerializer.new(coach, include_schedules: true).serializable_hash,
      status: 200
    )
  end

  def create
    coach = Coach.new(coach_params)

    if coach.save
      render_success(
        data: CoachSerializer.new(coach).serializable_hash,
        status: 201
      )
    else
      render_error(
        message: '教练创建失败',
        status: 422,
        code: 'validation_failed',
        details: coach.errors.full_messages
      )
    end
  end

  def update
    coach = Coach.find(params[:id])

    if coach.update(coach_params)
      render_success(
        data: CoachSerializer.new(coach).serializable_hash,
        status: 200
      )
    else
      render_error(
        message: '教练更新失败',
        status: 422,
        code: 'validation_failed',
        details: coach.errors.full_messages
      )
    end
  end

  def destroy
    coach = Coach.find(params[:id])
    coach.destroy

    render_success(
      data: { message: '教练已删除' },
      status: 200
    )
  end

  def weekly_schedules
    coach = Coach.find(params[:id])
    date = params[:date]&.to_date || Date.current
    schedules = coach.schedules_for_week(date)

    render_success(
      data: ActiveModelSerializers::SerializableResource.new(schedules, each_serializer: CoachScheduleSerializer),
      status: 200
    )
  end

  def available_slots
    coach = Coach.find(params[:id])
    date = params[:date]&.to_date || Date.current

    if date < Date.current
      render_error(
        message: '不能查询过去日期的可用时段',
        status: 422,
        code: 'past_date'
      )
      return
    end

    slots = coach.available_slots_for_date(date)

    render_success(
      data: ActiveModelSerializers::SerializableResource.new(slots, each_serializer: CoachScheduleSerializer),
      status: 200
    )
  end

  private

  def coach_params
    params.require(:coach).permit(
      :name,
      :phone,
      :specialty,
      :status
    )
  end
end
