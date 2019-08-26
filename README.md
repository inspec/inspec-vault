# inspec-vault Plugin

This is a plugin for [Chef InSpec](https://www.inspec.io/) that allows [Inputs](https://www.inspec.io/docs/reference/inputs/) to be read from [HashiCorp Vault](https://www.vaultproject.io/).

## To Install This Plugin

Assuming it has been published to RubyGems, you can install this gem using:

```
you@machine $ inspec plugin install inspec-vault
```

## What This Plugin Does

Whenever profile code like this is encountered:

```ruby
# In profile "my_profile"
describe input("some_input") do
  it { should cmp "some_expected_value" }
end
```

Chef InSpec will for a Vault secret located at `secret/inspec/my_profile` with a key "some_input". It will use the vault if found; otherwise it will fall back to other means of resolving the input.

## Configuring the Plugin

This plugin supports the following options:

### VAULT_ADDR

This environment variable is the URL and port of your Vault installation. Default is http://127.0.0.1:8200.

### VAULT_TOKEN

This value is the secret used to authenticate to Vault. Required, no default provided.

## Developing This Plugin

Please have a look at our CONTRIBUTING.md for general guidelines.

### Testing

Run `bundle exec rake test:lint` for linting, `bundle exec rake test:unit` for unit tests, and `bundle exec rake test:integration` for integration tests.

Note that integration tests will download and run Vault server locally.

