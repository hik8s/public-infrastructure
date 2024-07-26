# Manifest rendering for apps

```bash
export BASE="apps"
export CLUSTER_NAME="public1"
export SOURCE_PATH="clusters/$CLUSTER_NAME/$BASE"
export GENERATE_PATH="source-of-truth/$CLUSTER_NAME/$BASE"

mkdir -p $GENERATE_PATH
rm -rf $GENERATE_PATH/*
kubectl kustomize --enable-helm $SOURCE_PATH -o $GENERATE_PATH
```
