terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes-alpha = {
      source = "hashicorp/kubernetes-alpha"
      version = "~> 0.5.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "null_resource" "install_helm" {
  provisioner "local-exec" {
    command = <<-EOT
      sudo apt update -y
      sudo apt install -y curl
      curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
      chmod 700 get_helm.sh
      ./get_helm.sh
      rm ./get_helm.sh
    EOT
  }
}

resource "null_resource" "add_helm_repository" {
  provisioner "local-exec" {
    command = "helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver && helm repo update"
  }

  depends_on = [
    null_resource.install_helm
  ]
}

resource "null_resource" "install_ebs_csi_driver" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --version 2.22.0 --repo https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  }

  depends_on = [
    null_resource.add_helm_repository
  ]
}

# The rest of your resources remain unchanged, as this method only replaces the helm_release resource.

resource "kubernetes_storage_class" "ebs" {
  metadata {
    name = "tigera-elasticsearch"
  }
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
}

resource "kubernetes_namespace" "tigera_operator" {
  metadata {
    name = "tigera-operator"
  }
}

resource "kubernetes_secret" "tigera_pull_secret" {
  metadata {
    name      = "tigera-pull-secret"
    namespace = "tigera-operator"
  }

  data = {
    ".dockerconfigjson" = file("/home/tigera/config.json")
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "null_resource" "tigera_operator" {
  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://downloads.tigera.io/ee/v3.18.0-2.0/manifests/tigera-operator.yaml"
  }
  depends_on = [
    kubernetes_namespace.tigera_operator, 
    kubernetes_secret.tigera_pull_secret
  ]
}

resource "null_resource" "tigera_prometheus_operator" {
  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://downloads.tigera.io/ee/v3.18.0-2.0/manifests/tigera-prometheus-operator.yaml"
  }
  depends_on = [
    null_resource.tigera_operator
  ]
}

resource "null_resource" "configure_tigera_prometheus" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl create secret generic tigera-pull-secret \
        --type=kubernetes.io/dockerconfigjson -n tigera-prometheus \
        --from-file=.dockerconfigjson=/home/tigera/config.json
      kubectl patch deployment -n tigera-prometheus calico-prometheus-operator \
        -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name": "tigera-pull-secret"}]}}}}'
    EOT
  }
  depends_on = [
    null_resource.tigera_prometheus_operator
  ]
}

resource "null_resource" "calico_installation_configuration" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f -<<EOF
      apiVersion: operator.tigera.io/v1
      kind: Installation
      metadata:
        name: default
      spec:
        variant: TigeraSecureEnterprise
        imagePullSecrets:
        - name: tigera-pull-secret
        calicoNetwork:
          ipPools:
          - blockSize: 26
            cidr: 10.48.0.0/24
            encapsulation: None
            natOutgoing: Enabled
            nodeSelector: all()
      EOF
    EOT
  }
  depends_on = [
    null_resource.configure_tigera_prometheus
  ]
}

resource "null_resource" "tigera_custom_resources" {
  provisioner "local-exec" {
    command = "kubectl apply --server-side -f https://downloads.tigera.io/ee/v3.18.0-2.0/manifests/custom-resources.yaml"
  }
  depends_on = [
    null_resource.tigera_prometheus_operator, 
    null_resource.calico_installation_configuration
  ]
}

resource "null_resource" "wait_130_seconds" {
  provisioner "local-exec" {
    command = "sleep 130"
  }
  depends_on = [
    null_resource.tigera_custom_resources
  ]
}

resource "null_resource" "tigera_license" {
  provisioner "local-exec" {
    command = "kubectl create -f /home/tigera/license.yaml"
  }
  depends_on = [
    null_resource.wait_130_seconds
  ]
}
