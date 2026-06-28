class ForceUtf8ParamsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    ensure_utf8_query_string(env)
    ensure_utf8_rack_input(env)

    @app.call(env)
  end

  private

  def ensure_utf8_query_string(env)
    qs = env['QUERY_STRING']
    return unless qs

    env['QUERY_STRING'] = qs.dup.force_encoding('UTF-8')
  rescue StandardError
    nil
  end

  def ensure_utf8_rack_input(env)
    input = env['rack.input']
    return unless input

    body = input.read
    body = body.dup.force_encoding('UTF-8') if body && !body.valid_encoding?
    env['rack.input'] = StringIO.new(body) if body
  rescue StandardError
    nil
  end
end
