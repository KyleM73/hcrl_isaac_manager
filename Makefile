SHELL := /bin/bash
.ONESHELL:

# Package manager selection - can be 'conda' or 'uv'
PACKAGE_MANAGER ?= conda
VENV_NAME ?= ilab
ISAACSIM_SETUP := resources/IsaacLab/_isaac_sim/setup_conda_env.sh
PYTHON_PATH := resources/isaacsim/_build/linux-x86_64/release/kit/python/bin/python3
RC_FILE := $$HOME/.bashrc

# other variables
TOPDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ENV_BASH := $(TOPDIR)/scripts/.env.bash

.PHONY: all deps gitman clean setup setup-conda setup-uv clean-conda clean-uv cluster

all: deps gitman clean setup

deps:
	sudo apt-get update && sudo apt-get upgrade -y
	sudo apt-get install -y cmake build-essential
	sudo apt autoremove -y
	@if ! command -v gcc >/dev/null 2>&1 || [ $$(gcc -dumpversion | cut -d. -f1) -lt 11 ]; then \
		sudo apt-get install -y gcc-11 g++-11; \
		sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 200; \
		sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 200; \
	fi
	@if ! command -v git-lfs >/dev/null 2>&1; then \
		sudo apt install -y git-lfs; \
	fi
	@if [ "$$PACKAGE_MANAGER" = "uv" ]; then \
		if ! command -v uv >/dev/null 2>&1; then \
			curl -LsSf https://astral.sh/uv/install.sh | sh; \
			source $$HOME/.cargo/env; \
		fi; \
	fi
	pip install --user --no-input gitman >/dev/null 2>&1 || true; \

gitman:
	gitman update

clean: clean-$(PACKAGE_MANAGER)
	@if grep -Fxq "source $(ENV_BASH)" $(RC_FILE); then \
		echo "[INFO] Removing .env.bash from $$( basename $(RC_FILE) )"
		sed -i "\|source $(ENV_BASH)|d" $(RC_FILE); \
	fi;

clean-conda:
	export CONDA_NO_PLUGINS=true; \
	source $$HOME/miniconda3/etc/profile.d/conda.sh; \
	if [ "$$CONDA_DEFAULT_ENV" = "$(VENV_NAME)" ]; then \
		conda deactivate; \
	fi; \
	if conda info --envs | grep -qE '^\s*$(VENV_NAME)\s'; then \
		conda remove -y --name $(VENV_NAME) --all; \
	fi;

clean-uv:
	@if [ -d "resources/IsaacLab/$(VENV_NAME)" ]; then \
		rm -rf resources/IsaacLab/$(VENV_NAME); \
	fi;

setup: setup-$(PACKAGE_MANAGER)
	@if [ ! -f "$(TOPDIR)/scripts/.env.wandb" ]; then \
		read -p "W&B Username: " WANDB_USERNAME; \
		read -p "W&B API Key: " WANDB_API_KEY; \
		echo "[INFO] Writing wandb env file..."; \
		WANDB_USERNAME=$$WANDB_USERNAME WANDB_API_KEY=$$WANDB_API_KEY envsubst < scripts/cluster/tools/.env.wandb.template > scripts/.env.wandb; \
	fi;
	@if ! grep -Fxq "source $(ENV_BASH)" $(RC_FILE); then \
		echo "[INFO] Adding .env.bash to $$( basename $(RC_FILE) )"; \
		echo "source $(ENV_BASH)" >> $(RC_FILE); \
	fi;

setup-conda:
	export CONDA_NO_PLUGINS=true; \
	source $$HOME/miniconda3/etc/profile.d/conda.sh; \
	cp scripts/isaacsim/setup_conda_env.sh resources/IsaacLab/_isaac_sim/setup_conda_env.sh; \
	cp scripts/isaacsim/setup_python_env.sh resources/IsaacLab/_isaac_sim/setup_python_env.sh; \
	cd resources/IsaacLab && ./isaaclab.sh -c $(VENV_NAME); \
	conda run -n $(VENV_NAME) ./isaaclab.sh -i rsl_rl;

