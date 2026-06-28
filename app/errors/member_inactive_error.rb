class MemberInactiveError < ApiError
  def initialize(message = '会员状态异常')
    super(message, status: 422, code: 'member_inactive')
  end
end
