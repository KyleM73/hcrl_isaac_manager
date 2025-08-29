MANAGER_DIR="$(realpath $( cd "$( dirname "$0" )" &> /dev/null && pwd )/../)"

alias ilab="source ${MANAGER_DIR}/scripts/.env.wandb && cd ${MANAGER_DIR}/resources/IsaacLab/source/hcrl_isaaclab && conda activate ilab"
alias manager="cd ${MANAGER_DIR} && conda activate base"
