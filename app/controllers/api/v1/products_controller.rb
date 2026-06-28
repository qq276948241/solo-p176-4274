class Api::V1::ProductsController < ApplicationController
  def index
    scope = ProductSearchService.new.search(params)

    render_success(
      data: ActiveModelSerializers::SerializableResource.new(scope, each_serializer: ProductSerializer),
      status: 200
    )
  end

  def show
    product = Product.find(params[:id])
    render_success(
      data: ProductSerializer.new(product).serializable_hash,
      status: 200
    )
  end

  def create
    product = Product.new(product_params)

    if product.save
      render_success(
        data: ProductSerializer.new(product).serializable_hash,
        status: 201
      )
    else
      render_error(
        message: '商品创建失败',
        status: 422,
        code: 'validation_failed',
        details: product.errors.full_messages
      )
    end
  end

  def update
    product = Product.find(params[:id])

    if product.update(product_params)
      render_success(
        data: ProductSerializer.new(product).serializable_hash,
        status: 200
      )
    else
      render_error(
        message: '商品更新失败',
        status: 422,
        code: 'validation_failed',
        details: product.errors.full_messages
      )
    end
  end

  def destroy
    product = Product.find(params[:id])
    product.destroy

    render_success(
      data: { message: '商品已删除' },
      status: 200
    )
  end

  private

  def product_params
    params.require(:product).permit(
      :title,
      :description,
      :category,
      :condition,
      :price,
      :published_at,
      :status
    )
  end
end
