# kube-init

Easy way to deploy a Kubernates Cluster on a Linux Server

1. Create Linux Box from your favourite cloud provider
2. Then apply `wget -qO- http://git.io/veKCI | sh`
3. Now you've a standalone cluster running inside your server
4. Then create a socks proxy via this server with `ssh -D 8082 root@<your-server-ip>
5. Then configure your browser to use a SOCKS proxy with port=8082 host=localhost
6. Then choose any tutorial you like and start playing with kubernetes
7. Start Here: <>
7. You can access IPs assigned by kubernetes directly from your browser
