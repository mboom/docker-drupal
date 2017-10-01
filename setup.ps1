# Install PHP and PostgreSQL in a Windows Server Core environment with IIS enabled and prepare for Drupal

# Define user account information
$postgresusr = "postgres"
$postgrespw = "P@ssw0rd"
$service = "NT AUTHORITY\NetworkService"

# Define download URLs and install paths
$urlrewriteurl = "https://download.microsoft.com/download/D/D/E/DDE57C26-C62C-4C59-A1BB-31D58B36ADA2/rewrite_amd64_en-US.msi"
$phpurl = "http://windows.php.net/downloads/releases/php-7.1.10-nts-Win32-VC14-x64.zip"
$php = "C:\Program Files\PHP"
$ssh2url = "http://windows.php.net/downloads/pecl/releases/ssh2/1.1.2/php_ssh2-1.1.2-7.1-nts-vc14-x64.zip"
$curlcaurl = "https://curl.haxx.se/ca/cacert.pem"
$curlca = "C:\Program Files\curl\CA bundle"
$composerurl = "https://getcomposer.org/installer"
$composer = "C:\Program Files\Composer"
$postgresurl = "https://get.enterprisedb.com/postgresql/postgresql-9.6.4-1-windows-x64-binaries.zip"
$postgres = "C:\Program Files\PostgreSQL\9.6"

# Install Visual C++ Redistributable Packages for Visual Studio 2013
Start-Process .\vcredist_x64.exe -NoNewWindow -Wait -ArgumentList "/install", "/quiet", "/norestart"
Remove-Item vcredist_x64.exe


# Install Visual C++ Redistributable for Visual Studio 2015
Start-Process .\vc_redist.x64.exe -NoNewWindow -Wait -ArgumentList "/install", "/quiet", "/norestart"
Remove-Item vc_redist.x64.exe

# Install URL Rewrite for IIS
Invoke-WebRequest -Uri $urlrewriteurl -OutFile rewrite.msi
Start-Process msiexec -NoNewWindow -Wait -ArgumentList "/package rewrite.msi", "/quiet", "/norestart"
Remove-Item rewrite.msi

# Enable FastCGI for IIS
dism /enable-feature /online /featureName:IIS-CGI /all

