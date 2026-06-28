require "test_helper"

class ChineseSearchEdgeCasesTest < ActionDispatch::IntegrationTest
  def setup
    @token = Token.generate('test', 1.day)

    @cn_product = Product.create!(
      title: '哑铃套装',
      description: '专业级可调节哑铃，适合家庭健身',
      category: '器材',
      condition: 'new',
      price: 299.00,
      status: 'active',
      published_at: 1.day.ago
    )

    @en_product = Product.create!(
      title: 'Whey Protein',
      description: 'High quality protein for muscle building',
      category: '补剂',
      condition: 'new',
      price: 199.00,
      status: 'active',
      published_at: 2.hours.ago
    )
  end

  def auth_headers
    { 'Authorization' => "Bearer #{@token.token}" }
  end

  test "service level: Chinese keyword directly" do
    results = ProductQueryService.new(Product.all, q: '哑铃').call
    assert_includes results.map(&:id), @cn_product.id
    assert_equal 1, results.count
  end

  test "service level: English keyword directly" do
    results = ProductQueryService.new(Product.all, q: 'Whey').call
    assert_includes results.map(&:id), @en_product.id
  end

  test "HTTP level: Chinese keyword via params hash" do
    get api_v1_products_path, params: { q: '哑铃' }, headers: auth_headers
    assert_response :success
    body = JSON.parse(response.body)
    ids = body['data'].map { |p| p['id'] || p.dig('attributes', 'id') }
    assert_includes ids, @cn_product.id,
      "Chinese keyword via params should match. Got: #{ids.inspect}"
  end

  test "HTTP level: English keyword via params hash" do
    get api_v1_products_path, params: { q: 'Whey' }, headers: auth_headers
    assert_response :success
    body = JSON.parse(response.body)
    ids = body['data'].map { |p| p['id'] || p.dig('attributes', 'id') }
    assert_includes ids, @en_product.id
  end

  test "HTTP level: Chinese keyword in URL query string directly" do
    get "/api/v1/products?q=#{ERB::Util.url_encode('哑铃')}", headers: auth_headers
    assert_response :success
    body = JSON.parse(response.body)
    ids = body['data'].map { |p| p['id'] || p.dig('attributes', 'id') }
    assert_includes ids, @cn_product.id,
      "URL-encoded Chinese should match. Got: #{ids.inspect}"
  end

  test "HTTP level: percent-encoded Chinese in query string" do
    get "/api/v1/products?q=#{ERB::Util.url_encode('哑铃')}", headers: auth_headers
    assert_response :success
    body = JSON.parse(response.body)
    ids = body['data'].map { |p| p['id'] || p.dig('attributes', 'id') }
    assert_includes ids, @cn_product.id,
      "Percent-encoded Chinese in URL should match. Got: #{ids.inspect}"
  end

  test "Chinese keyword matches description" do
    results = ProductQueryService.new(Product.all, q: '家庭健身').call
    assert_includes results.map(&:id), @cn_product.id
  end

  test "Partial Chinese character matches" do
    results = ProductQueryService.new(Product.all, q: '铃').call
    assert_includes results.map(&:id), @cn_product.id
  end

  test "Chinese + category filter combined" do
    results = ProductQueryService.new(Product.all, q: '哑铃', category: '器材').call
    assert_includes results.map(&:id), @cn_product.id
    assert_equal 1, results.count
  end

  test "Non-existent Chinese keyword returns empty" do
    results = ProductQueryService.new(Product.all, q: '不存在的关键词').call
    assert_empty results
  end

  test "Chinese and English searches do not interfere with each other" do
    cn_results = ProductQueryService.new(Product.all, q: '哑铃').call
    en_results = ProductQueryService.new(Product.all, q: 'Whey').call

    assert_includes cn_results.map(&:id), @cn_product.id
    assert_not_includes cn_results.map(&:id), @en_product.id
    assert_includes en_results.map(&:id), @en_product.id
    assert_not_includes en_results.map(&:id), @cn_product.id
  end
end
