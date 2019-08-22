
# See https://github.com/inspec/inspec/blob/master/docs/dev/plugins.md#implementing-input-plugins

module InspecPlugins::Vault
  class Input < Inspec.plugin(2, :input)

    def initialize
      # Perform any auth or other setup
      # If https://github.com/inspec/inspec/pull/4406 merges, may use Config stash
    end

    def list_inputs(profile_name)
      # TODO: retval is array of input names as strings
    end

    def fetch(profile_name, input_name)
      # TODO: retval is value or nil
    end

  end
end
