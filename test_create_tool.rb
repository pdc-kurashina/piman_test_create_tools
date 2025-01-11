# frozen_string_literal: true

require 'yaml'
require 'csv'
require 'i18n'

require './config/create_test_settings/setting_test_create_tool'
require './config/create_test_settings/set_application_settings'
require './config/locales/initialize_i18n'

# テスト作成ツールの設定を行うクラス
class SetCreateTestToolSetting
  include SettingTestCreateTool
  include SetApplicationSettings
  include SettingI18n

  SettingI18n::SetI18n.execute

  # ファイルパスを取得
  paths = SettingTestCreateTool.set_paths
  ::YAML_PATH = paths[:yml_path]
  ::CSV_PATH = paths[:csv_path]
  ::FORM_ITEMS_YML_PATH = paths[:form_items_yml_path]

  # オプションパラメータで指定された機能名・画面名・バージョンを取得
  options = SettingTestCreateTool.set_options
  ::OPTION_PARAMS = [options[:f], options[:d], options[:v]].freeze

  # 試験対象のアプリケーションの名前を取得
  ::APP_NAME = SetApplicationSettings.set_application_name

  # 試験でデフォルトで試験を行うユーザータイプを取得
  ::DEFAULT_TEST_USER = SetApplicationSettings.default_test_user
  ::DEFAULT_SUB_TEST_USER_MAP = SetApplicationSettings.default_sub_test_user_map

  # テスト対象の機能名と日本語名のハッシュ
  ::FUNCTION_NAME_HASH = SetApplicationSettings.set_function_name_hash

  # テスト対象の機能名と左メニュー、顧客タブ、設置先タブの表示有無のハッシュ
  ::FUNCTION_LEFT_MENU_HASH = SetApplicationSettings.set_function_left_menu_hash
  ::FUNCTION_CUSTOMER_TAB_HASH = SetApplicationSettings.set_function_customer_tab_hash
  ::FUNCTION_PLACE_TAB_HASH = SetApplicationSettings.set_function_place_tab_hash

  # ユーザータイプと日本語名のハッシュ
  ::USER_TYPE_ARRAY = SetApplicationSettings.set_user_type_array
end

module CommonTools
  def combine_text(args)
    args.join('<br>')
  end
end

# ユーザごとのアクセス権限データの取得
class GetPermissions
  def self.get_permissions(yml_path)
    data = YAML.load_file(yml_path)
    data['permissions']
  end
end

class GetFormItems
  def self.get_form_items(yml_path, function_name)
    data = YAML.load_file(yml_path)
    form_items_data = data[function_name]
    form_items_data_array = []
    if data[function_name].nil?
      DEFAULT_SUB_TEST_USER_MAP.each do |f_key, f_value|
        next unless f_key.include?(function_name)

        f_value.each do |key, value|
          if key.include?(function_name)
            form_items_data = { login_user: value, data: data[key] }
            form_items_data_array << form_items_data
          end
        end
      end
    else
      form_items_data_array << { login_user: '', data: form_items_data }
    end
    form_items_data_array
  end
end

