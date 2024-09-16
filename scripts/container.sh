#!/usr/bin/env bash

# make the cwd the pwd
cd "${0%/*}"
# export wandb api keys
if ! grep -Fxq "# export wandb api keys" ../resources/IsaacLab/docker/Dockerfile.base
then
    echo "" >> ../resources/IsaacLab/docker/Dockerfile.base
    echo "# export wandb api keys" >> ../resources/IsaacLab/docker/Dockerfile.base
    cat ./wandb >> ../resources/IsaacLab/docker/Dockerfile.base
fi
# take git ownership of the hcrl extension
sudo chown -R "${USER:-$(id -un)}" ../resources/IsaacLab/source/extensions/isaaclab.hcrl/
# turn off x11 mode
ssh_mode='"0"'
sed -i "s/^__ISAACLAB_X11_FORWARDING_ENABLED.*/__ISAACLAB_X11_FORWARDING_ENABLED: ${ssh_mode}/" ../resources/IsaacLab/docker/.container.yaml
# start the container
python3 "../resources/IsaacLab/docker/container.py" "${@:1}"
