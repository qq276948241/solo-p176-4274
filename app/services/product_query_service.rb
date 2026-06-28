class ProductQueryService
  attr_reader :scope, :params

  VALID_SORT_KEYS = %w[published_desc published_asc price_desc price_asc].freeze

  def initialize(scope = Product.all, params = {})
    @scope = scope
    @params = normalize_params(params)
  end

  def call
    apply_filters
    apply_sort
    @scope
  end

  private

  def apply_filters
    @scope = filter_by_keyword(@scope, extract_keyword)
    @scope = filter_by_category(@scope, extract_value(:category))
    @scope = filter_by_condition(@scope, extract_value(:condition))
    @scope = filter_by_status(@scope, extract_value(:status))
  end

  def filter_by_keyword(scope, keyword)
    return scope if keyword.nil?

    keyword = ensure_utf8(keyword)
    return scope if keyword.strip.empty?

    term = "%#{sanitize(keyword.strip)}%"
    scope.where('title LIKE :q OR description LIKE :q', q: term)
  end

  def filter_by_category(scope, category)
    return scope if category.nil?

    category = ensure_utf8(category)
    return scope if category.strip.empty?

    scope.by_category(category.strip)
  end

  def filter_by_condition(scope, condition)
    return scope if condition.nil?

    condition = ensure_utf8(condition)
    return scope if condition.strip.empty?

    scope.by_condition(condition.strip)
  end

  def filter_by_status(scope, status)
    return scope if status.nil?

    status = ensure_utf8(status)
    return scope if status.strip.empty?

    scope.where(status: status.strip)
  end

  def apply_sort
    sort_key = extract_sort_key
    @scope = resolve_sort(@scope, sort_key)
  end

  def resolve_sort(scope, sort_key)
    case sort_key
    when 'published_asc'  then scope.order(published_at: :asc)
    when 'price_desc'     then scope.order(price: :desc)
    when 'price_asc'      then scope.order(price: :asc)
    else                        scope.order(published_at: :desc)
    end
  end

  def extract_keyword
    @params[:q]
  end

  def extract_value(key)
    @params[key]
  end

  def extract_sort_key
    key = @params[:sort]
    VALID_SORT_KEYS.include?(key) ? key : 'published_desc'
  end

  def sanitize(value)
    value.to_s.gsub(/[%_\\]/) { |char| "\\#{char}" }
  end

  def normalize_params(params)
    if params.respond_to?(:to_unsafe_h)
      params.to_unsafe_h.with_indifferent_access
    else
      params.with_indifferent_access
    end
  end

  def ensure_utf8(value)
    return value if value.nil?

    str = value.to_s
    return str if str.encoding == Encoding::UTF_8 && str.valid_encoding?

    if str.encoding == Encoding::ASCII_8BIT
      forced = str.dup.force_encoding('UTF-8')
      return forced if forced.valid_encoding?
    end

    if str.valid_encoding?
      str.encode('UTF-8', invalid: :replace, undef: :replace)
    else
      str.dup.force_encoding('UTF-8')
    end
  end
end
