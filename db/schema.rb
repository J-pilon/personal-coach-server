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

ActiveRecord::Schema[7.1].define(version: 2025_08_06_012507) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ai_requests", force: :cascade do |t|
    t.text "prompt", null: false
    t.string "job_type", null: false
    t.string "hash_value", null: false
    t.string "status", null: false
    t.text "error_message"
    t.bigint "profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hash_value"], name: "index_ai_requests_on_hash_value"
    t.index ["job_type"], name: "index_ai_requests_on_job_type"
    t.index ["profile_id"], name: "index_ai_requests_on_profile_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "work_role"
    t.string "education"
    t.text "desires"
    t.text "limiting_beliefs"
    t.string "onboarding_status", default: "incomplete"
    t.datetime "onboarding_completed_at"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "smart_goals", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "timeframe", null: false
    t.text "specific"
    t.text "measurable"
    t.text "achievable"
    t.text "relevant"
    t.text "time_bound"
    t.boolean "completed", default: false
    t.bigint "profile_id", null: false
    t.datetime "target_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_smart_goals_on_profile_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.boolean "completed", default: false
    t.integer "action_category", null: false
    t.bigint "profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "priority"
    t.bigint "smart_goal_id"
    t.index ["profile_id"], name: "index_tasks_on_profile_id"
    t.index ["smart_goal_id"], name: "index_tasks_on_smart_goal_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.string "kind", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "source", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_tickets_on_created_at"
    t.index ["kind"], name: "index_tickets_on_kind"
    t.index ["profile_id"], name: "index_tickets_on_profile_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "jti", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "ai_requests", "profiles"
  add_foreign_key "profiles", "users"
  add_foreign_key "smart_goals", "profiles"
  add_foreign_key "tasks", "profiles"
  add_foreign_key "tasks", "smart_goals"
  add_foreign_key "tickets", "profiles"
end
