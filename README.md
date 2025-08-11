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
CLUSTER_PYTHON_EXECUTABLE="source/hcrl_isaaclab/scripts/train.py --server"
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

> ***Note: when installing Isaac Lab, only install the rsl-rl framework (i.e. `./isaaclab.sh -i rsl-rl`).*** rl-games requires an old version of wandb that is incompatible with hcrl_isaaclab.

## Cluster

After rebuilding the docker image (e.g. for updating dependencies), build and push the sif image with
```bash
scripts/cluster.sh push
```

If you need to repush the existing sif image (e.g. if `push` times out on SSH), use
```bash
scripts/cluster.sh repush
```

To run a task on the cluster, run the command
```bash
scripts/cluster.sh job --task <task_name> <other cli args here>
```

## Asynchronous Video Logging

To asynchronously log videos to W&B, start the listener with
```bash
scripts/video_listener.sh add
```

Remove the listener with
```bash
scripts/video_listener.sh remove
```

> **Note:** the listener must be run on a machine that meets Isaac Sim's [GPU requirements](https://docs.isaacsim.omniverse.nvidia.com/latest/installation/requirements.html#system-requirements).

The listener only tracks a single task (currently "Crab-Baseline-v0" project). Multiple listeners on the same task has undefined behavior. To change the task being tracked, edit `$task` in `video_listener.sh`.

When creating a run, you can record videos asynchronously with the `--log_videos_async` flag.

# Makefile Usage

The project includes a Makefile that supports both **conda** and **UV** package managers for environment management.

## Quick Start

```bash
# Use default package manager (conda)
make
make conda
conda activate ilab

# Use specific package manager
PACKAGE_MANAGER=uv make
make uv
source ilab/bin/activate
```

## Available Targets

### Main Targets
- **`all`** - Run complete setup: deps → gitman → clean → setup
- **`deps`** - Install system dependencies and package managers
- **`gitman`** - Update git submodules
- **`clean`** - Clean up environments (uses selected package manager)
- **`setup`** - Setup development environment (uses selected package manager)

### Package Manager Specific Targets
- **`clean-conda`** - Remove conda environment
- **`clean-uv`** - Remove UV virtual environment
- **`setup-conda`** - Setup conda environment
- **`setup-uv`** - Setup UV virtual environment

### Convenience Targets
- **`conda`** - Force use of conda for all operations
- **`uv`** - Force use of UV for all operations

## Package Manager Selection

### Environment Variable
```bash
# Set UV as default for this session
export PACKAGE_MANAGER=uv

# Or specify per command
PACKAGE_MANAGER=uv make setup
```

### Command Line Override
```bash
# Use UV for this command only
make uv

# Use conda for this command only  
make conda
```

## Detailed Target Descriptions

### `deps` Target
- Updates system packages
- Installs build tools (gcc-11+ if needed)
- Installs UV if `PACKAGE_MANAGER=uv`
- Installs gitman for submodule management

### `gitman` Target
- Updates all git submodules in `resources/`
- Downloads Isaac Sim and IsaacLab repositories
- Maintains hcrl extensions

### `clean` Target
- **Conda**: Deactivates and removes `ilab` environment
- **UV**: Removes `.venv` directory

### `setup` Target
- **Conda**: Creates `ilab` environment and installs IsaacLab
- **UV**: Creates virtual environment and installs package in editable mode

## Examples

### Complete Setup with UV
```bash
# Clean install with UV
PACKAGE_MANAGER=uv make all
```

### Switch Package Managers
```bash
# Start with conda
make conda

# Switch to UV
make uv

# Clean both
make clean
PACKAGE_MANAGER=uv make clean
```

### Development Workflow
```bash
# Initial setup
make deps
make gitman
make setup

# Daily development
make gitman  # Update dependencies
make clean   # Clean environment
make setup   # Recreate environment
```

## Troubleshooting

### Conda Issues
```bash
# Fix conda initialization
conda init bash
source ~/.bashrc

# Reset environment
make clean
make setup
```

### UV Issues
```bash
# Reinstall UV
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.cargo/env

# Reset environment
PACKAGE_MANAGER=uv make clean
PACKAGE_MANAGER=uv make setup
```

### General Issues
```bash
# Clean everything and start fresh
make clean
make deps
make gitman
make setup
```

## Environment Variables

- **`PACKAGE_MANAGER`** - Set to `conda` or `uv` (default: `conda`)
- **`CONDA_NO_PLUGINS`** - Disables conda plugins for stability
- **`SHELL`** - Set to `/bin/bash` for proper shell handling