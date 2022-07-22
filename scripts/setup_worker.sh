#!/usr/bin/env bash
set -e

sudo apt update && sudo apt -y upgrade
echo "deb http://archive.ubuntu.com/ubuntu/ bionic main" | sudo tee -a /etc/apt/sources.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32
sudo add-apt-repository -y ppa:ondrej/php 
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y apt-transport-https exiftool git mysql-client nodejs php8.1 unzip
sudo apt-get remove -y apache2 apache2-utils
sudo apt install -y libjpeg8 libicu-dev libssh2-1 libssh2-1-dev libtiff5 libz-dev libzip-dev libomp-dev libgomp1
sudo apt install -y php8.1-{apcu,dom,bcmath,fpm,opcache,intl,mysql,mbstring,zip,redis}
curl -sS https://getcomposer.org/installer -o composer-setup.php \
&& sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer


### Install pm2 and phing
sudo npm install pm2 -g
curl -OL https://www.phing.info/get/phing-2.17.0.phar
sudo mv ./phing-2.17.0.phar /usr/bin/phing
sudo chmod +x /usr/bin/phing
sudo mv /tmp/configs/pm2.service /etc/systemd/system/pm2.service
sudo systemctl daemon-reload
sudo systemctl enable pm2

chmod 700 /home/ubuntu/.ssh
echo $ADMIN_SSH_PUBLIC_KEY > /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys

### Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws/ awscliv2.zip

### Install CUDA
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo DEBIAN_FRONTEND=noninteractive apt-get install keyboard-configuration
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /"
sudo apt-get update
sudo apt-get install -y nvidia-driver-510 cuda libcudnn8=8.4.0.27-1+cuda11.6 libcudnn8-dev=8.4.0.27-1+cuda11.6 

# Install CodeDeploy Agent
sudo apt-get install -y ruby wget
wget https://aws-codedeploy-$AWS_REGION.s3.$AWS_REGION.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto | tee /tmp/codedeploy_logfile
sudo systemctl enable codedeploy-agent

### Install cloudwatch agent
sudo curl -o /root/amazon-cloudwatch-agent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E /root/amazon-cloudwatch-agent.deb
sudo rm -f /root/amazon-cloudwatch-agent.deb
sudo cp /tmp/configs/cloudwatch_agent/worker.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sudo systemctl enable amazon-cloudwatch-agent.service

sudo rm -rf /tmp/configs
