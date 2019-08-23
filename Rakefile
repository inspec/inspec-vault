# A Rakefile defines tasks to help maintain your project.
# Rake provides several task templates that are useful.

# This task template will make a task named 'test', and run
# the tests that it finds.
require "rake/testtask"

ENV["VAULT_DEV_ROOT_TOKEN_ID"] ||= "s.kr5NQVFlUEi7XV64W3SVhqoE"
ENV["VAULT_RELEASE"] ||= "1.2.2"
ENV["VAULT_API_ADDR"] ||= "http://127.0.0.1"
ENV["VAULT_LOG_LEVEL"] ||= "debug" # default "info" is noisy

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
  Rake::TestTask.new(:unit) do |t|
    t.libs.push "lib"
    t.test_files = FileList["test/unit/*_test.rb"]
  end

  desc "Run integration tests by starting a local Vault server"
  task integration: %i{int:install_vault int:start_vault int:seed_vault int:test int:stop_vault }

  def windows?
    RUBY_PLATFORM =~ /cygwin|mswin|mingw/
  end

  def mac_os?
    RUBY_PLATFORM =~ /darwin/
  end

  namespace(:int) do
    Rake::TestTask.new(:test) do |t|
      t.libs.push "lib"
      t.test_files = FileList["test/integration/*_test.rb"]
    end

    task(:install_vault) do
      if windows?
        raise "No windows integration testing yet"
      elsif mac_os?
        sh "test/integration/support/install-vault.macos.sh"
      else
        sh "test/integration/support/install-vault.linux.sh"
      end
    end

    task(:start_vault) do
      puts "test/integration/support/vault server -dev &"
      pid = spawn(ENV, "test/integration/support/vault server -dev &")
      Process.detach(pid)
    end

    task(:seed_vault) do
      Dir.chdir("test/fixtures/vault") do
        Dir["**/*.json"].each do |json_pathname|
          path_parts = json_pathname.split(/[\/\\]/)

          path_prefix = "secret/inspec" # TODO - custom path prefix support
          profile_name = path_parts.last.sub(/\.json$/, "")

          # Shell out to do a file load of secrets
          sh "../../integration/support/vault kv put #{path_prefix}/#{profile_name} @#{json_pathname}"
        end
      end
    end

    task(:stop_vault) do
      if windows?
        raise "No windows integration testing yet"
      else
        sh "pkill vault"
      end
    end

  end
end

task default: %i{test:lint test:unit}