setup-uv:
	uv venv --clear --python $(PYTHON_PATH) resources/IsaacLab/$(VENV_NAME)
	cat >> resources/IsaacLab/$(VENV_NAME)/bin/activate <<-'EOF'
	if [[ "$${BASH_SOURCE[0]}" == /* ]]; then
	    ACTIVATE_SCRIPT_PATH="$${BASH_SOURCE[0]}"
	else
	    ACTIVATE_SCRIPT_PATH="$$(pwd)/$${BASH_SOURCE[0]}"
	fi
	ACTIVATE_SCRIPT_DIR="$$(dirname "$$(readlink -f "$$ACTIVATE_SCRIPT_PATH")")"
	ISAACLAB_ROOT="$$ACTIVATE_SCRIPT_DIR/../.."
	ISAACLAB_ROOT="$$(readlink -f "$$ISAACLAB_ROOT")"
	. "$$ISAACLAB_ROOT/_isaac_sim/setup_conda_env.sh"
	export ISAACLAB_PATH="$$ISAACLAB_ROOT"
	export CONDA_PREFIX="$$VIRTUAL_ENV"
	EOF
	cat > resources/IsaacLab/$(VENV_NAME)/bin/isaaclab <<-'EOF'
	#!/usr/bin/env bash
	set -e
	if [[ "$$0" == /* ]]; then
	    SCRIPT_PATH="$$0"
	else
	    SCRIPT_PATH="$$(pwd)/$$0"
	fi
	SCRIPT_DIR="$$(dirname "$$(readlink -f "$$SCRIPT_PATH")")"
	ISAACLAB_SCRIPT="$$SCRIPT_DIR/../../isaaclab.sh"
	ISAACLAB_SCRIPT="$$(readlink -f "$$ISAACLAB_SCRIPT")"
	exec "$$ISAACLAB_SCRIPT" "$$@"
	EOF
	chmod +x resources/IsaacLab/$(VENV_NAME)/bin/isaaclab
	source resources/IsaacLab/$(VENV_NAME)/bin/activate && \
	hash -r && \
	export CONDA_PREFIX="$$VIRTUAL_ENV" && \
	uv pip install --upgrade pip && \
	python -m pip install --upgrade pip && \
	isaaclab -i rsl_rl;

conda:
	$(MAKE) PACKAGE_MANAGER=conda all

uv:
	$(MAKE) PACKAGE_MANAGER=uv all

cluster:
	@if [ ! -f "$(TOPDIR)/scripts/cluster/.env.cluster" ]; then \
		read -p "TACC Username: " CLUSTER_USERNAME; \
		read -p "Home Directory (`echo '$$HOME'` from TACC machine): " HOME; \
		read -p "Scratch Directory (`echo '$$SCRATCH'` from TACC machine): " SCRATCH; \
		case "$$HOME" in /*) ;; *) HOME="/$$HOME" ;; esac; \
		case "$$SCRATCH" in /*) ;; *) SCRATCH="/$$SCRATCH" ;; esac; \
		echo "[INFO] Writing cluster env file..."; \
		HOME=$$HOME SCRATCH=$$SCRATCH CLUSTER_USERNAME=$$CLUSTER_USERNAME envsubst < scripts/cluster/tools/.env.cluster.template > scripts/cluster/.env.cluster; \
	fi;
	@if [ ! -f "$(TOPDIR)/scripts/cluster/submit_job_slurm.sh" || ! -f "$(TOPDIR)/scripts/cluster/submit_distributed_job_slurm.sh" ]; then \
		read -p "Email (for job notifications): " EMAIL; \
		echo "[INFO] Writing SLURM job config file..."; \
		EMAIL=$$EMAIL QUEUE="gpu-a100-small" NUM_PROCS=1 envsubst < scripts/cluster/tools/submit_job_slurm.template.sh > scripts/cluster/submit_job_slurm.sh; \
		EMAIL=$$EMAIL QUEUE="gpu-a100" NUM_PROCS=2 envsubst < scripts/cluster/tools/submit_job_slurm.template.sh > scripts/cluster/submit_distributed_job_slurm.sh; \
	fi;
	if ! command -v docker >/dev/null 2>&1; then \
		curl -fsSL https://get.docker.com -o get-docker.sh; \
		sudo sh get-docker.sh; \
		sudo groupadd docker; \
		sudo usermode -aG docker $$USER; \
		newgrp docker; \
		echo "[INFO] Docker successfully installed and configured. Log out and back in for changes to take effect, then rerun `make cluster`."; \
		exit 0; \
	fi;
	if ! command -v nvidia-container-toolkit >/dev/null 2>&1; then \
		curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
			&& curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
			sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
			sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
			&& \
			sudo apt-get update; \
		sudo apt-get install -y nvidia-container-toolkit; \
		sudo systemctl restart docker; \
		sudo nvidia-ctk runtime configure --runtime=docker; \
		sudo systemctl restart docker; \
	fi;
	if ! command -v apptainer >/dev/null 2>&1; then \
		sudo apt update; \
		sudo apt install -y software-properties-common; \
		sudo add-apt-repository -y ppa:apptainer/ppa; \
		sudo apt update; \
		sudo apt install -y apptainer; \
	fi;
	$(TOPDIR)/scripts/container.sh start;
	$(TOPDIR)/scripts/cluster.sh push;