class CreateValidationTest
  include CommonTools

  def generate_validation_test(yml_path, option_params, fixed_precondition_text)
    form_items_data_array = GetFormItems.get_form_items(yml_path, option_params[0])

    validation_test_array = []

    form_items_data_array.each do |form_items_data|
      login_user = form_items_data[:login_user]
      case option_params[1]
      when I18n.t('display.new'), I18n.t('display.duplicate')
        form_items_data[:data].each_value do |value|
          validation_test_array << new_validate_test_spec(login_user, value, fixed_precondition_text, option_params)
        end
      when I18n.t('display.edit')
        form_items_data[:data].each_value do |value|
          validation_test_array << edit_validate_test_spec(login_user, value, fixed_precondition_text, option_params)
        end
      end
    end
    validation_test_array
  end

  private

  def new_validate_test_spec(login_user, value, fixed_precondition_text, option_params)
    display_login_user = login_user.empty? ? I18n.t('user.maintenance') : login_user
    fixed_precondition_text = fixed_precondition_text.gsub('#$%&#$%&', display_login_user)
    base_array = [I18n.t('section.new_validation'), value['call'], fixed_precondition_text, '', '', '',
                  option_params[2]]
    if value['require'] == true
      require_true_test(base_array, value, option_params, 'create')
    elsif value['require'] == 'case'
      require_case_test(base_array, value, option_params, 'create')
    else
      require_false_test(base_array, value, option_params, 'create')
    end
    base_array
  end

  def edit_validate_test_spec(login_user, value, fixed_precondition_text, option_params)
    display_login_user = login_user.empty? ? I18n.t('user.maintenance') : login_user
    fixed_precondition_text = fixed_precondition_text.gsub('#$%&#$%&', display_login_user)
    base_array = [I18n.t('section.edit_validation'), value['call'], fixed_precondition_text, '', '', '',
                  option_params[2]]
    if value['require'] == true
      require_true_test(base_array, value, option_params, 'update')
    elsif value['require'] == 'case'
      require_case_test(base_array, value, option_params, 'update')
    else
      require_false_test(base_array, value, option_params, 'update')
    end
    base_array
  end

  def require_true_test(base_array, value, _option_params, action_name)
    base_array[4] =
      combine_text([I18n.t('step.input_presence', num: '1', button_name: I18n.t("button.#{action_name}"),
                                                  field_name: value['call'])])
    base_array[5] = combine_text([I18n.t('result.input_error', num: '1')])
  end

  def require_case_test(base_array, value, option_params, action_name)
    cases = value['case'].split(',')
    cases.each do |a_case|
      case_condition, case_require = a_case.split('場合は、')
      case_condition = case_condition.chop if case_condition[-1] == 'の'
      base_array[4] =
        combine_text([I18n.t('step.input_case_presence', num: '1', button_name: I18n.t("button.#{action_name}"),
                                                         case_condition: case_condition, field_name: value['call'])])
      if case_require == I18n.t('label.required')
        base_array[5] = combine_text([I18n.t('result.input_error', num: '1')])
      else
        base_array[5] =
          combine_text([I18n.t('result.input_success', num: '1', button_name: I18n.t("button.#{action_name}"),
                                                       function_name: FUNCTION_NAME_HASH[option_params[0]])])
      end
    end
  end

  def require_false_test(base_array, value, option_params, action_name)
    base_array[4] =
      combine_text([I18n.t('step.input_presence', num: '1', button_name: I18n.t("button.#{action_name}"),
                                                  field_name: value['call'])])
    base_array[5] =
      combine_text([I18n.t('result.input_success', num: '1', button_name: I18n.t("button.#{action_name}"),
                                                   function_name: FUNCTION_NAME_HASH[option_params[0]])])
  end
end

