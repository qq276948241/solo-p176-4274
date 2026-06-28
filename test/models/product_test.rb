require "test_helper"

class ProductTest < ActiveSupport::TestCase
  def setup
    @valid_attrs = {
      title: '哑铃套装',
      description: '专业级可调节哑铃',
      category: '器材',
      condition: 'new',
      price: 299.00,
      status: 'active'
    }
  end

  test 'creates a valid product' do
    product = Product.new(@valid_attrs)
    assert product.valid?
  end

  test 'requires title' do
    product = Product.new(@valid_attrs.merge(title: nil))
    assert_not product.valid?
    assert_includes product.errors[:title], "can't be blank"
  end

  test 'requires category' do
    product = Product.new(@valid_attrs.merge(category: nil))
    assert_not product.valid?
    assert_includes product.errors[:category], "can't be blank"
  end

  test 'validates category inclusion' do
    product = Product.new(@valid_attrs.merge(category: 'invalid'))
    assert_not product.valid?
    assert_includes product.errors[:category], 'is not included in the list'
  end

  test 'validates condition inclusion' do
    product = Product.new(@valid_attrs.merge(condition: 'invalid'))
    assert_not product.valid?
    assert_includes product.errors[:condition], 'is not included in the list'
  end

  test 'validates status inclusion' do
    product = Product.new(@valid_attrs.merge(status: 'invalid'))
    assert_not product.valid?
    assert_includes product.errors[:status], 'is not included in the list'
  end

  test 'validates price is non-negative' do
    product = Product.new(@valid_attrs.merge(price: -1))
    assert_not product.valid?
    assert_includes product.errors[:price], 'must be greater than or equal to 0'
  end

  test 'allows nil price' do
    product = Product.new(@valid_attrs.merge(price: nil))
    assert product.valid?
  end

  test 'sets published_at on create when active' do
    product = Product.create!(@valid_attrs)
    assert_not_nil product.published_at
  end

  test 'does not set published_at when inactive' do
    product = Product.create!(@valid_attrs.merge(status: 'inactive'))
    assert_nil product.published_at
  end

  test 'active scope returns only active products' do
    Product.create!(@valid_attrs.merge(status: 'active'))
    Product.create!(@valid_attrs.merge(title: 'Inactive', status: 'inactive'))

    assert_equal 1, Product.active.count
  end

  test 'by_category scope filters correctly' do
    Product.create!(@valid_attrs.merge(category: '器材'))
    Product.create!(@valid_attrs.merge(title: 'Other', category: '补剂'))

    assert_equal 1, Product.by_category('器材').count
  end

  test 'by_condition scope filters correctly' do
    Product.create!(@valid_attrs.merge(condition: 'new'))
    Product.create!(@valid_attrs.merge(title: 'Used', condition: 'good'))

    assert_equal 1, Product.by_condition('new').count
  end

  test 'recent scope orders by published_at desc' do
    old = Product.create!(@valid_attrs.merge(title: 'Old', published_at: 2.days.ago))
    recent = Product.create!(@valid_attrs.merge(title: 'Recent', published_at: 1.hour.ago))

    results = Product.recent
    assert_equal recent.id, results.first.id
  end
end
