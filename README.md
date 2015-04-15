# kube-init

Easiest way to deploy a Kubernetes Cluster to learn Kubernetes

### Deploy the Cluster

1. Create a Ubuntu 64 Server/VM from your favourite cloud provider
2. Then apply: `wget -qO- http://git.io/veKlu | sudo sh`
3. Now you've a standalone Kubernetes cluster running inside your server

### Configure Network Access (optional)
Now we need to configure your local machine to access the Kubernetes network.

1. Let's create a SOCKS proxy via your server with command: `ssh -D 8082 root@your-server-ip`
2. Then configure your browser to use a SOCKS proxy with `port=8082` and `host=localhost`
3. You can access IPs assigned by kubernetes directly from your browser

### Start Learning
1. Starting Learning Kuberneted from here: <>
2. Then choose any tutorial you like and start playing with kubernetes
3. You can also select your step by step guide to Kubernetes.
