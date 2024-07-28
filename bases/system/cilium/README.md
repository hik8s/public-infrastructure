# Cilium

## Policy audit mode

```bash
KUBE_APISERVER_ID=$(kubectl exec -n kube-system ds/cilium -- cilium endpoint list -o jsonpath='{[?(@.status.identity.id==1)].id}')
kubectl exec -n kube-system ds/cilium -- cilium monitor -t policy-verdict --related-to $KUBE_APISERVER_ID
```

```bash
kubectl exec -n kube-system ds/cilium -- cilium endpoint config $KUBE_APISERVER_ID PolicyAuditMode=Enabled
```

```bash
kubectl exec -n kube-system ds/cilium -- cilium endpoint config $KUBE_APISERVER_ID PolicyAuditMode=Disabled
```

```bash
INGRESS_ID=$(kubectl exec -n kube-system ds/cilium -- cilium endpoint list -o jsonpath='{[?(@.status.identity.id==8)].id}')
kubectl exec -n kube-system ds/cilium -- cilium monitor -t policy-verdict --related-to $INGRESS_ID
```
