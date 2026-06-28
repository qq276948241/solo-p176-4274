class CardExpiredError < ApiError
  def initialize(message = '月卡已过期')
    super(message, status: 422, code: 'card_expired')
  end
end
