#!/usr/bin/env bash

# make the cwd the pwd
cd "$(dirname "$0")"

cp cluster/.env.cluster ../resources/IsaacLab/docker/cluster/.env.cluster
cp .env.wandb  ../resources/IsaacLab/docker/cluster/.env.wandb
cp cluster/cluster_interface.sh  ../resources/IsaacLab/docker/cluster/cluster_interface.sh
cp cluster/run_singularity.sh  ../resources/IsaacLab/docker/cluster/run_singularity.sh
cp cluster/submit_job_slurm.sh  ../resources/IsaacLab/docker/cluster/submit_job_slurm.sh
cp cluster/submit_distributed_job_slurm.sh  ../resources/IsaacLab/docker/cluster/submit_distributed_job_slurm.sh

cd ../resources/IsaacLab/docker/cluster
./cluster_interface.sh "${@:1}"
