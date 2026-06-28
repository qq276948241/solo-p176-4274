module ErrorHandlable
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_standard_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
    rescue_from ActiveRecord::RecordNotUnique, with: :handle_record_not_unique
    rescue_from ApiError, with: :handle_api_error
  end

  private

  def handle_api_error(error)
    render_error(
      message: error.message,
      status: error.status,
      code: error.code,
      details: error.details
    )
  end

  def handle_record_not_found(error)
    resource_name = error.model&.underscore&.humanize || '资源'
    render_error(
      message: "#{resource_name}不存在",
      status: 404,
      code: 'not_found'
    )
  end

  def handle_record_invalid(error)
    render_error(
      message: '数据验证失败',
      status: 422,
      code: 'validation_failed',
      details: error.record.errors.full_messages
    )
  end

  def handle_record_not_unique(error)
    render_error(
      message: '数据已存在',
      status: 409,
      code: 'record_not_unique'
    )
  end

  def handle_standard_error(error)
    Rails.logger.error "Unhandled error: #{error.class.name} - #{error.message}"
    Rails.logger.error error.backtrace&.first(10)&.join("\n")

    if Rails.env.development? || Rails.env.test?
      render_error(
        message: error.message,
        status: 500,
        code: 'internal_server_error',
        details: {
          error_class: error.class.name,
          backtrace: error.backtrace&.first(10)
        }
      )
    else
      render_error(
        message: '服务器内部错误',
        status: 500,
        code: 'internal_server_error'
      )
    end
  end

  def render_error(message:, status:, code:, details: nil)
    response = {
      error: {
        message: message,
        code: code,
        status: status
      }
    }
    response[:error][:details] = details if details

    render json: response, status: status
  end

  def render_success(data:, status: 200, meta: nil)
    response = { data: data }
    response[:meta] = meta if meta
    render json: response, status: status
  end

  def render_paginated(relation, serializer, options: {})
    page = params[:page].to_i
    per_page = params[:per_page].to_i
    page = 1 if page <= 0
    per_page = 20 if per_page <= 0 || per_page > 100

    total_count = relation.count
    total_pages = (total_count.to_f / per_page).ceil
    paginated = relation.offset((page - 1) * per_page).limit(per_page)

    render_success(
      data: serializer.new(paginated, options).serializable_hash[:data],
      meta: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    )
  end
end
