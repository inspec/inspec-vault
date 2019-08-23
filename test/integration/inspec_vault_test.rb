
require_relative "./helper"

describe "the inspec-vault plugin" do
  include VaultIntegrationHelper

  let(:env) do
    {
      # VAULT_ADDR: "https://127.0.0.1:8200" # These should already be set by rakefile
      # VAULT_TOKEN: ""                      # These should already be set by rakefile
    }
  end
  describe "when run with a profile mentioning the inputs" do
    it "should find the values in vault" do
      cmd = "exec #{profile_fixtures}/profile-01"
      result = run_inspec_with_vault_plugin(cmd, env: env)
      assert_empty result.stderr
      assert_equal result.exit_status, 0
    end
  end

  # Try inheritance
  # Try override
  # Try custome prefix
  # Try custom priority
end
