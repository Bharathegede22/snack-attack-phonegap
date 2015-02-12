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

ActiveRecord::Schema.define(version: 20150210093736) do

  create_table "accidents", force: true do |t|
    t.boolean  "active",                                                            default: true
    t.boolean  "insurance",                                                         default: false
    t.integer  "carblock_id"
    t.integer  "car_id",                         limit: 2
    t.integer  "cargroup_id",                    limit: 2
    t.string   "impact_area",                    limit: 20
    t.integer  "severity",                       limit: 1
    t.string   "notes"
    t.integer  "service_center_id",              limit: 2
    t.string   "booking_key",                    limit: 10
    t.datetime "starts"
    t.datetime "ends"
    t.string   "insurance_company",              limit: 20
    t.string   "surveyor_name"
    t.datetime "surveyor_visit_time"
    t.datetime "garage_estimate_time"
    t.datetime "surveyor_approval_time"
    t.datetime "surveyor_approved_invoice_time"
    t.datetime "final_approval_time"
    t.datetime "ends_invoice"
    t.string   "claim_number",                   limit: 30
    t.decimal  "cost_estimate",                             precision: 8, scale: 2
    t.decimal  "labor_cost",                                precision: 8, scale: 2, default: 0.0
    t.decimal  "consumables_cost",                          precision: 8, scale: 2, default: 0.0
    t.decimal  "additional_cost",                           precision: 8, scale: 2, default: 0.0
    t.decimal  "total_cost",                                precision: 8, scale: 2, default: 0.0
    t.decimal  "discount",                                  precision: 7, scale: 2, default: 0.0
    t.decimal  "insurance_covered_amount",                  precision: 8, scale: 2, default: 0.0
    t.decimal  "customer_amount",                           precision: 8, scale: 2
    t.decimal  "zoom_cost",                                 precision: 8, scale: 2
    t.integer  "estimated_days",                 limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "auto_flag"
    t.integer  "vetted_by"
    t.datetime "vetted_at"
    t.integer  "checklist_by"
    t.integer  "sourcable_id"
    t.string   "sourcable_type"
  end

  add_index "accidents", ["carblock_id"], name: "index_accidents_on_carblock_id", using: :btree

  create_table "activities", force: true do |t|
    t.integer  "user_id"
    t.integer  "booking_id"
    t.decimal  "amount",               precision: 8, scale: 2, default: 0.0
    t.integer  "transferred_via_id"
    t.string   "transferred_via_type"
    t.string   "activity"
    t.string   "notes"
    t.string   "medium"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "activities", ["booking_id"], name: "index_activities_on_booking_id", using: :btree
  add_index "activities", ["user_id"], name: "index_activities_on_user_id", using: :btree

  create_table "alerts", force: true do |t|
    t.integer  "loggable_id"
    t.string   "loggable_type"
    t.string   "action",             limit: 30
    t.decimal  "severity",                      precision: 2, scale: 1
    t.datetime "resolved_at"
    t.integer  "created_by"
    t.integer  "resolved_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "resolved_dashboard"
    t.integer  "fleet_involved"
  end

  add_index "alerts", ["loggable_id"], name: "index_alerts_on_loggable_id", using: :btree
  add_index "alerts", ["loggable_type"], name: "index_alerts_on_loggable_type", using: :btree

  create_table "announcements", force: true do |t|
    t.string  "note"
    t.boolean "active"
  end

  create_table "attractions", force: true do |t|
    t.integer "city_id",         limit: 2
    t.string  "name"
    t.text    "description"
    t.text    "places"
    t.text    "best_time"
    t.string  "lat"
    t.string  "lng"
    t.integer "state",           limit: 1
    t.integer "category",        limit: 1
    t.boolean "outstation"
    t.string  "seo_title"
    t.string  "seo_description"
    t.string  "seo_keywords"
    t.string  "seo_h1"
    t.string  "seo_link"
  end

  add_index "attractions", ["city_id"], name: "index_attractions_on_city_id", using: :btree

  create_table "bankcodes", force: true do |t|
    t.string   "bankName"
    t.string   "issuerCode"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",     default: true
  end

  add_index "bankcodes", ["issuerCode"], name: "index_bankcodes_on_issuerCode", using: :btree

  create_table "bookings", force: true do |t|
    t.integer  "car_id",                     limit: 2
    t.integer  "location_id",                limit: 2
    t.integer  "user_id"
    t.integer  "booked_by"
    t.integer  "cancelled_by"
    t.string   "comment"
    t.integer  "days",                       limit: 1
    t.integer  "hours"
    t.decimal  "estimate",                              precision: 8,  scale: 2
    t.decimal  "discount",                              precision: 8,  scale: 2
    t.decimal  "total",                                 precision: 8,  scale: 2
    t.datetime "starts"
    t.datetime "ends"
    t.datetime "cancelled_at"
    t.datetime "returned_at"
    t.string   "ip"
    t.integer  "status",                     limit: 1,                           default: 0
    t.string   "jsi",                        limit: 10
    t.string   "user_name"
    t.string   "user_email"
    t.string   "user_mobile"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "start_km",                   limit: 10
    t.string   "end_km",                     limit: 10
    t.integer  "normal_days",                limit: 1,                           default: 0
    t.integer  "normal_hours",                                                   default: 0
    t.integer  "discounted_days",            limit: 1,                           default: 0
    t.integer  "discounted_hours",                                               default: 0
    t.datetime "actual_starts"
    t.datetime "actual_ends"
    t.datetime "last_starts"
    t.datetime "last_ends"
    t.boolean  "early",                                                          default: false
    t.boolean  "late",                                                           default: false
    t.boolean  "extended",                                                       default: false
    t.boolean  "rescheduled",                                                    default: false
    t.integer  "fuel_starts",                limit: 1
    t.integer  "fuel_ends",                  limit: 1
    t.integer  "daily_fare",                 limit: 2
    t.integer  "hourly_fare",                limit: 2
    t.integer  "hourly_km_limit",            limit: 2
    t.integer  "daily_km_limit",             limit: 2
    t.integer  "excess_kms",                 limit: 2,                           default: 0
    t.text     "notes"
    t.integer  "cargroup_id",                limit: 2
    t.integer  "fleet_id_start",             limit: 3
    t.integer  "fleet_id_end",               limit: 3
    t.integer  "individual_start",           limit: 1
    t.integer  "individual_end",             limit: 1
    t.integer  "transport",                  limit: 1
    t.datetime "unblocks"
    t.boolean  "outstation",                                                     default: false
    t.datetime "checkout"
    t.string   "confirmation_key",           limit: 20
    t.integer  "balance"
    t.string   "ref_initial"
    t.string   "ref_immediate"
    t.string   "promo"
    t.integer  "credit_status",                                                  default: 0
    t.integer  "offer_id"
    t.integer  "pricing_id"
    t.integer  "corporate_id"
    t.integer  "city_id",                    limit: 2
    t.string   "pricing_mode",               limit: 2
    t.string   "medium",                     limit: 20
    t.boolean  "shortened",                                                      default: false
    t.integer  "total_fare"
    t.integer  "deposit_status",             limit: 1,                           default: 0
    t.boolean  "carry",                                                          default: false
    t.boolean  "hold",                                                           default: false
    t.boolean  "release_payment",                                                default: false
    t.boolean  "settled",                                                        default: false
    t.integer  "actual_cargroup_id",         limit: 2
    t.integer  "actual_cargroup_id_count",   limit: 1,                           default: 0
    t.integer  "car_id_count",               limit: 1,                           default: 0
    t.integer  "cargroup_id_count",          limit: 1,                           default: 0
    t.integer  "ends_count",                 limit: 1,                           default: 0
    t.integer  "end_km_count",               limit: 1,                           default: 0
    t.integer  "location_id_count",          limit: 1,                           default: 0
    t.integer  "returned_at_count",          limit: 1,                           default: 0
    t.integer  "starts_count",               limit: 1,                           default: 0
    t.integer  "start_km_count",             limit: 1,                           default: 0
    t.boolean  "defer_deposit"
    t.boolean  "insufficient_deposit",                                           default: false
    t.integer  "fleet_checklist_by"
    t.integer  "start_checklist_by"
    t.integer  "end_checklist_by"
    t.datetime "release_payment_updated_at"
    t.decimal  "recorded_distance",                     precision: 10, scale: 2
  end

  add_index "bookings", ["car_id"], name: "index_bookings_on_car_id", using: :btree
  add_index "bookings", ["cargroup_id"], name: "index_bookings_on_cargroup_id", using: :btree
  add_index "bookings", ["confirmation_key"], name: "index_bookings_on_confirmation_key", using: :btree
  add_index "bookings", ["ends"], name: "index_bookings_on_ends", using: :btree
  add_index "bookings", ["jsi"], name: "index_bookings_on_jsi", using: :btree
  add_index "bookings", ["location_id"], name: "index_bookings_on_location_id", using: :btree
  add_index "bookings", ["ref_immediate"], name: "index_bookings_on_ref_immediate", using: :btree
  add_index "bookings", ["ref_initial"], name: "index_bookings_on_ref_initial", using: :btree
  add_index "bookings", ["starts"], name: "index_bookings_on_starts", using: :btree
  add_index "bookings", ["unblocks"], name: "index_bookings_on_unblocks", using: :btree
  add_index "bookings", ["user_email"], name: "index_bookings_on_user_email", using: :btree
  add_index "bookings", ["user_id"], name: "index_bookings_on_user_id", using: :btree
  add_index "bookings", ["user_mobile"], name: "index_bookings_on_user_mobile", using: :btree

  create_table "brands", force: true do |t|
    t.string "name"
  end

  create_table "campaigns", force: true do |t|
    t.string   "title"
    t.text     "content"
    t.text     "users_query"
    t.string   "from_email"
    t.string   "subject"
    t.integer  "frequency"
    t.boolean  "monday",      default: false
    t.boolean  "tuesday",     default: false
    t.boolean  "wednesday",   default: false
    t.boolean  "thursday",    default: false
    t.boolean  "friday",      default: false
    t.boolean  "saturday",    default: false
    t.boolean  "sunday",      default: false
    t.boolean  "active",      default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "sampling",    default: false
    t.boolean  "disable",     default: false
  end

  create_table "car_availabilities", force: true do |t|
    t.integer  "car_id"
    t.integer  "cargroup_id"
    t.integer  "location_id"
    t.string   "starts"
    t.string   "ends"
    t.integer  "time_available"
    t.string   "user_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "car_images", force: true do |t|
    t.integer  "car_id"
    t.integer  "car_imageable_id"
    t.string   "car_imageable_type"
    t.string   "side"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "view_image"
  end

  add_index "car_images", ["car_imageable_type", "car_imageable_id"], name: "index_car_images_on_car_imageable_type_and_car_imageable_id", using: :btree

  create_table "carblocks", force: true do |t|
    t.integer  "car_id",         limit: 2
    t.integer  "activity",       limit: 1
    t.string   "notes"
    t.datetime "starts"
    t.datetime "ends"
    t.datetime "created_at"
    t.integer  "cargroup_id",    limit: 1
    t.boolean  "active",                    default: true
    t.integer  "user_id"
    t.datetime "updated_at"
    t.boolean  "impact",                    default: false
    t.datetime "starts_initial"
    t.datetime "ends_initial"
    t.boolean  "source"
    t.text     "log"
    t.integer  "checklist_by"
    t.string   "medium",         limit: 20
  end

  add_index "carblocks", ["car_id"], name: "index_carblocks_on_car_id", using: :btree

  create_table "cargroup_offers", force: true do |t|
    t.integer "cargroup_id"
    t.integer "offer_id"
  end

  create_table "cargroups", force: true do |t|
    t.integer "brand_id",         limit: 2
    t.integer "model_id",         limit: 2
    t.string  "name"
    t.string  "display_name"
    t.boolean "status",                      default: false
    t.boolean "ended",                       default: false
    t.integer "priority",         limit: 1
    t.integer "seating",          limit: 1
    t.integer "wait_period",      limit: 2
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
    t.float   "kmpl"
    t.string  "seo_title"
    t.string  "seo_description"
    t.string  "seo_keywords"
    t.string  "seo_h1"
    t.string  "seo_link"
    t.boolean "kle",                         default: false
  end

  create_table "cargroups_cities", force: true do |t|
    t.integer "cargroup_id",    limit: 2
    t.integer "city_id",        limit: 2
    t.boolean "inventory_done",           default: false
  end

  add_index "cargroups_cities", ["city_id"], name: "index_cargroups_cities_on_city_id", using: :btree

  create_table "carmovements", force: true do |t|
    t.integer  "car_id",         limit: 2
    t.integer  "cargroup_id",    limit: 2
    t.integer  "location_id",    limit: 2
    t.datetime "starts"
    t.datetime "ends"
    t.boolean  "active",                   default: true
    t.integer  "user_id"
    t.datetime "updated_at"
    t.boolean  "impact",                   default: false
    t.datetime "created_at"
    t.integer  "reason",         limit: 1
    t.string   "notes"
    t.datetime "starts_initial"
    t.datetime "ends_initial"
    t.text     "log"
  end

  add_index "carmovements", ["car_id"], name: "index_carmovements_on_car_id", using: :btree
  add_index "carmovements", ["cargroup_id"], name: "index_carmovements_on_cargroup_id", using: :btree
  add_index "carmovements", ["location_id"], name: "index_carmovements_on_location_id", using: :btree

  create_table "cars", force: true do |t|
    t.integer  "cargroup_id",        limit: 2
    t.integer  "location_id",        limit: 2
    t.string   "name"
    t.integer  "status",             limit: 1,                           default: 0
    t.integer  "mileage",            limit: 3,                           default: 0
    t.string   "vin"
    t.string   "license"
    t.string   "insurer"
    t.string   "policy"
    t.integer  "wait_period",        limit: 2
    t.boolean  "allindia"
    t.string   "color",              limit: 10
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
    t.date     "starts"
    t.date     "ends"
    t.boolean  "kle_installed",                                          default: false
    t.boolean  "immobilizer",                                            default: false
    t.string   "tguid"
    t.string   "km_reading",         limit: 11
    t.integer  "fuel_reading",       limit: 1,                           default: 0
    t.date     "emi_start_date"
    t.string   "financier_name"
    t.string   "loan_account_num"
    t.string   "city_of_purchase"
    t.decimal  "rate_of_interest",              precision: 6,  scale: 4
    t.decimal  "loan_amount",                   precision: 10, scale: 2
    t.integer  "loan_tenure_months"
    t.date     "car_regn_date"
    t.integer  "city_id"
  end

  add_index "cars", ["cargroup_id"], name: "index_cars_on_cargroup_id", using: :btree
  add_index "cars", ["ends"], name: "index_cars_on_ends", using: :btree
  add_index "cars", ["location_id"], name: "index_cars_on_location_id", using: :btree
  add_index "cars", ["starts"], name: "index_cars_on_starts", using: :btree

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
    t.boolean  "active",                                                     default: true
  end

  add_index "charges", ["booking_id"], name: "index_charges_on_booking_id", using: :btree

  create_table "checklist_answers", force: true do |t|
    t.integer  "checklist_id"
    t.boolean  "status",                        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "starts",                        default: 1
    t.integer  "priority"
    t.string   "answer"
    t.integer  "checklistable_id"
    t.string   "checklistable_type"
    t.string   "medium",             limit: 20, default: "1"
    t.integer  "car_id",             limit: 2
    t.string   "initial_answer"
    t.datetime "question_open_time"
    t.datetime "answer_time"
  end

  add_index "checklist_answers", ["checklist_id"], name: "index_checklist_answers_on_checklist_id", using: :btree
  add_index "checklist_answers", ["checklistable_type", "checklistable_id"], name: "index_checklist_answers_on_checklistable", using: :btree

  create_table "checklists", force: true do |t|
    t.text     "header"
    t.string   "name"
    t.boolean  "active",         default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "starts",         default: 0
    t.string   "answer_type"
    t.integer  "priority"
    t.string   "answer_options"
    t.boolean  "image",          default: false
    t.integer  "order",          default: 0
    t.boolean  "hidden",         default: false
  end

  create_table "cities", force: true do |t|
    t.string  "name"
    t.text    "description"
    t.string  "lat"
    t.string  "lng"
    t.string  "pricing_mode",            limit: 2
    t.string  "contact_phone",           limit: 15
    t.string  "contact_email",           limit: 50
    t.string  "refund_contact_email",    limit: 50
    t.string  "seo_title"
    t.string  "seo_description"
    t.string  "seo_keywords"
    t.string  "seo_h1"
    t.string  "seo_inside_title"
    t.string  "seo_inside_description"
    t.string  "seo_inside_keywords"
    t.string  "seo_inside_h1"
    t.string  "seo_outside_title"
    t.string  "seo_outside_description"
    t.string  "seo_outside_keywords"
    t.string  "seo_outside_h1"
    t.boolean "active",                             default: false
    t.boolean "promo_pricing",                      default: false
    t.boolean "prelaunch",                          default: false
    t.string  "link_name"
    t.text    "address"
    t.text    "directions"
    t.string  "vat"
  end

  create_table "city_offers", force: true do |t|
    t.integer  "offer_id"
    t.integer  "city_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "corporates", force: true do |t|
    t.string   "name"
    t.boolean  "active",          default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "seo_title"
    t.string   "seo_description"
    t.string   "seo_keywords"
    t.string   "seo_h1"
    t.string   "seo_link"
  end

  create_table "coupon_codes", force: true do |t|
    t.string   "code"
    t.boolean  "used",       default: false
    t.integer  "booking_id"
    t.integer  "offer_id",                   null: false
    t.datetime "used_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "coupon_codes", ["code"], name: "index_coupon_codes_on_code", using: :btree

  create_table "crash_reports", force: true do |t|
    t.string   "platform"
    t.string   "version"
    t.string   "device_id"
    t.text     "crash_text"
    t.text     "notes"
    t.integer  "notification_sent", default: 0
    t.boolean  "resolved"
    t.string   "push_message"
    t.string   "resolved_version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "credits", force: true do |t|
    t.integer  "user_id"
    t.string   "booking_key"
    t.text     "promo_code"
    t.integer  "updated_by"
    t.string   "creditable_type"
    t.integer  "amount"
    t.boolean  "action",          default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "status",          default: true
    t.string   "note"
    t.integer  "creditable_id"
    t.integer  "source_name"
  end

  create_table "dashboard_devices", force: true do |t|
    t.string   "uid"
    t.string   "imei1"
    t.string   "imei2"
    t.string   "version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deals", force: true do |t|
    t.datetime "starts",                                null: false
    t.datetime "ends",                                  null: false
    t.datetime "offer_start",                           null: false
    t.datetime "offer_end",                             null: false
    t.integer  "cargroup_id", limit: 2,                 null: false
    t.integer  "car_id",      limit: 2,                 null: false
    t.integer  "location_id", limit: 2,                 null: false
    t.integer  "booking_id"
    t.integer  "discount",                              null: false
    t.boolean  "sold_out",              default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logged_at"
  end

  add_index "deals", ["booking_id"], name: "index_deals_on_booking_id", using: :btree
  add_index "deals", ["car_id"], name: "index_deals_on_car_id", using: :btree
  add_index "deals", ["cargroup_id"], name: "index_deals_on_cargroup_id", using: :btree
  add_index "deals", ["ends"], name: "index_deals_on_ends", using: :btree
  add_index "deals", ["location_id"], name: "index_deals_on_location_id", using: :btree
  add_index "deals", ["offer_end"], name: "index_deals_on_offer_end", using: :btree
  add_index "deals", ["offer_start"], name: "index_deals_on_offer_start", using: :btree
  add_index "deals", ["starts"], name: "index_deals_on_starts", using: :btree

  create_table "debugs", force: true do |t|
    t.integer  "debugable_id"
    t.string   "debugable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sourcable_id"
    t.string   "sourcable_type"
    t.string   "through"
    t.string   "action"
    t.string   "status"
    t.string   "medium"
    t.string   "message"
  end

  create_table "devices", force: true do |t|
    t.string   "uid"
    t.string   "platform"
    t.string   "version"
    t.text     "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "city_id"
    t.integer  "user_id"
    t.text     "install_utm"
    t.text     "last_signin_utm"
    t.text     "signin_utm"
    t.text     "signup_utm"
    t.boolean  "uninstall",       default: false
  end

  add_index "devices", ["uid"], name: "index_devices_on_uid", using: :btree
  add_index "devices", ["user_id"], name: "index_devices_on_user_id", using: :btree

  create_table "emails", force: true do |t|
    t.integer "user_id"
    t.string  "activity",   limit: 30
    t.date    "created_at"
    t.integer "booking_id"
  end

  add_index "emails", ["booking_id"], name: "index_emails_on_booking_id", using: :btree
  add_index "emails", ["created_at"], name: "index_emails_on_created_at", using: :btree
  add_index "emails", ["user_id"], name: "index_emails_on_user_id", using: :btree

  create_table "fleets", force: true do |t|
    t.string  "name"
    t.string  "email"
    t.string  "mobile"
    t.integer "role",        limit: 1
    t.date    "starts"
    t.date    "ends"
    t.integer "location_id", limit: 3
  end

  create_table "fuel_costs", force: true do |t|
    t.decimal  "cost",                     precision: 10, scale: 0
    t.boolean  "status",                                            default: false
    t.integer  "fuel_type",      limit: 1,                          default: 0
    t.datetime "effective_from"
  end

  create_table "fuel_details", force: true do |t|
    t.integer  "car_id",           limit: 2
    t.decimal  "quantity",                   precision: 5, scale: 2
    t.decimal  "price",                      precision: 6, scale: 2
    t.integer  "start_km_reading"
    t.integer  "end_km_reading"
    t.datetime "starts"
    t.datetime "ends"
    t.integer  "fleet_id",         limit: 3
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fuel_details", ["car_id"], name: "index_fuel_details_on_car_id", using: :btree

  create_table "greenrope_groups", force: true do |t|
    t.string   "name"
    t.datetime "last_contact_created_at"
    t.text     "query"
    t.integer  "flag"
    t.datetime "last_booking_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "holidays", force: true do |t|
    t.string  "name"
    t.date    "day"
    t.boolean "internal", default: false
    t.boolean "repeat",   default: false
  end

  add_index "holidays", ["repeat"], name: "index_holidays_on_repeat", using: :btree

  create_table "hubs", force: true do |t|
    t.string   "name"
    t.integer  "city_id"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.integer  "max",         limit: 1, default: 0
  end

  add_index "inventories", ["cargroup_id", "location_id", "slot"], name: "index_inventories_on_cargroup_id_and_location_id_and_slot", unique: true, using: :btree
  add_index "inventories", ["total"], name: "index_inventories_on_total", using: :btree

  create_table "ivrs", force: true do |t|
    t.string  "ssid"
    t.string  "digits"
    t.string  "phone"
    t.boolean "status"
  end

  create_table "jobs", force: true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "hire_type",       limit: 1
    t.integer  "min_workex",      limit: 1
    t.integer  "relevant_workex", limit: 1
    t.integer  "department",      limit: 1
    t.boolean  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "location_offers", force: true do |t|
    t.integer "location_id"
    t.integer "offer_id"
  end

  create_table "locations", force: true do |t|
    t.integer  "city_id",         limit: 2
    t.string   "name"
    t.string   "address"
    t.string   "lat"
    t.string   "lng"
    t.string   "map_link"
    t.text     "description"
    t.string   "mobile",          limit: 15
    t.string   "email",           limit: 100
    t.integer  "status",          limit: 1,                           default: 1
    t.boolean  "inventory_done",                                      default: false
    t.boolean  "ended",                                               default: false
    t.string   "disclaimer"
    t.integer  "block_time",      limit: 2
    t.integer  "zone_id"
    t.integer  "hub_id"
    t.integer  "user_id"
    t.decimal  "cash",                        precision: 7, scale: 2, default: 0.0
    t.string   "seo_title"
    t.string   "seo_description"
    t.string   "seo_keywords"
    t.string   "seo_h1"
    t.string   "seo_link"
    t.datetime "kle_enabled"
  end

  create_table "maintenaces", force: true do |t|
    t.boolean  "active",                                               default: true
    t.integer  "carblock_id"
    t.integer  "car_id",            limit: 2
    t.integer  "cargroup_id",       limit: 2
    t.integer  "service_center_id", limit: 2
    t.datetime "starts"
    t.datetime "ends"
    t.datetime "ends_invoice"
    t.string   "notes"
    t.string   "booking_key",       limit: 10
    t.integer  "booking_impact",    limit: 1
    t.decimal  "labor_cost",                   precision: 8, scale: 2, default: 0.0
    t.decimal  "consumables_cost",             precision: 8, scale: 2, default: 0.0
    t.decimal  "additional_cost",              precision: 8, scale: 2, default: 0.0
    t.decimal  "total_cost",                   precision: 8, scale: 2, default: 0.0
    t.decimal  "discount",                     precision: 7, scale: 2, default: 0.0
    t.decimal  "customer_refund",              precision: 7, scale: 2, default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "auto_flag"
    t.integer  "vetted_by"
    t.datetime "vetted_at"
    t.integer  "checklist_by"
    t.integer  "sourcable_id"
    t.string   "sourcable_type"
  end

  add_index "maintenaces", ["carblock_id"], name: "index_maintenaces_on_carblock_id", using: :btree

  create_table "models", force: true do |t|
    t.integer "brand_id", limit: 2
    t.string  "name"
  end

  create_table "notification_sents", force: true do |t|
    t.integer  "notificable_id"
    t.string   "notificable_type"
    t.string   "body"
    t.datetime "sent_at"
    t.integer  "no_of_times",      default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
  end

  create_table "notifieds", force: true do |t|
    t.integer  "push_notification_id"
    t.integer  "device_id"
    t.boolean  "status",               default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notifieds", ["device_id"], name: "index_notifieds_on_device_id", using: :btree
  add_index "notifieds", ["push_notification_id"], name: "index_notifieds_on_push_notification_id", using: :btree

  create_table "offers", force: true do |t|
    t.string   "heading"
    t.text     "description"
    t.string   "promo_code"
    t.boolean  "status",                                 default: true
    t.text     "disclaimer"
    t.integer  "visibility",                   limit: 1, default: 0
    t.text     "user_condition"
    t.text     "booking_condition"
    t.text     "output_condition"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "summary"
    t.text     "instructions"
    t.datetime "valid_till"
    t.string   "discount_type"
    t.integer  "value"
    t.datetime "creation_starts"
    t.datetime "creation_ends"
    t.datetime "trip_start_date"
    t.datetime "trip_end_date"
    t.boolean  "is_mobile_allowed",                      default: false
    t.boolean  "is_web_allowed",                         default: false
    t.integer  "min_amount"
    t.integer  "max_amount"
    t.integer  "used_count"
    t.string   "ref_initial"
    t.string   "ref_immediate"
    t.boolean  "booking_condition_return_nil",           default: true
    t.string   "weekdays"
  end

  create_table "operations_costs", force: true do |t|
    t.integer  "activity_id"
    t.string   "activity_type"
    t.string   "item_description"
    t.integer  "kind",             limit: 1
    t.decimal  "discount",                   precision: 5, scale: 2
    t.boolean  "warranty"
    t.decimal  "insurance_cover",            precision: 8, scale: 2
    t.decimal  "amount",                     precision: 8, scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", force: true do |t|
    t.string   "title"
    t.text     "content"
    t.boolean  "active",               default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "city_id",    limit: 2
  end

  add_index "pages", ["title"], name: "index_pages_on_title", using: :btree

  create_table "parking_slots", force: true do |t|
    t.integer "location_id"
    t.integer "slots"
  end

  create_table "payments", force: true do |t|
    t.integer  "booking_id"
    t.integer  "status",                       limit: 1,                           default: 0
    t.string   "through",                      limit: 20
    t.string   "key"
    t.text     "notes"
    t.decimal  "amount",                                  precision: 8,  scale: 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mode",                         limit: 1
    t.integer  "qb_id"
    t.decimal  "refunded_amount",                         precision: 10, scale: 0, default: 0
    t.decimal  "deposit_available_for_refund",            precision: 10, scale: 0, default: 0
    t.decimal  "deposit_paid",                            precision: 10, scale: 0, default: 0
    t.string   "rrn"
    t.string   "auth_id"
  end

  add_index "payments", ["booking_id"], name: "index_payments_on_booking_id", using: :btree
  add_index "payments", ["key"], name: "index_payments_on_key", using: :btree

  create_table "petty_cashes", force: true do |t|
    t.integer  "location_id",    limit: 2
    t.boolean  "credit",                                           default: false
    t.decimal  "amount",                   precision: 7, scale: 2
    t.string   "reason"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "remaining_cash",           precision: 7, scale: 2
    t.integer  "fleet_id",       limit: 3
  end

  add_index "petty_cashes", ["location_id"], name: "index_petty_cashes_on_location_id", using: :btree

  create_table "pictures", force: true do |t|
    t.integer  "pictureable_id"
    t.string   "pictureable_type"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
  end

  add_index "pictures", ["pictureable_type", "pictureable_id"], name: "index_pictures_on_pictureable_type_and_pictureable_id", using: :btree

  create_table "pricings", force: true do |t|
    t.integer "cargroup_id",                limit: 2
    t.integer "city_id",                    limit: 2
    t.integer "hourly_fare"
    t.integer "daily_fare"
    t.integer "weekly_fare"
    t.integer "monthly_fare"
    t.integer "hourly_kms"
    t.integer "daily_kms"
    t.integer "weekly_kms"
    t.integer "monthly_kms"
    t.date    "starts"
    t.string  "version",                    limit: 6
    t.boolean "status",                                                       default: false
    t.decimal "excess_kms",                           precision: 5, scale: 2
    t.integer "hourly_discounted_fare"
    t.integer "daily_discounted_fare"
    t.integer "hourly_bod_fare"
    t.integer "daily_bod_fare"
    t.integer "weekly_percentage_discount", limit: 2,                         default: 0
  end

  add_index "pricings", ["city_id", "cargroup_id"], name: "index_pricings_on_city_id_and_cargroup_id", using: :btree

  create_table "push_notifications", force: true do |t|
    t.string   "name"
    t.integer  "frequency"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string   "message"
    t.text     "query"
    t.text     "count_query"
    t.string   "app_page"
    t.boolean  "status",      default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qb_entries", force: true do |t|
    t.integer  "booking_id"
    t.integer  "qb_id"
    t.integer  "journalable_id"
    t.string   "journalable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "referrals", force: true do |t|
    t.integer  "referral_user_id"
    t.string   "referral_email",   limit: 63
    t.string   "source",           limit: 31
    t.integer  "valid_referral",   limit: 2
    t.boolean  "signup_flag"
    t.integer  "first_booking_id"
    t.integer  "referable_type",   limit: 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "referrals", ["referral_user_id", "referral_email"], name: "index_referrals_on_referral_user_id_and_referral_email", unique: true, using: :btree

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

  create_table "service_centers", force: true do |t|
    t.integer  "brand_id",   limit: 2
    t.string   "kind",       limit: 15
    t.integer  "city_id",    limit: 2
    t.string   "dealer"
    t.string   "location"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "servicings", force: true do |t|
    t.boolean  "active",                                              default: true
    t.integer  "carblock_id"
    t.integer  "car_id",            limit: 2
    t.integer  "cargroup_id",       limit: 2
    t.integer  "servicing_number",  limit: 2
    t.integer  "servicing_km"
    t.datetime "starts"
    t.datetime "ends"
    t.datetime "ends_invoice"
    t.integer  "service_center_id", limit: 2
    t.string   "notes"
    t.decimal  "cost_estimate",               precision: 8, scale: 2
    t.decimal  "labor_cost",                  precision: 8, scale: 2, default: 0.0
    t.decimal  "consumables_cost",            precision: 8, scale: 2, default: 0.0
    t.decimal  "additional_cost",             precision: 8, scale: 2, default: 0.0
    t.decimal  "total_cost",                  precision: 8, scale: 2, default: 0.0
    t.decimal  "discount",                    precision: 7, scale: 2, default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "checklist_by"
  end

  add_index "servicings", ["carblock_id"], name: "index_servicings_on_carblock_id", using: :btree

  create_table "sms", force: true do |t|
    t.integer  "booking_id"
    t.string   "phone",         limit: 10
    t.text     "message"
    t.integer  "status",        limit: 1,  default: 0
    t.string   "error_message"
    t.string   "api_key"
    t.datetime "delivered_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "activity"
  end

  add_index "sms", ["api_key"], name: "index_sms_on_api_key", using: :btree
  add_index "sms", ["booking_id"], name: "index_sms_on_booking_id", using: :btree
  add_index "sms", ["created_at"], name: "index_sms_on_created_at", using: :btree

  create_table "surveys", force: true do |t|
    t.string   "email"
    t.string   "lat"
    t.string   "lng"
    t.string   "distance"
    t.string   "destination"
    t.string   "city"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "t4u_logs", force: true do |t|
    t.integer  "car_id"
    t.string   "status"
    t.text     "message"
    t.text     "notice"
    t.string   "action"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "t4u_logs", ["car_id"], name: "index_t4u_logs_on_car_id", using: :btree

  create_table "templates", force: true do |t|
    t.string   "title"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "templates", ["title"], name: "index_templates_on_title", using: :btree

  create_table "test_inventories", force: true do |t|
    t.integer  "cargroup_id", limit: 2
    t.integer  "location_id", limit: 2
    t.integer  "city_id",     limit: 2
    t.integer  "total",       limit: 1, default: 0
    t.datetime "slot"
    t.integer  "max",         limit: 1, default: 0
  end

  add_index "test_inventories", ["cargroup_id", "location_id", "slot"], name: "index_inventories_on_cargroup_id_and_location_id_and_slot", unique: true, using: :btree
  add_index "test_inventories", ["total"], name: "index_inventories_on_total", using: :btree

  create_table "triplogs", force: true do |t|
    t.integer  "booking_id"
    t.integer  "attraction_id"
    t.integer  "state",         limit: 1
    t.datetime "created_at"
  end

  add_index "triplogs", ["attraction_id"], name: "index_triplogs_on_attraction_id", using: :btree
  add_index "triplogs", ["booking_id"], name: "index_triplogs_on_booking_id", using: :btree
  add_index "triplogs", ["state"], name: "index_triplogs_on_state", using: :btree

  create_table "users", force: true do |t|
    t.string   "name"
    t.date     "dob"
    t.string   "phone",                           limit: 15
    t.string   "license"
    t.integer  "status",                          limit: 1,                            default: 0
    t.string   "pincode",                         limit: 8
    t.integer  "role",                            limit: 1,                            default: 0
    t.boolean  "mobile",                                                               default: false
    t.string   "email",                                                                                null: false
    t.string   "ref_code"
    t.string   "encrypted_password",                                                   default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                   limit: 3,                            default: 0
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
    t.string   "city"
    t.boolean  "gender",                                                               default: false
    t.string   "country",                         limit: 10
    t.string   "state",                           limit: 50
    t.string   "authentication_token"
    t.string   "ref_initial"
    t.string   "ref_immediate"
    t.string   "otp"
    t.datetime "otp_valid_till"
    t.integer  "otp_attempts",                    limit: 1
    t.datetime "otp_last_attempt"
    t.integer  "total_credits"
    t.string   "note"
    t.boolean  "license_verified",                                                     default: false
    t.string   "blacklist_reason"
    t.string   "blacklist_auth"
    t.string   "authentication_token_valid_till"
    t.string   "medium",                          limit: 20
    t.integer  "license_status",                  limit: 1,                            default: 0
    t.integer  "license_approver_id"
    t.string   "license_notes",                   limit: 256
    t.date     "license_validity"
    t.decimal  "wallet_total_amount",                         precision: 10, scale: 0
    t.integer  "city_id",                         limit: 2
    t.datetime "license_updated_at"
    t.boolean  "card_saved",                                                           default: false
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["medium"], name: "index_users_on_medium", using: :btree
  add_index "users", ["ref_immediate"], name: "index_users_on_ref_immediate", using: :btree
  add_index "users", ["ref_initial"], name: "index_users_on_ref_initial", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "utilizations", force: true do |t|
    t.integer "booking_id"
    t.integer "car_id",              limit: 2
    t.integer "cargroup_id",         limit: 2
    t.integer "location_id",         limit: 2
    t.integer "minutes",             limit: 2, default: 0
    t.integer "billed_minutes",      limit: 2, default: 0
    t.integer "billed_minutes_last", limit: 2, default: 0
    t.integer "wday",                limit: 1
    t.integer "revenue"
    t.integer "revenue_last"
    t.date    "day"
    t.float   "fuel_margin"
  end

  add_index "utilizations", ["booking_id"], name: "index_utilizations_on_booking_id", using: :btree
  add_index "utilizations", ["car_id", "wday"], name: "index_utilizations_on_car_id_and_wday", using: :btree
  add_index "utilizations", ["cargroup_id", "wday"], name: "index_utilizations_on_cargroup_id_and_wday", using: :btree
  add_index "utilizations", ["location_id", "wday"], name: "index_utilizations_on_location_id_and_wday", using: :btree

  create_table "variables", force: true do |t|
    t.string   "key"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "versions", force: true do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "wallets", force: true do |t|
    t.integer  "transferable_id"
    t.string   "transferable_type"
    t.integer  "user_id"
    t.decimal  "amount",                      precision: 8, scale: 2, default: 0.0
    t.boolean  "credit"
    t.integer  "status",            limit: 1,                         default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "booking_id"
  end

  create_table "zones", force: true do |t|
    t.string   "name"
    t.integer  "city_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "seo_title"
    t.string   "seo_description"
    t.string   "seo_keywords"
    t.string   "seo_h1"
    t.string   "seo_link"
  end

end
