module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_token!
  end

  private

  def authenticate_token!
    token_string = extract_token_from_request
    raise UnauthorizedError unless token_string

    @current_token = Token.authenticate(token_string)
    raise UnauthorizedError unless @current_token
  end

  def extract_token_from_request
    auth_header = request.headers['Authorization']
    return nil unless auth_header

    if auth_header.start_with?('Bearer ')
      auth_header.split(' ').last
    else
      auth_header
    end
  end

  def current_token
    @current_token
  end
end
