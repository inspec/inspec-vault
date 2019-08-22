# A Rakefile defines tasks to help maintain your project.
# Rake provides several task templates that are useful.


# This task template will make a task named 'test', and run
# the tests that it finds.
require "rake/testtask"

namespace(:test) do
  #------------------------------------------------------------------#
  #                    Code Style Tasks
  #------------------------------------------------------------------#
  require "chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:lint)

  #------------------------------------------------------------------#
  #                    Test Runner Tasks
  #------------------------------------------------------------------#

  ["unit", "integration"].each do |type|
    Rake::TestTask.new(type.to_sym) do |t|
      t.libs.push "lib"
      t.test_files = FileList["test/#{type}/*_test.rb"]
    end
  end
end

task default: [:'test:lint', :'test:unit']
