# kube-init

Easiest way to deploy a Kubernetes Cluster to learn Kubernetes

### Deploy the Cluster

1. Create a Ubuntu 64 Server/VM from your favourite cloud provider
2. Then apply: `wget -qO- http://git.io/veKlu | sudo sh`
3. Now you've a standalone Kubernetes cluster running inside your server

### Configure Network Access (optional)
Now we need to configure your local machine to access the Kubernetes network.

1. Let's create a SOCKS proxy server with this command: `ssh -D 8082 root@your-server-ip`
2. Then configure your browser to use the above SOCKS proxy with `port=8082` and `host=localhost`
3. Now, you can access IPs assigned by kubernetes directly from your browser

### Start Learning
1. Starting Learning Kuberneted from here: https://meteorhacks.com/learn-kubernetes-the-future-of-the-cloud.html
2. Then you can choose any tutorial you like and start playing with kubernetes
