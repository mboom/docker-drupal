# Install Drupal in a Windows Server environment

# Define user account information
$postgresusr = "postgres"
$drupalusr = "drupal"
$drupalpw = "drupal"
$drupaldb = "drupal"

# Define download URL
$drupalversion = "drupal-8.3.7"
$drupalurl = "https://ftp.drupal.org/files/projects/$drupalversion.zip"
$drupal = "C:\site"

# Download Drupal package
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $drupalurl -OutFile drupal.zip
Expand-Archive -Path drupal.zip -DestinationPath $drupal
Remove-Item drupal.zip
move C:\site\$drupalversion\* $drupal
Remove-Item -R $drupal\$drupalversion
cd $drupal
composer require drush/drush
cd C:\
setx PATH /M ((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path + ";$drupal\vendor\bin")
$env:Path += ";$drupal\vendor\bin"

# Create Drupal user and database
Start-Process psql -NoNewWindow -Wait -ArgumentList "--command `"CREATE USER $drupalusr PASSWORD '$drupalpw';`"", "--command `"CREATE DATABASE $drupaldb OWNER $drupalusr;`"", "--quiet", "--username $postgresusr"

# Create New IIS Site
Import-Module IISAdministration
New-IISSite -BindingInformation *:80: -Name Drupal -PhysicalPath $drupal

# Remove Default Web Site and Start Drupal website
Stop-IISSite -Confirm:$false -Name "Default Web Site"
Remove-IISSite -Confirm:$false -Name "Default Web Site"

Remove-Item drupal.ps1
