#!/bin/bash


gecho() {
  local msg=$1  # Capture the argument
  echo -e "\e[32m${msg}\e[0m"
}


recho() {
  local msg=$1  # Capture the argument
  echo -e "\e[31m${msg}\e[0m"
}

oecho() {
  local msg=$1  # Capture the argument
  echo -e "\e[33m${msg}\e[0m"
}

mecho() {
    local msg=$1  # Capture the argument
    echo -e "\e[35m${msg}\e[0m"
}

# Function to backup a Docker volume
# Arguments:
#   volume: The name of the Docker volume to backup
#   filepath: The directory where the backup should be stored
backup_volume() {
    # Store the function arguments in local variables
    local volume=$1
    local filepath=$2

        # if debug is true, print the following # and pwd
    if [ "$DEBUG" = true ]; then
        mecho "volume: $volume"
        mecho "filepath: $filepath"
    fi


    # Create the backup directory if it doesn't exist
    mkdir -p $filepath

    # Set the correct permissions for the backup directory
    chmod -R 777 $filepath 


    # Run a Docker command to backup the volume
    # This command runs a temporary Docker container with the alpine image,
    # mounts the volume to /volume in the container,
    # mounts the backup directory to /backup in the container,
    # and runs the tar command to create a compressed archive of the volume in the backup directory
    docker run --rm -v $volume:/volume -v $filepath:/backup alpine tar -czvf /backup/$volume.tar /volume > /dev/null

    # Check the exit status of the Docker command
    if [ $? -eq 0 ]
    then
        # If the Docker command was successful, print a success message
        echo "$volume backed up successfully."
    else
        # If the Docker command failed, print an error message and exit with a status code of 1
        echo "Error backing up $volume."
        exit 1
    fi
}


backup_image() {
    local image=$1
    local backup_dir=$2

    # Check if the image exists
    if [ -z "$(docker images -q $image)" ]; then
        recho "Error: Image $image does not exist."
        exit 1
    fi

    # Create a safe image name for the backup file
    local safe_image_name=$(echo $image | tr '/' '.')
    safe_image_name=$(echo $safe_image_name | tr ':' '_')

    # Create the backup directory if it doesn't exist
    if [ ! -d $backup_dir ]; then
        mkdir -p $backup_dir
    fi

    # Save the image to a tar file
    docker save $image > $backup_dir/$safe_image_name.tar
    gecho "Image $image has been backed up to $backup_dir/$safe_image_name.tar"
}


process_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --debug)
                DEBUG=true
                ;;
            --migrate)
                MIGRATE="$2"
                shift # Skip the argument value
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
        shift # Move to the next key or value
    done
}

validate_arguments() {
    # If the 'migrate' parameter is not 'export' or 'import'
    if [[ "$MIGRATE" != "export" && "$MIGRATE" != "import" ]]; then 
        echo "Please specify '--migrate 'export|import''"; 
        exit 1; 
    fi

    # Require root privileges
    if [ "$EUID" -ne 0 ]; then 
        echo "Please run as root"; 
        exit 1; 
    fi
}

stop_running_containers() {
    # Get all currently running container IDs and save them in an array
    running_containers=$(docker ps -q)

    # Stop the running containers
    if [ ! -z "$running_containers" ]; then
        gecho "Stopping running containers: $running_containers"
        docker stop $running_containers
    else
        oecho "No running containers to stop."
    fi
}

restart_containers() {
    # Start the previously running containers
    if [ ! -z "$running_containers" ]; then
        gecho "Restarting containers: $running_containers"
        docker start $running_containers
    else
        oecho "No containers to restart."
    fi
}

set_current_folder_name() {
    NAME_CURRENT_FOLDER=$(basename "$PWD")
}

set_scripts_directory_path() {
    NAME_SCRIPTS_DIRECTORY_PATH=$(pwd)
}

set_project_name() {
    if [ "$NAME_CURRENT_FOLDER" == "$NAME_DOCKER_MIGRATE" ]; then


        PROJECT_NAME=$(basename "$(dirname "$(dirname "$NAME_SCRIPTS_DIRECTORY_PATH")")")
        # if debug is true, print the following # and pwd
        if [ "$DEBUG" = true ]; then
            mecho "PROJECT_NAME: $PROJECT_NAME"
            mecho "pwd is $(pwd)"
        fi
    elif [ "$NAME_CURRENT_FOLDER" == "$NAME_MIGRATION_STATION" ]; then
        PROJECT_NAME=$(basename "$0")
    else
        echo "Error: Current folder name should be either $NAME_DOCKER_MIGRATE or $NAME_MIGRATION_STATION"
        exit 1
    fi
}

