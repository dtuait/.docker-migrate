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
docker stop $(docker ps -a -q) >/dev/null 2>&1

# Iterate over each volume and import
for volume in "${volumes[@]}"; do
    # Check if the volume exists, if not create it
    if [ -z "$(docker volume ls -q | grep $volume)" ]; then
        docker volume create $volume

    else
        echo "Volume $volume already exists."
        exit 1
    fi
done

# import volumes to docker
for volume in "${volumes[@]}"; do

    # Check if the volume exists, if not create it
    if [ -z "$(docker volume ls -q | grep $volume)" ]; then

        echo "Creating volume $volume..."
        
        docker volume create $volume

        echo "Importing $volume..."
        docker run --rm -v $volume:/volume -v $(pwd)/volumes:/backup alpine tar -xzvf /backup/$volume.tar >/dev/null

        if [ $? -eq 0 ]; then
            echo "$volume imported successfully."
        else
            echo "Error importing $volume."
            exit 1
        fi

    else
        echo "Volume $volume already exists."
        exit 1
    fi

done

echo "Importing images..."

for image in "${images[@]}"; do
    echo "Loading image $image..."
    docker load -i images/$image.tar >/dev/null

    if [ $? -eq 0 ]; then
        echo "$image loaded successfully."
    else
        echo "Error loading $image."
        exit 1
    fi
done
