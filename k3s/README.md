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

## Helm Repos

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

[open-webui](https://artifacthub.io/packages/helm/open-webui/open-webui)

```bash
# Static/Not Maintained
# helm repo add stable https://charts.helm.sh/stable

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add open-webui https://helm.openwebui.com/
helm search repo | grep -v DEPRECATED > ../charts.txt
```