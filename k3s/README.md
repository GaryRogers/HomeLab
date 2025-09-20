# K3s

K3s doesn't want to install as a package in Ubuntu, but rather as a script you run. With this in mind, I'm skipping making this an ansible thing, at least for now.

## Install process

_(Stolen from [Digital Ocean](https://www.digitalocean.com/community/tutorials/how-to-setup-k3s-kubernetes-cluster-on-ubuntu))_

```bash
# Run the Install Script from K3s
curl -sfL https://get.k3s.io | sh -

# Check status w/systemctl

systemctl status k3s
```