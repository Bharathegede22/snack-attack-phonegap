# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20131019060418) do

  create_table "attractions", force: true do |t|
    t.integer "city_id",     limit: 2
    t.string  "name"
    t.text    "description"
    t.text    "places"
    t.string  "best_time"
    t.string  "lat"
    t.string  "lng"
  end

  add_index "attractions", ["city_id"], name: "index_attractions_on_city_id", using: :btree

  create_table "bookings", force: true do |t|
    t.integer  "car_id",           limit: 2
    t.integer  "location_id",      limit: 2
    t.integer  "user_id"
    t.integer  "booked_by"
    t.integer  "cancelled_by"
    t.string   "comment"
    t.integer  "days",             limit: 1
    t.integer  "hours",            limit: 1
    t.decimal  "estimate",                    precision: 8, scale: 2
    t.decimal  "discount",                    precision: 8, scale: 2
    t.decimal  "total",                       precision: 8, scale: 2
    t.datetime "starts"
    t.datetime "ends"
    t.datetime "cancelled_at"
    t.datetime "returned_at"
    t.string   "ip"
    t.integer  "status",           limit: 1,                          default: 0
    t.string   "jsi",              limit: 10
    t.string   "user_name"
    t.string   "user_email"
    t.string   "user_mobile"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "start_km",         limit: 10
    t.string   "end_km",           limit: 10
    t.integer  "normal_days",      limit: 1,                          default: 0
    t.integer  "normal_hours",     limit: 2,                          default: 0
    t.integer  "discounted_days",  limit: 1,                          default: 0
    t.integer  "discounted_hours", limit: 2,                          default: 0
    t.datetime "actual_starts"
    t.datetime "actual_ends"
    t.datetime "last_starts"
    t.datetime "last_ends"
    t.boolean  "early",                                               default: false
    t.boolean  "late",                                                default: false
    t.boolean  "extended",                                            default: false
    t.boolean  "rescheduled",                                         default: false
    t.integer  "fuel_starts",      limit: 1
    t.integer  "fuel_ends",        limit: 1
    t.integer  "daily_fare",       limit: 2
    t.integer  "hourly_fare",      limit: 2
    t.integer  "hourly_km_limit",  limit: 2
    t.integer  "daily_km_limit",   limit: 2
    t.integer  "excess_kms",       limit: 2,                          default: 0
    t.text     "notes"
    t.integer  "cargroup_id",      limit: 2
  end

  add_index "bookings", ["car_id"], name: "index_bookings_on_car_id", using: :btree
  add_index "bookings", ["cargroup_id"], name: "index_bookings_on_cargroup_id", using: :btree
  add_index "bookings", ["ends"], name: "index_bookings_on_ends", using: :btree
  add_index "bookings", ["jsi"], name: "index_bookings_on_jsi", using: :btree
  add_index "bookings", ["location_id"], name: "index_bookings_on_location_id", using: :btree
  add_index "bookings", ["starts"], name: "index_bookings_on_starts", using: :btree
  add_index "bookings", ["user_email"], name: "index_bookings_on_user_email", using: :btree
  add_index "bookings", ["user_id"], name: "index_bookings_on_user_id", using: :btree
  add_index "bookings", ["user_mobile"], name: "index_bookings_on_user_mobile", using: :btree

  create_table "brands", force: true do |t|
    t.string "name"
  end

  create_table "cargroups", force: true do |t|
    t.integer "brand_id",         limit: 2
    t.integer "model_id",         limit: 2
    t.string  "name"
    t.string  "display_name"
    t.boolean "status",                                              default: false
    t.integer "priority",         limit: 1
    t.integer "seating",          limit: 1
    t.integer "wait_period",      limit: 2
    t.integer "daily_fare",       limit: 2
    t.integer "hourly_fare",      limit: 2
    t.string  "disclaimer"
    t.text    "description"
    t.integer "cartype",          limit: 1
    t.integer "drive",            limit: 1
    t.integer "fuel",             limit: 1
    t.boolean "manual"
    t.string  "color",            limit: 10
    t.boolean "power_windows"
    t.boolean "aux"
    t.boolean "leather_interior"
    t.boolean "power_seat"
    t.boolean "bluetooth"
    t.boolean "gps"
    t.boolean "premium_sound"
    t.boolean "radio"
    t.boolean "sunroof"
    t.boolean "power_steering"
    t.boolean "dvd"
    t.boolean "ac"
    t.boolean "heating"
    t.boolean "cd"
    t.boolean "mp3"
    t.boolean "alloy_wheels"
    t.boolean "handsfree"
    t.boolean "cruise"
    t.boolean "smoking"
    t.boolean "pet"
    t.boolean "handicap"
    t.integer "hourly_km_limit",  limit: 2,                          default: 40
    t.integer "daily_km_limit",   limit: 2,                          default: 200
    t.decimal "excess_kms",                  precision: 5, scale: 2
  end

  create_table "cars", force: true do |t|
    t.integer  "cargroup_id",      limit: 2
    t.integer  "location_id",      limit: 2
    t.string   "name"
    t.integer  "status",           limit: 1,  default: 0
    t.integer  "mileage",          limit: 3,  default: 0
    t.string   "vin"
    t.string   "license"
    t.string   "insurer"
    t.string   "policy"
    t.integer  "wait_period",      limit: 2
    t.boolean  "allindia"
    t.string   "color",            limit: 10
    t.boolean  "leather_interior"
    t.boolean  "mp3"
    t.boolean  "gps"
    t.boolean  "bluetooth"
    t.boolean  "radio"
    t.boolean  "dvd"
    t.boolean  "aux"
    t.boolean  "roofrack"
    t.boolean  "alloy_wheels"
    t.boolean  "handsfree"
    t.boolean  "child_seat"
    t.boolean  "smoking"
    t.boolean  "pet"
    t.boolean  "handicap"
    t.string   "jsi"
    t.string   "jsi_old"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cars", ["cargroup_id"], name: "index_cars_on_cargroup_id", using: :btree
  add_index "cars", ["location_id"], name: "index_cars_on_location_id", using: :btree

  create_table "charges", force: true do |t|
    t.integer  "booking_id"
    t.integer  "refund",                  limit: 1,                          default: 0
    t.string   "activity",                limit: 40
    t.integer  "hours",                   limit: 2,                          default: 0
    t.integer  "billed_total_hours",      limit: 2,                          default: 0
    t.integer  "billed_standard_hours",   limit: 2,                          default: 0
    t.integer  "billed_discounted_hours", limit: 2,                          default: 0
    t.decimal  "estimate",                           precision: 8, scale: 2, default: 0.0
    t.decimal  "discount",                           precision: 8, scale: 2, default: 0.0
    t.decimal  "amount",                             precision: 8, scale: 2, default: 0.0
    t.string   "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "charges", ["booking_id"], name: "index_charges_on_booking_id", using: :btree

  create_table "cities", force: true do |t|
    t.string "name"
    t.text   "description"
    t.string "lat"
    t.string "lng"
  end

  create_table "images", force: true do |t|
    t.integer  "imageable_id"
    t.string   "imageable_type"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
  end

  add_index "images", ["imageable_type", "imageable_id"], name: "index_images_on_imageable_type_and_imageable_id", using: :btree

  create_table "inventories", force: true do |t|
    t.integer  "cargroup_id", limit: 2
    t.integer  "location_id", limit: 2
    t.integer  "city_id",     limit: 2
    t.integer  "total",       limit: 1, default: 0
    t.datetime "slot"
  end

  add_index "inventories", ["cargroup_id", "slot"], name: "index_inventories_on_cargroup_id_and_slot", using: :btree
  add_index "inventories", ["city_id", "slot"], name: "index_inventories_on_city_id_and_slot", using: :btree
  add_index "inventories", ["location_id", "slot"], name: "index_inventories_on_location_id_and_slot", using: :btree

  create_table "locations", force: true do |t|
    t.integer "city_id",     limit: 2
    t.string  "name"
    t.string  "address"
    t.string  "lat"
    t.string  "lng"
    t.string  "map_link"
    t.text    "description"
  end

  create_table "models", force: true do |t|
    t.integer "brand_id", limit: 2
    t.string  "name"
  end

  create_table "payments", force: true do |t|
    t.integer  "booking_id"
    t.integer  "status",     limit: 1,                          default: 0
    t.string   "through",    limit: 20
    t.string   "key"
    t.string   "notes"
    t.decimal  "amount",                precision: 8, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "payments", ["booking_id"], name: "index_payments_on_booking_id", using: :btree
  add_index "payments", ["key"], name: "index_payments_on_key", using: :btree

  create_table "refunds", force: true do |t|
    t.integer  "booking_id"
    t.integer  "status",     limit: 1,                          default: 0
    t.string   "through",    limit: 20
    t.string   "key"
    t.string   "notes"
    t.decimal  "amount",                precision: 8, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "refunds", ["booking_id"], name: "index_refunds_on_booking_id", using: :btree
  add_index "refunds", ["key"], name: "index_refunds_on_key", using: :btree

  create_table "reviews", force: true do |t|
    t.integer  "booking_id"
    t.integer  "user_id"
    t.integer  "car_id",           limit: 2
    t.integer  "location_id",      limit: 2
    t.string   "title"
    t.text     "comment"
    t.string   "ip"
    t.boolean  "active",                                              default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cargroup_id",      limit: 2
    t.string   "jsi",              limit: 10
    t.decimal  "rating_friendly",             precision: 2, scale: 1
    t.decimal  "rating_tech",                 precision: 2, scale: 1
    t.decimal  "rating_condition",            precision: 2, scale: 1
    t.decimal  "rating_location",             precision: 2, scale: 1
  end

  add_index "reviews", ["booking_id"], name: "index_reviews_on_booking_id", using: :btree
  add_index "reviews", ["car_id"], name: "index_reviews_on_car_id", using: :btree
  add_index "reviews", ["cargroup_id"], name: "index_reviews_on_cargroup_id", using: :btree
  add_index "reviews", ["jsi"], name: "index_reviews_on_jsi", using: :btree
  add_index "reviews", ["location_id"], name: "index_reviews_on_location_id", using: :btree
  add_index "reviews", ["user_id"], name: "index_reviews_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "name"
    t.date     "dob"
    t.string   "phone",                  limit: 15
    t.string   "address"
    t.string   "license"
    t.integer  "country_id",             limit: 2
    t.integer  "state_id",               limit: 1
    t.integer  "status",                 limit: 1,  default: 0
    t.string   "pincode",                limit: 8
    t.integer  "role",                   limit: 1,  default: 0
    t.boolean  "mobile",                            default: false
    t.string   "email",                                             null: false
    t.string   "encrypted_password",                default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 3,  default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "utilizations", force: true do |t|
    t.integer "booking_id"
    t.integer "car_id",              limit: 2
    t.integer "cargroup_id",         limit: 2
    t.integer "location_id",         limit: 2
    t.integer "minutes",             limit: 2,                         default: 0
    t.integer "billed_minutes",      limit: 2,                         default: 0
    t.integer "billed_minutes_last", limit: 2,                         default: 0
    t.integer "wday",                limit: 1
    t.decimal "revenue",                       precision: 7, scale: 2, default: 0.0
    t.decimal "revenue_last",                  precision: 7, scale: 2, default: 0.0
    t.date    "day"
  end

  add_index "utilizations", ["booking_id"], name: "index_utilizations_on_booking_id", using: :btree
  add_index "utilizations", ["car_id", "wday"], name: "index_utilizations_on_car_id_and_wday", using: :btree
  add_index "utilizations", ["cargroup_id", "wday"], name: "index_utilizations_on_cargroup_id_and_wday", using: :btree
  add_index "utilizations", ["location_id", "wday"], name: "index_utilizations_on_location_id_and_wday", using: :btree

end
