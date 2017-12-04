BOX_OS = "centos/7"
BOX_VERSION = "1710.01"
NETWORK_ADAPTER_NAME = "Microsoft KM-TEST Loopback Adapter"
CERT_PATH = "/vagrant/certs/"
BINARY_PATH = "/vagrant/binaries/"

ETCD_SERVER_COUNT = 3
KUBERNETES_MASTER_COUNT = 2
KUBERNETES_NODE_COUNT = 4

$ipGroup = "10.240.0"
$domainName = "example.com"

$etcdServerNameSuffix = "etcd"
$etcdServersStartIp = 10
$etcdServers = []
$etcdClusterConfig = ""
$etcdServerList = ""

$kubernetesMasterNameSuffix = "kubemaster"
$kubernetesMasterStartIp = 20
$kubernetesMasters = []
$kubernetesMasterList = ""

$kubernetesNodeNameSuffix = "kubenode"
$kubernetesNodeStartIp = 30
$kubernetesNodes = []

$hostsFileContent = ""

for i in 1..ETCD_SERVER_COUNT
$etcdServers << {
    name: "#{$etcdServerNameSuffix}#{i}",
    hostname: "#{$etcdServerNameSuffix}#{i}",
    ipAddress: "#{$ipGroup}.#{$etcdServersStartIp + i}"
}
end

for etcd in $etcdServers
    $hostsFileContent << etcd[:ipAddress] + " " + etcd[:hostname] + " " + etcd[:hostname] + "." + "#{$domainName}" + "\n"
    $etcdClusterConfig << "," + etcd[:hostname] + "=" + "https://" + etcd[:ipAddress] + ":2380"
    $etcdServerList << ",https://" + etcd[:ipAddress] + ":2379"
end
$etcdClusterConfig = $etcdClusterConfig[1..-1]
$etcdServerList = $etcdServerList[1..-1]

for i in 1..KUBERNETES_MASTER_COUNT
$kubernetesMasters << {
    name: "#{$kubernetesMasterNameSuffix}#{i}",
    hostname: "#{$kubernetesMasterNameSuffix}#{i}",
    ipAddress: "#{$ipGroup}.#{$kubernetesMasterStartIp + i}"
}
end

for master in $kubernetesMasters
    $hostsFileContent << master[:ipAddress] + " " + master[:hostname] + " " + master[:hostname] + "." + "#{$domainName}" + "\n"
    $kubernetesMasterList << ",https://" + master[:ipAddress] + ":6443"
end
$kubernetesMasterList = $kubernetesMasterList[1..-1]


for i in 1..KUBERNETES_NODE_COUNT
$kubernetesNodes << {
    number: i,
    name: "#{$kubernetesNodeNameSuffix}#{i}",
    hostname: "#{$kubernetesNodeNameSuffix}#{i}",
    ipAddress: "#{$ipGroup}.#{$kubernetesNodeStartIp + i}"
}
end

for node in $kubernetesNodes
    $hostsFileContent << node[:ipAddress] + " " + node[:hostname] + " " + node[:hostname] + "." + "#{$domainName}" + "\n"
end

$cmdInitialSetup = <<SCRIPT
yum -y update

service firewalld stop
systemctl disable firewalld
yum -y remove firewalld

cat <<EOF > /etc/selinux/config
SELINUX=disabled
SELINUXTYPE=targeted
EOF

cat <<EOF >> /etc/hosts
127.0.0.1    localhost.localdomain localhost
#{$hostsFileContent}
EOF
SCRIPT

$cmdCopyEtcdCertificates = <<SCRIPT
sudo mkdir -p /etc/etcd
yes | cp #{CERT_PATH}ca.pem #{CERT_PATH}ca-key.pem #{CERT_PATH}ca-config.json /etc/etcd
yes | cp #{CERT_PATH}etcd/etcd.pem #{CERT_PATH}etcd/etcd-key.pem /etc/etcd
SCRIPT

$cmdCopyMasterCertificates = <<SCRIPT
sudo mkdir -p /var/lib/kubernetes

