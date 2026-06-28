class InvalidCardTypeError < ApiError
  def initialize(message = '无效的卡类型')
    super(message, status: 422, code: 'invalid_card_type')
  end
end
