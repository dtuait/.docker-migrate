#!/bin/bash

# array of image names to import
images=(
    "web-django-6-django-app"
    "web-django-6-webserver"
)

# Array of volume names to backup
volumes=(
    "django-app_webserver_var-www"
    "django-app_webserver_etc-apache2"
    "django-app_webserver_etc_letsencrypt-cached"
    "django-app_django-app_usr-src-app"
)




# before doing anything make sure all containers are stopped
docker stop $(docker ps -a -q) > /dev/null 2>&1








## Export volumes starts here ##
###




# Delete the volumes directory if it exists, then recreate it
if [ -d "volumes" ]; then
    rm -rf volumes
fi
mkdir -p ./volumes


# Loop over volumes and back each one up
for volume in "${volumes[@]}"; do
    echo "Backing up $volume..."
    docker run --rm -v $volume:/volume -v $(pwd)/volumes:/backup alpine tar -czvf /backup/$volume.tar /volume > /dev/null

    if [ $? -eq 0 ]
    then
        echo "$volume backed up successfully."
    else
        echo "Error backing up $volume."
        exit 1
    fi
done

echo "All volumes have been saved in .tar file."

## Export volumes ends here ##


## Export images starts here ##

# Delete the images directory if it exists, then recreate it
if [ -d "images" ]; then
  rm -rf images
fi
mkdir images

echo "Exporting images..."

for images in "${images[@]}"; do
    echo "Backing up $images..."
    docker save -o images/$images.tar $images > /dev/null

    if [ $? -eq 0 ]
    then
        echo "$images backed up successfully."
    else
        echo "Error backing up $images."
        exit 1
    fi
done

## Export images ends here ##

echo "All images have been saved in .tar file."
exit 0