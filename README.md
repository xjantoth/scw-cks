# Instructions to create/delete an instance at Scaleway

Generate your API key first in Scaleway web console

```bash
scw init 
```

### Create a Scaleway instance

```bash
wget https://raw.githubusercontent.com/xjantoth/scw-cks/main/install_master.sh

scw instance server \
create type=DEV1-S zone=fr-par-1 \
image=ubuntu_focal root-volume=l:20G \
name=scw-k8s-cmdx ip=new project-id=431d432b-1849-445f-a66b-7d1ccdf5d34a \
cloud-init=@install_master.sh
```

### Delete an instance

```bash
scw instance server stop $(scw instance server list name=scw-k8s-cmd -ojson | jq -r '.[].id')
scw instance server delete $(scw instance server list name=scw-k8s-cmd -ojson | jq -r '.[].id')
```


### SSH to a newly created server

```bash
ssh -i ~/.ssh/scw-k8s-cks  root@$(scw instance server list name=scw-k8s-cmd -ojson | jq -r '.[].public_ip.address')
```


### Ansible


```bash
cd ansible

# export required env. variables
export SCW_TOKEN=...
export ANSIBLE_HOST_KEY_CHECKING=False
export SCW_ACCESS_KEY=...
export SCW_SECRET_KEY=...
export PROJECT_ID=...

ansible-playbook scw-playbook.yaml \
  -e SCW_ACCESS_KEY="${SCW_ACCESS_KEY}" \
  -e SCW_SECRET_KEY="${SCW_SECRET_KEY}" \
  -e PROJECT_ID="${PROJECT_ID}"

scw-cks % mainU  scw-cks ssh -i ssh/id_rsa -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o User='root' -o ConnectTimeout=10 10.40.50.50

```

###### Reconfigure Kubernetes cluster with -e crio or -e containerd

```bash
ansible-playbook scw-playbook.yaml \
  -e SCW_ACCESS_KEY="${SCW_ACCESS_KEY}" \
  -e SCW_SECRET_KEY="${SCW_SECRET_KEY}" \
  -e PROJECT_ID="${PROJECT_ID}" \
  -i inventory \
  --tags k8s_init \
  -e container_runtime="crio"
```

###### Destroy scaleway instance


```bash
ansible-playbook scw-playbook-delete.yaml \
  -e SCW_ACCESS_KEY="${SCW_ACCESS_KEY}" \
  -e SCW_SECRET_KEY="${SCW_SECRET_KEY}" \
  -e PROJECT_ID="${PROJECT_ID}"

# Argo
ansible-playbook scw-playbook.yaml \
  -e SCW_ACCESS_KEY="${SCW_ACCESS_KEY}" \
  -e SCW_SECRET_KEY="${SCW_SECRET_KEY}" \
  -e PROJECT_ID="${PROJECT_ID}" \
  -i inventory \
  -e container_runtime="containerd" --tags istio -e GITHUB_SECRET=secret_generated_at_github

```


###### Webohook via Argo Events

```bash
# Port 32500 is HTTP port of Istio's ingressgateway
# https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

curl -XPOST 51.158.106.182:32500/push -H "Content-Type: application/json" -d '{"name": "linuxize", "email": "linuxize@example.com"}'

```
