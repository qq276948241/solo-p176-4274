class CoachInactiveError < ApiError
  def initialize(message = '教练状态异常')
    super(message, status: 422, code: 'coach_inactive')
  end
end
