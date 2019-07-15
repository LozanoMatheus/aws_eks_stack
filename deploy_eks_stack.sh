#!/usr/bin/env bash

declare -xr PROJECT_BASEDIR="$(dirname "${BASH_SOURCE[0]}" | pwd)"
declare -xr CONFIG_DIR="${PROJECT_BASEDIR}/config_files"
declare -r  TERRAFORM_VERSION="${TERRAFORM_VERSION:-'0.12.4'}"
declare -r  AWS_SHARED_CREDENTIALS_FILE=${AWS_SHARED_CREDENTIALS_FILE:-~/.aws/credentials}
declare -r  LOG_FILE="/tmp/${0//.sh/}_$(date +'%Y%m%d').log"
declare -rl KERNEL_NAME="$(uname -s)"
declare -xr AWS_REGION="${AWS_REGION:-"eu-west-2"}"
declare -xr CLUSTER_NAME="${CLUSTER_NAME:-"mlozano-eks-cluster"}"
declare -xr TF_VAR_my_public_ip="${MY_PUBLIC_IP:-"$(curl -s ifconfig.co)"}"
declare -xr TF_VAR_ssh_key_name="${SSH_KEY_NAME:-"ssh_key_eks_workers"}"
declare -xr TF_VAR_ssh_key_path="${SSH_KEY_PATH:-"${PROJECT_BASEDIR}/keys"}"

function log_msg() {
  echo "$(date +'%Y-%m-%d %T')" $@ | tee -a "${LOG_FILE}"
}

for i in bash_scripts/*.shinc ; do
  . "${i}"
done

log_msg "Checking for dependencies"
check_prereqs

if [[ -z "${1}" ]]; then
  declare -r TERRAFORM_QUESTION="What action you want to execute?
  1) Deploy
  2) Destroy
  Default: Deploy
  -> "

  read -ep "${TERRAFORM_QUESTION}" terraform_action
  declare -lr TERRAFORM_ACTION="${terraform_action:-"Deploy"}"
else
  declare -lr TERRAFORM_ACTION="${1:-"Deploy"}"
fi

case "${TERRAFORM_ACTION}" in
  1|deploy)
    log_msg "Starting to deploy the AWS EKS stack"
    cd terraform_automation/
    terraform_deploy
    setup_kubectl
    terraform_write_output
    setup_cluster
    setup_helm
    exit
    ;;
  2|destroy)
    log_msg "Starting to destroy the AWS EKS stack"
    cd terraform_automation/
    delete_apps
    terraform_destroy
    exit
    ;;
  *)
    log_msg "The action \"${TERRAFORM_ACTION}\" is not known"
    exit
    ;;
esac
