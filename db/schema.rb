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

ActiveRecord::Schema[8.1].define(version: 2025_11_09_210004) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "credentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.string "nickname"
    t.text "public_key", null: false
    t.integer "sign_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["external_id"], name: "index_credentials_on_external_id", unique: true
    t.index ["user_id"], name: "index_credentials_on_user_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", null: false
    t.integer "program_id", null: false
    t.integer "repeat_count", null: false
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.index ["program_id", "position"], name: "index_exercises_on_program_id_and_position"
    t.index ["program_id"], name: "index_exercises_on_program_id"
  end

  create_table "programs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "uuid", null: false
    t.index ["user_id"], name: "index_programs_on_user_id"
    t.index ["uuid"], name: "index_programs_on_uuid", unique: true
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.text "auth_key", null: false
    t.datetime "created_at", null: false
    t.text "endpoint", null: false
    t.text "p256dh_key", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "reminders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "days_of_week", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "last_sent_at"
    t.integer "program_id", null: false
    t.time "time", null: false
    t.string "timezone", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["enabled"], name: "index_reminders_on_enabled"
    t.index ["program_id"], name: "index_reminders_on_program_id"
    t.index ["user_id"], name: "index_reminders_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.string "webauthn_id", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["webauthn_id"], name: "index_users_on_webauthn_id", unique: true
  end

  create_table "workouts", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "exercises_data"
    t.integer "program_id"
    t.string "program_title"
    t.datetime "started_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["program_id"], name: "index_workouts_on_program_id"
    t.index ["user_id"], name: "index_workouts_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "credentials", "users", on_delete: :cascade
  add_foreign_key "exercises", "programs", on_delete: :cascade
  add_foreign_key "programs", "users", on_delete: :cascade
  add_foreign_key "push_subscriptions", "users", on_delete: :cascade
  add_foreign_key "reminders", "programs", on_delete: :cascade
  add_foreign_key "reminders", "users", on_delete: :cascade
  add_foreign_key "workouts", "programs", on_delete: :nullify
  add_foreign_key "workouts", "users", on_delete: :cascade
end