validate_migration_and_directory() {
    # local DOCKER_MIGRATE=".docker-migrate" # - set as global variable instead
    # local MIGRATION_STATION="migration_station" # - set as global variable instead

    # if debug is true, print the following
    if [ "$DEBUG" = true ]; then
        mecho "Current folder name: $NAME_CURRENT_FOLDER"
    fi

    if [ "$MIGRATE" = "export" ]; then

        if [ "$NAME_CURRENT_FOLDER" != "$NAME_DOCKER_MIGRATE" ]; then
            recho "Error: For export, current directory should be $NAME_DOCKER_MIGRATE"
            exit 1
        fi


        # # Check if the directory ../../migration_station exists
        if [ ! -d $NAME_SCRIPTS_DIRECTORY_PATH/../../../migration_station ]; then
            # If it doesn't exist, print an error message and exit with status code 1
            recho "Error: $NAME_SCRIPTS_DIRECTORY_PATH/../../../migration_station does not exist."
            exit 1
           


        else 
            if [ "$DEBUG" = true ]; then
                # prove that ../../../migration_station exists
                mecho "Directory ../../../migration_station exists."
            fi
        fi




    elif [ "$MIGRATE" = "import" ]; then
        if [ "$NAME_CURRENT_FOLDER" != "$NAME_MIGRATION_STATION" ]; then
            recho "Error: For import, parent directory should be $NAME_MIGRATION_STATION"
            exit 1
        fi
    else
        recho "Error: Unknown MIGRATE value: $MIGRATE"
        exit 1
    fi
}

delete_old_images_tar_files() {
    # Delete the images directory if it exists, then recreate it
    if [ -d "$NAME_SCRIPTS_DIRECTORY_PATH/_images" ]; then
        gecho "Deleting old images..."
        rm -rf /$NAME_SCRIPTS_DIRECTORY_PATH/_images
    fi
    mkdir -p $NAME_SCRIPTS_DIRECTORY_PATH/_images
}

get__images() {
    local current_path=$(pwd)

    if [ "$DEBUG" = true ]; then
        mecho "Reading images from images.txt..."
        cat $NAME_SCRIPTS_DIRECTORY_PATH/images.txt
    fi

    if [ "$NAME_CURRENT_FOLDER" == "$NAME_MIGRATION_STATION" ]; then
        cd $NAME_SCRIPTS_DIRECTORY_PATH/../$PROJECT_NAME/.devcontainer/.docker-migrate
        if  [ ! -f "./images.txt" ]; then
            touch ./images.txt
        fi
        mapfile -t images < ./images.txt
    else
        if [ ! -f "$NAME_SCRIPTS_DIRECTORY_PATH/images.txt" ]; then
            gecho "Creating images.txt..."
            touch $NAME_SCRIPTS_DIRECTORY_PATH/images.txt
        fi
        mapfile -t images < $NAME_SCRIPTS_DIRECTORY_PATH/images.txt
    fi

    cd $current_path
}

delete_old_volumes_tar_files() {
            # Delete the volumes directory if it exists, then recreate it
            if [ -d "$NAME_SCRIPTS_DIRECTORY_PATH/_volumes" ]; then
                gecho "Deleting old volumes..."
                rm -rf /$NAME_SCRIPTS_DIRECTORY_PATH/_volumes
            fi
            mkdir -p $NAME_SCRIPTS_DIRECTORY_PATH/_volumes
        }

get__volumes() {


    

    # if debg is true, print the following
    if [ "$DEBUG" = true ]; then
        mecho "Reading volumes from volumes.txt..."
        cat $NAME_SCRIPTS_DIRECTORY_PATH/volumes.txt
    fi


    # $NAME_CURRENT_FOLDER is migration_station
    if [ "$NAME_CURRENT_FOLDER" == "$NAME_MIGRATION_STATION" ]; then
        # store the current cd path
        local current_path=$(pwd)

        # cd to the project directory
        cd $NAME_SCRIPTS_DIRECTORY_PATH/../$PROJECT_NAME/.devcontainer/.docker-migrate
        if  [ ! -f "./volumes.txt" ]; then
            touch ./volumes.txt
        fi
        mapfile -t volumes < ./volumes.txt
        # cd back to the current path   
        cd $current_path
    else

        # if volumes.txt does not exist, create it
        if [ ! -f "$NAME_SCRIPTS_DIRECTORY_PATH/volumes.txt" ]; then
            gecho "Creating volumes.txt..."
            touch $NAME_SCRIPTS_DIRECTORY_PATH/volumes.txt
        fi
        mapfile -t volumes < $NAME_SCRIPTS_DIRECTORY_PATH/volumes.txt
    fi
} 


