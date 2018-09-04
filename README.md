# Install iExec Kata Worker

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

This script will install Docker Engine and Kata Containers if required. 
Then it will configure Docker to use Kata Containers by default.
You will be able to configure vCPU number and RAM quantity which will be used for iExec task execution.