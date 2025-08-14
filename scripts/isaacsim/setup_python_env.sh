#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -n "$ZSH_VERSION" ]; then
    SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
fi
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SCRIPT_DIR/.:$SCRIPT_DIR/exts/isaacsim.robot.schema/plugins/lib:$SCRIPT_DIR/exts/isaacsim.robot_motion.lula/pip_prebundle:$SCRIPT_DIR/exts/isaacsim.asset.exporter.urdf/pip_prebundle:$SCRIPT_DIR/kit:$SCRIPT_DIR/kit/kernel/plugins:$SCRIPT_DIR/kit/libs/iray:$SCRIPT_DIR/kit/plugins:$SCRIPT_DIR/kit/plugins/bindings-python:$SCRIPT_DIR/kit/plugins/carb_gfx:$SCRIPT_DIR/kit/plugins/rtx:$SCRIPT_DIR/kit/plugins/gpu.foundation
export PYTHONPATH=$PYTHONPATH:$SCRIPT_DIR/kit/python/lib/python3.11:$SCRIPT_DIR/kit/python/lib/python3.11/site-packages:$SCRIPT_DIR/python_packages:$SCRIPT_DIR/exts/isaacsim.simulation_app:$SCRIPT_DIR/extsDeprecated/omni.isaac.kit:$SCRIPT_DIR/kit/kernel/py:$SCRIPT_DIR/kit/plugins/bindings-python:$SCRIPT_DIR/exts/isaacsim.robot_motion.lula/pip_prebundle:$SCRIPT_DIR/exts/isaacsim.asset.exporter.urdf/pip_prebundle:$SCRIPT_DIR/extscache/omni.kit.pip_archive-0.0.0+8131b85d.lx64.cp311/pip_prebundle:$SCRIPT_DIR/exts/omni.isaac.core_archive/pip_prebundle:$SCRIPT_DIR/exts/omni.isaac.ml_archive/pip_prebundle:$SCRIPT_DIR/exts/omni.pip.compute/pip_prebundle:$SCRIPT_DIR/exts/omni.pip.cloud/pip_prebundle
