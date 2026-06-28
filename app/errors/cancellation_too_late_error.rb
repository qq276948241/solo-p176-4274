class CancellationTooLateError < ApiError
  def initialize(message = '距离开始时间不足2小时，无法取消')
    super(message, status: 422, code: 'cancellation_too_late')
  end
end
