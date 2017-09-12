# docker-drupal

Download Visual C++ Redistributable Packages for Visual Studio 2013 (x64) (https://www.microsoft.com/en-us/download/details.aspx?id=40784) and Microsoft Visual C++ 2015 Redistributable Update 3 (x64) (https://www.microsoft.com/en-us/download/details.aspx?id=53587) manually, make sure that the files are called vcredist_x64.exe for 2013 and vc_redist.x64.exe for 2015 and add the files to the same folder as the Docker- and setupfiles.

Build with Docker: docker build --tag drupal .
And run an container with this base-image: docker run --detach --publish 80:80 drupal
When you browse to the IP Address of your Docker host you should see the Drupal setup.
After installing a Drupal site, change the temporary directory from sites/default/files/tmp to sites\default\files\tmp and clear the cache. This will bring back all css and javascript files.
