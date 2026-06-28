require "test_helper"

class ProductSearchServiceTest < ActiveSupport::TestCase
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
    results = ProductSearchService.new.search({})
    assert_equal 4, results.count
  end

  test 'searches by keyword in title' do
    results = ProductSearchService.new.search(q: '哑铃')
    assert_includes results.map(&:id), @dumbbell.id
    assert_not_includes results.map(&:id), @protein.id
  end

  test 'searches by keyword in description' do
    results = ProductSearchService.new.search(q: '增肌')
    assert_includes results.map(&:id), @protein.id
    assert_not_includes results.map(&:id), @dumbbell.id
  end

  test 'searches by keyword matching both title and description' do
    results = ProductSearchService.new.search(q: '健身')
    assert_includes results.map(&:id), @gloves.id
    assert_includes results.map(&:id), @dumbbell.id
  end

  test 'returns empty for non-matching keyword' do
    results = ProductSearchService.new.search(q: '不存在的商品')
    assert_empty results
  end

  test 'filters by category' do
    results = ProductSearchService.new.search(category: '器材')
    assert_includes results.map(&:id), @dumbbell.id
    assert_not_includes results.map(&:id), @protein.id
  end

  test 'filters by condition' do
    results = ProductSearchService.new.search(condition: 'new')
    assert_includes results.map(&:id), @dumbbell.id
    assert_includes results.map(&:id), @protein.id
    assert_not_includes results.map(&:id), @yoga_mat.id
  end

  test 'combines keyword and category filter' do
    results = ProductSearchService.new.search(q: '垫', category: '配件')
    assert_includes results.map(&:id), @yoga_mat.id
    assert_not_includes results.map(&:id), @dumbbell.id
  end

  test 'combines keyword and condition filter' do
    results = ProductSearchService.new.search(q: '蛋白', condition: 'new')
    assert_includes results.map(&:id), @protein.id
    assert_not_includes results.map(&:id), @yoga_mat.id
  end

  test 'combines category and condition filter' do
    results = ProductSearchService.new.search(category: '器材', condition: 'new')
    assert_includes results.map(&:id), @dumbbell.id
    assert_not_includes results.map(&:id), @yoga_mat.id
  end

  test 'combines keyword, category and condition' do
    results = ProductSearchService.new.search(q: '哑铃', category: '器材', condition: 'new')
    assert_includes results.map(&:id), @dumbbell.id
    assert_equal 1, results.count
  end

  test 'filters by status' do
    results = ProductSearchService.new.search(status: 'inactive')
    assert_includes results.map(&:id), @gloves.id
    assert_equal 1, results.count
  end

  test 'orders by published_at descending' do
    results = ProductSearchService.new.search({})
    ids = results.map(&:id)
    assert_equal [@protein.id, @dumbbell.id, @yoga_mat.id, @gloves.id], ids
  end

  test 'ignores blank params' do
    results = ProductSearchService.new.search(q: '', category: nil, condition: '')
    assert_equal 4, results.count
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

    results = ProductSearchService.new.search(q: '100%纯')
    assert results.count <= 1
  end
end
