# Install Docker
wget -qO- https://get.docker.com/ | sh
HOSTNAME=$(hostname -i)

## ETCD
docker run \
    --net=host \
    -d kubernetes/etcd:2.0.5.1 \
    /usr/local/bin/etcd \
        --addr=$HOSTNAME:4001 \
        --bind-addr=0.0.0.0:4001 \
        --data-dir=/var/etcd/data

## HyperKube
docker run \
    --net=host \
    -d \
    -v /var/run/docker.sock:/var/run/docker.sock\
    gcr.io/google-containers/hyperkube:v0.14.1 \
      /hyperkube kubelet \
        --api_servers=http://localhost:8080 \
        --v=2 \
        --address=0.0.0.0 \
        --enable_server \
        --hostname_override=127.0.0.1 \
        --config=/etc/kubernetes/manifests

## Proxy which changes IP Tables Rules
docker run \
    -d \
    --net=host \
    --privileged \
    gcr.io/google_containers/hyperkube:v0.14.1 \
      /hyperkube proxy \
        --master=http://127.0.0.1:8080 \
        --v=2

## Installing kubectl
ARCH=$(python -c 'import platform; print platform.architecture()[0]')
if [[ ${ARCH} == '64bit' ]]; then
  KUBECTL_ARCH=amd64
else
  KUBECTL_ARCH=386
fi

wget http://storage.googleapis.com/kubernetes-release/release/v0.14.1/bin/linux/$KUBECTL_ARCH/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin

## Done
echo
echo
echo "=> Installed a Standalone Kubernates Cluster!"
echo "->  type "kubectl" to start playing with the cluster"
