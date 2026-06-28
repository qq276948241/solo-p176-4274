class ProductSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :category, :condition,
             :price, :published_at, :status, :created_at, :updated_at
end
