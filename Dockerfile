# Base image IIS
FROM microsoft/iis

# Load setup files
ADD drupal.ps1 drupal.ps1
ADD php1.ini php1.ini
ADD php2.ini php2.ini
ADD setup.ps1 setup.ps1
ADD vc_redist.x64.exe vc_redist.x64.exe
ADD vcredist_x64.exe vcredist_x64.exe

# Execute setup script
RUN powershell -Command .\setup.ps1

# Create a Drupal site
RUN powershell -Command .\drupal.ps1
EXPOSE 80