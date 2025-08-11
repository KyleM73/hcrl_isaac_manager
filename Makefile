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

