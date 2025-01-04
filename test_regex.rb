# frozen_string_literal: true

# ruby test_regex.rb

# 以下のコードは各パターンが動作しているか確認するサンプルです。

# The code snippet you provided is a Ruby script that tests various regular expression patterns
# against a set of test texts. Here's a breakdown of what the code does:

TEST_TEXTS = [
  'abc',
  "abc\n",
  'abcd',
  'Price: 100 yen',
  'color', 'colour',
  'hello',
  'foo', 'foobar',
  "foo\nbar",
  '2024-12-14',
  'abc def',
  '$250',
  '12-12'
].freeze

PATTERNS = [
  /a.b/,
  /^abc/,
  /abc$/,
  /\Aabc/,
  /abc\z/,
  /abc\Z/,
  /\bword\b/,
  /\Babc/,
  /[abc]/,
  /[^abc]/,
  /[0-9]/,
  /\d\d/,
  /\D/,
  /\w+/,
  /\W/,
  /\s*/,
  /\S+/,
  /a*/,
  /a+/,
  /colou?r/,
  /a{3}/,
  /a{2,}/,
  /a{2,4}/,
  /(abc)+/,
  /(?:abc){2}/,
  /(?<word>\w+)/,
  /(?<d>\d{2})-\k<d>/,
  /\d+(?=円)/,
  /foo(?!bar)/,
  /(?<=\$)\d+/,
  /(?<!\$)\d+/
].freeze

PATTERNS.each do |pat|
  puts "Pattern: #{pat}"
  TEST_TEXTS.each do |text|
    puts "  '#{text}' => #{text.match?(pat)}"
  end
  puts
end
