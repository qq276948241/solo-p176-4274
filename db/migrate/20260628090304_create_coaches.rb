class CreateCoaches < ActiveRecord::Migration[8.1]
  def change
    create_table :coaches do |t|
      t.string :name, null: false
      t.string :phone, null: false
      t.string :specialty
      t.string :status, null: false, default: 'active'

      t.timestamps
    end
    add_index :coaches, :phone, unique: true
    add_index :coaches, :status
  end
end
