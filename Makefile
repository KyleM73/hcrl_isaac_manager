SHELL := /bin/bash
.ONESHELL:

# Package manager selection - can be 'conda' or 'uv'
PACKAGE_MANAGER ?= uv
VENV_NAME ?= ilab
RC_FILE ?= $$HOME/.bashrc

# other variables
TOPDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BASH_UTILS := $(TOPDIR)/scripts/utils.sh

.PHONY: all deps gitman clean setup setup-conda setup-uv clean-conda clean-uv docker cluster

all: deps gitman clean setup

deps:
	sudo apt-get update && sudo apt-get install -y cmake build-essential
	sudo apt autoremove -y
	@if [ "$$PACKAGE_MANAGER" = "uv" ]; then \
		if ! command -v uv >/dev/null 2>&1; then \
			curl -LsSf https://astral.sh/uv/install.sh | sh; \
		fi; \
		uv sync; \
	fi
	pip install --user --no-input gitman >/dev/null 2>&1 || true; \

gitman:
	gitman update

clean: clean-$(PACKAGE_MANAGER)
	@if grep -Fq "source $(BASH_UTILS)" $(RC_FILE); then \
		echo "[INFO] Removing $$( basename $(BASH_UTILS) ) from $$( basename $(RC_FILE) )"
		sed -i "\|^.*source $(BASH_UTILS)|d" $(RC_FILE); \
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
		WANDB_USERNAME=$$WANDB_USERNAME WANDB_API_KEY=$$WANDB_API_KEY envsubst < scripts/tools/.env.wandb.template > scripts/.env.wandb; \
	fi;
	@if ! grep -Fq "source $(BASH_UTILS)" $(RC_FILE); then \
		echo "[INFO] Adding $$( basename $(BASH_UTILS) ) to $$( basename $(RC_FILE) )"; \
		echo "PACKAGE_MANAGER=$(PACKAGE_MANAGER) VENV_NAME=$(VENV_NAME) source $(BASH_UTILS)" >> $(RC_FILE); \
		echo -e "[INFO] Successfully added $$( basename $(BASH_UTILS) ) to $$( basename $(RC_FILE) )\n"; \
		echo -e "\t\t1. For development in the main hcrl_isaaclab extension, run:	ilab"; \
		echo -e "\t\t2. For manager use (e.g. cluster scripts), run:					manager"; \
		echo -e "\n"; \
	fi;

setup-conda:
	export CONDA_NO_PLUGINS=true; \
	source $$HOME/miniconda3/etc/profile.d/conda.sh; \
	conda create -n $(VENV_NAME) python=3.11; \
	conda activate $(VENV_NAME); \
	pip install --upgrade pip; \
	pip install "isaacsim[all,extscache]==5.1.0" --extra-index-url https://pypi.nvidia.com; \
	pip install -U torch==2.7.0 torchvision==0.22.0 --index-url https://download.pytorch.org/whl/cu128; \
	cd resources/IsaacLab; \
	./isaaclab.sh -c $(VENV_NAME); \
	./isaaclab.sh -i rsl_rl;

setup-uv:
	uv venv --python 3.11 resources/IsaacLab/$(VENV_NAME); \
	cd resources/IsaacLab && source $(VENV_NAME)/bin/activate; \
	uv pip install --upgrade pip; \
	uv pip install "isaacsim[all,extscache]==5.1.0" --extra-index-url https://pypi.nvidia.com; \
	uv pip install -U torch==2.7.0 torchvision==0.22.0 --index-url https://download.pytorch.org/whl/cu128; \
	./isaaclab.sh -u $(VENV_NAME); \
	./isaaclab.sh -i rsl_rl;

conda:
	$(MAKE) PACKAGE_MANAGER=conda all

uv:
	$(MAKE) PACKAGE_MANAGER=uv all

docker:
	if ! command -v docker >/dev/null 2>&1; then \
		curl -fsSL https://get.docker.com -o get-docker.sh; \
		sudo sh get-docker.sh; \
		sudo groupadd docker; \
		sudo usermod -aG docker $$USER; \
		newgrp docker; \
	fi;
	$(TOPDIR)/scripts/container.sh start;

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
		EMAIL=$$EMAIL QUEUE="gpu-a100-small" NUM_PROCS=1 NUM_CPUS=32 envsubst < scripts/cluster/tools/submit_job_slurm.template.sh > scripts/cluster/submit_job_slurm.sh; \
		EMAIL=$$EMAIL QUEUE="gpu-a100" NUM_PROCS=2 NUM_CPUS=64 envsubst < scripts/cluster/tools/submit_job_slurm.template.sh > scripts/cluster/submit_distributed_job_slurm.sh; \
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
	$(MAKE) docker;
	$(TOPDIR)/scripts/cluster.sh push;
