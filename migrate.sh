while [ $# -gt 0 ]; do

    if [[ $1 == *"--"* ]]
    then
        param="${1/--/}"
        declare $param="$2"
        # echo $param $1 $2 # Optional to see the parameter:value result
    fi

  shift 1 # rykker positionelle parameter en gang til venstre
done




# if migrate is not not "export" or "import"
# if [[ -z "$migrate" ]]; then echo "Please specify '--migrate 'export|import''"; exit 1; fi;
if [[ "$migrate" != "export" && "$migrate" != "import" ]]; then echo "Please specify '--migrate 'export|import''"; exit 1; fi;

# before doing anything make sure all containers are stopped
docker stop $(docker ps -a -q) > /dev/null 2>&1

# array of image names to import
mapfile -t images < images.txt

# Read volumes.txt into array
mapfile -t volumes < volumes.txt



# Export script starts here
if [ "$migrate" == "export" ]; then

    echo "Exporting volumes..."


    # Delete the volumes directory if it exists, then recreate it
    if [ -d "_volumes" ]; then
        rm -rf _volumes
    fi
    mkdir -p ./_volumes

    # Loop over volumes and back each one up
    for volume in "${volumes[@]}"; do
        echo "Backing up $volume..."
        docker run --rm -v $volume:/volume -v $(pwd)/_volumes:/backup alpine tar -czvf /backup/$volume.tar /volume > /dev/null

        if [ $? -eq 0 ]
        then
            echo "$volume backed up successfully."
        else
            echo "Error backing up $volume."
            exit 1
        fi
    done

    echo "Done exporting volumes."


    echo "Exporting images..."
    # Delete the images directory if it exists, then recreate it
    if [ -d "_images" ]; then
        rm -rf _images
    fi
        mkdir _images

    for images in "${images[@]}"; do
    safe_image_name=$(echo $images | tr '/' '.')
    echo "Backing up $images..."
    docker save -o _images/$safe_image_name.tar $images > /dev/null

    if [ $? -eq 0 ]
    then
        echo "$images backed up successfully."
    else
        echo "Error backing up $images."
        exit 1
    fi

    echo "Done exporting images."

done

# Export script ends here
elif [ "$migrate" == "import" ]; then
# Import script starts here
    echo "Importing volumes..."
    # import volumes to docker
    for volume in "${volumes[@]}"; do

        # Check if the volume exists, if not create it
        if [ -z "$(docker volume ls -q | grep $volume)" ]; then

            echo "Creating volume $volume..."
            
            docker volume create $volume

            echo "Importing $volume..."
            docker run --rm -v $volume:/volume -v $(pwd)/_volumes:/backup alpine tar -xzvf /backup/$volume.tar >/dev/null

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

    echo "Done importing volumes."

    echo "Importing images..."
    for image in "${images[@]}"; do
        echo "Loading image $image..."
        safe_image_name=$(echo $images | tr '/' '.')
        docker load -i _images/$safe_image_name.tar >/dev/null

        if [ $? -eq 0 ]; then
            echo "$image loaded successfully."
        else
            echo "Error loading $image."
            exit 1
        fi
    done

    echo "Done importing images."

# Import script ends here    
fi


echo "Script has completed $migrate"
exit 0
