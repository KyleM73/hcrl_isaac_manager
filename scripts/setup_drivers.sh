#!/usr/bin/env bash
sudo add-apt-repository ppa:graphics-drivers -y
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install nvidia-driver-550 nvidia-dkms-550