#!/bin/bash
set -e

cd "$(dirname ${BASH_SOURCE[0]})"
[[ $UTIL_SOURCED != yes && -f ./util.sh ]] && source ./util.sh

# Ensure settings file exists
ensure_setttings_file "$@"

# Install
install_dependencies "$@"

# Delete
printf "\nWARNING: THIS COMMAND WILL DELETE YOUR ENVIRONMENT AND LEAD TO DATA LOSS.\n"
printf "\nAre you sure you want to proceed? Press ENTER to ABORT OR Type the environment name to confirm removal ($STAGE): "
read -r confirmation

if [[ "$STAGE" != "$confirmation" ]]
then
    printf "\nConfirmation mismatch. Exiting ...\n"
    exit
fi

function componentRemove {
    COMPONENT_DIR=$1
    COMPONENT_NAME=$2

    printf "\Removing component: $COMPONENT_NAME ...\n\n"
    cd $SOLUTION_DIR/$COMPONENT_DIR
    $EXEC sls remove -s $STAGE
}

componentRemove "ui" "UI"
#componentRemove "post-deployment" "Post-Deployment"
#componentRemove "backend" "Backend"
componentRemove "infrastructure" "Infrastructure"

printf "\n----- ENVIRONMENT DELETED SUCCESSFULLY 🎉 -----\n\n\n"
