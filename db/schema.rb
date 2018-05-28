# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180204155643) do

  create_table "facts", force: :cascade do |t|
    t.binary "value"
    t.string "key"
    t.integer "location_id"
  end

  create_table "images", force: :cascade do |t|
    t.string "src"
    t.string "link"
    t.integer "location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "country", null: false
    t.string "city", null: false
    t.integer "cost", default: 0, null: false
    t.integer "days", default: 1, null: false
    t.integer "trip_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "summary"
    t.binary "wiki"
    t.string "state"
    t.integer "order"
    t.integer "peace_index", default: 0, null: false
  end

  create_table "tags", force: :cascade do |t|
    t.string "value", null: false
    t.integer "trip_id", null: false
  end

  create_table "todos", force: :cascade do |t|
    t.text "value"
    t.string "key"
    t.integer "location_id"
  end

  create_table "trips", force: :cascade do |t|
    t.integer "year"
    t.integer "matt_rating"
    t.integer "heather_rating"
    t.integer "min_flight_cost"
    t.string "destination_airport"
    t.string "return_airport"
    t.integer "max_flight_cost"
    t.integer "total_hours"
    t.integer "travel_hours"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "avg_flight_cost"
    t.boolean "ignore_return_flight", default: false
    t.boolean "ignore_destination_flight", default: false
    t.boolean "ignore_in_lifetime", default: false
  end

end
