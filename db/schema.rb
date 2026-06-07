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

ActiveRecord::Schema[8.1].define(version: 2026_06_07_144554) do
  create_table "document_nodes", id: :string, force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "document_id", null: false
    t.integer "heading_level"
    t.json "meta"
    t.string "node_id"
    t.string "node_type", null: false
    t.string "parent_id"
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_document_nodes_on_document_id"
    t.index ["parent_id"], name: "index_document_nodes_on_parent_id"
  end

  create_table "documents", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "file_path", null: false
    t.string "file_type", default: "markdown", null: false
    t.datetime "last_modified_at"
    t.datetime "last_opened_at"
    t.integer "size"
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["file_path"], name: "index_documents_on_file_path", unique: true
  end

  add_foreign_key "document_nodes", "document_nodes", column: "parent_id"
  add_foreign_key "document_nodes", "documents"
end
