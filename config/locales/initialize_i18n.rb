# frozen_string_literal: true

require 'i18n'

module SettingI18n
  class SetI18n
    def self.set_i18n
      I18n.load_path << Dir["#{File.expand_path('config/locales')}/*.yml"]
      I18n.default_locale = :ja
    end

    def self.execute
      SetI18n.set_i18n unless I18n.default_locale == :ja
    end
  end
end
