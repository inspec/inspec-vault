# A Rakefile defines tasks to help maintain your project.
# Rake provides several task templates that are useful.

# This task template will make a task named 'test', and run
# the tests that it finds.
require "rake/testtask"

ENV["VAULT_DEV_ROOT_TOKEN_ID"] ||= "s.kr5NQVFlUEi7XV64W3SVhqoE"
ENV["VAULT_RELEASE"] ||= "1.2.2"

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

  %w{unit integration}.each do |type|
    Rake::TestTask.new(type.to_sym) do |t|
      t.libs.push "lib"
      t.test_files = FileList["test/#{type}/*_test.rb"]
    end
  end

  def windows?
    RUBY_PLATFORM =~ /cygwin|mswin|mingw/
  end

  def mac_os?
    RUBY_PLATFORM =~ /darwin/
  end

  namespace(:integration) do
    task(:install_vault) do
      if windows?
        raise "No windows integration testing yet"
        sh "test/integration/support/install-vault.windows.ps1"
      elsif mac_os?
        sh "test/integration/support/install-vault.macos.sh"
      else
        sh "test/integration/support/install-vault.linux.sh"
      end
    end

  end
end

task default: %i{test:lint test:unit}
