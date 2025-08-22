SHELL := /bin/bash
.ONESHELL:

# Package manager selection - can be 'conda' or 'uv'
PACKAGE_MANAGER ?= conda
VENV_NAME ?= ilab
ISAACSIM_SETUP := resources/IsaacLab/_isaac_sim/setup_conda_env.sh
PYTHON_PATH := resources/isaacsim/_build/linux-x86_64/release/kit/python/bin/python3

.PHONY: all deps gitman clean setup setup-conda setup-uv clean-conda clean-uv wandb cluster

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

clean-conda:
	export CONDA_NO_PLUGINS=true; \
	source $$HOME/miniconda3/etc/profile.d/conda.sh; \
	if [ "$$CONDA_DEFAULT_ENV" = "$(VENV_NAME)" ]; then \
		conda deactivate; \
	fi; \
	if conda info --envs | grep -qE '^\s*$(VENV_NAME)\s'; then \
		conda remove -y --name $(VENV_NAME) --all; \
	fi; \

clean-uv:
	@if [ -d "resources/IsaacLab/$(VENV_NAME)" ]; then \
		rm -rf resources/IsaacLab/$(VENV_NAME); \
	fi

setup: setup-$(PACKAGE_MANAGER)

setup-conda:
	export CONDA_NO_PLUGINS=true; \
	source $$HOME/miniconda3/etc/profile.d/conda.sh; \
	cp scripts/isaacsim/setup_conda_env.sh resources/IsaacLab/_isaac_sim/setup_conda_env.sh; \
	cp scripts/isaacsim/setup_python_env.sh resources/IsaacLab/_isaac_sim/setup_python_env.sh; \
	cd resources/IsaacLab && ./isaaclab.sh -c $(VENV_NAME); \
	conda run -n $(VENV_NAME) ./isaaclab.sh -i rsl_rl; \
	if [ ! -f "scripts/.env.wandb" ]; then \
		$(MAKE) wandb; \
	fi

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
	isaaclab -i rsl_rl; \
	if [ ! -f "scripts/.env.wandb" ]; then \
		$(MAKE) wandb; \
	fi

conda:
	$(MAKE) PACKAGE_MANAGER=conda all

uv:
	$(MAKE) PACKAGE_MANAGER=uv all

wandb:
	@read -p "W&B Username: " WANDB_USERNAME; \
	read -p "W&B API Key: " WANDB_API_KEY; \
	echo "Writing wandb env file..."; \
	WANDB_USERNAME=$$WANDB_USERNAME WANDB_API_KEY=$$WANDB_API_KEY envsubst < scripts/cluster/tools/.env.wandb.template > scripts/.env.wandb

cluster:
	@read -p "Home Directory (`echo '$$HOME'` from TACC machine): " HOME; \
	read -p "Scratch Directory (`echo '$$SCRATCH'` from TACC machine): " SCRATCH; \
	case "$$HOME" in /*) ;; *) HOME="/$$HOME" ;; esac; \
	case "$$SCRATCH" in /*) ;; *) SCRATCH="/$$SCRATCH" ;; esac; \
	echo "Writing cluster env file..."; \
	HOME=$$HOME SCRATCH=$$SCRATCH envsubst < scripts/cluster/tools/.env.cluster.template > scripts/cluster/.env.cluster

	@read -p "Email (for job notifications): " EMAIL; \
	echo "Writing SLURM job config file..."; \
	EMAIL=$$EMAIL envsubst < scripts/cluster/tools/submit_job_slurm.template.sh > scripts/cluster/submit_job_slurm.sh

	@echo "Successfully configured cluster setup."
