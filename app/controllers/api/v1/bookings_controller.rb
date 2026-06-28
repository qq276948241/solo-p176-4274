class Api::V1::BookingsController < ApplicationController
  def index
    scope = Booking.all
    scope = scope.by_member(params[:member_id]) if params[:member_id].present?
    scope = scope.by_coach(params[:coach_id]) if params[:coach_id].present?
    scope = scope.by_date(params[:date].to_date) if params[:date].present?
    scope = scope.where(status: params[:status]) if params[:status].present?

    if params[:upcoming].present? && params[:upcoming] == 'true'
      scope = scope.upcoming
    elsif params[:past].present? && params[:past] == 'true'
      scope = scope.past
    end

    scope = scope.order_by_time

    render_success(
      data: ActiveModelSerializers::SerializableResource.new(scope, each_serializer: BookingSerializer),
      status: 200
    )
  end

  def show
    booking = Booking.find(params[:id])
    render_success(
      data: BookingSerializer.new(booking, include_details: true).serializable_hash,
      status: 200
    )
  end

  def create
    booking_params = params.require(:booking).permit(:member_id, :coach_schedule_id)

    member = Member.find(booking_params[:member_id])
    coach_schedule = CoachSchedule.find(booking_params[:coach_schedule_id])

    booking = nil

    ActiveRecord::Base.transaction do
      booking = Booking.new(
        member: member,
        coach_schedule: coach_schedule,
        status: 'booked',
        consumed: false
      )

      if booking.save
        booking.mark_as_consumed!
      else
        raise ActiveRecord::Rollback
      end
    end

    if booking&.persisted?
      render_success(
        data: BookingSerializer.new(booking).serializable_hash,
        status: 201
      )
    else
      render_error(
        message: '预约创建失败',
        status: 422,
        code: 'validation_failed',
        details: booking&.errors&.full_messages || []
      )
    end
  end

  def cancel
    booking = Booking.find(params[:id])

    if booking.cancel!
      render_success(
        data: {
          message: '预约已取消',
          booking: BookingSerializer.new(booking).serializable_hash
        },
        status: 200
      )
    else
      render_error(
        message: '取消失败',
        status: 422,
        code: 'cancellation_failed'
      )
    end
  end

  def force_cancel
    booking = Booking.find(params[:id])

    if booking.force_cancel!
      render_success(
        data: {
          message: '预约已强制取消',
          booking: BookingSerializer.new(booking).serializable_hash
        },
        status: 200
      )
    else
      render_error(
        message: '取消失败',
        status: 422,
        code: 'cancellation_failed'
      )
    end
  end

  def complete
    booking = Booking.find(params[:id])

    if booking.complete!
      render_success(
        data: {
          message: '预约已完成',
          booking: BookingSerializer.new(booking).serializable_hash
        },
        status: 200
      )
    else
      render_error(
        message: '操作失败',
        status: 422,
        code: 'operation_failed'
      )
    end
  end

  def mark_no_show
    booking = Booking.find(params[:id])

    if booking.mark_as_no_show!
      render_success(
        data: {
          message: '已标记为未到',
          booking: BookingSerializer.new(booking).serializable_hash
        },
        status: 200
      )
    else
      render_error(
        message: '操作失败',
        status: 422,
        code: 'operation_failed'
      )
    end
  end

  def my_bookings
    member_id = params[:member_id]
    unless member_id.present?
      render_error(
        message: '请指定会员ID',
        status: 400,
        code: 'missing_member_id'
      )
      return
    end

    scope = Booking.by_member(member_id)

    if params[:status].present?
      scope = scope.where(status: params[:status])
    elsif params[:upcoming].present? && params[:upcoming] == 'true'
      scope = scope.upcoming
    elsif params[:past].present? && params[:past] == 'true'
      scope = scope.past
    end

    scope = scope.order_by_time

    render_success(
      data: ActiveModelSerializers::SerializableResource.new(scope, each_serializer: BookingSerializer),
      status: 200
    )
  end
end
