#!/bin/bash

set -e

# =========================================================
# Variables
# =========================================================

NAMESPACE="prometheus-operator"

GRAFANA_DEPLOYMENT="prometheus-grafana"
DEPLOYMENT_NAME="prometheus-kube-state-metrics"
DS_NAME="prometheus-prometheus-node-exporter"

VOLUME_NAME="tmp"
VOLUME_MOUNT_PATH="/tmp"

# =========================================================
# Wait for helm resources
# =========================================================

wait_for_resources() {

  echo "Waiting for Helm resources to stabilize..."

  kubectl rollout status deploy/"$GRAFANA_DEPLOYMENT" -n "$NAMESPACE" --timeout=300s

  kubectl rollout status deploy/"$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=300s

  kubectl rollout status ds/"$DS_NAME" -n "$NAMESPACE" --timeout=300s

  sleep 30
}

# =========================================================
# Patch Grafana deployment images
# =========================================================

patch_deploy_container_image() {

  echo "Patching Grafana deployment images..."

  CONTAINERS="grafana grafana-sc-dashboard grafana-sc-datasources"

  for CONTAINER_NAME in $CONTAINERS; do

    CONTAINER_INDEX=$(kubectl get deploy "$GRAFANA_DEPLOYMENT" -n "$NAMESPACE" -o json |
      jq --arg name "$CONTAINER_NAME" '
      (.spec.template.spec.containers // [])
      | to_entries
      | map(select(.value.name == $name))
      | if length > 0 then .[0].key else "null" end
      ')

    if [ "$CONTAINER_INDEX" = "null" ]; then
      echo "Container '$CONTAINER_NAME' not found. Skipping."
      continue
    fi

    if [ "$CONTAINER_NAME" = "grafana" ]; then
      IMAGE="us-central1-docker.pkg.dev/uc-sandbox-1/prometheus-operator-grafana/grafana:13.0.1-patched"
    else
      IMAGE="us-central1-docker.pkg.dev/uc-sandbox-1/kiwigrid-k8s-sidecar/sidecar:2.6.0-patch1"
    fi

    kubectl patch deploy "$GRAFANA_DEPLOYMENT" -n "$NAMESPACE" --type=json -p="[
      {
        \"op\": \"replace\",
        \"path\": \"/spec/template/spec/containers/$CONTAINER_INDEX/image\",
        \"value\": \"$IMAGE\"
      }
    ]"

    echo "Patched image for container '$CONTAINER_NAME'"

  done
}

# =========================================================
# Patch kube-state-metrics image
# =========================================================

patch_ksm_container_image() {

  echo "Patching kube-state-metrics image..."

  CONTAINER_INDEX=$(kubectl get deploy "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o json |
    jq --arg name "kube-state-metrics" '
    (.spec.template.spec.containers // [])
    | to_entries
    | map(select(.value.name == $name))
    | if length > 0 then .[0].key else "null" end
    ')

  if [ "$CONTAINER_INDEX" = "null" ]; then
    echo "kube-state-metrics container not found"
    return
  fi

  kubectl patch deploy "$DEPLOYMENT_NAME" -n "$NAMESPACE" --type=json -p="[
    {
      \"op\": \"replace\",
      \"path\": \"/spec/template/spec/containers/$CONTAINER_INDEX/image\",
      \"value\": \"us-central1-docker.pkg.dev/uc-sandbox-1/prometheus-operator-kube-state-metrics/kube-state-metrics:v2.18.0-patched\"
    }
  ]"

  echo "Patched kube-state-metrics image"
}

# =========================================================
# Patch node-exporter daemonset image
# =========================================================

patch_ds_container_image() {

  echo "Patching node-exporter image..."

  CONTAINER_INDEX=$(kubectl get ds "$DS_NAME" -n "$NAMESPACE" -o json |
    jq --arg name "node-exporter" '
    (.spec.template.spec.containers // [])
    | to_entries
    | map(select(.value.name == $name))
    | if length > 0 then .[0].key else "null" end
    ')

  if [ "$CONTAINER_INDEX" = "null" ]; then
    echo "node-exporter container not found"
    return
  fi

  kubectl patch ds "$DS_NAME" -n "$NAMESPACE" --type=json -p="[
    {
      \"op\": \"replace\",
      \"path\": \"/spec/template/spec/containers/$CONTAINER_INDEX/image\",
      \"value\": \"us-central1-docker.pkg.dev/uc-sandbox-1/prometheus-operator-node-exporter/node-exporter:v1.11.1-patched\"
    }
  ]"

  echo "Patched node-exporter image"
}

# =========================================================
# Add automountServiceAccountToken false
# =========================================================

patch_automount() {

  kubectl patch deploy "$GRAFANA_DEPLOYMENT" -n "$NAMESPACE" \
  --type='json' \
  -p='[
    {
      "op": "replace",
      "path": "/spec/template/spec/automountServiceAccountToken",
      "value": false
    }
  ]'

  kubectl patch deploy "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
  --type='json' \
  -p='[
    {
      "op": "replace",
      "path": "/spec/template/spec/automountServiceAccountToken",
      "value": false
    }
  ]'

  kubectl patch ds "$DS_NAME" -n "$NAMESPACE" \
  --type='json' \
  -p='[
    {
      "op": "replace",
      "path": "/spec/template/spec/automountServiceAccountToken",
      "value": false
    }
  ]'
}

# =========================================================
# Restart workloads
# =========================================================

restart_workloads() {

  echo "Restarting workloads..."

  kubectl rollout restart deploy "$GRAFANA_DEPLOYMENT" -n "$NAMESPACE"

  kubectl rollout restart deploy "$DEPLOYMENT_NAME" -n "$NAMESPACE"

  kubectl rollout restart ds "$DS_NAME" -n "$NAMESPACE"
}

# =========================================================
# Wait again after restart
# =========================================================

wait_after_restart() {

  kubectl rollout status deploy "$GRAFANA_DEPLOYMENT" -n "$NAMESPACE" --timeout=300s

  kubectl rollout status deploy "$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=300s

  kubectl rollout status ds "$DS_NAME" -n "$NAMESPACE" --timeout=300s
}

# =========================================================
# Verify Images
# =========================================================

verify_images() {

  echo "Grafana Images:"
  kubectl get deploy "$GRAFANA_DEPLOYMENT" -n "$NAMESPACE" \
  -o jsonpath='{.spec.template.spec.containers[*].image}'

  echo
  echo "Kube State Metrics Images:"
  kubectl get deploy "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
  -o jsonpath='{.spec.template.spec.containers[*].image}'

  echo
  echo "Node Exporter Images:"
  kubectl get ds "$DS_NAME" -n "$NAMESPACE" \
  -o jsonpath='{.spec.template.spec.containers[*].image}'

  echo
}

# =========================================================
# Main Execution
# =========================================================

wait_for_resources

patch_deploy_container_image

patch_ksm_container_image

patch_ds_container_image

patch_automount

restart_workloads

wait_after_restart

verify_images

echo "All patches completed successfully"
