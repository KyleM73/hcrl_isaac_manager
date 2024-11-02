#!/usr/bin/env bash

# make the cwd the pwd
cd "$(dirname "$0")"

cp cluster/.env.cluster ../resources/Isaaclab/docker/cluster/.env.cluster
cp .env.wandb  ../resources/Isaaclab/docker/cluster/.env.wandb
cp cluster/cluster_interface.sh  ../resources/Isaaclab/docker/cluster/cluster_interface.sh
cp cluster/run_singularity.sh  ../resources/Isaaclab/docker/cluster/run_singularity.sh
cp cluster/submit_job_slurm.sh  ../resources/Isaaclab/docker/cluster/submit_job_slurm.sh

../resources/Isaaclab/docker/cluster/cluster_interface.sh "${@:1}"