#!/bin/bash

# ==================================================
# 🔄 Kubernetes Goat: Dynamic Scenario Reloader
# ==================================================

SCENARIO=$1
export KUBECTL_INSECURE="--insecure-skip-tls-verify"

# 1. Input Validation
if [ -z "$SCENARIO" ]; then
  echo "❌ Error: No scenario provided."
  echo "💡 Usage: ./reload-goat.sh <scenario-folder-name>"
  echo "📝 Example: ./reload-goat.sh health-check"
  echo "📝 Example: ./reload-goat.sh build-code"
  exit 1
fi

DEPLOYMENT_FILE="scenarios/$SCENARIO/deployment.yaml"
INFRA_DIR="./infrastructure/$SCENARIO/"

if [ ! -f "$DEPLOYMENT_FILE" ]; then
  echo "❌ Error: Deployment file not found at $DEPLOYMENT_FILE"
  exit 1
fi

echo "🎯 Targeting Scenario: $SCENARIO"
echo "=================================================="

# 2. Dynamically extract the Deployment name from the YAML
DEPLOYMENT_NAME=$(awk '/kind: Deployment/{flag=1} flag && /name:/{print $2; exit}' "$DEPLOYMENT_FILE")

if [ -z "$DEPLOYMENT_NAME" ]; then
  echo "⚠️ Warning: Could not parse deployment name from YAML. Tear-down might be incomplete."
else
  echo "[1/5] 🧹 Tearing down existing deployment ($DEPLOYMENT_NAME)..."
  kubectl $KUBECTL_INSECURE delete -f "$DEPLOYMENT_FILE" --ignore-not-found=true
fi

# 3. Kill existing network tunnels
echo "[2/5] 🛑 Terminating existing port-forward tunnels..."
killall kubectl 2>/dev/null
sleep 2

# 4. Smart Compilation (Only builds if there is an infrastructure folder)
if [ -d "$INFRA_DIR" ]; then
  echo "[3/5] 🔨 Infrastructure directory found! Compiling fresh image..."
  # Dynamically extract the image name you wrote in the deployment file
  IMAGE_TAG=$(grep -oP '(?<=image: ).*' "$DEPLOYMENT_FILE" | grep -v "busybox" | tr -d '"'\''' | head -n 1)
  
  if [[ "$IMAGE_TAG" == *"my-secure"* ]] || [[ "$IMAGE_TAG" == *":v"* ]]; then
      echo "    📦 Building as: $IMAGE_TAG"
      minikube image build -t "$IMAGE_TAG" "$INFRA_DIR"
  else
      echo "    ⚠️ Image tag ($IMAGE_TAG) looks like a remote Hub image. Skipping local build."
  fi
else
  echo "[3/5] ⏩ No local infrastructure directory found. Skipping build phase."
fi

# 5. Apply the new configuration
echo "[4/5] 🚀 Deploying updated infrastructure..."
kubectl $KUBECTL_INSECURE apply -f "$DEPLOYMENT_FILE"

# 6. Wait for the cluster to stabilize
if [ -n "$DEPLOYMENT_NAME" ]; then
  echo "[5/5] ⏳ Waiting for $DEPLOYMENT_NAME to reach 'Running' state..."
  kubectl $KUBECTL_INSECURE wait --for=condition=available --timeout=60s "deployment/$DEPLOYMENT_NAME"
fi

# 7. Targeted Access Bridge (Bypassing access-kubernetes-goat.sh)
echo "🌉 Establishing dedicated access tunnel for $SCENARIO..."

# Map the Goat scenarios to their designated local ports and container ports
case "$SCENARIO" in
    "build-code") FORWARD_PORTS="1230:3000" ;;
    "health-check") FORWARD_PORTS="1231:8080" ;;
    "internal-proxy") FORWARD_PORTS="1232:3000" ;;
    "system-monitor") FORWARD_PORTS="1233:8080" ;;
    "kubernetes-goat-home") FORWARD_PORTS="1234:80" ;;
    "poor-registry") FORWARD_PORTS="1235:5000" ;;
    "hunger-check") FORWARD_PORTS="1236:8080" ;;
    *) FORWARD_PORTS="" ;;
esac

if [ -n "$FORWARD_PORTS" ]; then
    nohup kubectl $KUBECTL_INSECURE port-forward "svc/${SCENARIO}-service" --address 0.0.0.0 $FORWARD_PORTS > access-script.log 2>&1 &
    LOCAL_PORT=$(echo $FORWARD_PORTS | cut -d':' -f1)
    
    echo "=================================================="
    echo "✅ Reload Complete for: $SCENARIO"
    echo "🎯 Tunnel is live! Test it at: http://127.0.0.1:$LOCAL_PORT"
    echo "=================================================="
else
    echo "=================================================="
    echo "✅ Reload Complete for: $SCENARIO"
    echo "⚠️ No automatic port mapping defined for this scenario."
    echo "=================================================="
fi