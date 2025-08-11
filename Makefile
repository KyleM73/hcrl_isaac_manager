SHELL := /bin/bash

# Package manager selection - can be 'conda' or 'uv'
PACKAGE_MANAGER ?= conda

.PHONY: all deps gitman clean setup setup-conda setup-uv clean-conda clean-uv

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
	if [ "$$CONDA_DEFAULT_ENV" = "ilab" ]; then \
		conda deactivate; \
	fi; \
	if conda info --envs | grep -qE '^\s*ilab\s'; then \
		conda remove -y --name ilab --all; \
	fi; \

clean-uv:
	@if [ -d "resources/IsaacLab/ilab" ]; then \
		rm -rf resources/IsaacLab/ilab; \
	fi

setup: setup-$(PACKAGE_MANAGER)

setup-conda:
	export CONDA_NO_PLUGINS=true; \
	source $$HOME/miniconda3/etc/profile.d/conda.sh; \
	cd resources/IsaacLab && ./isaaclab.sh -c ilab; \
	conda run -n ilab ./isaaclab.sh -i rsl_rl ;\

setup-uv:
	uv venv --clear ilab && \
	source ilab/bin/activate && \
	export CONDA_PREFIX=$$(pwd)/ilab && \
	uv pip install --upgrade pip && \
	cd resources/IsaacLab && \
	./isaaclab.sh -i rsl_rl

conda:
	$(MAKE) PACKAGE_MANAGER=conda all

uv:
	$(MAKE) PACKAGE_MANAGER=uv all
