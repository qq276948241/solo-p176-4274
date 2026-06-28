class TokenExpiredError < ApiError
  def initialize(message = '认证令牌已过期')
    super(message, status: 401, code: 'token_expired')
  end
end