yes | cp #{CERT_PATH}ca.pem #{CERT_PATH}ca-key.pem #{CERT_PATH}ca-config.json /var/lib/kubernetes
yes | cp #{CERT_PATH}kubernetes/kubernetes.pem #{CERT_PATH}kubernetes/kubernetes-key.pem /var/lib/kubernetes
yes | cp #{CERT_PATH}etcd/etcd.pem #{CERT_PATH}etcd/etcd-key.pem /var/lib/kubernetes
SCRIPT

$cmdNodeCertificateSetup = <<SCRIPT
DIR=`pwd`
pushd #{BINARY_PATH}cfssl
cp cfssl_linux-amd64 cfssljson_linux-amd64 $DIR
popd

chmod +x cfssl_linux-amd64
sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
ln -s /usr/local/bin/cfssl /usr/bin/cfssl

chmod +x cfssljson_linux-amd64
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
ln -s /usr/local/bin/cfssljson /usr/bin/cfssljson

sudo mkdir -p /var/lib/kubernetes

yes | cp #{CERT_PATH}ca.pem #{CERT_PATH}ca-key.pem #{CERT_PATH}ca-config.json .

cat > %{hostname}-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "NO",
      "L": "Istanbul",
      "O": "Kubernetes",
      "OU": "Cluster",
      "ST": "Istanbul"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=%{hostname},%{ipAddress},localhost,127.0.0.1 \
  -profile=kubernetes \
  %{hostname}-csr.json | cfssljson -bare %{hostname}

yes | sudo cp #{CERT_PATH}ca.pem #{CERT_PATH}ca-key.pem %{hostname}.pem %{hostname}-key.pem /var/lib/kubernetes/
SCRIPT

$cmdEtcdSetup = <<SCRIPT
DIR=`pwd`
pushd #{BINARY_PATH}etcd
cp etcd.tar.gz $DIR
popd

tar xzvf etcd.tar.gz
mv `ls -d etcd-*/` etcd/
cp etcd/etcd* /usr/bin/
mkdir -p /var/lib/etcd

cat > etcd.service <<"EOF"
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/bin/etcd --name ETCD_NAME \
  --cert-file=/etc/etcd/etcd.pem \
  --key-file=/etc/etcd/etcd-key.pem \
  --peer-cert-file=/etc/etcd/etcd.pem \
  --peer-key-file=/etc/etcd/etcd-key.pem \
  --trusted-ca-file=/etc/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ca.pem \
  --initial-advertise-peer-urls https://INTERNAL_IP:2380 \
  --listen-peer-urls https://INTERNAL_IP:2380 \
  --listen-client-urls https://INTERNAL_IP:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://INTERNAL_IP:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster #{$etcdClusterConfig} \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

export INTERNAL_IP='%{ipAddress}'
export ETCD_NAME=$(hostname -s)
sed -i s/INTERNAL_IP/$INTERNAL_IP/g etcd.service
sed -i s/ETCD_NAME/$ETCD_NAME/g etcd.service
mv etcd.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable etcd
SCRIPT

$cmdKubernetesMasterSetup = <<SCRIPT
DIR=`pwd`
pushd #{BINARY_PATH}kubernetes
cp kube-apiserver kube-controller-manager kube-scheduler kubectl $DIR
popd

chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/bin/

cat > token.csv <<"EOF"
chAng3m3,admin,admin
chAng3m3,scheduler,scheduler
chAng3m3,kubelet,kubelet
EOF
sudo mv token.csv /var/lib/kubernetes/

cat > authorization-policy.jsonl <<"EOF"
{"apiVersion": "abac.authorization.kubernetes.io/v1beta1", "kind": "Policy", "spec": {"user":"*", "nonResourcePath": "*", "readonly": true}}
{"apiVersion": "abac.authorization.kubernetes.io/v1beta1", "kind": "Policy", "spec": {"user":"admin", "namespace": "*", "resource": "*", "apiGroup": "*"}}
{"apiVersion": "abac.authorization.kubernetes.io/v1beta1", "kind": "Policy", "spec": {"user":"scheduler", "namespace": "*", "resource": "*", "apiGroup": "*"}}
{"apiVersion": "abac.authorization.kubernetes.io/v1beta1", "kind": "Policy", "spec": {"user":"kubelet", "namespace": "*", "resource": "*", "apiGroup": "*"}}
{"apiVersion": "abac.authorization.kubernetes.io/v1beta1", "kind": "Policy", "spec": {"group":"system:serviceaccounts", "namespace": "*", "resource": "*", "apiGroup": "*", "nonResourcePath": "*"}}
EOF
sudo mv authorization-policy.jsonl /var/lib/kubernetes/

