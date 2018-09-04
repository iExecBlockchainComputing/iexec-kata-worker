#!/bin/bash

# Function which checks exit status and stops execution
function checkExitStatus() {
  if [ $1 -eq 0 ]; then
    echo OK
  else
    echo $2
    read -p "Press [Enter] to exit..."
    exit 1
  fi
}

echo "Welcome to iExec Kata Worker installer..."
# Showing components list to be installed
echo "-----------------------------------------"
echo "We will install following components:"
if [ $(dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -c "ok installed") -eq 0 ] && [ $(dpkg-query -W -f='${Status}' docker-engine 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
    echo " * Docker Engine"
fi
if [ $(dpkg-query -W -f='${Status}' kata-runtime 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
    echo " * Kata Containers (runtime, proxy and shim)"
fi
echo " * iExec Worker"
echo "-----------------------------------------"
while [ "$answerinstall" != "yes" ] && [ "$answerinstall" != "no" ]; do
    read -p "Do you want to continue? [yes/no] " answerinstall
done

if [ "$answerinstall" == "no" ]; then
    exit 1
fi
echo "-----------------------------------------"

# Installing docker engine
if [ $(dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -c "ok installed") -eq 0 ] && [ $(dpkg-query -W -f='${Status}' docker-engine 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
    echo "Installing docker..."
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce
    usermod -aG docker ubuntu
    docker --version
    checkExitStatus $? "Failed to install docker..."
fi

# Installing Kata Containers
if [ $(dpkg-query -W -f='${Status}' kata-runtime 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
    echo "Installing Kata containers..."
    sh -c "echo 'deb http://download.opensuse.org/repositories/home:/katacontainers:/release/xUbuntu_$(lsb_release -rs)/ /' > /etc/apt/sources.list.d/kata-containers.list"
    curl -sL  http://download.opensuse.org/repositories/home:/katacontainers:/release/xUbuntu_$(lsb_release -rs)/Release.key | apt-key add -
    apt-get update
    apt-get -y install kata-runtime kata-proxy kata-shim

    kata-runtime kata-check
    checkExitStatus $? "Failed to launch Kata containers..."

    # Configuring docker daemon
    echo "Configuring docker daemon..."
    cat >/etc/docker/daemon.json  << EOF
{
  "default-runtime": "kata-runtime",
  "runtimes": {
    "kata-runtime": {
      "path": "/usr/bin/kata-runtime"
    }
  }
}
EOF

    # Restarting docker daemon
    echo "Restaring docker daemon..."
    systemctl daemon-reload
    systemctl restart docker

fi

# Check Kata containers
echo "Checking kata containers support..."
kata-runtime kata-check
checkExitStatus $? "Failed to launch Kata containers..."
echo "-----------------------------------------"

# Configure worker tasks vCPU and RAM
while [ "$answerconfig" != "yes" ] && [ "$answerconfig" != "no" ]; do
    read -p "Do you want to configure task vCPU number and RAM? [yes/no] " answerconfig
    echo "-----------------------------------------"
done

if [ "$answerconfig" == "yes" ]; then

  # Configure worker CPU number and RAM
  echo "Configuring worker task vCPU number and RAM..."

  # Get vCPU number
  while [[ ! $vCPUNumber =~ ^[0-9]+$ ]]; do
    read -p "Enter task vCPU number (min. 1): " vCPUNumber
    if [ $vCPUNumber -lt 1 ]; then
      vCPUNumber=""
    fi
  done
  echo "All tasks will be launched with $vCPUNumber CPUs."
  echo "-----------------------------------------"

  # Get RAM 
  while [[ ! $ram =~ ^[0-9]+$ ]]; do
    read -p "Enter task RAM in megabytes (min. 2048): " ram
    if [ $ram -lt 2048 ]; then
      ram=""
    fi
  done

  # Writing Kata containers config
  sed -i "s/default_vcpus\ =\ [0-9]*/default_vcpus\ =\ $vCPUNumber/g" /usr/share/defaults/kata-containers/configuration.toml
  sed -i "s/default_maxvcpus\ =\ [0-9]*/default_maxvcpus\ =\ $vCPUNumber/g" /usr/share/defaults/kata-containers/configuration.toml
  sed -i -E "s/#?default_memory\ =\ [0-9]*/default_memory\ =\ $ram/g" /usr/share/defaults/kata-containers/configuration.toml
fi

# Pulling iExec worker
docker pull iexechub/worker:latest

echo "-----------------------------------------"
echo "iExec Kata Worker was successfully installed."
echo "-----------------------------------------"