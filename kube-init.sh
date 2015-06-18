UBUNTU_DISTRO=`uname -a | grep Ubuntu`
ARCHI=`uname -m`

if [ ! "$UBUNTU_DISTRO" ]; then
  echo "=> kube-init requires a Ubuntu distro (64 bit)"
  exit 1
fi

if [ $ARCHI != "x86_64" ]; then
  echo "=> kube-init requires a 64 bit Ubuntu distro"
  exit 1
fi

# Install Docker 
wget -qO- https://get.docker.com/ | sh

## ETCD
docker run \
    -d \
    --net=host \
    quay.io/coreos/etcd:v2.0.9 \
        --addr=127.0.0.1:4001 \
        --bind-addr=0.0.0.0:4001 \
        --data-dir=/var/etcd/data

## HyperKube apiserver
# here we set the address to `0.0.0.0`
# that's because we need to bind the api server with all IPs.
# So, in kube-dns `kube2sky` can connect to api server via
# docker's IP bridge IP 
# otherwise, we need to go through a lot of security related stuff
docker run \
    --net=host \
    -d \
    -v /var/run/docker.sock:/var/run/docker.sock\
    meteorhacks/hyperkube \
      /hyperkube apiserver \
      --portal_net=10.0.0.1/24 \
      --address=0.0.0.0 \
      --etcd_servers=http://127.0.0.1:4001 \
      --cluster_name=kubernetes \
      --v=2

## HyperKube controller-manager
docker run \
    --net=host \
    -d \
    -v /var/run/docker.sock:/var/run/docker.sock\
    meteorhacks/hyperkube \
      /hyperkube controller-manager \
      --master=127.0.0.1:8080 \
      --machines=127.0.0.1 \
      --sync_nodes=true \
      --v=2

## HyperKube scheduler
docker run \
    --net=host \
    -d \
    -v /var/run/docker.sock:/var/run/docker.sock\
    meteorhacks/hyperkube \
      /hyperkube scheduler \
      --master=127.0.0.1:8080 \
      --v=2

## HyperKube kubelet
docker run \
    --net=host \
    -d \
    -v /var/run/docker.sock:/var/run/docker.sock\
    meteorhacks/hyperkube \
      /hyperkube kubelet \
        --api_servers=http://127.0.0.1:8080 \
        --v=2 \
        --address=0.0.0.0 \
        --hostname_override=127.0.0.1 \
        --cluster_dns=10.0.0.10 \
        --cluster_domain="kubernetes.local" \
        --config=/etc/kubernetes/manifests

## Proxy which changes IP Tables Rules
docker run \
    -d \
    --net=host \
    --privileged \
    meteorhacks/hyperkube \
      /hyperkube proxy \
        --master=http://127.0.0.1:8080 \
        --v=2

## kubectl
docker run --rm -v /usr/local/bin:/_bin meteorhacks/hyperkube /bin/bash -c "cp /kubectl /_bin"
chmod +x /usr/local/bin/kubectl

## Add DNS Support
cat <<EOF > /tmp/kube-dns-rc.yaml
apiVersion: v1beta3
kind: ReplicationController
metadata:
  labels:
    k8s-app: kube-dns
  name: kube-dns
  namespace: default
spec:
  replicas: 1
  selector:
    k8s-app: kube-dns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
    spec:
      dnsPolicy: "Default"
      containers:
      - args: [
          "-listen-client-urls=http://0.0.0.0:2379,http://0.0.0.0:4001",
          "-initial-cluster-token=skydns-etcd",
          "-advertise-client-urls=http://127.0.0.1:4001"
        ]
        image: quay.io/coreos/etcd:v2.0.3
        name: etcd
      - args: [
          "-domain=kubernetes.local.",
          # we are using docker's default bridge IP here
          # that's the only way we can connect inside from the pod
          "--kube_master_url=http://172.17.42.1:8080"
        ]
        image: gcr.io/google_containers/kube2sky:1.9
        name: kube2sky
      - args: [
          "-machines=http://localhost:4001",
          "-addr=0.0.0.0:53",
          "-domain=kubernetes.local.",
        ]
        image: gcr.io/google_containers/skydns:2015-03-11-001
        name: skydns
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
EOF

cat <<EOF > /tmp/kube-dns-service.yaml
apiVersion: v1beta3
kind: Service
metadata:
  labels:
    k8s-app: kube-dns
  name: kube-dns
  namespace: default
spec:
  portalIP: 10.0.0.10
  ports:
  - port: 53
    protocol: UDP
    targetPort: 53
  selector:
    k8s-app: kube-dns
EOF

waitFor() {
    cmd=$1
    while [ 1 ]; do
        ok=$(eval $cmd)
        if [ "$ok" ]; then
            break
        fi
        sleep 1
    done
}

echo
echo "=> Waiting for ETCD. (takes upto 2-5 minute)"
waitFor "wget -qO- http://127.0.0.1:4001/version | grep etcd"
echo "=>  ETCD is now online."

echo
echo "=> Waiting for Kubernates API. (takes upto 2-5 minute)"
waitFor "wget -qO- http://127.0.0.1:8080/version | grep major"
echo "=>  Kubernates API is now online."

echo
echo "=> Setting up DNS confgurations"

kubectl create -f /tmp/kube-dns-rc.yaml
kubectl create -f /tmp/kube-dns-service.yaml

rm /tmp/kube-dns-rc.yaml /tmp/kube-dns-service.yaml

echo
echo "=> Waiting for DNS confgurations (takes upto 2-5 minute)"
waitFor 'kubectl get pod -l k8s-app=kube-dns | grep Running | grep "3/3"'
echo "=>  DNS confguration completed."

## Done
echo
echo "------------------------------------------------------------------"
echo "=> Installed a Standalone Kubernates Cluster!"
echo "->  type "kubectl" to start playing with the cluster"
echo "->  to learn about Kubernetes, visit here: http://goo.gl/jmxn2W"
echo "------------------------------------------------------------------"
echo
