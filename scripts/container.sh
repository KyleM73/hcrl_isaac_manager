#!/usr/bin/env bash

# make the cwd the pwd
cd "$(dirname "$0")"
# mark hcrl git directories as safe
git config --global --add safe.directory ../resources/IsaacLab/source/hcrl_isaaclab/
# export wandb api keys
if [[ -z "${PROFILE}" ]]; then
    wandb_env_file="$(pwd)/.env.wandb"
else
    wandb_env_file="$(pwd)/.env.wandb.${PROFILE}"
fi
dockerfile="$(pwd)/Dockerfile.base"
target_env_file="../resources/IsaacLab/docker/.env.base"
if ! grep -Fxq -f "$wandb_env_file" "$target_env_file"; then
    cat "$wandb_env_file" >> "$target_env_file"
fi
cat $dockerfile > ../resources/IsaacLab/docker/Dockerfile.base
# take git ownership of the hcrl extension
sudo chown -R "${USER:-$(id -un)}" ../resources/IsaacLab/source/hcrl_isaaclab/
# turn off x11 mode
ssh_mode='"0"'
sed -i "s/^x11_forwarding_enabled.*/x11_forwarding_enabled: ${ssh_mode}/" ../resources/IsaacLab/docker/.container.cfg
# start the container
python3 ../resources/IsaacLab/docker/container.py "${@:1}" base
