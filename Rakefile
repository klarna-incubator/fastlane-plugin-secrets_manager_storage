require "bundler/gem_tasks"

desc "Formats everything with prettier"
task :prettier do
  sh "./node_modules/.bin/prettier --write '**/*.json' '**/*.rb' '**/*.md' Gemfile Rakefile **/Fastfile .prettierrc"
end
