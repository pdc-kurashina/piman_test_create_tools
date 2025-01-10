ActiveRecord::Schema[7.0].define(version: 2025_01_08_063533) do
    create_table "customer_managers", charset: "utf8", force: :cascade do |t|
        t.integer "customer_id", null: false
        t.string "name", null: false
        t.string "department"
        t.string "phone_number"
        t.string "fax_number"
        t.string "tel"
        t.string "email"
        t.text "note"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
    end

    create_table "customers", id: :integer, charset: "utf8", force: :cascade do |t|
        t.string "name", limit: 100, null: false
        t.string "kana", limit: 200, null: false
        t.string "note", limit: 1000, default: "", null: false
        t.integer "created_user_id", null: false
        t.integer "updated_user_id", null: false
        t.datetime "created_at", precision: nil, null: false
        t.datetime "updated_at", precision: nil, null: false
        t.string "supplier", limit: 100
        t.boolean "cancelled", default: false
        t.integer "customer_type", null: false
        t.string "corporation_number", null: false
        t.string "transaction_type", null: false
        t.integer "initial_transaction_amount", null: false
        t.integer "business_category_detail_id", null: false
        t.integer "rating", null: false
        t.integer "credit_limit", null: false
        t.string "representative_name"
        t.json "directors"
        t.string "post_code", null: false
        t.string "address", null: false
        t.string "tel", null: false
        t.string "url"
        t.integer "capital"
        t.integer "list_division"
        t.date "establishment_day"
        t.integer "employee"
        t.integer "settling_month"
        t.integer "registration_certificate_attachment_file_id"
        t.integer "warning_company_count"
        t.integer "caution_company_count"
        t.integer "penalty_company_count"
    end
end