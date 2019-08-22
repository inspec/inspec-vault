require "vault"
require "byebug"

# See https://github.com/inspec/inspec/blob/master/docs/dev/plugins.md#implementing-input-plugins

module InspecPlugins::Vault
  class Input < Inspec.plugin(2, :input)

    attr_reader :path_prefix
    attr_reader :vault
    attr_reader :inject_data_in_prefix

    def initialize
      # Perform any auth or other setup
      # If https://github.com/inspec/inspec/pull/4406 merges, may use Config stash

      # Read inspec prefix from somewhere
      # TODO: read path prefix this from config
      @path_prefix = ENV["VAULT_INSPEC_PATH_PREFIX"] || "secret/inspec"

      # When you actually read a value, on the KV2 backend you must
      # read secret/data/path, not secret/path
      # https://www.vaultproject.io/api/secret/kv/kv-v2.html#read-secret-version
      @inject_data_in_prefix = path_prefix.start_with?("secret") # TODO: make this configurable

      # Vault gem will rely on ENV["VAULT_ADDR"] (url) and ENV["VAULT_TOKEN"] (auth)
      # TODO: optionally read URL and token from config as well
      @vault = Vault::Client.new

      # TODO: override priority from config
    end

    # returns Array of input names as strings
    def list_inputs(profile_name)
      vault.with_retries(Vault::HTTPConnectionError) do
        path = expand_path_prefix("#{path_prefix}/#{profile_name}")
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
      path = expand_path_prefix("#{path_prefix}/#{profile_name}")
      vault.with_retries(Vault::HTTPConnectionError) do
        doc = vault.logical.read(path)
        # Keys from vault are always symbolized
        return doc.data[:data][input_name.to_sym] if doc
      end
    end

    private
    # Inject the word "data" as the second word in the path
    # TODO: this is awful and clearly a hack
    # https://www.vaultproject.io/api/secret/kv/kv-v2.html#read-secret-version
    def expand_path_prefix(prefix)
      return prefix unless inject_data_in_prefix
      parts = prefix.split('/')
      ([ parts.first, "data"].concat parts.slice(1..-1)).join('/')
    end
  end
end
