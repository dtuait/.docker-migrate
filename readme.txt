
This scripts expects to be a submodule under my-git-project/.devcontainer/.docker-migrate, and it relies on the existing of folder next "my-git-project" named migration_station

this script depends on the following paths
for exporting /home/vicmrp/docker/[project]/.docker-migrate
for importing /home/vicmrp/docker/migration_station/




How to export entire project:

first cd to /home/vicmrp/docker/[project]/.docker-migrate

If you want to export images and volumes, then specify them in 
images.txt and volumes.txt

run sudo bash .migrate --migrate 'export'

Under /home/vicmrp/docker/migration_station/
You can find a [project].tar.gz which contains everything, as well as a script named [project] you can use to import in another machine.








How to import project

Put [project].tar.gz and [project] under /home/vicmrp/docker/migration_station/ in the new enviroment.
cd to /home/vicmrp/docker/migration_station/

run the script sudo bash [project] --migrate 'import'

Note if a volume already exist it will be renamed $volume -> $volume-$datetime
Note if a image already exist, it will be deleted.

