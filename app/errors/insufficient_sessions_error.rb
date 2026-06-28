class InsufficientSessionsError < ApiError
  def initialize(message = '次卡次数不足')
    super(message, status: 422, code: 'insufficient_sessions')
  end
end
