# inspec-vault Plugin

This is a plugin for [Chef InSpec](https://www.inspec.io/) that allows [Inputs](https://www.inspec.io/docs/reference/inputs/) to be read from [HashiCorp Vault](https://www.vaultproject.io/).

* **Project State: Active** (but EXPERIMENTAL)
* **Issues Response SLA: 3 business days**
* **Pull Request Response SLA: 3 business days**

For more information on project states and SLAs, see [this documentation](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md).

## Notice - Experimental Project

This Chef InSpec plugin is in the early stages of research and development. Functionality may be defective, incomplete, or be withdrawn in the future. If you are interested in helping this project mature, please join the conversation or contribute code at the [inspec-vault project](https://github.com/inspec/inspec-vault).

## To Install This Plugin

Assuming it has been published to RubyGems, you can install this gem using:

```
you@machine $ inspec plugin install inspec-vault
```

## Loading Secrets into Vault

A full introduction to Vault is beyond the scope of this document, but begin by downloading a recent version from https://www.vaultproject.io . Then, start a Vault dev-mode server with the following command:

```
$ vault server -dev
```

From there, you can then store an input. For example, look at the command below to store an input named `my_input` with the value of 2, for the `my_profile` profile. Once entered, Vault responds with metadata about the entry.

```
[cwolfe@lodi inspec-vault]$ vault kv put secret/inspec/my_profile my_input=2
Key              Value
---              -----
created_time     2019-09-10T17:54:16.237055Z
deletion_time    n/a
destroyed        false
version          1
```

With that value stored, Chef InSpec will now be able to retrieve the value.

## What This Plugin Does

With the inspec-vault plugin enabled, whenever an `input()` DSL call appears in profile control code, Chef InSpec contacts the Vault server. If the secret is located in Vault, Chef InSpec uses this value. Otherwise, it searches for other sources to resolve the input, such as other plugins, profile metadata, or CLI values, as described in the Chef InSpec [input precedence](https://www.inspec.io/docs/reference/inputs/) documentation. 


### Profile Based Lookup

The default mode allows you to use profile-specific secrets.

For example, whenever profile code like this is encountered:

```ruby
# In profile "my_profile"
describe input("some_input") do
  it { should cmp "some_expected_value" }
end
```

With no other settings, Chef InSpec looks for a Vault secret located at `secret/inspec/my_profile` with a key named `some_input`, where `inspec` is derived from the `path_prefix` setting and `my_profile` is the name of this InSpec profile.

### Absolute Path Lookup

To access global information instead of a value related to a specific profile, qualify the path in absolute syntax with a starting `/`. For example:

```ruby
describe input("/configuration/webserver/password")
 it { should cmp "some_expected_value" }
end
```

In this case, Chef InSpec searches the `secret/configuration/webserver` document and returns the value of the `password` key.

## Usage with Test Kitchen

To allow for more development/production parity, this input plugin detects if it is called from within Test Kitchen. As tests should limit access to third party systems, by default the plugin will revert on using the `data_bags_path` from kitchen's `provisioner` section:

```yaml
suites:
  - name: default
    verifier:
      load_plugins: true
    data_bags_path: "test/integration/data_bags"
```

With this configuration, the databag at `test/integration/data_bags/inspec` will be accessed and the contents of the `vault.json` file within this directory get parsed. Any Vault lookups will be evaluated against the contained data.

The databag fallback mode and the databag or item names can be configured for the plugin.

Support for `load_plugins` was introduced in version 1.3.2 of the `kitchen-inspec` verifier plugin. Earlier versions are unable to load InSpec V2 plugins.

## Configuring the Plugin

Each plugin option may be set either as an environment variable, or as a plugin option in your Chef InSpec configuration file at `~/.inspec/config.json`. For example, to set the `prefix_path` option in the config file, lay out the config file as follows:

```json
{
  "version": "1.2",
  "plugins":{
    "inspec-vault":{
      "prefix_path":"my-profiles"
    }
  }
}
```

Config file option names are always lowercase.

This plugin supports the following options:

### INSPEC_DATABAG_FALLBACK

### databag_fallback

A boolean that indicates if the plugin should use a data bag within Test Kitchen. The default value is "true". This allows for mocking a Vault server in development instances.

### INSPEC_DATABAG_ITEM

### databag_item

A string with the name of the data bag item to use. If `databag_fallback` is `true`, then the default value is "vault".

### INSPEC_DATABAG_NAME

### databag_name

A string with the name of the data bag to use. If `databag_fallback` is `true`, then the default value is "inspec".

### INSPEC_VAULT_MOUNT_POINT

### mount_point

A string that indicates where the key-value path should begin; default value is "secret". The path is constructed as `<mount_point>/data/<path_prefix>/<profile_name>`.

### INSPEC_VAULT_PATH_PREFIX

### path_prefix

A string that indicates the latter portion of the key-value path; default value is "inspec". The path is constructed as `<mount_point>/data/<path_prefix>/<profile_name>`.

### INSPEC_VAULT_PRIORITY

### priority

A number between 0 and 100, default 60. When two input provides both provide a value for the same input name, the priority determines which providers' value is used, with the higher priority prevailing. Core Chef InSpec providers only range up to 50, so inspec-vault will (by default) override any other input provider.

### VAULT_ADDR

### vault_addr

This environment variable is the URL and port of your Vault installation. Default is http://127.0.0.1:8200.

### VAULT_TOKEN

This value is the secret used to authenticate to Vault. Required, no default provided.

## Developing This Plugin

Please have a look at our CONTRIBUTING.md for general guidelines.

### Testing

Run `bundle exec rake test:lint` for linting, `bundle exec rake test:unit` for unit tests, and `bundle exec rake test:integration` for integration tests.

Note that integration tests will download and run Vault server locally.
