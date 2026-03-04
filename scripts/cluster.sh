#!/usr/bin/env bash

if [ -z $CLUSTER ]; then
    echo "[ERROR] CLUSTER is not set. Usage: CLUSTER=<value> scripts/cluster.sh <args>"
    exit 1
fi;

# make the cwd the pwd
cd "$(dirname "$0")"

CONFIG_DIR="cluster/${CLUSTER}_config"
if [ ! -d $CONFIG_DIR ]; then
    echo "[ERROR] Config directory $CONFIG_DIR not found for cluster $CLUSTER. Create config from template with \`CLUSTER=$CLUSTER make add-cluster\`."
    exit 1
fi;

cp .env.wandb  ../resources/IsaacLab/docker/cluster/.env.wandb
cp cluster/cluster_interface.sh  ../resources/IsaacLab/docker/cluster/cluster_interface.sh
cp cluster/run_singularity.sh  ../resources/IsaacLab/docker/cluster/run_singularity.sh
cp $CONFIG_DIR/.env.cluster ../resources/IsaacLab/docker/cluster/.env.cluster
cp $CONFIG_DIR/submit_job_slurm.sh  ../resources/IsaacLab/docker/cluster/submit_job_slurm.sh

cd ../resources/IsaacLab/docker/cluster
./cluster_interface.sh "${@:1}"
