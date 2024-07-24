# Manifest rendering for system

```bash
export BASE="system"
export CLUSTER_NAME="public1"
export SOURCE_PATH="clusters/$CLUSTER_NAME/$BASE"
export GENERATE_PATH="zz_generated/$CLUSTER_NAME/$BASE"

mkdir -p $GENERATE_PATH
rm -rf $GENERATE_PATH/*
kubectl kustomize --enable-helm $SOURCE_PATH -o $GENERATE_PATH
```
