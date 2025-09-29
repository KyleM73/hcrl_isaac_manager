#!/usr/bin/env bash

# get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
HCRL_ISAACLAB_DIR="$( realpath "${SCRIPT_DIR}/../resources/IsaacLab/source/hcrl_isaaclab" )"
OUTPUTS_DIR="${HCRL_ISAACLAB_DIR}/outputs"

print_help() {
    echo "Usage: $0 command --task task_name [--help]"
    echo
    echo "Arguments:"
    echo "  command                         'add' to add a listener for the specified task. 'remove' to remove an existing listener for the task"
    echo "  --task task_name                The IsaacLab environment to run during video recording"
    echo "  --wandb_project project_path    The path (<entity>/<project>) for the W&B project to track"
    echo "  --profile profile_name          The conda env to use for video logging. Defaults to 'ilab'"
    echo "  --user user_name                The user whose wandb info should be used for logging (i.e. '.env.wandb.user_name'). Defaults to None (uses '.env.wandb')"
    echo "  -h, --help                      Show this help message and exit"
}

# Parse options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --task)
            task="$2"
            shift
            ;;
        --wandb_project)
            wandb_project="$2"
            shift
            ;;
        --profile)
            profile="$2"
            shift
            ;;
        --user)
            user="$2"
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        -*)
            echo "Invalid option: $1" >&2
            print_help
            exit 1
            ;;
        *)
            command=$1
            ;;
        \? )
            echo "Invalid argument: $1" >&2
            print_help
            exit 1
            ;;
    esac
    shift
done

# Check for command
if [ -z "$command" ]; then
    echo "[ERROR]: command is required." >&2
    print_help
    exit 1
elif [ -z "$task" ]; then
    echo "[ERROR]: task is required." >&2
    print_help
    exit 1
elif [ -z "$wandb_project" ]; then
    echo "[ERROR]: wandb project is required." >&2
    print_help
    exit 1
fi

if [ -z "$profile" ]; then
    profile="ilab"
fi

if [ -z "$user" ]; then
    wandb_file=".env.wandb"
else
    wandb_file=".env.wandb.${user}"
fi


RUN_SCRIPT_COMMAND="mkdir -p ${OUTPUTS_DIR} && $HCRL_ISAACLAB_DIR/scripts/utils/log_videos_async.sh ${SCRIPT_DIR}/${wandb_file} ${profile} --task ${task} --wandb_project ${wandb_project} &> ${OUTPUTS_DIR}/${task,,}_video_logging.log"

CRON_COMMAND="$( printf "SHELL=/bin/bash\n*/30 * * * * ${RUN_SCRIPT_COMMAND}" )"

VIEW_CRONJOBS_MSG="You can view your current jobs with \`crontab -l\`."

case $command in
    add)
        crontab -l > crontmp
        if ! grep -Fq "$CRON_COMMAND" crontmp ; then
            echo "[INFO] Adding cron job..."
            echo "$CRON_COMMAND" >> crontmp
            crontab crontmp
            echo "[INFO] Successfully added cron job. $VIEW_CRONJOBS_MSG"
            rm crontmp
        else
            echo "Error: cron job already exists. $VIEW_CRONJOBS_MSG"
            rm crontmp
            exit 1
        fi
        ;;
    remove)
        crontab -l > crontmp
        if grep -Fq "$CRON_COMMAND" crontmp ; then
            echo "[INFO] Removing cron job..."
            grep -Fxv -f <(printf '%s\n' "$CRON_COMMAND") crontmp > cronout
            crontab cronout
            echo "[INFO] Successfully removed cron job. $VIEW_CRONJOBS_MSG"
            rm crontmp cronout
        else
            echo "Error: cron job does not exist. $VIEW_CRONJOBS_MSG"
            rm crontmp
            exit 1
        fi
        ;;
    *)
        echo "Error: Invalid command: $command" >&2
        print_help
        exit 1
        ;;
esac
