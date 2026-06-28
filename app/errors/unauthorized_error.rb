class UnauthorizedError < ApiError
  def initialize(message = '无效的认证令牌')
    super(message, status: 401, code: 'unauthorized')
  end
end
