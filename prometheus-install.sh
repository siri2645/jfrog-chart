#!/bin/bash

set +e

NAMESPACE="prometheus-operator"

HELM_RELEASE="prometheus"
HELM_CHART="prometheus-community/kube-prometheus-stack"

GRAFANA_DEPLOYMENT="prometheus-grafana"
DEPLOYMENT_NAME="prometheus-kube-state-metrics"
DS_NAME="prometheus-prometheus-node-exporter"

############################################
# PRIVATE IMAGES
############################################

GRAFANA_IMAGE="us-central1-docker.pkg.dev/uc-sandbox-1/prometheus-operator-grafana/grafana:13.0.1-patched"

SIDECAR_IMAGE="us-central1-docker.pkg.dev/uc-sandbox-1/kiwigrid-k8s-sidecar/sidecar:2.6.0-patch1"

KSM_IMAGE="us-central1-docker.pkg.dev/uc-sandbox-1/prometheus-operator-kube-state-metrics/kube-state-metrics:v2.18.0-patched"

NODE_EXPORTER_IMAGE="us-central1-docker.pkg.dev/uc-sandbox-1/prometheus-operator-node-exporter/node-exporter:v1.11.1-patched"

############################################
# HELM INSTALL / UPGRADE
############################################

echo "Deploying Prometheus Operator..."

helm upgrade --install "$HELM_RELEASE" "$HELM_CHART" \
  -n "$NAMESPACE" \
  --create-namespace \
  -f values.yaml

echo "Waiting for Helm resources to stabilize..."

kubectl rollout status deploy "$GRAFANA_DEPLOYMENT" -n "$NAMESPACE" --timeout=180s || true
kubectl rollout status deploy "$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=180s || true
kubectl rollout status daemonset "$DS_NAME" -n "$NAMESPACE" --timeout=180s || true

############################################
# PATCH GRAFANA IMAGES
############################################

echo "Patching Grafana deployment images..."

kubectl set image deployment/"$GRAFANA_DEPLOYMENT" \
-n "$NAMESPACE" \
grafana="$GRAFANA_IMAGE" || true

echo "Patched image for container 'grafana'"

kubectl set image deployment/"$GRAFANA_DEPLOYMENT" \
-n "$NAMESPACE" \
grafana-sc-dashboard="$SIDECAR_IMAGE" || true

echo "Patched image for container 'grafana-sc-dashboard'"

kubectl set image deployment/"$GRAFANA_DEPLOYMENT" \
-n "$NAMESPACE" \
grafana-sc-datasources="$SIDECAR_IMAGE" || true

echo "Patched image for container 'grafana-sc-datasources'"

############################################
# PATCH KUBE STATE METRICS IMAGE
############################################

echo "Patching kube-state-metrics image..."

kubectl set image deployment/"$DEPLOYMENT_NAME" \
-n "$NAMESPACE" \
kube-state-metrics="$KSM_IMAGE" || true

echo "Patched kube-state-metrics image"

############################################
# PATCH NODE EXPORTER IMAGE
############################################

echo "Patching node-exporter image..."

kubectl set image daemonset/"$DS_NAME" \
-n "$NAMESPACE" \
node-exporter="$NODE_EXPORTER_IMAGE" || true

echo "Patched node-exporter image"

############################################
# PATCH AUTOMOUNT FALSE
############################################

kubectl patch deployment "$GRAFANA_DEPLOYMENT" \
-n "$NAMESPACE" \
--type='json' \
-p='[
{
"op":"replace",
"path":"/spec/template/spec/automountServiceAccountToken",
"value":false
}
]' || true

kubectl patch deployment "$DEPLOYMENT_NAME" \
-n "$NAMESPACE" \
--type='json' \
-p='[
{
"op":"replace",
"path":"/spec/template/spec/automountServiceAccountToken",
"value":false
}
]' || true

kubectl patch daemonset "$DS_NAME" \
-n "$NAMESPACE" \
--type='json' \
-p='[
{
"op":"replace",
"path":"/spec/template/spec/automountServiceAccountToken",
"value":false
}
]' || true

############################################
# RESTART WORKLOADS
############################################

echo "Restarting workloads..."

kubectl rollout restart deployment "$GRAFANA_DEPLOYMENT" -n "$NAMESPACE" || true
kubectl rollout restart deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" || true
kubectl rollout restart daemonset "$DS_NAME" -n "$NAMESPACE" || true

############################################
# WAIT FOR ROLLOUT
############################################

if kubectl rollout status deployment "$GRAFANA_DEPLOYMENT" -n "$NAMESPACE" --timeout=180s; then
    echo "Grafana rollout success"
else
    echo "Grafana rollout failed. Continuing..."
fi

if kubectl rollout status deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=180s; then
    echo "kube-state-metrics rollout success"
else
    echo "kube-state-metrics rollout failed. Continuing..."
fi

if kubectl rollout status daemonset "$DS_NAME" -n "$NAMESPACE" --timeout=180s; then
    echo "node-exporter rollout success"
else
    echo "node-exporter rollout failed. Continuing..."
fi

############################################
# VERIFY IMAGES
############################################

echo "Checking final images..."

kubectl get deploy "$GRAFANA_DEPLOYMENT" \
-n "$NAMESPACE" \
-o=jsonpath='{.spec.template.spec.containers[*].image}'

echo ""

kubectl get deploy "$DEPLOYMENT_NAME" \
-n "$NAMESPACE" \
-o=jsonpath='{.spec.template.spec.containers[*].image}'

echo ""

kubectl get daemonset "$DS_NAME" \
-n "$NAMESPACE" \
-o=jsonpath='{.spec.template.spec.containers[*].image}'

echo ""

echo "Script complete. All containers patched."
