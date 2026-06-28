class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_token!, only: [:login]

  def login
    if valid_credentials?
      token = Token.generate('API Access Token')
      render_success(
        data: {
          token: token.token,
          expires_at: token.expires_at.iso8601,
          description: token.description
        },
        status: 200
      )
    else
      render_error(
        message: '用户名或密码错误',
        status: 401,
        code: 'invalid_credentials'
      )
    end
  end

  def logout
    current_token.revoke!
    render_success(
      data: { message: '已成功退出登录' },
      status: 200
    )
  end

  def refresh
    new_token = current_token.refresh!
    render_success(
      data: {
        token: new_token.token,
        expires_at: new_token.expires_at.iso8601
      },
      status: 200
    )
  end

  def verify
    render_success(
      data: {
        valid: current_token.alive?,
        expires_at: current_token.expires_at.iso8601,
        description: current_token.description
      },
      status: 200
    )
  end

  private

  def valid_credentials?
    username = params[:username]
    password = params[:password]

    default_username = ENV['API_USERNAME'] || 'admin'
    default_password = ENV['API_PASSWORD'] || 'admin123'

    username == default_username && password == default_password
  end
end
