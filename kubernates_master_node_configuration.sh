echo "######### CHANGING THE HOST NAME ###################"
hostnamectl set-hostname 'k8s-master'
exec bash

echo "########## DISABLE THE SELINUX #####################"
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

echo "######## INSTALLING THE FIREWALL ###################"
yum install firewalld -y
systemctl start firewalld
systemctl enable firewalld
systemctl status firewalld

echo "########## ENABLING THE PORT FOR Kubernetes PROCESSES ############"
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --reload
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

echo "###### NEED TO CONFIGURE THE /etc/hosts FILE AND PUT ENTRY FOR WORKER AND MASTER NODE #######"
#echo "172.31.7.4 k8s-master" >> /etc/hosts
#echo "172.31.12.224 worker-node1" >> /etc/hosts
#echo "172.31.5.160 worker-node2" >> /etc/hosts

echo "########### Kubernetes REPO FOR DOWNLOADING NEEDFUL RPMS #################"
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

echo "############  INSTALLING DOCKER DEPENDENCIES YUM, DEVICE-MAPPER AND LVM2 ###################"				  
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

echo "########### ADDING DOCKER REPO ################"
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

echo "#################### ENABLING THE DOCKER-CE-NIGHTLY ################"
yum-config-manager --enable docker-ce-nightly

echo "################## INSTALLING containerd.io-1.2.6 ######"
yum -y install \
    https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm

echo "########### INSTALLING DOCKER ########################"
yum install -y docker-ce docker-ce-cli

echo "############# STARTING THE DOCKER AND KUBELET SERVICEs ############"

yum install kubeadm -y
systemctl restart docker && systemctl enable docker
systemctl  restart kubelet && systemctl enable kubelet

echo "########### CREATING THE Kubernetes CONFIGURATION DIRECTORIES ##########"

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

echo "############ STARTING THE KUBEADM PROCESSES ##########"
echo " KINDLY NOTE THE KUBEADM JOIN TAKEN AS IT IS REQUIRED TO USE IN WORKER NODES"
sleep 16

export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"