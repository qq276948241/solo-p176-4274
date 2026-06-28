class Api::V1::CoachSchedulesController < ApplicationController
  def index
    scope = CoachSchedule.all
    scope = scope.by_coach(params[:coach_id]) if params[:coach_id].present?

    if params[:date].present?
      scope = scope.for_date(params[:date].to_date)
    elsif params[:week_date].present?
      scope = scope.for_week(params[:week_date].to_date)
    end

    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.order_by_time

    render_success(
      data: ActiveModelSerializers::SerializableResource.new(scope, each_serializer: CoachScheduleSerializer),
      status: 200
    )
  end

  def show
    schedule = CoachSchedule.find(params[:id])
    render_success(
      data: CoachScheduleSerializer.new(schedule, include_bookings: true).serializable_hash,
      status: 200
    )
  end

  def create
    schedule = CoachSchedule.new(schedule_params)

    if schedule.save
      render_success(
        data: CoachScheduleSerializer.new(schedule).serializable_hash,
        status: 201
      )
    else
      render_error(
        message: '排班创建失败',
        status: 422,
        code: 'validation_failed',
        details: schedule.errors.full_messages
      )
    end
  end

  def update
    schedule = CoachSchedule.find(params[:id])

    if schedule.update(schedule_params)
      render_success(
        data: CoachScheduleSerializer.new(schedule).serializable_hash,
        status: 200
      )
    else
      render_error(
        message: '排班更新失败',
        status: 422,
        code: 'validation_failed',
        details: schedule.errors.full_messages
      )
    end
  end

  def destroy
    schedule = CoachSchedule.find(params[:id])

    if schedule.bookings.booked.exists?
      render_error(
        message: '该排班已有预约，无法删除',
        status: 409,
        code: 'has_bookings'
      )
      return
    end

    schedule.destroy
    render_success(
      data: { message: '排班已删除' },
      status: 200
    )
  end

  def batch_create_weekly
    coach_id = params[:coach_id]
    week_date = params[:week_date]&.to_date || Date.current
    time_slots = params[:time_slots] || []

    unless coach_id.present?
      render_error(
        message: '请指定教练ID',
        status: 400,
        code: 'missing_coach_id'
      )
      return
    end

    if time_slots.empty?
      render_error(
        message: '请提供时段列表',
        status: 400,
        code: 'missing_time_slots'
      )
      return
    end

    result = CoachSchedule.batch_create_weekly_schedule(coach_id, week_date, time_slots)

    if result[:errors].empty?
      render_success(
        data: {
          message: "成功创建 #{result[:created].count} 个排班",
          schedules: ActiveModelSerializers::SerializableResource.new(result[:created], each_serializer: CoachScheduleSerializer)
        },
        status: 201
      )
    else
      render_error(
        message: '部分排班创建失败',
        status: 422,
        code: 'partial_failure',
        details: {
          created_count: result[:created].count,
          errors: result[:errors]
        }
      )
    end
  end

  def available
    scope = CoachSchedule.available.order_by_time
    scope = scope.by_coach(params[:coach_id]) if params[:coach_id].present?

    if params[:date].present?
      scope = scope.for_date(params[:date].to_date)
    elsif params[:week_date].present?
      scope = scope.for_week(params[:week_date].to_date)
    end

    scope = scope.select do |s|
      !s.full? && !s.past?
    end

    render_success(
      data: ActiveModelSerializers::SerializableResource.new(scope, each_serializer: CoachScheduleSerializer),
      status: 200
    )
  end

  private

  def schedule_params
    params.require(:coach_schedule).permit(
      :coach_id,
      :date,
      :start_time,
      :end_time,
      :status,
      :max_bookings
    )
  end
end
