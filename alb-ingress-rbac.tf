# resource "kubernetes_namespace" "kube_system" {
#   metadata {
#     name = "kube-system"
#   }
# }

# resource "kubernetes_service_account" "alb_ingress_controller" {
#   metadata {
#     cluster="cropin-v2-eks"
    
#     name      = "alb-ingress-controller"
#     policy_arn = aws_iam_policy.example.arn
#     namespace = kubernetes_namespace.kube_system.metadata.0.name
    
#   }
# }

# resource "kubernetes_role" "alb_ingress_controller" {
#   metadata {
#     name      = "alb-ingress-controller"
#     namespace = kubernetes_namespace.kube_system.metadata.0.name
#   }

#   rule {
#     api_groups = [""]
#     resources  = ["configmaps", "endpoints", "events", "ingresses", "ingresses/status", "services"]
#     verbs      = ["create", "get", "list", "update", "watch", "patch"]
#   }

#   rule {
#     api_groups = [""]
#     resources  = ["nodes", "pods", "secrets", "services", "namespaces"]
#     verbs      = ["get", "list", "watch"]
#   }
# }

# resource "kubernetes_role_binding" "alb_ingress_controller" {
#   metadata {
#     name      = "alb-ingress-controller"
#     namespace = kubernetes_namespace.kube_system.metadata.0.name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.alb_ingress_controller.metadata.0.name
#     namespace = kubernetes_namespace.kube_system.metadata.0.name
#   }

#   role_ref {
#     kind     = "Role"
#     name     = kubernetes_role.alb_ingress_controller.metadata.0.name
#     api_group = "rbac.authorization.k8s.io"
#   }
# }




# locals {
#   alb_ingress_controller_image = "docker.io/amazon/aws-alb-ingress-controller:v2.2.0"
# }

# provider "kubernetes" {
#   load_config_file = "false"

#   host                   = aws_eks_cluster.eks_cluster.cluster_endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.cluster_ca)

#   token = data.aws_eks_cluster_auth.cluster.token
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = aws_eks_cluster.eks_cluster.cluster_id
# }

# module "alb_ingress_controller" {
#   source = "terraform-aws-modules/kubernetes-aws-alb-ingress-controller/aws"

#   cluster_name = aws_eks_cluster.eks_cluster.cluster_id

#   create_iam_policy = true
#   oidc_issuer_url   = aws_eks_cluster.eks_cluster.oidc_issuer_url
#   oidc_client_id    = "sts.amazonaws.com"

#   image = local.alb_ingress_controller_image

#   vpc_id = module.vpc.vpc_id
# }



# locals {
#    # Your AWS EKS Cluster ID goes here.
#   k8s_cluster_name = aws_eks_cluster.eks_cluster.cluster_id
# }



# data "aws_eks_cluster" "target" {
#   name = "local.k8s_cluster_name"
# }

# data "aws_eks_cluster_auth" "aws_iam_authenticator" {
#   name = data.aws_eks_cluster.target.name
# }

# provider "kubernetes" {
#   alias = "eks"
#   host                   = data.aws_eks_cluster.target.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.target.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.aws_iam_authenticator.token
#   load_config_file       = false
# }

# module "alb_ingress_controller" {
#   source  = "iplabs/alb-ingress-controller/kubernetes"
#   version = "3.1.0"

#   providers = {
#     kubernetes = "kubernetes.eks"
#   }

#   k8s_cluster_type = "eks"
#   k8s_namespace    = "kube-system"

#   aws_region_name  = var.aws_region
#   k8s_cluster_name = data.aws_eks_cluster.target.name
# }

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_cluster.id]
      command     = "aws"
    }
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.1"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks_cluster.id
  }

  set {
    name  = "image.tag"
    value = "v2.4.2"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  depends_on = [
    aws_eks_node_group.eks_ng_public,
    aws_iam_role_policy_attachment.aws_load_balancer_controller_attach
  ]
}

