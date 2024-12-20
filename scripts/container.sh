#!/usr/bin/env bash

# make the cwd the pwd
cd "$(dirname "$0")"
# export wandb api keys
wandb_env_file="$(pwd)/.env.wandb"
cat $wandb_env_file >> ../resources/IsaacLab/docker/.env.base
# take git ownership of the hcrl extension
sudo chown -R "${USER:-$(id -un)}" ../resources/IsaacLab/source/extensions/isaaclab.hcrl/
# turn off x11 mode
ssh_mode='"0"'
sed -i "s/^x11_forwarding_enabled.*/x11_forwarding_enabled: ${ssh_mode}/" ../resources/IsaacLab/docker/.container.cfg
# start the container
python3 ../resources/IsaacLab/docker/container.py "${@:1}" base
