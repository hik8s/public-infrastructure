# Manifest rendering for system

```bash
export BASE="system"
export CLUSTER_NAME="public1"
export SOURCE_PATH="clusters/$CLUSTER_NAME/$BASE"
export GENERATE_PATH="source-of-truth/$CLUSTER_NAME/$BASE"

mkdir -p $GENERATE_PATH
rm -rf $GENERATE_PATH/*
kubectl kustomize --enable-helm $SOURCE_PATH -o $GENERATE_PATH
find source-of-truth/$CLUSTER_NAME/system/ -name "*secret*.yaml" -print0 | xargs -0 -I {} sops -e -i {}
```
