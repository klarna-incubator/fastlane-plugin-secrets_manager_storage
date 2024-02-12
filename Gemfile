source("https://rubygems.org")

gem "fastlane", ">= 2.219.0"
gem "pry"
gem "rake"
gem "rspec"
gem "rspec_junit_formatter"
gem "simplecov"

# Necessary gems for prettier formatting
gem "prettier_print"
gem "syntax_tree"
gem "syntax_tree-haml"
gem "syntax_tree-rbs"

gemspec

plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
