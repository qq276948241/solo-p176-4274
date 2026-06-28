require "test_helper"

class Api::V1::ProductsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @token = Token.generate('test', 1.day)

    @product = Product.create!(
      title: '哑铃套装',
      description: '专业级可调节哑铃',
      category: '器材',
      condition: 'new',
      price: 299.00,
      status: 'active',
      published_at: 1.day.ago
    )

    Product.create!(
      title: '乳清蛋白粉',
      description: '高效增肌补剂',
      category: '补剂',
      condition: 'new',
      price: 199.00,
      status: 'active',
      published_at: 2.hours.ago
    )
  end

  test 'GET index returns products list' do
    get api_v1_products_path, headers: auth_headers
    assert_response :success
  end

  test 'GET index with q param filters by keyword' do
    get api_v1_products_path, params: { q: '哑铃' }, headers: auth_headers
    assert_response :success
  end

  test 'GET index with category param filters by category' do
    get api_v1_products_path, params: { category: '器材' }, headers: auth_headers
    assert_response :success
  end

  test 'GET index with condition param filters by condition' do
    get api_v1_products_path, params: { condition: 'new' }, headers: auth_headers
    assert_response :success
  end

  test 'GET index with combined params' do
    get api_v1_products_path, params: { q: '哑铃', category: '器材', condition: 'new' }, headers: auth_headers
    assert_response :success
  end

  test 'GET show returns a product' do
    get api_v1_product_path(@product), headers: auth_headers
    assert_response :success
  end

  test 'POST create creates a product' do
    assert_difference 'Product.count', 1 do
      post api_v1_products_path, params: {
        product: {
          title: '新商品',
          category: '服饰',
          condition: 'new',
          price: 99.00
        }
      }, headers: auth_headers
    end
    assert_response :created
  end

  test 'PUT update updates a product' do
    put api_v1_product_path(@product), params: {
      product: { title: '更新后哑铃' }
    }, headers: auth_headers
    assert_response :success
    @product.reload
    assert_equal '更新后哑铃', @product.title
  end

  test 'DELETE destroy removes a product' do
    assert_difference 'Product.count', -1 do
      delete api_v1_product_path(@product), headers: auth_headers
    end
    assert_response :success
  end

  test 'requires authentication' do
    get api_v1_products_path
    assert_response :unauthorized
  end

  private

  def auth_headers
    { 'Authorization' => "Bearer #{@token.token}" }
  end
end
