# frozen_string_literal: true

require 'yaml'
require 'csv'
require 'optparse'

require './setting_test_create_tool'
require './set_application_settings'

class SetCreateTestToolSetting
  include SettingTestCreateTool
  include SetApplicationSettings

  # ファイルパスを取得
  paths = SettingTestCreateTool.set_paths
  ::YAML_PATH = paths[:yml_path]
  ::CSV_PATH = paths[:csv_path]

  # オプションパラメータで指定された機能名・画面名・バージョンを取得
  options = SettingTestCreateTool.set_options
  ::OPTION_PARAMS = [options[:f], options[:d], options[:v]].freeze

  # 試験対象のアプリケーションの名前を取得
  ::APP_NAME = SetApplicationSettings.set_application_name

  # 試験でデフォルトで試験を行うユーザータイプを取得
  ::DEFAULT_TEST_USER = SetApplicationSettings.default_test_user

  # テスト対象の機能名と日本語名のハッシュ
  ::FUNCTION_NAME_HASH = SetApplicationSettings.set_function_name_hash

  # テスト対象の機能名と左メニュー、顧客タブ、設置先タブの表示有無のハッシュ
  ::FUNCTION_LEFT_MENU_HASH = SetApplicationSettings.set_function_left_menu_hash
  ::FUNCTION_CUSTOMER_TAB_HASH = SetApplicationSettings.set_function_customer_tab_hash
  ::FUNCTION_PLACE_TAB_HASH = SetApplicationSettings.set_function_place_tab_hash

  # ユーザータイプと日本語名のハッシュ
  ::USER_TYPE_ARRAY = SetApplicationSettings.set_user_type_array
end

# ユーザごとのアクセス権限データの取得
class GetPermissions
  def self.get_permissions(yml_path)
    data = YAML.load_file(yml_path)
    data['permissions']
  end
end

