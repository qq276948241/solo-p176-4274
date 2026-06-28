# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_28_125323) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.bigint "coach_schedule_id", null: false
    t.boolean "consumed", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "member_id", null: false
    t.string "status", default: "booked", null: false
    t.datetime "updated_at", null: false
    t.index ["coach_schedule_id"], name: "index_bookings_on_coach_schedule_id"
    t.index ["consumed"], name: "index_bookings_on_consumed"
    t.index ["member_id", "coach_schedule_id"], name: "index_bookings_on_member_id_and_coach_schedule_id", unique: true
    t.index ["member_id"], name: "index_bookings_on_member_id"
    t.index ["status"], name: "index_bookings_on_status"
  end

  create_table "coach_schedules", force: :cascade do |t|
    t.bigint "coach_id", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.time "end_time", null: false
    t.integer "max_bookings", default: 1, null: false
    t.time "start_time", null: false
    t.string "status", default: "available", null: false
    t.datetime "updated_at", null: false
    t.index ["coach_id", "date", "start_time", "end_time"], name: "index_coach_schedules_on_coach_and_time", unique: true
    t.index ["coach_id"], name: "index_coach_schedules_on_coach_id"
    t.index ["date", "start_time", "end_time"], name: "index_coach_schedules_on_date_and_start_time_and_end_time"
    t.index ["status"], name: "index_coach_schedules_on_status"
  end

  create_table "coaches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.string "specialty"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["phone"], name: "index_coaches_on_phone", unique: true
    t.index ["status"], name: "index_coaches_on_status"
  end

  create_table "members", force: :cascade do |t|
    t.string "card_type", default: "prepaid", null: false
    t.datetime "created_at", null: false
    t.date "monthly_end_date"
    t.date "monthly_start_date"
    t.string "name", null: false
    t.string "phone", null: false
    t.integer "remaining_sessions", default: 0
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["card_type"], name: "index_members_on_card_type"
    t.index ["phone"], name: "index_members_on_phone", unique: true
    t.index ["status"], name: "index_members_on_status"
  end

  create_table "products", force: :cascade do |t|
    t.string "category", null: false
    t.string "condition", default: "new", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.datetime "published_at"
    t.string "status", default: "active", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_products_on_category"
    t.index ["condition"], name: "index_products_on_condition"
    t.index ["published_at"], name: "index_products_on_published_at"
    t.index ["status"], name: "index_products_on_status"
  end

  create_table "tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "expires_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_tokens_on_expires_at"
    t.index ["token"], name: "index_tokens_on_token", unique: true
  end

  add_foreign_key "bookings", "coach_schedules"
  add_foreign_key "bookings", "members"
  add_foreign_key "coach_schedules", "coaches"
end
