# Talos Linux

Talos Linux is a minimal, secure and immutable Linux operating system distribution specifically designed to run Kubernetes clusters.

## Dedicated Hetzner

These are the instructions for deploying a Kubernetes cluster on a dedicated Hetzner server.

### Instructions

1. Firewall configuration

    Go to <https://robot.hetzner.com/server> -> `Server Auction #2345678` -> `Firewall`

    ```bash
    export YOUR_HOME_IP=$(curl --silent --write '\n' ifconfig.me) && echo $YOUR_HOME_IP
    ./scripts/printf-firewall-table.sh
    ```

    The `Rules (incoming)` should look like this:

    ```bash
    Name                         | Version  | Protocol | Source IP          | ...  | Destination port | Action  
    -----------------------------|----------|----------|--------------------|------|------------------|---------
    Allow home                   | ipv4     | *        | <your_home_ip>/32  | ...  |                  | accept  
    Drop kube-apiserver + talos  | *        | *        |                    | ...  | 6443,50000-50001 | discard
    Allow all                    | *        | *        |                    | ...  |                  | accept
    ```

2. Login

    After purchasing your server, the rescue system should be activated. Otherwise:

    Go to <https://robot.hetzner.com/server> -> `Server Auction #2345678` -> `Rescue` -> `Activate rescue system` (select your key).

    ```bash
    SERVER_IP='142.132.218.124'
    ssh root@$SERVER_IP
    ```

3. Installation

    We download the Talos Linux disk image and write it to one of the disks. Run this on your `server`:

    ```bash
    TALOS_VERSION='v1.7.5'

    # Select a disk on your system: /dev/sda or /dev/nvme0n1
    TARGET_DISK=$(lsblk | grep disk | awk '{print "/dev/"$1}' | head -n1) && echo $TARGET_DISK

    # Download the disk image for the bare-metal installation.
    wget -O '/tmp/talos.raw.xz' "https://github.com/siderolabs/talos/releases/download/$TALOS_VERSION/metal-amd64.raw.xz"

    # Write the raw disk image to the target disk.
    xz -d --stdout /tmp/talos.raw.xz | dd of=$TARGET_DISK && sync

    shutdown --reboot now
    ```

    Install talosctl on your `computer`:

    ```bash
    brew install siderolabs/tap/talosctl
    ```

    Verify successful installation. You should see a list of disks:

    ```bash
    talosctl --nodes $SERVER_IP disks --insecure
    ```

4. Talosctl configuration

    Give your cluster a name:

    ```bash
    export CLUSTER_NAME='public1'
    ```

    Generate cluster `secrets`:

    ```bash
    CLUSTER_DIR="clusters/$CLUSTER_NAME/cluster/talos"
    mkdir -p $CLUSTER_DIR
    talosctl gen secrets --output-file "$CLUSTER_DIR/secrets.yaml"
    ```

    Generate `talosconfig`:

    ```bash
    talosctl gen config \
        --with-secrets $CLUSTER_DIR/secrets.yaml    \
        --output-types talosconfig                  \
        --output talosconfig                        \
        $CLUSTER_NAME "https://$SERVER_IP:6443"
    
    # Add server IP to endpoints
    talosctl --talosconfig talosconfig config endpoint $SERVER_IP
    ```

    Add the configuration of this cluster to your `~/.talos/config`:

    ```bash
    talosctl config merge ./talosconfig
    ```

    Delete the file:

    ```bash
    rm talosconfig
    ```

