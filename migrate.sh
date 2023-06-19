while [ $# -gt 0 ]; do

    if [[ $1 == *"--"* ]]
    then
        param="${1/--/}"
        declare $param="$2"
        # echo $param $1 $2 # Optional to see the parameter:value result
    fi

  shift 1 # rykker positionelle parameter en gang til venstre
done


if [[ -z "$migrate" ]]; then echo "Please specify '--migrate 'export|import''"; exit 1; fi;

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


# if [ "$migrate" == "export" ]; then
#     echo "Exporting volumes..."
#     bash _export.sh
#     echo "Done exporting volumes."
# elif [ "$migrate" == "import" ]; then
#     echo "Importing volumes..."
#     bash _import.sh
#     echo "Done importing volumes."
# else
#     echo "Please specify '--migrate 'export|import''"
# fi