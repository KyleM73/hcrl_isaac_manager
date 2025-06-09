#!/usr/bin/env bash

# get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
HCRL_ISAACLAB_DIR="$( realpath "${SCRIPT_DIR}/../resources/IsaacLab/source/hcrl_isaaclab" )"
OUTPUTS_DIR="${HCRL_ISAACLAB_DIR}/outputs"

profile="isaaclab"
task="Crab-Baseline-v0"  # TODO: make this an optional argument

RUN_SCRIPT_COMMAND="mkdir -p ${OUTPUTS_DIR} && $HCRL_ISAACLAB_DIR/scripts/log_videos_async.sh ${SCRIPT_DIR}/.env.wandb ${profile} --task ${task} &>> ${OUTPUTS_DIR}/log_videos_async.log &"
CRON_COMMAND="$( printf "SHELL=/bin/bash\n*/30 * * * * ${RUN_SCRIPT_COMMAND}" )"

VIEW_CRONJOBS_MSG="You can view your current jobs with \`crontab -l\`."

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
            grep -Fv "$CRON_COMMAND" crontmp > cronout
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
        help
        exit 1
        ;;
esac
