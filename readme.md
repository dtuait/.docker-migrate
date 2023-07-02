# How to export:

1. step one, create a volumes.txt file and put the name of the volumes you want to export here. 

For example:

vicmrp@hp-debian11:~/Documents/docker$ docker volume ls
DRIVER    VOLUME NAME
local     django-app_django-app_usr-src-app
local     django-app_webserver_etc-apache2
local     django-app_webserver_etc_letsencrypt-cached
local     django-app_webserver_var-www

vicmrp@hp-debian11:~/Documents/docker$ cat docker-migrate/volumes.txt 
django-app_django-app_usr-src-app
django-app_webserver_etc-apache2
django-app_webserver_etc_letsencrypt-cached
django-app_webserver_var-wwwv

2. step two, how to import:
3. 
./migrate --migrate 'export'




