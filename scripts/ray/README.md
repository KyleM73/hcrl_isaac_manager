# Using the Ray Servers

## Setup

Make accounts (or use existing accounts):

- [Tailscale](https://tailscale.com/) (use a non-utexas.edu email)
    - Follow the instructions on account creation to install Tailscale on your local machine
    - When prompted to add a second device, skip the tutorial
- [Github](https://github.com/signup)
- [wandb](https://wandb.ai/signup) (select Models under "What do you want to try first?", if prompted)

Add the server machine to your Tailnet (get link from Slack).

## Dependencies

The ray scripts assume that you've installed IsaacLab and hcrl_isaac using hcrl_isaac_manager.

> Note:
> - All paths below are relative to the `hcrl_isaac_manager` directory.
> - Below assumes you are using `uv` as your package manager. If you use conda, you will need to manually install
> dependencies listed in `pyproject.toml`.
> - Commands below are consistent for Unix-like systems, i.e. Linux and Mac. If running on Windows, some commands may
> be different.

Fill out `scripts/ray/.env.ray` and `scripts/ray/job_config.yaml`. Use absolute paths (should start with `/home/<user>/...`)

Python dependencies from `pyproject.toml` will be automatically installed from the `make deps` hook (automatically
called with `make`). If you want to avoid installing other Isaac Lab dependencies, you can create the uv env with
```bash
uv sync
```

Activate the uv environment. You will need to have the environment activated anytime you want to use the ray commands.

```bash
source .venv/bin/activate
```

Ensure connectivity to the server with

```bash
scripts/ray.sh list
```

This should display a blank table, like so:
```
                           Ray Jobs                                                                                                                             
┏━━━━━━━━┳━━━━━━┳━━━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━┳━━━━━━━━━━━━┓
┃ Job ID ┃ User ┃ Start Time ┃ End Time ┃ Status ┃ Entrypoint ┃
┡━━━━━━━━╇━━━━━━╇━━━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━━╇━━━━━━━━━━━━┩
└────────┴──────┴────────────┴──────────┴────────┴────────────┘
```

## Using the ray.sh interface

You can access the Ray dashboard at `http://<server_ip>:8265`. The dashboard is view-only, i.e. you cannot cancel jobs
from this interface.

### `./ray.sh job`

- Sends a job to the server.
    - You can modify the script that runs (e.g. between `train.py` and `play.py`) in the `python_script` field of `job_config.yaml`
- Can be followed by any arguments you'd like to pass to the script (e.g. `--task reach-v0`)
- Note that once you start a job, the program will output the logs from the job into your shell. You can exit this (Ctrl-C) without affecting the job

### `./ray.sh stop <job_id>`

- Stop a running job
- Can provide additional arguments (see [`ray job stop` docs](https://docs.ray.io/en/latest/cluster/running-applications/job-submission/cli.html#ray-job-stop))
- You can only stop jobs that have been created by you. If you really want to bypass this, comment out the check in
`scripts/ray/ray_interface.sh`.

### `./ray.sh list`

- List your currently running jobs, ascending by start time
- View all users' runs with `--all_users`
- View the status of all runs with `--all_statuses`

### `./ray.sh logs <job_id>`

- Download and print logs for a job
- Can provide additional arguments (see [`ray job logs` docs](https://docs.ray.io/en/latest/cluster/running-applications/job-submission/cli.html#ray-job-logs))
- You can redirect the output to a file with the `>` operator: `./ray.sh logs <job_id> > <file_path>`
- Generally, you can use W&B to view your run logs and metrics. This function is mainly for when your job fails before it can deploy, or if you aren't using W&B

## How it works

1. Currently, each server node runs a modified Isaac Lab docker container with some additional dependencies (ray, git-lfs,
etc.). The `hcrl_robots` repo is also cloned to `/workspace/isaaclab`. This is necessary since `hcrl_robots` files are
too large to mount at runtime.

2. When a job is sent, file mounts (configured in `scripts/ray/job_config.yaml` as `"/path/on/local/": "/path/on/server"`)
are copied from your local machine to the server.

3. User-specified initialization commands (`init_commands` in `job_config.yaml`) are then executed. The default init
command creates a symlink from the top-level `hcrl_robots` to its usual place in `hcrl_isaaclab/resources`.

4. The job script (`python_script` in `job_config.yaml`) is executed with any additional CLI args passed by the user.

5. The script finishes or fails, after which file mounts are deleted.