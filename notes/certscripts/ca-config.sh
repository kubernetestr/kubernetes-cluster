#!/bin/bash

CFSSL_DOWNLOAD_PATH="https://pkg.cfssl.org/R1.2/"


for binary in cfssl_linux-amd64 cfssljson_linux-amd64; do
  if [ ! -f ${binary} ]; then
    curl -L --create-dirs "${CFSSL_DOWNLOAD_PATH}${binary}" -o "${binary}"
  fi
done

chmod +x cfssl_linux-amd64
sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
ln -s /usr/local/bin/cfssl /usr/bin/cfssl

chmod +x cfssljson_linux-amd64
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
ln -s /usr/local/bin/cfssljson /usr/bin/cfssljson


export CERT_PATH=certs/

rm -rf ${CERT_PATH}
mkdir ${CERT_PATH}
pushd ${CERT_PATH}

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
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

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

mkdir etcd
pushd etcd

cat > etcd-csr.json <<EOF
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
  -ca=../ca.pem \
  -ca-key=../ca-key.pem \
  -config=../ca-config.json \
  -hostname=172.31.105.3,172.31.100.210,172.31.114.218,pamir1,pamir2,pamir3,127.0.0.1,localhost \
  -profile=kubernetes \
  etcd-csr.json | cfssljson -bare etcd

yes | cp etcd.pem etcd-key.pem ../ca.pem ../ca-key.pem /etc/etcd/

popd

mkdir kubernetes
pushd kubernetes

cat > kubernetes-csr.json <<EOF
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
  -ca=../ca.pem \
  -ca-key=../ca-key.pem \
  -config=../ca-config.json \
  -hostname=10.32.0.1,172.31.105.3,172.31.100.210,pamir1,pamir2,127.0.0.1,localhost \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes
