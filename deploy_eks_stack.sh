#!/usr/bin/env bash

set -o allexport

for i in bash_scripts/*.shinc ; do
  . "${i}"
done

log_msg "Checking for dependencies"
pre_deploy_check

if [[ -z "${1}" ]]; then
  declare -r MAIN_QUESTION="What action you want to execute?
  1) Deploy     3) Setup
  2) Destroy    4) App_deploy
  Default: Deploy
  -> "
  read -ep "${MAIN_QUESTION}" main_action
  declare -lr MAIN_ACTION="${main_action:-"Deploy"}"
else
  declare -lr MAIN_ACTION="${1:-"Deploy"}"
fi

case "${MAIN_ACTION}" in
  1|deploy)
    log_msg "Starting to deploy the AWS EKS stack"
    cd terraform_automation/
    terraform_deploy
    exit
    ;;
  2|destroy)
    log_msg "Starting to destroy the AWS EKS stack"
    cd terraform_automation/
    terraform_destroy
    [[ $? -eq 0 ]] && rm -rf *tfstate* .terraform/
    exit
    ;;
  3|setup)
    setup_environment
    exit
    ;;
  4|app_deploy)
    declare -r SETUP_QUESTION="Do you want setup the cluster? y/n
    Default: n
    -> "
    read -ep "${SETUP_QUESTION}" setup_action
    declare -lr SETUP_ACTION="${setup_action:-"n"}"
    [[ "${SETUP_ACTION// /}" == 'y' ]] && setup_environment
    declare -ra APPS_TO_DEPLOY="${BASH_ARGV[@]/4}"
    deploy_apps ${APPS_TO_DEPLOY[@]}
    exit
    ;;
  *)
    log_msg "The action \"${MAIN_ACTION}\" is not known"
    exit
    ;;
esac