# Download and install PHP
Invoke-WebRequest -Uri $phpurl -OutFile php.zip
Expand-Archive -Path php.zip -DestinationPath $php
Remove-Item php.zip
move php1.ini $php\php.ini
setx PATH /M ((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path + ";$php")
$env:Path += ";$php"

# Download ssh2
Invoke-WebRequest -Uri $ssh2url -OutFile php_ssh2.zip
Expand-Archive -Path php_ssh2.zip -DestinationPath php_ssh2
Remove-Item php_ssh2.zip
move php_ssh2\php_ssh2.dll $php\ext\php_ssh2.dll
Remove-Item -R php_ssh2

# Download curl ca-bundle
md $curlca
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $curlcaurl -OutFile $curlca\cacert.crt

# Download and install Composer
md $composer
Start-Process php -NoNewWindow -Wait -ArgumentList "-r `"copy('$composerurl', '$composer\composer-setup.php');`""
Start-Process php -NoNewWindow -Wait -ArgumentList "-r `"if (hash_file('SHA384', '$composer\composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('$composer\composer-setup.php'); } echo PHP_EOL;`""
Start-Process php -NoNewWindow -Wait -ArgumentList "`"$composer\composer-setup.php`"", "--install-dir=`"$composer`""
Start-Process php -NoNewWindow -Wait -ArgumentList "-r `"unlink('$composer\composer-setup.php');`""
Write-Output "php `"$composer\composer.phar`" @args" > $composer\composer.ps1
setx PATH /M ((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path + ";$composer")
$env:Path += ";$composer"

# Add PHP as a FastCGI application to IIS
Import-Module IISAdministration
# Register the PHP CGI executable
if (!(Get-IISConfigSection -SectionPath "system.webServer/fastCgi" | Get-IISConfigCollection | Get-IISConfigCollectionElement -ConfigAttribute @{fullPath="$php\php-cgi.exe"})) {
	Get-IISConfigSection -SectionPath "system.webServer/fastCgi" | Get-IISConfigCollection | New-IISConfigCollectionElement -ConfigAttribute @{activityTimeout=600; fullPath="$php\php-cgi.exe"; instanceMaxRequests=10000; maxInstances=0; monitorChangesTo="$php\php.ini"; requestTimeout=600}
}
if (!(Get-IISConfigSection -SectionPath "system.webServer/fastCgi" | Get-IISConfigCollection | Get-IISConfigCollectionElement -ConfigAttribute @{fullPath="$php\php-cgi.exe"} | Get-IISConfigElement -ChildElementName environmentVariables | Get-IISConfigCollection | Get-IISConfigCollectionElement -ConfigAttribute @{name="PHP_FCGI_MAX_REQUESTS"})) {
	Get-IISConfigSection -SectionPath "system.webServer/fastCgi" | Get-IISConfigCollection | Get-IISConfigCollectionElement -ConfigAttribute @{fullPath="$php\php-cgi.exe"} | Get-IISConfigElement -ChildElementName environmentVariables | Get-IISConfigCollection | New-IISConfigCollectionElement -ConfigAttribute @{name="PHP_FCGI_MAX_REQUESTS"; value=10000}
}
if (!$(Get-IISConfigSection -SectionPath "system.webServer/fastCgi" | Get-IISConfigCollection | Get-IISConfigCollectionElement -ConfigAttribute @{fullPath="$php\php-cgi.exe"} | Get-IISConfigElement -ChildElementName environmentVariables | Get-IISConfigCollection | Get-IISConfigCollectionElement -ConfigAttribute @{name="PHPRC"})) {
	Get-IISConfigSection -SectionPath "system.webServer/fastCgi" | Get-IISConfigCollection | Get-IISConfigCollectionElement -ConfigAttribute @{fullPath="$php\php-cgi.exe"} | Get-IISConfigElement -ChildElementName environmentVariables | Get-IISConfigCollection | New-IISConfigCollectionElement -ConfigAttribute @{name="PHPRC"; value=$php}
}
# Map the PHP CGI executable as handler for php files
if (!(Get-IISConfigSection -SectionPath "system.webServer/handlers" | Get-IISConfigCollection | Get-IISConfigCollectionElement -ConfigAttribute @{name="PHP_via_FastCGI"})) {
	Get-IISConfigSection -SectionPath "system.webServer/handlers" | Get-IISConfigCollection | New-IISConfigCollectionElement -AddAt 0 -ConfigAttribute @{modules="FastCgiModule"; name="PHP_via_FastCGI"; path="*.php"; resourceType="Either"; scriptProcessor="$php\php-cgi.exe"; verb="GET,HEAD,POST"}
}

# Download and install PostgreSQL
Invoke-WebRequest -Uri $postgresurl -OutFile postgres.zip
Expand-Archive -Path postgres.zip -DestinationPath .
Remove-Item postgres.zip
md $postgres
move pgsql\* $postgres
Remove-Item -R pgsql
$acl = Get-Acl $postgres
$acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule "$service", ReadAndExecute, "ContainerInherit, ObjectInherit", InheritOnly, Allow))
Set-Acl $postgres $acl
setx PATH /M ((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path + ";$postgres\bin")
$env:Path += ";$postgres\bin"
Start-Process initdb -NoNewWindow -Wait -ArgumentList "--auth trust", "--pgdata `"$postgres\data`"", "--encoding utf8", "--username $postgresusr"
$acl = Get-Acl $postgres\data
$acl.SetOwner((New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList "$service"))
dir -r $postgres\data | Set-Acl -AclObject $acl
$acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule "$service", FullControl, "ContainerInherit, ObjectInherit", InheritOnly, Allow))
Set-Acl $postgres\data $acl
Start-Process pg_ctl -NoNewWindow -Wait -ArgumentList "register", "-N postgresql", "-U `"$service`"", "-D `"$postgres\data`"", "-w"
net start postgresql

# Prepare PHP settings for Drupal
Remove-Item $php\php.ini
copy php2.ini $php\php.ini
Remove-Item php2.ini

# Remove setup script
Remove-Item setup.ps1
