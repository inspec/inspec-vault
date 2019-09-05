# Install vault
if [ ! -f test/integration/support/vault ]; then
  apt-get -yq install unzip
  curl https://releases.hashicorp.com/vault/${VAULT_RELEASE}/vault_${VAULT_RELEASE}_linux_amd64.zip --output vault.zip
  unzip vault.zip
  mv vault test/integration/support/vault
  rm -f vault.zip
fi