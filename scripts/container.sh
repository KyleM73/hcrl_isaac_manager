#!/usr/bin/env bash

# make the cwd the pwd
cd "${0%/*}"
# export wandb api keys
source ./wandb.sh
# take git ownership of the hcrl extension
sudo chown -R "${USER:-$(id -un)}" ../resources/IsaacLab/source/extensions/isaaclab.hcrl/
# turn off x11 mode
ssh_mode='"0"'
sed -i "s/^__ISAACLAB_X11_FORWARDING_ENABLED.*/__ISAACLAB_X11_FORWARDING_ENABLED: ${ssh_mode}/" ../resources/IsaacLab/docker/.container.yaml
# add train and safe scripts and ignore them from git tracking
if ! grep -Fxq "source/train.sh" ../resources/IsaacLab/.gitignore
then
    echo "" >> ../resources/IsaacLab/.gitignore
    echo "# train script" >> ../resources/IsaacLab/.gitignore
    echo "source/train.sh" >> ../resources/IsaacLab/.gitignore
fi
cp train.sh ../resources/IsaacLab/source/train.sh
chmod +x ../resources/IsaacLab/source/train.sh
if ! grep -Fxq "source/mark_safe.sh" ../resources/IsaacLab/.gitignore
then
    echo "" >> ../resources/IsaacLab/.gitignore
    echo "# mark safe script" >> ../resources/IsaacLab/.gitignore
    echo "source/mark_safe.sh" >> ../resources/IsaacLab/.gitignore
fi
cp mark_safe.sh ../resources/IsaacLab/source/mark_safe.sh
chmod +x ../resources/IsaacLab/source/mark_safe.sh
# start the container
../resources/IsaacLab/docker/container.sh $@
