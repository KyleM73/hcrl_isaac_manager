# Setup

## Environment variables
```bash
touch scripts/.env.wandb
echo "export WANDB_USERNAME=<username>" >> scripts/.env.wandb
echo "export WANDB_API_KEY=<key>" >> scripts/.env.wandb
```
Cluster only:
```bash
touch scripts/cluster/.env.cluster
```

Fill in the following:
```bash
###
# Cluster specific settings
###

# Job scheduler used by cluster.
# Currently supports PBS and SLURM
CLUSTER_JOB_SCHEDULER=SLURM
# Docker cache dir for Isaac Sim (has to end on docker-isaac-sim)
# e.g. /cluster/scratch/$USER/docker-isaac-sim
CLUSTER_ISAAC_SIM_CACHE_DIR=/some/path/on/cluster/docker-isaac-sim
# Isaac Lab directory on the cluster (has to end on isaaclab)
# e.g. /cluster/home/$USER/isaaclab
CLUSTER_ISAACLAB_DIR=/some/path/on/cluster/isaaclab
# Cluster login
CLUSTER_LOGIN=username@cluster_ip
# Cluster scratch directory to store the SIF file
# e.g. /cluster/scratch/$USER
CLUSTER_SIF_PATH=/some/path/on/cluster/
# Remove the temporary isaaclab code copy after the job is done
REMOVE_CODE_COPY_AFTER_JOB=false
# Python executable within Isaac Lab directory to run with the submitted job
CLUSTER_PYTHON_EXECUTABLE=source/extensions/isaaclab.hcrl/scripts/server_train.py
```
Replace email in `scripts/cluster/submit_job_slurm.sh`:
```bash
#SBATCH --mail-user=<email>
```

## Gitman setup
```bash
pip3 install gitman
gitman update
```
Note that adding the `--force` flag will overwrite all local changes.

# Usage

## Local
See Isaaclab instructions to setup Isaac Sim and the docker interface, the IsaacLab folder in `resources/` can be treated as if it were the standalone repo, just with the hcrl extension installed.

## Cluster
```bash
sudo scripts/cluster.sh push # first time only
sudo scripts/cluster.sh job --task Spot-Baseline-v0
```