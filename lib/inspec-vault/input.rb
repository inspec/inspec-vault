require "vault"

# See https://github.com/inspec/inspec/blob/master/docs/dev/plugins.md#implementing-input-plugins

module InspecPlugins::Vault
  class Input < Inspec.plugin(2, :input)

    attr_reader :plugin_conf
    attr_reader :mount_point
    attr_reader :path_prefix
    attr_reader :vault
    attr_reader :priority

    def initialize
      @plugin_conf = Inspec::Config.cached.fetch_plugin_config("inspec-vault")

      @mount_point = fetch_plugin_setting("mount_point", "secret")
      @path_prefix = fetch_plugin_setting("path_prefix", "inspec")
      @priority = fetch_plugin_setting("priority", 60).to_i

      @vault = Vault::Client.new(
        address: fetch_vault_setting("vault_addr"),
        token: fetch_vault_setting("vault_token")
      )
    end

    def default_priority
      priority
    end

    # returns Array of input names as strings
    def list_inputs(profile_name)
      vault.with_retries(Vault::HTTPConnectionError) do
        path = logical_path_for_profile(profile_name)
        doc = vault.logical.read(path)
        return [] unless doc
        return doc.data[:data].keys.map(&:to_s)
      end
    end

    # Fetch a value of a single input from Vault
    # Assumption: inputs have been stored on documents named for their
    # profiles, and each input has a key-value pair in the document.
    # TODO we should probably cache these - https://github.com/inspec/inspec-vault/issues/15
    def fetch(profile_name, input_name)
      path = logical_path_for_profile(profile_name)
      vault.with_retries(Vault::HTTPConnectionError) do
        doc = vault.logical.read(path)
        # Keys from vault are always symbolized
        return doc.data[:data][input_name.to_sym] if doc
      end
    end

    private

    def logical_path_for_profile(profile_name)
      # When you actually read a value, on the KV2 backend you must
      # read secret/data/path, not secret/path (as on the CLI)
      # https://www.vaultproject.io/api/secret/kv/kv-v2.html#read-secret-version
      # Is this true for all backends?
      "#{mount_point}/data/#{path_prefix}/#{profile_name}"
    end

    def fetch_plugin_setting(setting_name, default = nil)
      env_var_name = "INSPEC_VAULT_#{setting_name.upcase}"
      ENV[env_var_name] || plugin_conf[setting_name] || default
    end

    def fetch_vault_setting(setting_name)
      ENV[setting_name.upcase] || plugin_conf[setting_name]
    end
  end
end
