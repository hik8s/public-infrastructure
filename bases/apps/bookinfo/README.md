# bookinfo example

To deploy this app, it needs to be added to the apps kustomization of your cluster, e.g. public1:

- [apps](../../../clusters/public1/apps/kustomization.yaml)

Rendering of the apps kustomization is done here: [README.md](../../../clusters/public1/apps/README.md)

This renders all resources and saves them to `zz_generated/`. The rendered manifests are picked up from the main branch by our kustomizations:

- [apps](../../../clusters/public1/system/fluxcd/kustomizations/apps.yaml)
- [system](../../../clusters/public1/system/fluxcd/kustomizations/system.yaml)
