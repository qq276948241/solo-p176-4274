require "test_helper"

class ProductQueryServiceTest < ActiveSupport::TestCase
  def setup
    @dumbbell = Product.create!(
      title: '哑铃套装',
      description: '专业级可调节哑铃，适合家庭健身',
      category: '器材',
      condition: 'new',
      price: 299.00,
      status: 'active',
      published_at: 1.day.ago
    )

    @protein = Product.create!(
      title: '乳清蛋白粉',
      description: '高效增肌补剂，巧克力口味',
      category: '补剂',
      condition: 'new',
      price: 199.00,
      status: 'active',
      published_at: 2.hours.ago
    )

    @yoga_mat = Product.create!(
      title: '瑜伽垫',
      description: '加厚防滑瑜伽垫，适合瑜伽和拉伸',
      category: '配件',
      condition: 'like_new',
      price: 89.00,
      status: 'active',
      published_at: 3.days.ago
    )

    @gloves = Product.create!(
      title: '健身手套',
      description: '防滑透气健身手套，保护手掌',
      category: '服饰',
      condition: 'good',
      price: 49.00,
      status: 'inactive',
      published_at: 1.week.ago
    )
  end

  test 'returns all products with no params' do
    results = ProductQueryService.new.call
    assert_equal 4, results.count
  end

  test 'searches by keyword in title' do
    results = ProductQueryService.new(Product.all, q: '哑铃').call
    assert_includes results.map(&:id), @dumbbell.id
    assert_not_includes results.map(&:id), @protein.id
  end

  test 'searches by keyword in description' do
    results = ProductQueryService.new(Product.all, q: '增肌').call
    assert_includes results.map(&:id), @protein.id
    assert_not_includes results.map(&:id), @dumbbell.id
  end

  test 'searches by keyword matching both title and description' do
    results = ProductQueryService.new(Product.all, q: '健身').call
    assert_includes results.map(&:id), @gloves.id
    assert_includes results.map(&:id), @dumbbell.id
  end

  test 'returns empty for non-matching keyword' do
    results = ProductQueryService.new(Product.all, q: '不存在的商品').call
    assert_empty results
  end

  test 'filters by category' do
    results = ProductQueryService.new(Product.all, category: '器材').call
    assert_includes results.map(&:id), @dumbbell.id
    assert_not_includes results.map(&:id), @protein.id
  end

  test 'filters by condition' do
    results = ProductQueryService.new(Product.all, condition: 'new').call
    assert_includes results.map(&:id), @dumbbell.id
    assert_includes results.map(&:id), @protein.id
    assert_not_includes results.map(&:id), @yoga_mat.id
  end

  test 'combines keyword and category filter' do
    results = ProductQueryService.new(Product.all, q: '垫', category: '配件').call
    assert_includes results.map(&:id), @yoga_mat.id
    assert_not_includes results.map(&:id), @dumbbell.id
  end

  test 'combines keyword and condition filter' do
    results = ProductQueryService.new(Product.all, q: '蛋白', condition: 'new').call
    assert_includes results.map(&:id), @protein.id
    assert_not_includes results.map(&:id), @yoga_mat.id
  end

  test 'combines category and condition filter' do
    results = ProductQueryService.new(Product.all, category: '器材', condition: 'new').call
    assert_includes results.map(&:id), @dumbbell.id
    assert_not_includes results.map(&:id), @yoga_mat.id
  end

  test 'combines keyword, category and condition' do
    results = ProductQueryService.new(Product.all, q: '哑铃', category: '器材', condition: 'new').call
    assert_includes results.map(&:id), @dumbbell.id
    assert_equal 1, results.count
  end

  test 'filters by status' do
    results = ProductQueryService.new(Product.all, status: 'inactive').call
    assert_includes results.map(&:id), @gloves.id
    assert_equal 1, results.count
  end

  test 'default orders by published_at descending' do
    results = ProductQueryService.new.call
    ids = results.map(&:id)
    assert_equal [@protein.id, @dumbbell.id, @yoga_mat.id, @gloves.id], ids
  end

  test 'treats nil params as no-op (does not filter)' do
    results = ProductQueryService.new(Product.all, q: nil, category: nil, condition: nil, status: nil).call
    assert_equal 4, results.count
  end

  test 'treats empty string params as no-op (does not filter)' do
    results = ProductQueryService.new(Product.all, q: '', category: '', condition: '', status: '').call
    assert_equal 4, results.count
  end

  test 'treats whitespace-only params as no-op' do
    results = ProductQueryService.new(Product.all, q: '   ', category: '  ', condition: "\t").call
    assert_equal 4, results.count
  end

  test 'distinguishes nil and empty string equally as no filter' do
    nil_result = ProductQueryService.new(Product.all, category: nil).call.count
    empty_result = ProductQueryService.new(Product.all, category: '').call.count
    assert_equal nil_result, empty_result
    assert_equal 4, nil_result
  end

  test 'resolve_sort with published_asc' do
    results = ProductQueryService.new(Product.all, sort: 'published_asc').call
    ids = results.map(&:id)
    assert_equal [@gloves.id, @yoga_mat.id, @dumbbell.id, @protein.id], ids
  end

  test 'resolve_sort with price_desc' do
    results = ProductQueryService.new(Product.all, sort: 'price_desc').call
    ids = results.map(&:id)
    assert_equal [@dumbbell.id, @protein.id, @yoga_mat.id, @gloves.id], ids
  end

  test 'resolve_sort with price_asc' do
    results = ProductQueryService.new(Product.all, sort: 'price_asc').call
    ids = results.map(&:id)
    assert_equal [@gloves.id, @yoga_mat.id, @protein.id, @dumbbell.id], ids
  end

  test 'resolve_sort with invalid key falls back to published_desc' do
    results = ProductQueryService.new(Product.all, sort: 'invalid_key').call
    ids = results.map(&:id)
    assert_equal [@protein.id, @dumbbell.id, @yoga_mat.id, @gloves.id], ids
  end

  test 'resolve_sort with nil falls back to published_desc' do
    results = ProductQueryService.new(Product.all, sort: nil).call
    ids = results.map(&:id)
    assert_equal [@protein.id, @dumbbell.id, @yoga_mat.id, @gloves.id], ids
  end

  test 'sanitizes LIKE wildcards in keyword' do
    Product.create!(
      title: '100%纯乳清',
      description: '高纯度蛋白',
      category: '补剂',
      condition: 'new',
      price: 299.00,
      status: 'active',
      published_at: Time.current
    )

    results = ProductQueryService.new(Product.all, q: '100%纯').call
    assert results.count <= 1
  end

  test 'keyword strips surrounding whitespace before matching' do
    results = ProductQueryService.new(Product.all, q: '  哑铃  ').call
    assert_includes results.map(&:id), @dumbbell.id
  end

  test 'category strips surrounding whitespace before matching' do
    results = ProductQueryService.new(Product.all, category: '  器材  ').call
    assert_includes results.map(&:id), @dumbbell.id
  end

  test 'accepts params as symbol keys' do
    results = ProductQueryService.new(Product.all, { q: '哑铃', category: '器材' }).call
    assert_includes results.map(&:id), @dumbbell.id
    assert_equal 1, results.count
  end

  test 'accepts params as string keys' do
    results = ProductQueryService.new(Product.all, { 'q' => '哑铃', 'category' => '器材' }).call
    assert_includes results.map(&:id), @dumbbell.id
    assert_equal 1, results.count
  end

  test 'Chinese keyword with GBK-encoded bytes is forced to UTF-8 and matches' do
    gbk_keyword = '哑铃'.encode('GBK')
    results = ProductQueryService.new(Product.all, q: gbk_keyword).call
    assert_includes results.map(&:id), @dumbbell.id,
      "GBK-encoded Chinese keyword should be converted to UTF-8 and match"
  end

  test 'Chinese keyword with ASCII-8BIT encoding is forced to UTF-8 and matches' do
    binary_keyword = '哑铃'.b
    results = ProductQueryService.new(Product.all, q: binary_keyword).call
    assert_includes results.map(&:id), @dumbbell.id,
      "ASCII-8BIT encoded Chinese keyword should be forced to UTF-8 and match"
  end

  test 'English keyword still works after encoding fix' do
    results = ProductQueryService.new(Product.all, q: 'Whey').call
    assert_empty results
  end

  test 'Chinese and English keywords do not interfere with each other' do
    cn_results = ProductQueryService.new(Product.all, q: '哑铃').call
    en_results = ProductQueryService.new(Product.all, q: '手套').call

    assert_includes cn_results.map(&:id), @dumbbell.id
    assert_not_includes cn_results.map(&:id), @gloves.id
    assert_includes en_results.map(&:id), @gloves.id
    assert_not_includes en_results.map(&:id), @dumbbell.id
  end

  test 'Chinese partial character match works' do
    results = ProductQueryService.new(Product.all, q: '铃').call
    assert_includes results.map(&:id), @dumbbell.id
  end

  test 'Chinese keyword matches description' do
    results = ProductQueryService.new(Product.all, q: '家庭健身').call
    assert_includes results.map(&:id), @dumbbell.id
  end

  test 'Chinese category filter works after encoding fix' do
    gbk_category = '器材'.encode('GBK')
    results = ProductQueryService.new(Product.all, category: gbk_category).call
    assert_includes results.map(&:id), @dumbbell.id
  end

  test 'ensure_utf8 returns nil for nil input' do
    svc = ProductQueryService.new
    assert_nil svc.send(:ensure_utf8, nil)
  end

  test 'ensure_utf8 preserves valid UTF-8 strings' do
    svc = ProductQueryService.new
    result = svc.send(:ensure_utf8, '哑铃')
    assert_equal Encoding::UTF_8, result.encoding
    assert_equal '哑铃', result
  end

  test 'ensure_utf8 converts GBK to UTF-8' do
    svc = ProductQueryService.new
    gbk_str = '哑铃'.encode('GBK')
    result = svc.send(:ensure_utf8, gbk_str)
    assert_equal Encoding::UTF_8, result.encoding
    assert_equal '哑铃', result
  end

  test 'ensure_utf8 handles ASCII-8BIT binary with Chinese content' do
    svc = ProductQueryService.new
    binary_str = '哑铃'.b
    result = svc.send(:ensure_utf8, binary_str)
    assert_equal Encoding::UTF_8, result.encoding
    assert_equal '哑铃', result
  end
end
