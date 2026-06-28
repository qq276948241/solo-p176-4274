class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :member, null: false, foreign_key: true
      t.references :coach_schedule, null: false, foreign_key: true
      t.string :status, null: false, default: 'booked'
      t.boolean :consumed, null: false, default: false

      t.timestamps
    end
    add_index :bookings, [:member_id, :coach_schedule_id], unique: true
    add_index :bookings, :status
    add_index :bookings, :consumed
  end
end
