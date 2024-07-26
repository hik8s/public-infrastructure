# Deploy hik8s-system

This includes

- logd

```bash
export CLUSTER_NAME="public1"
export APP="hik8s-system"
export SOURCE_PATH="bases/apps/$APP"
export GENERATE_PATH="source-of-truth/$CLUSTER_NAME/apps/$APP"
```

```bash
kubectl -n $APP create secret generic hik8s-credentials \
--from-literal=clientid=${HIK8S_CLIENT_ID}       \
--from-literal=clientsecret=${HIK8S_CLIENT_SECRET}       \
--from-literal=auth0domain=${HIK8S_AUTH0_DOMAIN}       \
--dry-run=client -o yaml > ./$SOURCE_PATH/secret.yaml
```

```bash
mkdir -p $GENERATE_PATH
rm -rf $GENERATE_PATH/*
kubectl kustomize --enable-helm $SOURCE_PATH -o $GENERATE_PATH
```

```bash
kubectl apply -f $GENERATE_PATH
```
