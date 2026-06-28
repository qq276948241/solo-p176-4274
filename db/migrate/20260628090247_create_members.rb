class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.string :name, null: false
      t.string :phone, null: false
      t.string :card_type, null: false, default: 'prepaid'
      t.integer :remaining_sessions, default: 0
      t.date :monthly_start_date
      t.date :monthly_end_date
      t.string :status, null: false, default: 'active'

      t.timestamps
    end
    add_index :members, :phone, unique: true
    add_index :members, :card_type
    add_index :members, :status
  end
end