class CreateTest
  include CommonTools

  # テスト仕様書を生成するメソッド
  def generate_test_spec(yml_path, csv_path, form_items_yml_path, option_params)
    permissions_data = GetPermissions.get_permissions(yml_path)

    menu_tab_array = get_menu_tab_array(option_params)

    fixed_precondition_text = generate_fixed_precondition_text(option_params)

    login_users = get_login_users(option_params)

    csv_headers = %w[セクション タイトル 前提条件 備考 手順 期待する結果 対応バージョン]
    CSV.open(csv_path, 'w', write_headers: true, headers: csv_headers) do |csv|
      menu_tab_array.each_with_index do |is_creatable, order|
        next unless is_creatable

        USER_TYPE_ARRAY.each do |user_type|
          csv << display_test_spec(user_type, option_params, menu_tab_array, order, permissions_data)
        end

        case option_params[1]
        when I18n.t('display.new')
          new_test_spec(csv, option_params, fixed_precondition_text, login_users)
        when I18n.t('display.duplicate')
          duplicate_test_spec(csv, option_params, fixed_precondition_text, login_users)
        when I18n.t('display.edit')
          edit_test_spec(csv, option_params, fixed_precondition_text, login_users)
          generate_destroy(csv, option_params[0], option_params[2])
        end

        add_validation_test_spec(csv, form_items_yml_path, option_params, fixed_precondition_text)
      end
    end
  end

  private

  def get_login_users(option_params)
    login_users = []
    DEFAULT_SUB_TEST_USER_MAP.each do |f_key, f_value|
      next unless f_key.include?(option_params[0])

      f_value.each do |key, value|
        login_users << value if key.include?(option_params[0])
      end
    end
    login_users << DEFAULT_TEST_USER if login_users.empty?
    login_users
  end

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

  def generate_fixed_precondition_text(option_params)
    precondition_text = [
      I18n.t('precondition.login', app_name: APP_NAME, test_user: '#$%&#$%&'),
      I18n.t('precondition.display', function_name: FUNCTION_NAME_HASH[option_params[0]],
                                     display_name: option_params[1])
    ]
    combine_text(precondition_text)
  end

  def display_test_spec(user_type, option_params, menu_tab_array, order, permissions_data)
    [
      I18n.t('section.display'), user_type.values.first,
      generate_precondition(user_type, option_params[0], option_params[1], menu_tab_array, order), '',
      generate_step(option_params[0], option_params[1], menu_tab_array, order),
      generate_result(option_params[0], option_params[1],
                      permissions_data[user_type.keys.first.to_s][option_params[0]]),
      option_params[2]
    ]
  end

  def new_test_spec(csv, option_params, fixed_precondition_text, login_users)
    login_users.each do |login_user|
      csv << [
        option_params[1], I18n.t('title.create'),
        "#{fixed_precondition_text.gsub('#$%&#$%&', login_user)}#{I18n.t('precondition.before_create_data')}", '',
        combine_text([I18n.t('step.input', num: '1', button_name: I18n.t('button.create')),
                      I18n.t('step.click_button', num: '2', button_name: I18n.t('button.cancel'))]),
        combine_text([I18n.t('result.input_success', num: '1', button_name: I18n.t('button.create'),
                                                     function_name: FUNCTION_NAME_HASH[option_params[0]]),
                      I18n.t('result.create_input_check', num: '2',
                                                          function_name: FUNCTION_NAME_HASH[option_params[0]])]),
        option_params[2]
      ]
    end
  end

  def duplicate_test_spec(csv, option_params, fixed_precondition_text, login_users)
    login_users.each do |login_user|
      csv << [
        option_params[1], I18n.t('title.create'),
        "#{fixed_precondition_text.gsub('#$%&#$%&', login_user)}#{I18n.t('precondition.before_create_data')}", '',
        combine_text([I18n.t('step.input', num: '1', button_name: I18n.t('button.duplicate')),
                      I18n.t('step.click_button', num: '2', button_name: I18n.t('button.cancel'))]),
        combine_text([I18n.t('result.input_success', num: '1', button_name: I18n.t('button.create'),
                                                     function_name: FUNCTION_NAME_HASH[option_params[0]]),
                      I18n.t('result.duplicate_input_check', num: '2',
                                                             function_name: FUNCTION_NAME_HASH[option_params[0]])]),
        option_params[2]
      ]
    end
  end

  def edit_test_spec(csv, option_params, fixed_precondition_text, login_users)
    login_users.each do |login_user|
      csv << [
        option_params[1], I18n.t('title.update'),
        "#{fixed_precondition_text.gsub('#$%&#$%&', login_user)}#{I18n.t('precondition.before_create_data')}", '',
        combine_text([I18n.t('step.input', num: '1', button_name: I18n.t('button.update')),
                      I18n.t('step.click_button', num: '2', button_name: I18n.t('button.cancel'))]),
        combine_text([I18n.t('result.input_success', num: '1', button_name: I18n.t('button.update'),
                                                     function_name: FUNCTION_NAME_HASH[option_params[0]]),
                      I18n.t('result.update_input_check', num: '2',
                                                          function_name: FUNCTION_NAME_HASH[option_params[0]])]),
        option_params[2]
      ]
    end
  end

  # テスト仕様書の前提条件を生成するメソッド（表示の場合）
  def generate_precondition(user_type, function_name, display_name, menu_tab_array, order)
    fixed_precondition_text = I18n.t('precondition.login', app_name: APP_NAME, test_user: user_type.values.first)
    precondition_display_text = "#{FUNCTION_NAME_HASH[function_name]}の#{precondition_display(display_name)}に遷移していること。"
    case display_name
    when I18n.t('display.index')
      precondition_index(order, menu_tab_array, fixed_precondition_text, precondition_display_text)
    when I18n.t('display.new'), I18n.t('display.duplicate'), I18n.t('display.edit')
      precondition_other_than_index(order, menu_tab_array, fixed_precondition_text, precondition_display_text)
    end
  end

  def precondition_index(order, menu_tab_array, fixed_precondition_text, precondition_display_text)
    if order.zero? && menu_tab_array[0]
      "#{fixed_precondition_text}#{precondition_display_text}"
    elsif order == 1 && menu_tab_array[1]
      "#{fixed_precondition_text}#{I18n.t('precondition.moved_customer_show')}"
    elsif order == 2 && menu_tab_array[2]
      "#{fixed_precondition_text}#{I18n.t('precondition.moved_place_show')}"
    end
  end

  def precondition_other_than_index(order, menu_tab_array, fixed_precondition_text, precondition_display_text)
    base_text = fixed_precondition_text
    if order.zero? && menu_tab_array[0]
      base_text += "#{precondition_display_text}#{I18n.t('precondition.before_create_data')}"
    elsif order == 1 && menu_tab_array[1]
      base_text += "#{I18n.t('precondition.moved_customer_show')}#{I18n.t('precondition.before_create_data')}"
    elsif order == 2 && menu_tab_array[2]
      base_text += "#{I18n.t('precondition.moved_place_show')}#{I18n.t('precondition.before_create_data')}"
    end
    base_text
  end

  # テスト仕様書の前提条件で予めどこへ遷移しているべきかを返すメソッド
  def precondition_display(display_name)
    case display_name
    when I18n.t('display.index')
      I18n.t('display.dashboard')
    when I18n.t('display.new'), I18n.t('display.duplicate'), I18n.t('display.show')
      I18n.t('display.index')
    when I18n.t('display.edit')
      I18n.t('display.show')
    end
  end

  # テスト仕様書の手順を生成するメソッド
  def generate_step(function_name, display_name, menu_tab_array, order)
    case display_name
    when I18n.t('display.show')
      step_for_view
    when I18n.t('display.new'), I18n.t('display.duplicate'), I18n.t('display.edit')
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
    I18n.t('step.click_record', num: '1')
  end

  def step_for_click_button(display_name)
    I18n.t('step.click_button', num: '1', button_name: display_name)
  end

  def step_for_left_menu(function_name)
    I18n.t('step.click_left_menu', num: '1', function_name: FUNCTION_NAME_HASH[function_name])
  end

  def step_for_tab_click(function_name)
    I18n.t('step.click_tab_menu', num: '1', function_name: FUNCTION_NAME_HASH[function_name])
  end

  # テスト仕様書の期待する結果を生成するメソッド
  def generate_result(function_name, display_name, permissions)
    if display_name == '一覧' && !readable?(permissions)
      return I18n.t('result.not_left_menu', num: '1',
                                            function_name: FUNCTION_NAME_HASH[function_name])
    end

    if [I18n.t('display.new'), I18n.t('display.duplicate')].include?(display_name) && !writable?(permissions)
      return I18n.t('result.not_exist_button', num: '1', button_name: I18n.t('button.new'))
    end

    if display_name == I18n.t('display.edit') && !writable?(permissions)
      return I18n.t('result.not_exist_button', num: '1', button_name: I18n.t('button.edit'))
    end

    I18n.t('result.move_display', num: '1', function_name: FUNCTION_NAME_HASH[function_name],
                                  display_name: display_name)
  end

  def readable?(permissions)
    permissions.include?('read') || permissions.include?('limit_read') ? true : false
  end

  def writable?(permissions)
    permissions.include?('write') || permissions.include?('limit_write') ? true : false
  end

  # 編集画面での削除の試験を生成するメソッド
  def generate_destroy(csv, function_name, version)
    precondition_text = [
      I18n.t('precondition.login', app_name: APP_NAME, test_user: DEFAULT_TEST_USER),
      I18n.t('precondition.display', function_name: FUNCTION_NAME_HASH[function_name],
                                     display_name: I18n.t('display.edit'))
    ]
    fixed_precondition_text = combine_text(precondition_text)
    csv << add_delete_confirm_modal(fixed_precondition_text, version)
    csv << add_delete_cancel(function_name, fixed_precondition_text, version)
    csv << add_delete_execute(function_name, fixed_precondition_text, version)
  end

  def add_delete_confirm_modal(fixed_precondition_text, version)
    [
      I18n.t('section.delete'), I18n.t('title.delete_confirm_modal'), fixed_precondition_text, '',
      combine_text([I18n.t('step.click_delete_button', num: '1')]),
      combine_text([I18n.t('result.open_delete_confirm_modal', num: '1')]),
      version
    ]
  end

  def add_delete_cancel(function_name, fixed_precondition_text, version)
    [
      I18n.t('section.delete'), I18n.t('title.delete_cancel'), fixed_precondition_text, '',
      combine_text([I18n.t('step.click_delete_button', num: '1'), I18n.t('step.click_cancel_button', num: '2'),
                    I18n.t('step.click_cancel_button_double', num: '3')]),
      combine_text([I18n.t('result.open_delete_confirm_modal', num: '1'),
                    I18n.t('result.close_delete_confirm_modal', num: '2'),
                    I18n.t('result.delete_cancel', num: '3', function_name: FUNCTION_NAME_HASH[function_name])]),
      version
    ]
  end

  def add_delete_execute(function_name, fixed_precondition_text, version)
    [
      I18n.t('section.delete'), I18n.t('title.delete'), fixed_precondition_text, '',
      combine_text([I18n.t('step.click_delete_button', num: '1'), I18n.t('step.click_delete_button', num: '2')]),
      combine_text([I18n.t('result.open_delete_confirm_modal', num: '1'),
                    I18n.t('result.delete_success', num: '2', function_name: FUNCTION_NAME_HASH[function_name])]),
      version
    ]
  end

  def add_validation_test_spec(csv, form_items_yml_path, option_params, fixed_precondition_text)
    validation_test_array = CreateValidationTest.new.generate_validation_test(form_items_yml_path, option_params,
                                                                              fixed_precondition_text)
    validation_test_array.each do |validation_test|
      csv << validation_test
    end
  end
end

CreateTest.new.generate_test_spec(YAML_PATH, CSV_PATH, FORM_ITEMS_YML_PATH, OPTION_PARAMS)
