class InvalidTimeRangeError < ApiError
  def initialize(message = '结束时间必须晚于开始时间')
    super(message, status: 422, code: 'invalid_time_range')
  end
end