execute_migration() {
    if [ "$MIGRATE" == "export" ]; then
        # Put the code for the 'export' case here

        gecho "Exporting volumes..."        
        delete_old_volumes_tar_files
        get__volumes
        for volume in "${volumes[@]}"; do

            # if debug is true, print the following
            if [ "$DEBUG" = true ]; then
                mecho "Backing up $volume..."
            fi

            gecho "Backing up $volume..."
            backup_volume $volume $NAME_SCRIPTS_DIRECTORY_PATH/_volumes

            if [ $? -eq 0 ]
            then
                gecho "$volume backed up successfully."
            else
                recho "Error backing up $volume."
                exit 1
            fi
        done
        gecho "Done exporting volumes."
        
        gecho "Exporting images..."
        delete_old_images_tar_files
        get__images
        for image in "${images[@]}"; do

            # if debug is true, print the following
            if [ "$DEBUG" = true ]; then
                mecho "Backing up $image..."
            fi

            # image name with / replaced by . and : replaced by _
            safe_image_name=$(echo $image | tr '/' '.')
            safe_image_name=$(echo $safe_image_name | tr ':' '_')
            gecho "Backing up $image..."
            backup_image $image $NAME_SCRIPTS_DIRECTORY_PATH/_images
            

        done
        gecho "Done exporting images."


        # Define the directory where the tar.gz file should be saved
        migration_station_dir="${NAME_SCRIPTS_DIRECTORY_PATH}/../../../migration_station"


        if [ -f "$migration_station_dir/$PROJECT_NAME" ]; then
            gecho "Deleting old $PROJECT_NAME... in $migration_station_dir"
            rm "$migration_station_dir/$PROJECT_NAME"
        fi        
        
        # if -d $migration_station_dir/$PROJECT_NAME exist delete it
        if [ -d "$migration_station_dir/$PROJECT_NAME" ]; then
            gecho "Deleting old $PROJECT_NAME... in $migration_station_dir"
            rm -rf "$migration_station_dir/$PROJECT_NAME"
        fi
        cp $NAME_SCRIPTS_DIRECTORY_PATH/migration_station.sh $migration_station_dir/$PROJECT_NAME

        
        # Define the tar.gz file name
        tar -czf $migration_station_dir/$PROJECT_NAME.tar.gz $NAME_SCRIPTS_DIRECTORY_PATH/../../../$PROJECT_NAME > /dev/null
        # check if successful
        if [ $? -eq 0 ]; then
            gecho "Creating tar.gz file..."
        else
            recho "Error creating tar.gz file."
            exit 1
        fi
    

















    elif [ "$MIGRATE" == "import" ]; then
        # Put the code for the 'import' case here
        gecho "importing..."

        # If $PROJECT_NAME already exists, move it to $PROJECT_NAME-$datetime        
        _project_dir=$NAME_SCRIPTS_DIRECTORY_PATH/../$PROJECT_NAME

        # if debg is true, print the following
        if [ "$DEBUG" = true ]; then
            mecho "$_project_dir"
            # exit 0
        fi

        ## $_project_dir >> /home/vicmrp/docker/migration_station/../../../api.security.ait.dtu.dk
        if [ -d "$_project_dir" ]; then
            # if debug the true, print the following
            datetime=$(date '+%Y-%m-%d-%H-%M-%S')
            gecho "Moving $PROJECT_NAME to $PROJECT_NAME-$datetime..."
            mv $_project_dir $_project_dir-$datetime
        fi

        # Extract the tar.gz file and put it in the parent directory
        _tar_project_dir=$NAME_SCRIPTS_DIRECTORY_PATH/$PROJECT_NAME.tar.gz
        gecho "Extracting tar.gz file...."
        tar -xzf $_tar_project_dir -C $NAME_SCRIPTS_DIRECTORY_PATH/../ > /dev/null


        # cd to the project directory
        gecho "cd's to $NAME_SCRIPTS_DIRECTORY_PATH/../$PROJECT_NAME/.devcontainer/.docker-migrate"
        cd $NAME_SCRIPTS_DIRECTORY_PATH/../$PROJECT_NAME/.devcontainer/.docker-migrate
        # if debug is true, print the following
        if [ "$DEBUG" = true ]; then
            mecho "pwd is $(pwd)"
        fi

        get__images
        gecho "Importing images..."
        for image in "${images[@]}"; do
            gecho "Loading image $image..."

            # delete image if it exists
            if [ ! -z "$(docker images -q $image)" ]; then

                # if container is using this image, delete it
                if [ ! -z "$(docker ps -a -q -f ancestor=$image)" ]; then
                    recho "Error: Container is using $image."
                    exit 1
                fi

                oecho "Deleting aleady existing image in this docker enviroment; image: $image..."
                docker rmi $image >/dev/null
            fi
            
            safe_image_name=$(echo $images | tr '/' '.')
            safe_image_name=$(echo $safe_image_name | tr ':' '_')
            echo $safe_image_name
            docker load -i _images/$safe_image_name.tar >/dev/null

            if [ $? -eq 0 ]; then
                gecho "$image loaded successfully."
            else
                recho "Error loading $image."
                exit 1
            fi
        done
        gecho "Done importing images."


        get__volumes
        gecho "Importing volumes..."
        # import volumes to docker
        for volume in "${volumes[@]}"; do

            # if debug is true, print the following
            if [ "$DEBUG" = true ]; then
                mecho "Importing $volume..."
            fi

            # if volume exists 
            if [ -n "$(docker volume ls -q | grep $volume)" ]; then

                # if debug is true, print the following
                if [ "$DEBUG" = true ]; then
                    mecho "Backup volume volume $volume..."
                fi
                
                backup_filepath=$_project_dir-$datetime/.devcontainer/.docker-migrate/_volumes_backup/
                # check if backup_filepath exist if not create it
                if [ ! -d $backup_filepath ]; then
                    mkdir -p $backup_filepath
                fi                
                backup_volume $volume $backup_filepath
                # check if successful
                if [ $? -eq 0 ]; then
                    gecho "$volume backed up successfully."
                else
                    recho "Error backing up $volume."
                    exit 1
                fi
                # delete the volume from docker enviroment
                # try to delete docker rm $volume
                docker volume rm $volume
                # check if successful
                if [ $? -eq 0 ]; then
                    gecho "$volume deleted successfully."
                else
                    recho "Error deleting $volume."
                    exit 1
                fi
            fi
                
            docker volume create $volume

            docker run --rm -v $volume:/volume -v $(pwd)/_volumes:/backup alpine tar -xzvf /backup/$volume.tar >/dev/null
            if [ $? -eq 0 ]; then
                gecho "$volume imported successfully."
            else
                recho "Error importing $volume."
                exit 1
            fi

        done

        gecho "Done importing volumes."
        
        delete_old_images_tar_files
        delete_old_volumes_tar_files


    else
        echo "Error: Unknown MIGRATE value: $MIGRATE"
        exit 1
    fi
}



















