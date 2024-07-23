# install-azmodules.ps1

# Update the PowerShellGet module
Install-Module -Name PowerShellGet -Force -AllowClobber -Scope AllUsers

# Install the Az.Accounts module and its dependencies
Install-Module -Name Az -Force -AllowClobber -Scope AllUsers

# Verify installation
Import-Module Az.Accounts