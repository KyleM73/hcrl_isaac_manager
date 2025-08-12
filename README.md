# Setup

General:
```
make
```

Cluster:
```
make cluster
```

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
scripts/video_listener.sh add --task <task_name>
```

Remove the listener with
```bash
scripts/video_listener.sh remove --task <task_name>
```

More script options can be viewed with `scripts/video_listener.sh --help`. When creating a server run, you can record videos asynchronously with the `--video` flag.

> **Note:** the listener must be run on a machine that meets Isaac Sim's [GPU requirements](https://docs.isaacsim.omniverse.nvidia.com/latest/installation/requirements.html#system-requirements).


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
- **UV**: Removes `ilab` directory

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