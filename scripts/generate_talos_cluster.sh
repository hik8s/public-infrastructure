#!/bin/bash

# Check if CLUSTER_NAME is set
if [ -z "$CLUSTER_NAME" ]; then
  echo "CLUSTER_NAME is not set. Please set it before running this script."
  exit 1
fi

SERVER_IP=$(host api.$CLUSTER_NAME.hik8s.ai | awk '{print $4}')

# Check if SERVER_IP is set
if [ -z "$SERVER_IP" ]; then
  SERVER_IP=$(host api.$CLUSTER_NAME.hik8s.ai | awk '{print $4}')
  if [ -z "$SERVER_IP" ]; then
    echo "SERVER_IP is not set. Please set it before running this script."
  fi
  exit 1
fi

BASE_PATCHES='bases/cluster/talos/patches'
CLUSTER_DIR="clusters/$CLUSTER_NAME/cluster/talos"
CLUSTER_PATCHES="$CLUSTER_DIR/patches"

sops -d -i clusters/$CLUSTER_NAME/cluster/talos/secrets.yaml

talosctl gen config \
    --output $CLUSTER_DIR/cluster.yaml                                  \
    --output-types controlplane                                                 \
    --with-cluster-discovery=false                                              \
    --with-secrets "$CLUSTER_DIR/secrets.yaml"                                  \
    --config-patch "@$BASE_PATCHES/cluster-allow-controlplane-schedule.yaml"    \
    --config-patch "@$BASE_PATCHES/cluster-network-disable-cni-and-proxy.yaml"  \
    --config-patch "@$BASE_PATCHES/kubelet-add-extra-mounts.yaml"               \
    --config-patch "@$BASE_PATCHES/machine-network-enable-dhcp.yaml"            \
    --config-patch "@$CLUSTER_PATCHES/machine-network-hostname.yaml"            \
    --config-patch "@$CLUSTER_PATCHES/machine-install-disk.yaml"                \
    $CLUSTER_NAME https://$SERVER_IP:6443 --force

sops -e -i $CLUSTER_DIR/secrets.yaml
sops -e -i $CLUSTER_DIR/cluster.yaml
