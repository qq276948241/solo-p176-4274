class ApiError < StandardError
  attr_reader :status, :code, :details

  def initialize(message, status: 400, code: nil, details: nil)
    super(message)
    @status = status
    @code = code || default_code_for_status(status)
    @details = details
  end

  private

  def default_code_for_status(status)
    case status
    when 400 then 'bad_request'
    when 401 then 'unauthorized'
    when 403 then 'forbidden'
    when 404 then 'not_found'
    when 409 then 'conflict'
    when 422 then 'unprocessable_entity'
    when 500 then 'internal_server_error'
    else
      'error'
    end
  end
end
