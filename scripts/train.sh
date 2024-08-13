#!/usr/bin/env bash

# mark extensions as safe
git config --global --add safe.directory /workspace/isaaclab/source/extensions/isaaclab.hcrl
# train
/workspace/isaaclab/isaaclab.sh -p /workspace/isaaclab/source/extensions/isaaclab.hcrl/scripts/train_estimator.py --headless --enable_cameras --video $@