export INTERNAL_IP='%{ipAddress}'

cat > kube-apiserver.service <<"EOF"
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-apiserver \
  --admission-control=NamespaceLifecycle,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota \
  --advertise-address=INTERNAL_IP \
  --allow-privileged=true \
  --apiserver-count=2 \
  --authorization-mode=ABAC \
  --authorization-policy-file=/var/lib/kubernetes/authorization-policy.jsonl \
  --bind-address=0.0.0.0 \
  --enable-swagger-ui=true \
  --etcd-cafile=/var/lib/kubernetes/ca.pem \
  --etcd-certfile=/var/lib/kubernetes/etcd.pem \
  --etcd-keyfile=/var/lib/kubernetes/etcd-key.pem \
  --insecure-bind-address=0.0.0.0 \
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \
  --etcd-servers=#{$etcdServerList} \
  --service-account-key-file=/var/lib/kubernetes/ca-key.pem \
  --service-cluster-ip-range=10.32.0.0/24 \
  --service-node-port-range=30000-32767 \
  --tls-ca-file=/var/lib/kubernetes/ca.pem \
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \
  --token-auth-file=/var/lib/kubernetes/token.csv \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sed -i s/INTERNAL_IP/$INTERNAL_IP/g kube-apiserver.service
sudo mv kube-apiserver.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver
sudo systemctl start kube-apiserver

cat > kube-controller-manager.service <<"EOF"
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-controller-manager \
  --allocate-node-cidrs=true \
  --cluster-cidr=10.200.0.0/16 \
  --cluster-name=kubernetes \
  --leader-elect=true \
  --master=http://INTERNAL_IP:8080 \
  --root-ca-file=/var/lib/kubernetes/ca.pem \
  --service-account-private-key-file=/var/lib/kubernetes/ca-key.pem \
  --service-cluster-ip-range=10.32.0.0/24 \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sed -i s/INTERNAL_IP/$INTERNAL_IP/g kube-controller-manager.service
sudo mv kube-controller-manager.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable kube-controller-manager
sudo systemctl start kube-controller-manager

cat > kube-scheduler.service <<"EOF"
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-scheduler \
  --leader-elect=true \
  --master=http://INTERNAL_IP:8080 \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sed -i s/INTERNAL_IP/$INTERNAL_IP/g kube-scheduler.service
sudo mv kube-scheduler.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable kube-scheduler
sudo systemctl start kube-scheduler

source <(kubectl completion bash)
SCRIPT

$cmdKubernetesNodeSetup = <<SCRIPT
sudo mkdir -p /etc/cni/net.d \
  /opt/cni/bin \
  /var/run/kubernetes \
  /var/lib/kubelet

cp #{BINARY_PATH}docker/docker-ce.tgz .
tar -xf docker-ce.tgz
sudo cp docker/docker* /usr/bin/

cp #{BINARY_PATH}cni/cni.tgz .
tar -xvf cni.tgz -C /opt/cni/bin/

cat > docker.service <<"EOF"
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io

[Service]
ExecStart=/usr/bin/dockerd \
  --iptables=false \
  --ip-masq=false \
  --host=unix:///var/run/docker.sock \
  --log-level=error \
  --storage-driver=overlay
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo mv docker.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker

DIR=`pwd`
pushd #{BINARY_PATH}kubernetes
cp kubectl kube-proxy kubelet $DIR
popd
chmod +x kubectl kube-proxy kubelet
sudo mv kubectl kube-proxy kubelet /usr/bin/

cat > kubeconfig <<"EOF"
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/ca.pem
    server: https://#{$ipGroup}.#{$kubernetesMasterStartIp + 1}:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubelet
  name: kubelet
current-context: kubelet
users:
- name: kubelet
  user:
    token: chAng3m3
EOF
sudo mv kubeconfig /var/lib/kubelet/

cat > 10-bridge.conf <<EOF
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "10.200.½{number}.0/24"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF

cat > 99-loopback.conf <<EOF
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF
sudo mv 10-bridge.conf 99-loopback.conf /etc/cni/net.d/

