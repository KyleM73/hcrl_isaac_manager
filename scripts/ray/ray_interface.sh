#!/usr/bin/env bash

#==
# Configurations
#==

# Exits if error occurs
set -e

# Set tab-spaces
tabs 4

# get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ISAACLAB_DIR="$( realpath "${SCRIPT_DIR}/../../../" )"

#==
# Functions
#==

# Function to check docker versions
check_docker_version() {
    # check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo "[Error] Docker is not installed! Please check the 'Docker Guide' for instruction." >&2;
        exit 1
    fi
}

#==
# Main
#==

help() {
    echo -e "\nusage: $(basename "$0") [-h] <command> [<profile>] [<job_args>...] -- Utility for interfacing between IsaacLab and compute clusters."
    echo -e "\noptions:"
    echo -e "  -h              Display this help message."
    echo -e "\ncommands:"
    echo -e "  push [<profile>]              Push the docker image to the cluster."
    echo -e "  job [<profile>] [<job_args>]  Submit a job to the cluster."
    echo -e "\nwhere:"
    echo -e "  <profile>  is the optional container profile specification. Defaults to 'base'."
    echo -e "  <job_args> are optional arguments specific to the job command."
    echo -e "\n" >&2
}

# Parse options
while getopts ":h" opt; do
    case ${opt} in
        h )
            help
            exit 0
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            help
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Check for command
if [ $# -lt 1 ]; then
    echo "Error: Command is required." >&2
    help
    exit 1
fi

command=$1
shift

case $command in
    push)
        if [ $# -gt 1 ]; then
            echo "Error: Too many arguments for push command." >&2
            help
            exit 1
        fi
        echo "Building and pushing Ray Docker image"
        # Check that docker is installed
        check_docker_version
        # Build docker image
        docker build -t isaac-ray:latest -f $SCRIPT_DIR/Dockerfile .
        # Tag and push docker image to Docker Hub
        docker tag isaac-ray:latest esturman/isaac-ray:latest;
        docker push esturman/isaac-ray:latest;
        ;;
    job)
        job_args="$@"
        echo "[INFO] Executing job command"
        [ -n "$job_args" ] && echo -e "\tJob arguments: $job_args"
        source $SCRIPT_DIR/.env.ray
        # Submit job
        echo "[INFO] Executing job script..."
        RAY_RUNTIME_ENV_IGNORE_GITIGNORE=1 python $SCRIPT_DIR/submit_job.py \
            --config_file $SCRIPT_DIR/ray.cfg \
            --env_file $SCRIPT_DIR/.env.ray \
            --py_modules $EXT_PATHS \
            --aggregate_jobs ray/wrap_resources.py \
                --sub_jobs "/workspace/isaaclab/isaaclab.sh -p $PYTHON_SCRIPT $job_args"
        ;;
    *)
        echo "Error: Invalid command: $command" >&2
        help
        exit 1
        ;;
esac
