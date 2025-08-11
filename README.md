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
