class Api::V1::MembersController < ApplicationController
  def index
    scope = Member.all
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(card_type: params[:card_type]) if params[:card_type].present?
    scope = scope.where('name LIKE ?', "%#{params[:keyword]}%") if params[:keyword].present?
    scope = scope.order(created_at: :desc)

    render_success(
      data: ActiveModelSerializers::SerializableResource.new(scope, each_serializer: MemberSerializer),
      status: 200
    )
  end

  def show
    member = Member.find(params[:id])
    render_success(
      data: MemberSerializer.new(member, include_bookings: true).serializable_hash,
      status: 200
    )
  end

  def create
    member = Member.new(member_params)

    if member.save
      render_success(
        data: MemberSerializer.new(member).serializable_hash,
        status: 201
      )
    else
      render_error(
        message: '会员创建失败',
        status: 422,
        code: 'validation_failed',
        details: member.errors.full_messages
      )
    end
  end

  def update
    member = Member.find(params[:id])

    if member.update(member_params)
      render_success(
        data: MemberSerializer.new(member).serializable_hash,
        status: 200
      )
    else
      render_error(
        message: '会员更新失败',
        status: 422,
        code: 'validation_failed',
        details: member.errors.full_messages
      )
    end
  end

  def destroy
    member = Member.find(params[:id])
    member.destroy

    render_success(
      data: { message: '会员已删除' },
      status: 200
    )
  end

  def eligibility
    member = Member.find(params[:id])
    render_success(
      data: member.booking_eligibility,
      status: 200
    )
  end

  def recharge
    member = Member.find(params[:id])
    amount = params[:sessions].to_i

    if member.prepaid?
      if amount > 0
        member.increment!(:remaining_sessions, amount)
        render_success(
          data: {
            message: "成功充值 #{amount} 次",
            remaining_sessions: member.remaining_sessions
          },
          status: 200
        )
      else
        render_error(
          message: '充值次数必须大于0',
          status: 422,
          code: 'invalid_amount'
        )
      end
    else
      render_error(
        message: '月卡会员不支持次数充值',
        status: 422,
        code: 'invalid_card_type'
      )
    end
  end

  def extend_membership
    member = Member.find(params[:id])

    if member.monthly?
      new_start_date = params[:start_date]&.to_date || Date.current
      months = params[:months].to_i

      if months > 0
        new_end_date = new_start_date + months.months - 1.day
        member.update!(
          monthly_start_date: new_start_date,
          monthly_end_date: new_end_date
        )
        render_success(
          data: {
            message: "成功续期 #{months} 个月",
            monthly_start_date: member.monthly_start_date,
            monthly_end_date: member.monthly_end_date
          },
          status: 200
        )
      else
        render_error(
          message: '续期月数必须大于0',
          status: 422,
          code: 'invalid_months'
        )
      end
    else
      render_error(
        message: '次卡会员不支持月卡续期',
        status: 422,
        code: 'invalid_card_type'
      )
    end
  end

  private

  def member_params
    params.require(:member).permit(
      :name,
      :phone,
      :card_type,
      :remaining_sessions,
      :monthly_start_date,
      :monthly_end_date,
      :status
    )
  end
end