5. Cluster configuration

    Specify a directory that acts as source of truth for resources applied in your cluster:

    ```bash
    BASE_PATCHES="bases/cluster/talos/patches"
    CLUSTER_PATCHES="clusters/$CLUSTER_NAME/cluster/talos/patches"
    SOURCE_OF_TRUTH_DIR="source-of-truth/$CLUSTER_NAME/cluster/talos"
    mkdir -p "$SOURCE_OF_TRUTH_DIR"
    ```

    BASE_PATCHES contains general patches and CLUSTER_PATCHES contains specific patches such as hostname and disk name.

    Generate the cluster configuration, `cluster.yaml`:

    Note: If you do not install [hik8s/agents](https://github.com/hik8s/agents), you probably do not need `kubelet-add-extra-mounts.yaml`.
    <!-- TODO: programmatically generate files in $CLUSTER_PATCHES -->
    ```bash
    talosctl gen config \
    --output $SOURCE_OF_TRUTH_DIR/cluster.yaml                                  \
    --output-types controlplane                                                 \
    --with-cluster-discovery=false                                              \
    --with-secrets "$CLUSTER_DIR/secrets.yaml"                                  \
    --config-patch "@$BASE_PATCHES/cluster-allow-controlplane-schedule.yaml"    \
    --config-patch "@$BASE_PATCHES/cluster-network-disable-cni-and-proxy.yaml"  \
    --config-patch "@$BASE_PATCHES/kubelet-add-extra-mounts.yaml"               \
    --config-patch "@$BASE_PATCHES/machine-network-enable-dhcp.yaml"            \
    --config-patch "@$CLUSTER_PATCHES/machine-network-hostname.yaml"            \
    --config-patch "@$CLUSTER_PATCHES/machine-install-disk.yaml"                \
    $CLUSTER_NAME https://$SERVER_IP:6443
    ```

6. Cluster deployment

    Apply the cluster configuration, `cluster.yaml`

    ```bash
    talosctl --nodes $SERVER_IP apply-config --file $SOURCE_OF_TRUTH_DIR/cluster.yaml --insecure
    ```

    Check the status of the cluster:

    ```bash
    talosctl --nodes $SERVER_IP dashboard
    ```

    `Bootstrap` the cluster. As soon as you see this log message: ```please run `talosctl bootstrap` against one of the following IPs```. Then run:

    ```bash
    talosctl --nodes $SERVER_IP bootstrap
    ```

    Install `kubectl`:

    ```bash
    brew install kubernetes-cli
    ```

    Configure `~/.kube/config`:  

    ```bash
    talosctl --nodes $SERVER_IP kubeconfig
    ```

    Check if the node is exists:

    ```bash
    kubectl get nodes
    ```

7. Deploy Cilium

    We have generated the `cluster.yaml` without `Container Networking Interface` (CNI) and without `kube-proxy`. Cilium will do both.

    Add a values file with your server IP:

    ```bash
    cat > bases/system/cilium/cilium-values.yaml <<EOF
    ipam:
      mode: kubernetes
    kubeProxyReplacement: strict
    hostFirewall:
      enabled: true
    externalIPs:
      enabled: true
    securityContext:
      capabilities:
        ciliumAgent: [CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID]
        cleanCiliumState: [NET_ADMIN,SYS_ADMIN,SYS_RESOURCE]
    cgroup:
      autoMount:
        enabled: false
      hostRoot: /sys/fs/cgroup
    k8sServiceHost: ${SERVER_IP}
    k8sServicePort: 6443
    EOF
    ```
    <!-- TODO: programmatically create clusters/$CLUSTER_NAME/system/kustomization.yaml -->
    In the file `clusters/$CLUSTER_NAME/system/kustomization.yaml` we will collect all the system components that we will use in this cluster. At the moment, it only contains Cilium, which in turn can be found in `bases/system/cilium/`.

    Generate the cluster manifests for the `system` kustomization:

    ```bash
    export SOURCE_PATH="clusters/$CLUSTER_NAME/system"
    export GENERATE_PATH="source-of-truth/$CLUSTER_NAME/system"

    mkdir -p $GENERATE_PATH
    kubectl kustomize --enable-helm $SOURCE_PATH -o $GENERATE_PATH
    ```

    Apply these generated Kubernetes manifests:

    ```bash
    kubectl apply -f $GENERATE_PATH
    ```

### References

<https://datavirke.dk/posts/bare-metal-kubernetes-part-1-talos-on-hetzner/>
  
- This is a very detailed, well written and explained guide that served as a template for many of the configurations used.
