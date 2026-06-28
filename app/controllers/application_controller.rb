class ApplicationController < ActionController::API
  include Authenticable
  include ErrorHandlable
end