cat > kubelet.service <<"EOF"
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/kubelet \
  --allow-privileged=true \
  --cloud-provider= \
  --cluster-dns=10.32.0.10 \
  --cluster-domain=cluster.local \
  --container-runtime=docker \
  --docker=unix:///var/run/docker.sock \
  --network-plugin=cni \
  --kubeconfig=/var/lib/kubelet/kubeconfig \
  --fail-swap-on=false \
  --serialize-image-pulls=false \
  --tls-cert-file=/var/lib/kubernetes/%{hostname}.pem \
  --tls-private-key-file=/var/lib/kubernetes/%{hostname}-key.pem \
  --runtime-cgroups=/systemd/system.slice \
  --kubelet-cgroups=/systemd/system.slice \
  --pod-cidr=10.200.%{number}.0/24 \
  --v=2

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo mv kubelet.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable kubelet
sudo systemctl start kubelet

cat > kube-proxy.service <<"EOF"
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-proxy \
  --master=https://#{$ipGroup}.#{$kubernetesMasterStartIp + 1}:6443 \
  --kubeconfig=/var/lib/kubelet/kubeconfig \
  --proxy-mode=iptables \
  --cluster-cidr=10.200.0.0/16 \
  --v=2

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo mv kube-proxy.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable kube-proxy
sudo systemctl start kube-proxy

source <(kubectl completion bash)
SCRIPT

$cmdReboot = <<SCRIPT
reboot
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox"

  $etcdServers.each do |etcd|
    config.vm.define etcd[:name] do |box|
      box.vm.box = BOX_OS
      box.vm.box_version = BOX_VERSION
      box.vm.provider "virtualbox" do |v|
        v.memory = 512
        v.cpus = 1
      end
      box.vm.hostname = etcd[:hostname]
      box.vm.network "public_network", bridge: NETWORK_ADAPTER_NAME, ip: etcd[:ipAddress]
      box.vm.synced_folder ".", "/vagrant", disabled: false, type: "rsync", rsync__auto: true
      box.vm.provision "shell", inline: $cmdInitialSetup
      box.vm.provision "shell", inline: $cmdCopyEtcdCertificates  
      box.vm.provision "shell", inline: $cmdEtcdSetup % {hostname: etcd[:hostname], ipAddress: etcd[:ipAddress]}
      box.vm.provision "shell", inline: $cmdReboot
    end
  end

  $kubernetesMasters.each do |master|
    config.vm.define master[:name] do |box|
      box.vm.box = BOX_OS
      box.vm.box_version = BOX_VERSION
      box.vm.provider "virtualbox" do |v|
        v.memory = 512
        v.cpus = 1
      end
      box.vm.hostname = master[:hostname]
      box.vm.network "public_network", bridge: NETWORK_ADAPTER_NAME, ip: master[:ipAddress]
      box.vm.synced_folder ".", "/vagrant", disabled: false, type: "rsync", rsync__auto: true
      box.vm.provision "shell", inline: $cmdInitialSetup
      box.vm.provision "shell", inline: $cmdCopyMasterCertificates
      box.vm.provision "shell", inline: $cmdKubernetesMasterSetup % {hostname: master[:hostname], ipAddress: master[:ipAddress]}
      box.vm.provision "shell", inline: $cmdReboot
    end
  end

    $kubernetesNodes.each do |node|
    config.vm.define node[:name] do |box|
      box.vm.box = BOX_OS
      box.vm.box_version = BOX_VERSION
      box.vm.provider "virtualbox" do |v|
        v.memory = 1024
        v.cpus = 1
      end
      box.vm.hostname = node[:hostname]
      box.vm.network "public_network", bridge: NETWORK_ADAPTER_NAME, ip: node[:ipAddress]
      box.vm.synced_folder ".", "/vagrant", disabled: false, type: "rsync", rsync__auto: true
      box.vm.provision "shell", inline: $cmdInitialSetup
      box.vm.provision "shell", inline: $cmdNodeCertificateSetup % {hostname: node[:hostname], ipAddress: node[:ipAddress]}
      box.vm.provision "shell", inline: $cmdKubernetesNodeSetup % {number: node[:number] - 1, hostname: node[:hostname]}
      box.vm.provision "shell", inline: $cmdReboot
    end
  end
end