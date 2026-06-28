class PastDateError < ApiError
  def initialize(message = '不能预约过去的日期')
    super(message, status: 422, code: 'past_date')
  end
end
