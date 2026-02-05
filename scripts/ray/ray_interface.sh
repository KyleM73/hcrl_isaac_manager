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
    echo -e "\nusage: $(basename "$0") [-h] <command> [<job_args>...] -- Utility for interfacing between IsaacLab and Ray clusters."
    echo -e "\noptions:"
    echo -e "  -h              Display this help message."
    echo -e "\ncommands:"
    echo -e "  push                                 Push the docker image to Docker Hub (will be pulled by the cluster on next startup)."
    echo -e "  job [<job_args>]                     Submit a job to the cluster."
    echo -e "  stop [<run_id>] [<script_args>]      Stop a currently running job."
    echo -e "  list [<script_args>]                 View existing jobs on the cluster."
    echo -e "  logs [<run_id>] [<script_file>]      Print logs from a run."
    echo -e "\nwhere:"
    echo -e "  <job_args> are optional arguments specific to the job command."
    echo -e "  <script_args> are the per-script arguments (see Ray documentation and list_jobs.py)."
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
        job_config=$SCRIPT_DIR/job_config.yaml
        # Submit job
        echo "[INFO] Executing job script..."
        RAY_RUNTIME_ENV_IGNORE_GITIGNORE=1 python $SCRIPT_DIR/submit_job.py \
            --config_file $SCRIPT_DIR/ray.cfg \
            --job_config $job_config \
            --aggregate_jobs ray/wrap_resources.py \
                --gpu_per_worker 1 \
                $job_args
        ;;
    stop)
        job_id=$1
        shift
        stop_args="$@"
        source $SCRIPT_DIR/.env.ray
        if python $SCRIPT_DIR/list_jobs.py --user_id $UT_EID --check_id $job_id; then
            ray job stop --address http://100.95.64.90:8265 $job_id $stop_args
        else
            echo "[ERROR] The specified job $job_id cannot be stopped."
            echo "[ERROR] Only running jobs started by you can be cancelled."
            echo "[ERROR] You can view these jobs with \`scripts/ray.sh list\`." 
            exit 1
        fi
        ;;
    list)
        list_args="$@"
        source $SCRIPT_DIR/.env.ray
        python $SCRIPT_DIR/list_jobs.py --user_id $UT_EID $list_args
        ;;
    logs)
        job_id=$1
        shift 1
        logs_args="$@"
        source $SCRIPT_DIR/.env.ray
        if python $SCRIPT_DIR/list_jobs.py --user_id $UT_EID --all_statuses --check_id $job_id; then
            ray job logs --address http://100.95.64.90:8265 $job_id $logs_args
        else
            echo "[ERROR] The specified job $job_id cannot be stopped."
            echo "[ERROR] You may only view the logs of jobs started by you."
            echo "[ERROR] You can view these jobs with \`scripts/ray.sh list --all_statuses\`." 
            exit 1
        fi
        ;;
    *)
        echo "Error: Invalid command: $command" >&2
        help
        exit 1
        ;;
esac
