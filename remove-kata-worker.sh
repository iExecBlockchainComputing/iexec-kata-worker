#!/bin/bash

echo "Welcome to iExec Kata Worker removal tool..."
# Showing components list to be removed
echo "-----------------------------------------"
echo "We will remove following components:"

if [ ! $(dpkg-query -W -f='${Status}' kata-runtime 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
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

if [ ! $(dpkg-query -W -f='${Status}' kata-runtime 2>/dev/null | grep -c "ok installed") -eq 0 ] ; then
	apt-get -y remove kata-runtime kata-proxy kata-shim
	# Removing docker daemon configuration
	rm -f /etc/docker/daemon.json

	# Restoring docker daemon configuration if needed
    if [ -f /etc/docker/daemon.json.bak ]; then
      echo "-----------------------------------------"
      echo "Restoring docker daemon configuration..."
      mv /etc/docker/daemon.json.bak /etc/docker/daemon.json
    fi

    # Restarting docker daemon
    echo "-----------------------------------------"
    echo "Restaring docker daemon..."
    systemctl daemon-reload
    systemctl restart docker
    echo "-----------------------------------------"

fi

# Removing docker image
docker rmi -f iexechub/worker:latest
echo "-----------------------------------------"
echo "iExec Kata Worker was successfully removed."
echo "-----------------------------------------"
