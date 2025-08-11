SHELL := /bin/bash

.PHONY: all deps gitman clean setup

all: deps gitman clean setup

deps:
	sudo apt-get update && sudo apt-get upgrade -y
	sudo apt-get install -y build-essential
	sudo apt autoremove -y
	@if ! command -v gcc >/dev/null 2>&1 || [ $$(gcc -dumpversion | cut -d. -f1) -lt 11 ]; then \
		sudo apt-get install -y gcc-11 g++-11; \
		sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 200; \
		sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 200; \
	fi
	pip install --user --no-input gitman >/dev/null 2>&1 || true; \

gitman:
	gitman update

clean:
	export CONDA_NO_PLUGINS=true; \
	source $$HOME/miniconda3/etc/profile.d/conda.sh; \
	if [ "$$CONDA_DEFAULT_ENV" = "ilab" ]; then \
		conda deactivate; \
	fi; \
	if conda info --envs | grep -qE '^\s*ilab\s'; then \
		conda remove -y --name ilab --all; \
	fi; \

setup:
	export CONDA_NO_PLUGINS=true; \
	source $$HOME/miniconda3/etc/profile.d/conda.sh; \
	cd resources/IsaacLab && ./isaaclab.sh -c ilab; \
	conda run -n ilab ./isaaclab.sh -i rsl_rl

cluster:
	@read -p "W&B Username: " WANDB_USERNAME; \
	read -p "W&B API Key: " WANDB_API_KEY; \
	echo "Writing wandb env file..."; \
	WANDB_USERNAME=$$WANDB_USERNAME WANDB_API_KEY=$$WANDB_API_KEY envsubst < scripts/cluster/tools/.env.wandb.template > scripts/.env.wandb

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