class CreateTest
  # テスト仕様書を生成するメソッド
  def generate_test_spec(yml_path, csv_path, option_params)
    permissions_data = GetPermissions.get_permissions(yml_path)

    menu_tab_array = get_menu_tab_array(option_params)

    csv_headers = %w[セクション タイトル 前提条件 備考 手順 期待する結果 対応バージョン]
    CSV.open(csv_path, 'w', write_headers: true, headers: csv_headers) do |csv|
      menu_tab_array.each_with_index do |is_creatable, order|
        next unless is_creatable

        USER_TYPE_ARRAY.each do |user_type|
          csv << display_test_spec(user_type, option_params, menu_tab_array, order, permissions_data)
        end

        precondition_text = [
          "#{APP_NAME}に#{DEFAULT_TEST_USER}でログインしていること。",
          "#{FUNCTION_NAME_HASH[option_params[0]]}の#{option_params[1]}画面へ遷移していること。"
        ]
        fixed_precondition_text = combine_text(precondition_text)
        case option_params[1]
        when '新規登録'
          csv << new_test_spec(option_params, fixed_precondition_text)
        when '複製'
          csv << duplicate_test_spec(option_params, fixed_precondition_text)
        when '編集'
          csv << edit_test_spec(option_params, fixed_precondition_text)
          generate_destroy(csv, option_params[0], option_params[2])
        end
      end
    end
  end

  private

  def get_menu_tab_array(option_params)
    is_left_menu =    left_menu?(FUNCTION_LEFT_MENU_HASH, option_params[0])
    is_customer_tab = customer_tab?(FUNCTION_CUSTOMER_TAB_HASH, option_params[0])
    is_place_tab =    place_tab?(FUNCTION_PLACE_TAB_HASH, option_params[0])

    exit if !is_left_menu && !is_customer_tab && !is_place_tab

    [is_left_menu, is_customer_tab, is_place_tab]
  end

  def left_menu?(hash, function_name)
    hash[function_name]
  end

  def customer_tab?(hash, function_name)
    hash[function_name]
  end

  def place_tab?(hash, function_name)
    hash[function_name]
  end

  def display_test_spec(user_type, option_params, menu_tab_array, order, permissions_data)
    [
      '表示', user_type.values.first,
      generate_precondition(user_type, option_params[0], option_params[1], menu_tab_array, order), '',
      generate_step(option_params[0], option_params[1], menu_tab_array, order),
      generate_result(option_params[0], option_params[1],
                      permissions_data[user_type.keys.first.to_s][option_params[0]]),
      option_params[2]
    ]
  end

  def new_test_spec(option_params, fixed_precondition_text)
    [
      option_params[1], '登録', "#{fixed_precondition_text}備考の表をもとにデータを登録していること。", '',
      combine_text(['1. 備考の表に沿ってデータを入力し、「登録」ボタンをクリックする。', '2. 「キャンセル」ボタンをクリックする。']),
      combine_text(["1. 正常に登録され、#{FUNCTION_NAME_HASH[option_params[0]]}閲覧画面へ遷移すること。このとき、入力した内容が表示されていること。",
                    "2. #{FUNCTION_NAME_HASH[option_params[0]]}一覧画面へ遷移すること。このとき、登録したデータが一覧テーブルに表示されていること。"]),
      option_params[2]
    ]
  end

  def duplicate_test_spec(option_params, fixed_precondition_text)
    [
      option_params[1], '登録', "#{fixed_precondition_text}備考の表をもとにデータを登録していること。", '',
      combine_text(['1. 備考の表に沿ってデータを入力し、「複製」ボタンをクリックする。', '2. 「キャンセル」ボタンをクリックする。']),
      combine_text(
        [
          "1. 正常に登録され、#{FUNCTION_NAME_HASH[option_params[0]]}閲覧画面へ遷移すること。このとき、入力した内容が表示されていること。",
          "2. #{FUNCTION_NAME_HASH[option_params[0]]}一覧画面へ遷移すること。このとき、複製元のデータと複製したデータが一覧テーブルに表示されていること。"
        ]
      ),
      option_params[2]
    ]
  end

  def edit_test_spec(option_params, fixed_precondition_text)
    [
      option_params[1], '更新', "#{fixed_precondition_text}備考の表をもとにデータを登録していること。", '',
      combine_text(['1. 備考の表に沿ってデータを入力し、「更新」ボタンをクリックする。', '2. 「キャンセル」ボタンをクリックする。']),
      combine_text(["1. 正常に登録され、#{FUNCTION_NAME_HASH[option_params[0]]}閲覧画面へ遷移すること。このとき、入力した内容が表示されていること。",
                    "2. #{FUNCTION_NAME_HASH[option_params[0]]}一覧画面へ遷移すること。このとき、更新したデータが一覧テーブルに表示されていること。"]),
      option_params[2]
    ]
  end

  # テスト仕様書の前提条件を生成するメソッド（表示の場合）
  def generate_precondition(user_type, function_name, display_name, menu_tab_array, order)
    fixed_precondition_text = "#{APP_NAME}に#{user_type.values.first}でログインしていること。"
    precondition_display_text = "#{FUNCTION_NAME_HASH[function_name]}の#{precondition_display(display_name)}に遷移していること。"
    case display_name
    when '一覧'
      precondition_index(order, menu_tab_array, fixed_precondition_text, precondition_display_text)
    when '新規登録', '複製', '編集'
      precondition_other_than_index(order, menu_tab_array, fixed_precondition_text, precondition_display_text)
    end
  end

  def precondition_index(order, menu_tab_array, fixed_precondition_text, precondition_display_text)
    if order.zero? && menu_tab_array[0]
      "#{fixed_precondition_text}#{precondition_display_text}"
    elsif order == 1 && menu_tab_array[1]
      "#{fixed_precondition_text}顧客閲覧画面に遷移していること。"
    elsif order == 2 && menu_tab_array[2]
      "#{fixed_precondition_text}設置先閲覧画面に遷移していること。"
    end
  end

  def precondition_other_than_index(order, menu_tab_array, fixed_precondition_text, precondition_display_text)
    if order.zero? && menu_tab_array[0]
      "#{fixed_precondition_text}#{precondition_display_text}備考の表をもとにデータを登録していること。"
    elsif order == 1 && menu_tab_array[1]
      "#{fixed_precondition_text}顧客閲覧画面に遷移していること。備考の表をもとにデータを登録していること。"
    elsif order == 2 && menu_tab_array[2]
      "#{fixed_precondition_text}設置先閲覧画面に遷移していること。備考の表をもとにデータを登録していること。"
    end
  end

  # テスト仕様書の前提条件で予めどこへ遷移しているべきかを返すメソッド
  def precondition_display(display_name)
    case display_name
    when '一覧'
      'ダッシュボード'
    when '新規登録', '複製', '閲覧'
      '一覧画面'
    when '編集'
      '閲覧'
    end
  end

  # テスト仕様書の手順を生成するメソッド
  def generate_step(function_name, display_name, menu_tab_array, order)
    case display_name
    when '閲覧'
      step_for_view
    when '新規登録', '複製', '編集'
      step_for_click_button(display_name)
    else
      # display_name が「閲覧」「新規登録」「複製」「編集」以外の場合
      case order
      when 0
        step_for_left_menu(function_name) if menu_tab_array[0]
      when 1, 2
        step_for_tab_click(function_name) if menu_tab_array[order]
      end
    end
  end

  def step_for_view
    '1. 予め登録しておいたデータの行をクリックする。'
  end

  def step_for_click_button(display_name)
    "1. 「#{display_name}」ボタンをクリックする。"
  end

  def step_for_left_menu(function_name)
    "1. 左メニューの「#{FUNCTION_NAME_HASH[function_name]}」をクリックする。"
  end

  def step_for_tab_click(function_name)
    "1. 「#{FUNCTION_NAME_HASH[function_name]}」タブをクリックする。"
  end

  # テスト仕様書の期待する結果を生成するメソッド
  def generate_result(function_name, display_name, permissions)
    return "1. 左メニューに#{FUNCTION_NAME_HASH[function_name]}が存在していないこと。" if display_name == '一覧' && !readable?(permissions)

    return '1. 「新規登録」ボタンが存在していないこと。' if %w[新規登録 複製 編集].include?(display_name) && !writable?(permissions)

    "1. #{FUNCTION_NAME_HASH[function_name]}#{display_name}画面へ遷移すること。"
  end

  def readable?(permissions)
    permissions.include?('read') || permissions.include?('limit_read') ? true : false
  end

  def writable?(permissions)
    permissions.include?('write') || permissions.include?('limit_write') ? true : false
  end

  # 編集画面での削除の試験を生成するメソッド
  def generate_destroy(csv, function_name, version)
    precondition_text =
      "#{APP_NAME}に#{DEFAULT_TEST_USER}でログインしていること。#{FUNCTION_NAME_HASH[function_name]}の編集画面へ遷移していること。"
    csv << [
      '削除', '削除確認モーダル表示', precondition_text, '',
      combine_text(['1. 「削除」ボタンをクリックする。']),
      combine_text(['1. 削除確認モーダルが表示されること。']),
      version
    ]
    csv << [
      '削除', '削除キャンセル', precondition_text, '',
      combine_text(['1. 「削除」ボタンをクリックする。', '2. 「キャンセル」ボタンをクリックする。', '3. 「キャンセル」ボタンを2回クリックする。']),
      combine_text(['1. 削除確認モーダルが表示されること。', '2. 削除確認モーダルが閉じること。',
                    "3. #{FUNCTION_NAME_HASH[function_name]}一覧画面へ遷移すること。このとき、削除対象のデータが存在していること。"]),
      version
    ]
    csv << [
      '削除', '削除', precondition_text, '',
      combine_text(['1. 「削除」ボタンをクリックする。', '2. 「削除」ボタンをクリックする。']),
      combine_text(['1. 削除確認モーダルが表示されること。',
                    "2. 削除が実行され、#{FUNCTION_NAME_HASH[function_name]}一覧画面へ遷移すること。このとき、削除対象のデータが存在していないこと。"]),
      version
    ]
  end

  def combine_text(args)
    args.join('<br>')
  end
end

CreateTest.new.generate_test_spec(YAML_PATH, CSV_PATH, OPTION_PARAMS)