# PARAMETERS SNAKE_UPPERCASE means that the variable is a constant after being set
MIGRATE=""
DEBUG=false
NAME_CURRENT_FOLDER=""
NAME_DOCKER_MIGRATE=".docker-migrate"
NAME_MIGRATION_STATION="migration_station"
NAME_SCRIPTS_DIRECTORY_PATH="" # the location of the script
PROJECT_NAME="" # the name of the project

# Process and validate command-line arguments
process_arguments "$@"
validate_arguments
set_current_folder_name
set_scripts_directory_path
validate_migration_and_directory
stop_running_containers
set_project_name

if [ "$DEBUG" = true ]; then
    mecho "MIGRATE: $MIGRATE"
    mecho "DEBUG: $DEBUG"
    mecho "NAME_CURRENT_FOLDER: $NAME_CURRENT_FOLDER"
    mecho "NAME_DOCKER_MIGRATE: $NAME_DOCKER_MIGRATE"
    mecho "NAME_MIGRATION_STATION: $NAME_MIGRATION_STATION"
    mecho "NAME_SCRIPTS_DIRECTORY_PATH: $NAME_SCRIPTS_DIRECTORY_PATH"
    mecho "PROJECT_NAME: $PROJECT_NAME"
fi

execute_migration
restart_containers

exit 0
