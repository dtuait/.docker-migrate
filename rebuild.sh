#!/bin/bash

# # array of image names to import
# mapfile -t images < images.txt



# # Stop and remove specified containers
# for container in ${containers[@]}; do
#     if [ "$(docker ps -a -q -f name=$container)" ]; then
#         docker stop $container
#         docker rm $container
#     fi
# done

# # Delete specified images
# for image in ${images[@]}; do
#     if [ "$(docker images -q $image)" ]; then
#         docker rmi $image
#     fi
# done

# # Build and start the services defined in the compose file
# docker compose up -d --build

