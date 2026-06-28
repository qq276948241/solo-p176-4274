class ProductSearchService
  attr_reader :scope

  def initialize(scope = Product.all)
    @scope = scope
  end

  def search(params)
    apply_keyword(params[:q])
    apply_category(params[:category])
    apply_condition(params[:condition])
    apply_status(params[:status])
    apply_sort

    @scope
  end

  private

  def apply_keyword(keyword)
    return if keyword.blank?

    term = "%#{sanitize(keyword)}%"
    @scope = @scope.where(
      'title LIKE :q OR description LIKE :q',
      q: term
    )
  end

  def apply_category(category)
    return if category.blank?

    @scope = @scope.by_category(category)
  end

  def apply_condition(condition)
    return if condition.blank?

    @scope = @scope.by_condition(condition)
  end

  def apply_status(status)
    return if status.blank?

    @scope = @scope.where(status: status)
  end

  def apply_sort
    @scope = @scope.recent
  end

  def sanitize(value)
    value.to_s.gsub(/[%_\\]/) { |char| "\\#{char}" }
  end
end
