#!/usr/bin/env bash

# make the cwd the pwd
cd "$(dirname "$0")"

if [[ -z "${PROFILE}" ]]; then
    CLUSTER_ENV=".env.cluster"
    WANDB_ENV=".env.wandb"
else
    CLUSTER_ENV=".env.cluster.${PROFILE}"
    WANDB_ENV=".env.wandb.${PROFILE}"
fi

cp cluster/$CLUSTER_ENV ../resources/IsaacLab/docker/cluster/.env.cluster
cp $WANDB_ENV  ../resources/IsaacLab/docker/cluster/.env.wandb
cp cluster/cluster_interface.sh  ../resources/IsaacLab/docker/cluster/cluster_interface.sh
cp cluster/run_singularity.sh  ../resources/IsaacLab/docker/cluster/run_singularity.sh
cp cluster/submit_job_slurm.sh  ../resources/IsaacLab/docker/cluster/submit_job_slurm.sh

cd ../resources/IsaacLab/docker/cluster
./cluster_interface.sh "${@:1}"
