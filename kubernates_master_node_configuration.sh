sudo -s <<EOF
	echo "######### CHANGING THE HOST NAME ###################"
	hostnamectl set-hostname 'master'

	echo "########## DISABLE THE SELINUX #####################"
	setenforce 0
	sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

	#echo "######## INSTALLING THE FIREWALL ###################"
	#yum install firewalld -y
	#systemctl start firewalld
	#systemctl enable firewalld
	#systemctl status firewalld

	#echo "########## ENABLING THE PORT FOR Kubernetes PROCESSES ############"
	#firewall-cmd --permanent --add-port=6443/tcp
	#firewall-cmd --permanent --add-port=2379-2380/tcp
	#firewall-cmd --permanent --add-port=10250/tcp
	#firewall-cmd --permanent --add-port=10251/tcp
	#firewall-cmd --permanent --add-port=10252/tcp
	#firewall-cmd --permanent --add-port=10255/tcp
	#firewall-cmd --reload
	#modprobe br_netfilter
	echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

	echo "###### NEED TO CONFIGURE THE /etc/hosts FILE AND PUT ENTRY FOR WORKER AND MASTER NODE #######"
	echo "`hostname -i | awk -F ' ' '{ print $2 }'` master" >> /etc/hosts

	echo "################## INSTALLING containerd.io-1.2.6 ######"
	yum -y install \
	https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm

	echo "########### Kubernetes REPO FOR DOWNLOADING NEEDFUL RPMS #################"
	touch /etc/yum.repos.d/kubernetes.repo
	echo "[kubernetes]" >> /etc/yum.repos.d/kubernetes.repo
        echo "name=Kubernetes" >> /etc/yum.repos.d/kubernetes.repo
        echo "baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64" >> /etc/yum.repos.d/kubernetes.repo
        echo "enabled=1" >> /etc/yum.repos.d/kubernetes.repo
        echo "gpgcheck=1" >> /etc/yum.repos.d/kubernetes.repo
        echo "repo_gpgcheck=1" >> /etc/yum.repos.d/kubernetes.repo
        echo "gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg" >> /etc/yum.repos.d/kubernetes.repo
        echo "        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" >> /etc/yum.repos.d/kubernetes.repo

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

	echo "########### INSTALLING DOCKER ########################"
	yum install -y docker-ce \
	docker-ce-cli

	echo "############# STARTING THE DOCKER AND KUBELET SERVICEs ############"
	yum install kubeadm -y
	systemctl restart docker && systemctl enable docker
	systemctl  restart kubelet && systemctl enable kubelet

	echo "############ STARTING THE KUBEADM PROCESSES ##########"
	echo " KINDLY NOTE THE KUBEADM JOIN TAKEN IN /tmp/kubeadm.log AS IT IS REQUIRED TO USE IN WORKER NODES"
	kubeadm init >> /tmp/kubeadm.log 2> /dev/null &
	sleep 500

	echo "########### CREATING THE Kubernetes CONFIGURATION DIRECTORIES ##########"
	mkdir -p $HOME/.kube
	cp -ir /etc/kubernetes/admin.conf $HOME/.kube/config
	chown $(id -u):$(id -g) $HOME/.kube/config

	export kubever=$(kubectl version | base64 | tr -d '\n')
	kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
EOF
