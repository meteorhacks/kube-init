# kube-init

Easiest way to deploy a Kubernetes Cluster to learn Kubernetes

### Deploy the Cluster

1. Create Linux Box from your favourite cloud provider
2. Install docker with: `wget -qO- https://get.docker.com/ | sh`
2. Then apply: `wget -qO- http://git.io/veKlu | sudo sh`
3. Now you've a standalone cluster running inside your server

### Configure Network Access
Now we are confiuring to access the Kubernetes network right from our local machine.

1. Create a socks proxy via your server with command: `ssh -D 8082 root@your-server-ip`
2. Then configure your browser to use a SOCKS proxy with `port=8082` and `host=localhost`
3. You can access IPs assigned by kubernetes directly from your browser

### Start Learning
1. Then choose any tutorial you like and start playing with kubernetes
2. Start Here: <>
