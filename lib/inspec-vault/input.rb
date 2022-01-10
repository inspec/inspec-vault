require "vault"

# See https://github.com/inspec/inspec/blob/master/docs/dev/plugins.md#implementing-input-plugins

module InspecPlugins::Vault
  class ConfigurationError < RuntimeError; end
  class DatabagNotFoundError < RuntimeError; end

  class Input < Inspec.plugin(2, :input)

    attr_reader :plugin_conf
    attr_reader :mount_point
    attr_reader :path_prefix
    attr_reader :priority
    attr_reader :input_name
    attr_reader :databag_fallback
    attr_reader :databag_name
    attr_reader :databag_item

    attr_writer :databag
    attr_writer :inspec_config
    attr_writer :logger
    attr_writer :vault

    def initialize
      logger.debug format("Inspec-Vault plugin version %s", VERSION)

      @plugin_conf = inspec_config.fetch_plugin_config("inspec-vault")

      @mount_point = fetch_plugin_setting("mount_point", "secret")
      @path_prefix = fetch_plugin_setting("path_prefix", "inspec")
      @databag_fallback = fetch_plugin_setting("databag_fallback", true)
      @databag_name = fetch_plugin_setting("databag_name", "inspec")
      @databag_item = fetch_plugin_setting("databag_item", "vault")

      # We need priority to be numeric; even though env vars or JSON may present it as string - hence the to_i
      @priority = fetch_plugin_setting("priority", 60).to_i

      logger.info "Running from TestKitchen" if inside_testkitchen?
    end

    # What priority should an input value recieve from us?
    # This plgin does not currently allow setting this on a per-input basis,
    # so they all recieve the same "default" value.
    # Implements https://github.com/inspec/inspec/blob/master/dev-docs/plugins.md#default_priority
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
    # TODO we should probably cache these - https://github.com/inspec/inspec-vault/issues/15
    def fetch(profile_name, input_name)
      @input_name = input_name

      path = logical_path_for_profile(profile_name)
      item = input_name

      if absolute_path?
        _empty, *path, item = input_name.split("/")
        path = logical_path path.join("/")
      end

      fetch_value(path, item)
    end

    private

    def inspec_config
      @inspec_config ||= Inspec::Config.cached
    end

    def logger
      @logger ||= Inspec::Log
    end

    def vault
      @vault ||= Vault::Client.new(
        address: fetch_vault_setting("vault_addr"),
        token: fetch_vault_setting("vault_token")
      )
    end

    def fetch_value(path, item)
      if inside_testkitchen? && use_databags?
        fetch_databag_value(path, item)
      else
        fetch_vault_value(path, item)
      end
    end

    def fetch_vault_value(path, item)
      logger.info format("Reading Vault secret %s/%s",
                         path.sub(/.data/, ""), item)

      vault.with_retries(Vault::HTTPConnectionError) do
        doc = vault.logical.read(path)

        # Keys from vault are always symbolized
        return doc.data[:data][item.to_sym] if doc
      end
    end

    # Assumption for profile based lookups: inputs have been stored on documents named
    # for their profiles, and each input has a key-value pair in the document.
    def logical_path_for_profile(profile_name)
      logical_path(profile_name)
    end

    def logical_path(relative_path)
      # When you actually read a value, on the KV2 backend you must
      # read secret/data/path, not secret/path (as on the CLI)
      # https://www.vaultproject.io/api/secret/kv/kv-v2.html#read-secret-version
      # Is this true for all backends?
      "#{mount_point}/data/#{prefix}#{relative_path}"
    end

    def prefix
      return "#{path_prefix}/" unless absolute_path?

      ""
    end

    def absolute_path?
      input_name.start_with?("/")
    end

    def fetch_plugin_setting(setting_name, default = nil)
      env_var_name = "INSPEC_VAULT_#{setting_name.upcase}"
      ENV[env_var_name] || plugin_conf[setting_name] || default
    end

    def fetch_vault_setting(setting_name)
      ENV[setting_name.upcase] || plugin_conf[setting_name]
    end

    # Check if this is called from within TestKitchen
    def inside_testkitchen?
      !! defined?(::Kitchen)
    end

    # Access to kitchen data
    # TODO: Switch to official API discussed in test-kitchen/test-kitchen#1674
    def kitchen
      require "binding_of_caller"
      binding.callers.find { |b| b.frame_description == "verify" }.receiver
    end

    # Return provisioner config
    def kitchen_provisioner_config
      kitchen.provisioner.send(:provided_config)
    end

    def use_databags?
      databag_fallback.to_s == "true"
    end

    def databag_path
      unless kitchen_provisioner_config[:data_bags_path]
        raise ConfigurationError.new("Need to set provisioner/data_bags_path in Kitchen configuration")
      end

      File.join(kitchen_provisioner_config[:data_bags_path], databag_name, databag_item + ".json")
    end

    def databag
      raise DatabagNotFoundError.new("Databag item '#{databag_path}' not found") unless File.exist? databag_path

      @databag ||= JSON.load File.read(databag_path)
    end

    def fetch_databag_value(path, item)
      logger.info format("Mocking Vault secret '%s/%s' from databag '%s' and item '%s'",
                         path.sub(/.data/, ""), item,
                         databag_name, item)

      # Path starts with "#{mount_point}/data", which is not needed
      remaining_path = path.split("/")[2..-1].join("/")

      jmes_path = remaining_path.tr("/", ".")
      path_contents = JMESPath.search(jmes_path, databag)

      path_contents[item] if path_contents
    end
  end
end
