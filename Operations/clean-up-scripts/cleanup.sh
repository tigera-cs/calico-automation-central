#!/bin/bash

set -e

echo "🚧 Stopping kubelet to prevent interface regeneration..."
sudo systemctl stop kubelet

echo "🧹 Deleting cali* and tunl* interfaces..."
for iface in $(ip -o link show | grep -E 'cali|tunl' | awk -F': ' '{print $2}' | cut -d@ -f1); do
  sudo ip link delete "$iface" 2>/dev/null || true
done

echo "🗺️ Deleting /32 pod routes in 10.233.x.x..."
for ip in $(ip route | grep -E '^10\.233\.[0-9]+\.[0-9]+/32' | awk '{print $1}'); do
  sudo ip route del "$ip" 2>/dev/null || true
done

echo "📡 Deleting proto bird BGP routes..."
for ip in $(ip route | grep 'proto bird' | grep 10.233 | grep 'via' | awk '{print $1}'); do
  sudo ip route del "$ip" 2>/dev/null || true
done

echo "🕳️ Deleting any blackhole routes from BIRD..."
for ip in $(ip route | grep 'proto bird' | grep blackhole | awk '{print $2}'); do
  sudo ip route del blackhole "$ip" 2>/dev/null || true
done

echo "🔥 Flushing nftables ruleset (Calico)..."
if sudo nft list ruleset | grep -q cali; then
  sudo nft flush ruleset
fi

echo "🔥 Flushing iptables-legacy Calico chains..."
for chain in $(sudo iptables-legacy -S | grep cali | awk '{print $2}' | sort -u); do
  sudo iptables-legacy -F "$chain" || true
  sudo iptables-legacy -X "$chain" || true
done

echo "🔥 Flushing iptables-nft Calico chains (if any)..."
for chain in $(sudo iptables -S | grep cali | awk '{print $2}' | sort -u); do
  sudo iptables -F "$chain" || true
  sudo iptables -X "$chain" || true
done

echo "🧾 Deleting Calico CNI config files..."
sudo rm -f /etc/cni/net.d/10-calico.conflist \
            /etc/cni/net.d/calico-kubeconfig \
            /etc/cni/net.d/calico_multi_interface_mode 2>/dev/null || true

echo "📦 Deleting Calico CNI plugin binaries..."
sudo rm -f /opt/cni/bin/calico* 2>/dev/null || true

echo "🔄 Restarting kubelet..."
sudo systemctl start kubelet

echo "✅ Calico cleanup completed on $(hostname)."
