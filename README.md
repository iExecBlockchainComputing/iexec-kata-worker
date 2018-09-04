# Install iExec Kata Worker

iExec Kata Worker installation script will install if required:
* Docker Engine 
* Kata Containers
* iExec Worker

It will prepare Docker environment to execute iExec worker with Kata containers

You will also be able to configure vCPU number and RAM quantity which will be used for iExec task execution.

## Requirements
### Hardware
* Intel VTX 
* ARM Hyp Mode
* IBM Power Systems

### OS
* Ubuntu

## Run installation script
```
sudo bash ./install-kata-worker.sh
```
