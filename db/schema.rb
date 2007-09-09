# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 33) do

  create_table "compilers", :force => true do |t|
    t.column "display_name",   :string
    t.column "extension",      :string
    t.column "source_name",    :string
    t.column "platform",       :string
    t.column "compiler",       :string
    t.column "compiler_flags", :string
    t.column "binaries",       :string
    t.column "interpreter",    :string
  end

  create_table "contests", :force => true do |t|
    t.column "short_name",           :string
    t.column "name",                 :string
    t.column "reg_message",          :text
    t.column "display_name",         :string
    t.column "created_at",           :datetime
    t.column "updated_at",           :datetime
    t.column "registration_open",    :integer,  :default => 0, :null => false
    t.column "statements_available", :integer,  :default => 0, :null => false
    t.column "publicly_visible",     :integer,  :default => 0, :null => false
    t.column "state",                :integer,  :default => 0, :null => false
    t.column "ending_at",            :datetime
    t.column "welcome_message",      :text
    t.column "started_at",           :datetime
    t.column "team_members_count",   :integer
  end

  create_table "contests_forms", :force => true do |t|
    t.column "contest_id", :integer
    t.column "form_id",    :integer
  end

  create_table "cookies", :force => true do |t|
    t.column "owner_type", :string,   :default => "", :null => false
    t.column "owner_id",   :integer,                  :null => false
    t.column "text",       :string,   :default => "", :null => false
    t.column "created_at", :datetime,                 :null => false
    t.column "usage",      :string,   :default => "", :null => false
    t.column "expires_at", :datetime
  end

  create_table "entites", :force => true do |t|
    t.column "display_name", :string, :default => "", :null => false
  end

  create_table "fields", :force => true do |t|
    t.column "form_id",   :integer
    t.column "name",      :string
    t.column "data_type", :string
    t.column "choices",   :text
    t.column "required",  :boolean
    t.column "label",     :string
    t.column "comment",   :text
  end

  create_table "forms", :force => true do |t|
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "title",      :string
    t.column "comment",    :text
  end

  create_table "imagine_cup_recs", :force => true do |t|
    t.column "team_id",    :integer,  :null => false
    t.column "created_at", :datetime
  end

  create_table "languages", :force => true do |t|
    t.column "display_name", :string
    t.column "iso_code_2",   :string
  end

  create_table "members", :force => true do |t|
    t.column "team_id",     :integer,  :default => 0, :null => false
    t.column "first_name",  :string
    t.column "last_name",   :string
    t.column "middle_name", :string
    t.column "email",       :string
    t.column "year_id",     :integer
    t.column "faculty",     :string
    t.column "created_at",  :datetime
  end

  create_table "messages", :force => true do |t|
    t.column "text",       :text,     :default => "", :null => false
    t.column "contest_id", :integer,                  :null => false
    t.column "created_at", :datetime
    t.column "updates_at", :datetime
  end

  create_table "password_sets", :force => true do |t|
    t.column "principal_type", :string
    t.column "principal_id",   :string
    t.column "used",           :boolean
    t.column "reason",         :string
    t.column "created_at",     :datetime
  end

  create_table "passwords", :force => true do |t|
    t.column "text",            :string
    t.column "password_set_id", :string
  end

  create_table "per_member_values", :force => true do |t|
    t.column "member_id", :integer
    t.column "field_id",  :integer
    t.column "value",     :string
  end

  create_table "problems", :force => true do |t|
    t.column "contest_id",     :integer
    t.column "name",           :string
    t.column "display_name",   :string
    t.column "input_file",     :string
    t.column "output_file",    :string
    t.column "check_method",   :integer,  :default => 2,    :null => false
    t.column "scoring_method", :string,   :default => "",   :null => false
    t.column "time_limit",     :integer
    t.column "memory_limit",   :string
    t.column "letter",         :string
    t.column "available",      :boolean,  :default => true
    t.column "created_at",     :datetime
    t.column "updated_at",     :datetime
  end

  create_table "questions", :force => true do |t|
    t.column "contest_id",             :integer,                  :null => false
    t.column "team_id",                :integer
    t.column "question",               :text,     :default => "", :null => false
    t.column "answer",                 :text
    t.column "visible_for_all_teams",  :boolean
    t.column "visible_for_spectators", :boolean
    t.column "asked_at",               :datetime
    t.column "answered_at",            :datetime
  end

  create_table "rating_definitions", :force => true do |t|
    t.column "contest_id",      :integer,                  :null => false
    t.column "scope_type",      :string,   :default => "", :null => false
    t.column "parent_scope_id", :integer
    t.column "options",         :text,     :default => "", :null => false
    t.column "created_at",      :datetime,                 :null => false
    t.column "updated_at",      :datetime,                 :null => false
  end

  create_table "ratings", :force => true do |t|
    t.column "rating_definition_id", :integer,  :null => false
    t.column "item_id",              :integer
    t.column "value",                :text
    t.column "created_at",           :datetime, :null => false
    t.column "updated_at",           :datetime, :null => false
  end

  create_table "run_tests", :force => true do |t|
    t.column "run_id",         :integer
    t.column "run_at",         :datetime
    t.column "test_ord",       :integer
    t.column "outcome",        :string
    t.column "partial_answer", :string
    t.column "points",         :string
  end

  create_table "runs", :force => true do |t|
    t.column "team_id",           :integer
    t.column "problem_id",        :integer
    t.column "submitted_at",      :datetime
    t.column "file_name",         :string
    t.column "compiler_id",       :integer
    t.column "state",             :integer
    t.column "state_assigned_at", :datetime
    t.column "outcome",           :string
    t.column "test_outcomes",     :string
    t.column "details",           :text
    t.column "points",            :integer
    t.column "origin_info",       :string
    t.column "submittion_id",     :integer
    t.column "penalty_time",      :integer
  end

  create_table "samsung_forms", :force => true do |t|
    t.column "member_id",       :integer
    t.column "fname",           :string
    t.column "pname",           :string
    t.column "sname",           :string
    t.column "gender",          :string
    t.column "birth_date",      :date
    t.column "birth_place",     :string
    t.column "marital_status",  :string
    t.column "children",        :string
    t.column "mailing_address", :string
    t.column "home_phone",      :string
    t.column "work_phone",      :string
    t.column "mobile_phone",    :string
    t.column "email",           :string
    t.column "edu_spec",        :string
    t.column "edu_period",      :string
    t.column "edu_university",  :string
    t.column "edu_courses",     :string
    t.column "edu_awards",      :string
    t.column "created_at",      :datetime
  end

  create_table "statements", :force => true do |t|
    t.column "cookie",     :string
    t.column "filename",   :string
    t.column "problem_id", :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "submittions", :force => true do |t|
    t.column "problem_id",        :integer
    t.column "team_id",           :integer
    t.column "compiler_id",       :integer
    t.column "submitted_at",      :datetime
    t.column "file_name",         :string
    t.column "state",             :integer
    t.column "state_assigned_at", :datetime
    t.column "created_at",        :datetime
  end

  create_table "teams", :force => true do |t|
    t.column "name",             :string,   :default => "", :null => false
    t.column "email",            :string
    t.column "coach_names",      :string
    t.column "coach_email",      :string
    t.column "university_id",    :integer
    t.column "contest_id",       :integer
    t.column "last_login_at",    :datetime
    t.column "password_sent_at", :datetime
    t.column "created_at",       :datetime
    t.column "form_data",        :text
  end

  create_table "testing_queues", :force => true do |t|
  end

  create_table "tests", :force => true do |t|
    t.column "problem_id",  :integer
    t.column "position",    :integer
    t.column "input_file",  :string
    t.column "answer_file", :string
  end

  create_table "tests_uploads", :force => true do |t|
    t.column "problem_id",        :integer
    t.column "filename",          :string
    t.column "original_filename", :string
    t.column "state",             :integer
    t.column "message",           :text
    t.column "created_at",        :datetime
    t.column "updated_at",        :datetime
    t.column "contest_id",        :integer,  :null => false
  end

  create_table "universities", :force => true do |t|
    t.column "name",                  :string
    t.column "city",                  :string
    t.column "address",               :string
    t.column "zip",                   :string
    t.column "person_for_invitation", :string
    t.column "created_at",            :datetime
  end

  create_table "users", :force => true do |t|
    t.column "first_name",    :string
    t.column "last_name",     :string
    t.column "middle_name",   :string
    t.column "position",      :string
    t.column "email",         :string
    t.column "password_id",   :integer
    t.column "last_login_at", :datetime
    t.column "created_at",    :datetime
  end

end
