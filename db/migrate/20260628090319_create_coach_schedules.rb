class CreateCoachSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :coach_schedules do |t|
      t.references :coach, null: false, foreign_key: true
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :status, null: false, default: 'available'
      t.integer :max_bookings, null: false, default: 1

      t.timestamps
    end
    add_index :coach_schedules, [:coach_id, :date, :start_time, :end_time], unique: true, name: 'index_coach_schedules_on_coach_and_time'
    add_index :coach_schedules, [:date, :start_time, :end_time]
    add_index :coach_schedules, :status
  end
end
