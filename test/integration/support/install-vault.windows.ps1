cd C:\vagrant\test\integration\support
if(!(Test-Path vault.exe)) {
  echo "Installing vault"

  # This is needed because the default TLS proto ordering causes the download to fail
  [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
  Invoke-WebRequest -Uri "https://releases.hashicorp.com/vault/$($Env:VAULT_RELEASE)/vault_$($Env:VAULT_RELEASE)_windows_amd64.zip" -OutFile vault.zip

  expand-archive -path 'vault.zip' -DestinationPath .
  del vault.zip

}