#!/bin/bash


# WARNING: Make sure the user you're executing this with;
# is either in the docker UNIX group, or just run the script as root;
# so the application image could be built and pushed to ECR;


# Populate AWS_PARAMETERS, so terraform could provision resources;
# You can generate these keys from AWS IAM console;
# by creating a new user with programmatic access and obtaining;
# these from there;
AWS_PARAMETERS=(
    AWS_ACCESS_KEY_ID=
    AWS_SECRET_ACCESS_KEY=
)


# Populate below PARAMETERS as per your requirements;
# and run with ./run.sh from the current terminal;
PARAMETERS=(
    region=eu-west-1
    db_username=postgres
    db_password=
    db_name=satellites
    db_port=5432
    app_port=8080
    app_bucket_name=satellites-api-data
    app_bucket_file_key=telemetry_data.json
)



function exec() {
    TERRAFORM_ARGS=""

    for PARAM in ${AWS_PARAMETERS[@]}; do
        if [[ $PARAM =~ ^.*=$ ]]; then
            echo -e "${PARAM::-1}: empty value; \nPlease make sure all values inside AWS_PARAMETERS are populated"
            exit 1
        else
            export ${PARAM}
        fi
    done

    for PARAM in ${PARAMETERS[@]}; do
        if [[ $PARAM =~ ^.*=$ ]]; then
            echo -e "${PARAM::-1}: empty value; \nPlease make sure all values inside PARAMETERS are populated"
            exit 1
        else
            TERRAFORM_ARGS="${TERRAFORM_ARGS} -var ${PARAM}"
        fi
    done

    cd ./terraform
    if [[ "$1" == "--destroy" ]]; then
        echo "Destroying with terraform.."

        bash -c "terraform destroy -auto-approve ${TERRAFORM_ARGS}"
        if [[ $? != 0 ]]; then
            echo "Error: Could not destroy terraform resources"
            exit 1
        fi

        echo "Destruction completed!"
        exit 0
    
    else
        echo "Provisioning with terraform.."

    fi

    bash -c "terraform init"
    bash -c "terraform apply -input=false -auto-approve ${TERRAFORM_ARGS}"

    if [[ $? != 0 ]]; then
        echo "Error: Could not provision terraform resources"
        exit 1
    fi

    BACKEND_URL="https://$(terraform output -raw app_address)"

    echo -e "\n\n\nProvisioning completed!\n"
    echo -e "Backend URL: ${BACKEND_URL}\n"
    echo "Endpoints:"
    echo "${BACKEND_URL}/get_satellites - Shows existing satellites and their telemetry data"
    echo "${BACKEND_URL}/add_satellite  - Adds a new satellite to S3 and the RDS database"
    echo -e "\n\nRun below command to see sample satellite data that is expected by the API when creating a new satellite:\n"
    echo -e "$ curl -XPOST -H 'Content-Type: application/json' ${BACKEND_URL}/add_satellite\n\n"
    echo -e "Then repeat the same command with -d '<Your JSON satellite data goes here>' flag to create a satellite:\n"
    echo "$ curl -XPOST -H 'Content-Type: application/json' -d '{"ping": "pong"}' ${BACKEND_URL}/add_satellite"
}

exec $@
