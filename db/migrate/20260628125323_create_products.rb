class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :title, null: false
      t.text :description
      t.string :category, null: false
      t.string :condition, null: false, default: 'new'
      t.decimal :price, precision: 10, scale: 2, default: 0
      t.datetime :published_at
      t.string :status, null: false, default: 'active'

      t.timestamps
    end
    add_index :products, :category
    add_index :products, :condition
    add_index :products, :status
    add_index :products, :published_at
  end
end
