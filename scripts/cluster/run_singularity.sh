#!/usr/bin/env bash

for arg in ${@:3}; do
    if [[ "$arg" == "--distributed" ]]; then
        export CLUSTER_PYTHON_EXECUTABLE="$CLUSTER_PYTHON_DISTRIBUTED_EXECUTABLE"
        echo "(run_singularity.py): Running distributed job"
        break
    fi
done

echo -e "(run_singularity.py): Called on compute node:"
echo -e "\tCurrent isaaclab directory: $1"
echo -e "\tContainer profile: $2"
echo -e "\tPython executable: $CLUSTER_PYTHON_EXECUTABLE ${@:3}"


#==
# Helper functions
#==

setup_directories() {
    # Check and create directories
    for dir in \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/cache/kit" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/cache/ov" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/cache/pip" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/cache/glcache" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/cache/computecache" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/logs" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/data" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/documents"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "(run_singularity.py): Created directory: $dir"
        fi
    done
}


#==
# Main
#==


# get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# use unique tmpdir for each run
JOB_TMPDIR="$TMPDIR/isaaclab_$SLURM_JOB_ID"

# load variables to set the Isaac Lab path on the cluster
source $SCRIPT_DIR/.env.cluster
source $SCRIPT_DIR/.env.wandb
source $SCRIPT_DIR/../.env.base

# make sure that all directories exists in cache directory
mkdir "$JOB_TMPDIR"
setup_directories
# copy all cache files
cp -r $CLUSTER_ISAAC_SIM_CACHE_DIR $JOB_TMPDIR

# make sure logs directory exists (in the permanent isaaclab directory)
mkdir -p "$CLUSTER_ISAACLAB_DIR/logs"
touch "$CLUSTER_ISAACLAB_DIR/logs/.keep"

# copy the temporary isaaclab directory with the latest changes to the compute node
cp -r $1 $JOB_TMPDIR
# Get the directory name
dir_name=$(basename "$1")

# copy container to the compute node
tar -xf $CLUSTER_SIF_PATH/$2.tar -C $JOB_TMPDIR

# execute command in singularity container
# NOTE: ISAACLAB_PATH is normally set in `isaaclab.sh` but we directly call the isaac-sim python because we sync the entire
# Isaac Lab directory to the compute node and remote the symbolic link to isaac-sim
apptainer exec \
    -B $JOB_TMPDIR/docker-isaac-sim/cache/kit:${DOCKER_ISAACSIM_ROOT_PATH}/kit/cache:rw \
    -B $JOB_TMPDIR/docker-isaac-sim/cache/ov:${DOCKER_USER_HOME}/.cache/ov:rw \
    -B $JOB_TMPDIR/docker-isaac-sim/cache/pip:${DOCKER_USER_HOME}/.cache/pip:rw \
    -B $JOB_TMPDIR/docker-isaac-sim/cache/glcache:${DOCKER_USER_HOME}/.cache/nvidia/GLCache:rw \
    -B $JOB_TMPDIR/docker-isaac-sim/cache/computecache:${DOCKER_USER_HOME}/.nv/ComputeCache:rw \
    -B $JOB_TMPDIR/docker-isaac-sim/logs:${DOCKER_USER_HOME}/.nvidia-omniverse/logs:rw \
    -B $JOB_TMPDIR/docker-isaac-sim/data:${DOCKER_USER_HOME}/.local/share/ov/data:rw \
    -B $JOB_TMPDIR/docker-isaac-sim/documents:${DOCKER_USER_HOME}/Documents:rw \
    -B $JOB_TMPDIR/$dir_name:/workspace/isaaclab:rw \
    -B $CLUSTER_ISAACLAB_DIR/logs:/workspace/isaaclab/logs:rw \
    --nv --writable-tmpfs --containall $JOB_TMPDIR/$2.sif \
    bash -c "export OMP_NUM_THREADS=$OMP_NUM_THREADS && export ISAACLAB_PATH=/workspace/isaaclab && export WANDB_USERNAME=$WANDB_USERNAME && export WANDB_API_KEY=$WANDB_API_KEY && cd /workspace/isaaclab && /isaac-sim/python.sh ${CLUSTER_PYTHON_EXECUTABLE} ${@:3}"

EXIT_CODE=$?

# copy resulting cache files back to host
rsync -azPv $JOB_TMPDIR/docker-isaac-sim $CLUSTER_ISAAC_SIM_CACHE_DIR/..
# clean up tmpdir
rm -rf $JOB_TMPDIR

# if defined, remove the temporary isaaclab directory pushed when the job was submitted
# only remove folders if run finished successfully -- otherwise we want to keep the logs
if $REMOVE_CODE_COPY_AFTER_JOB && [ $EXIT_CODE -eq 0 ]; then
    rm -rf $1
fi

if [ $EXIT_CODE -eq 0 ]; then
    echo "(run_singularity.py): Success"
else
    echo "(run_singularity.py): Failed with exit code $EXIT_CODE"
fi

exit $EXIT_CODE
