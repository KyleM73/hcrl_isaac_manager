.PHONY: all deps gitman setup clean

all: deps gitman setup

deps:
	sudo apt-get update
	sudo apt-get install -y build-essential
	@if ! command -v gcc >/dev/null 2>&1 || [ $$(gcc -dumpversion | cut -d. -f1) -lt 11 ]; then \
		sudo apt-get install -y gcc-11 g++-11; \
		sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 200; \
		sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 200; \
	fi

gitman:
	gitman update

setup:
	@if [ "$$CONDA_DEFAULT_ENV" = "ilab" ]; then \
		conda deactivate; \
	fi; \
	if conda env list | grep -qE '^\s*ilab\s'; then \
		conda remove -y --name ilab --all; \
	fi
	cd resources/IsaacLab && ./isaaclab.sh -c ilab
	conda run -n ilab ./resources/IsaacLab/isaaclab.sh -i rsl_rl

clean:
	@if [ "$$CONDA_DEFAULT_ENV" = "ilab" ]; then \
		conda deactivate; \
	fi
	@if conda env list | grep -qE '^\s*ilab\s'; then \
		conda remove -y --name ilab --all; \
	fi
