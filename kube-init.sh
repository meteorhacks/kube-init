## ETCD
docker run \
    --net=host \
    -d kubernetes/etcd:2.0.5.1 \
    /usr/local/bin/etcd \
        --addr=127.0.0.1:4001 \
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
        --cluster_dns=10.0.0.10 \
        --cluster_domain="kubernetes.local" \
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
if [ ${ARCH} == '64bit' ]; then
  KUBECTL_ARCH=amd64
else
  KUBECTL_ARCH=386
fi

wget http://storage.googleapis.com/kubernetes-release/release/v0.14.1/bin/linux/$KUBECTL_ARCH/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin

## Add DNS Support
cat <<EOF > /tmp/kube-dns-rc.yaml
kind: ReplicationController
apiVersion: v1beta1
id: kube-dns
namespace: default
labels:
  k8s-app: kube-dns
  kubernetes.io/cluster-service: "true"
desiredState:
  replicas: 1
  replicaSelector:
    k8s-app: kube-dns
  podTemplate:
    labels:
      name: kube-dns
      k8s-app: kube-dns
      kubernetes.io/cluster-service: "true"
    desiredState:
      manifest:
        version: v1beta2
        id: kube-dns
        dnsPolicy: "Default"  # Don't use cluster DNS.
        containers:
          - name: etcd
            image: quay.io/coreos/etcd:v2.0.3
            command: [
                    # entrypoint = "/etcd",
                    "-listen-client-urls=http://0.0.0.0:2379,http://0.0.0.0:4001",
                    "-initial-cluster-token=skydns-etcd",
                    "-advertise-client-urls=http://127.0.0.1:4001",
            ]
          - name: kube2sky
            image: gcr.io/google_containers/kube2sky:1.1
            command: [
                    # entrypoint = "/kube2sky",
                    "-domain=kubernetes.local",
            ]
          - name: skydns
            image: gcr.io/google_containers/skydns:2015-03-11-001
            command: [
                    # entrypoint = "/skydns",
                    "-machines=http://localhost:4001",
                    "-addr=0.0.0.0:53",
                    "-domain=kubernetes.local.",
            ]
            ports:
              - name: dns
                containerPort: 53
                protocol: UDP
EOF

cat <<EOF > /tmp/kube-dns-service.yaml
kind: Service
apiVersion: v1beta1
id: kube-dns
namespace: default
protocol: UDP
port: 53
portalIP: 10.0.0.10
containerPort: 53
labels:
  k8s-app: kube-dns
  name: kube-dns
  kubernetes.io/cluster-service: "true"
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
echo "=> Waiting for ETCD. (this will take upto 2-5 minute)"
waitFor "wget -qO- http://127.0.0.1:4001/version | grep releaseVersion"
echo "=>  ETCD is now online."

echo
echo "=> Waiting for Kubernates API. (this take upto 2-5 minute)"
waitFor "wget -qO- http://127.0.0.1:8080/version | grep major"
echo "=>  Kubernates API is now online."

kubectl create -f /tmp/kube-dns-rc.yaml
kubectl create -f /tmp/kube-dns-service.yaml

rm /tmp/kube-dns-rc.yaml /tmp/kube-dns-service.yaml

echo
echo "=> Waiting for DNS setup comes online. (takes upto 2-5 minute)"
waitFor 'kubectl get pod -l k8s-app=kube-dns | grep Running'
echo "=>  DNS confguration completed."

## Done
echo
echo
echo "=> Installed a Standalone Kubernates Cluster!"
echo "->  type "kubectl" to start playing with the cluster"
echo
echo
