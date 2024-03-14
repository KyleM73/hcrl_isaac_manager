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

#==
# Functions
#==

# print the usage description
print_help () {
    echo -e "\nusage: $(basename "$0") [-h] [run] [start] [stop] -- Utility for handling docker in Orbit."
    echo -e "\noptional arguments:"
    echo -e "\t-h, --help         Display the help content."
    echo -e "\tstart              Build the docker image and create the container in detached mode."
    echo -e "\tenter              Begin a new bash process within an existing orbit container."
    echo -e "\tcopy               Copy build and logs artifacts from the container to the host machine."
    echo -e "\tstop               Stop the docker container and remove it."
    echo -e "\n" >&2
}

install_apptainer() {
    # Installation procedure from here: https://apptainer.org/docs/admin/main/installation.html#install-ubuntu-packages
    read -p "[INFO] Required 'apptainer' package could not be found. Would you like to install it via apt? (y/N)" app_answer
    if [ "$app_answer" != "${app_answer#[Yy]}" ]; then
        sudo apt update && sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:apptainer/ppa
        sudo apt update && sudo apt install -y apptainer
    else
        echo "[INFO] Exiting because apptainer was not installed"
        exit
    fi
}

# Function to check docker versions
# If docker version is more than 25, the script errors out.
check_docker_version() {
    # Retrieve Docker version
    docker_version=$(docker --version | awk '{ print $3 }')
    apptainer_version=$(apptainer --version | awk '{ print $3 }')

    # Check if version is above 25.xx
    if [ "$(echo "${docker_version}" | cut -d '.' -f 1)" -ge 25 ]; then
        echo "[ERROR]: Docker version ${docker_version} is not compatible with Apptainer version ${apptainer_version}. Exiting."
        exit 1
    else
        echo "[INFO]: Building singularity with docker version: ${docker_version} and Apptainer version: ${apptainer_version}."
    fi
}

#==
# Main
#==

# check argument provided
if [ -z "$*" ]; then
    echo "[Error] No arguments provided." >&2;
    print_help
    exit 1
fi

# check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "[Error] Docker is not installed! Please check the 'Docker Guide' for instruction." >&2;
    exit 1
fi

# parse arguments
mode="$1"
# resolve mode
case $mode in
    start)
        gpu_idx="$2"
        export GPU_IDX=$gpu_idx
        echo "[INFO] Building the docker image and starting the container in the background..."
        pushd ${SCRIPT_DIR} > /dev/null 2>&1
        docker compose --file docker-compose.yaml up --detach --build --remove-orphans
        docker exec orbit-${gpu_idx:-0} sh -c 'ln -sfT /isaac-sim /workspace/orbit/_isaac_sim'
        popd > /dev/null 2>&1
        ;;
    enter)
        gpu_idx="$2"
        export GPU_IDX=$gpu_idx
        echo "[INFO] Entering the existing 'orbit' container in a bash session..."
        pushd ${SCRIPT_DIR} > /dev/null 2>&1
        docker exec --interactive --tty orbit-${gpu_idx:-0} bash
        popd > /dev/null 2>&1
        ;;
    copy)
        gpu_idx="$2"
        export GPU_IDX=$gpu_idx
        # check if the container is running
        if [ "$( docker container inspect -f '{{.State.Status}}' orbit-${gpu_idx:-0} 2> /dev/null)" != "running" ]; then
            echo "[Error] The 'orbit' container is not running! It must be running to copy files from it." >&2;
            exit 1
        fi
        echo "[INFO] Copying artifacts from the 'orbit' container..."
        echo -e "\t - /workspace/orbit/logs -> artifacts/logs"
        echo -e "\t - /workspace/orbit/docs/_build -> artifacts/docs/_build"
        echo -e "\t - /workspace/orbit/data_storage -> artifacts/data_storage"
        # enter the script directory
        pushd ${SCRIPT_DIR} > /dev/null 2>&1
        # We have to remove before copying because repeated copying without deletion
        # causes strange errors such as nested _build directories
        # warn the user
        echo -e "[WARN] Removing the existing artifacts...\n"
        rm -rf ../artifacts/logs ../artifacts/docs/_build ../artifacts/data_storage

        # create the directories
        mkdir -p ../artifacts/docs

        # copy the artifacts
        docker cp orbit-${gpu_idx:-0}:/workspace/orbit/logs ../artifacts/logs
        docker cp orbit-${gpu_idx:-0}:/workspace/orbit/docs/_build ../artifacts/docs/_build
        docker cp orbit-${gpu_idx:-0}:/workspace/orbit/data_storage ../artifacts/data_storage
        echo -e "\n[INFO] Finished copying the artifacts from the container."
        popd > /dev/null 2>&1
        ;;
    stop)
        echo "[INFO] Stopping the launched docker container..."
        pushd ${SCRIPT_DIR} > /dev/null 2>&1
        docker compose --file docker-compose.yaml down
        popd > /dev/null 2>&1
        ;;
    *)
        echo "[Error] Invalid argument provided: $1"
        print_help
        exit 1
        ;;
esac
