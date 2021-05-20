sudo apt update
sudo apt install -y apache2
sudo mv /var/www/html/index.html /var/www/html/index.html.old
sudo apt install -y docker.io
sudo usermod -a -G docker ubuntu
git clone https://github.com/tacobayle/demovip_server
cd demovip_server
sudo docker build . --tag demovip_server:latest
sudo apt-get install -y apache2-utils
sudo apt install -y python3-pip
sudo apt install -y python-pip
sudo apt install -y python-jmespath
sudo apt install -y jq
sudo apt install -y sshpass
pip install ansible==2.9.12
pip install avisdk==18.2.9
pip3 install avisdk==18.2.9
pip install pyvmomi
pip install dnspython
pip3 install dnspython
pip3 install netaddr
pip install netaddr
sudo -u ubuntu ansible-galaxy install -f avinetworks.avisdk
cd /usr/local/bin
sudo wget https://github.com/vmware/govmomi/releases/download/v0.24.0/govc_linux_amd64.gz
sudo gunzip govc_linux_amd64.gz
sudo mv govc_linux_amd64 govc
sudo chmod +x govc
sudo rm -fr /etc/netplan/50-cloud-init.yaml
sudo rm -fr /home/ubuntu/.ssh
sudo cloud-init clean --logs
sudo halt

# to create the ova: ovftool vi://vcenter.sddc-54-203-134-221.vmwarevmc.com/SDDC-Datacenter/vm/ubuntu-bionic-18.04-cloudimg easyavi-ubuntu-bionic.ova
# OVT tool: VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle

# update nsxt_infra : remove rules for backend and mgmt network, update progress NSX category, update userdata for jump and backend.