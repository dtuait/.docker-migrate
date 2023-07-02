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



2. define the images you want to export in images.txt

vicmrp@hp-debian11:~/Documents/docker/docker-migrate$ docker images 
REPOSITORY                TAG       IMAGE ID       CREATED       SIZE
alpine                    latest    c1aabb73d233   2 weeks ago   7.33MB
web-django-6-webserver    latest    9d7cc518b723   5 weeks ago   580MB
web-django-6-django-app   latest    013fa5be1012   5 weeks ago   1.48GB



web-django-6-webserver
web-django-6-django-app 





. step two, how to import:

./migrate --migrate 'export'




