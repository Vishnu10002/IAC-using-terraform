# Create IAM Role
resource "aws_iam_role" "eks_master_role" {
  name = "${local.name}-eks-master-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Associate IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_master_role.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_master_role.name
}

/*
# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_master_role.name
}
*/

data "http" "policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/master/docs/examples/iam-policy.json"
  }



resource "aws_iam_policy" "example" {
  name   = "ALBIngressControllerIAMPolicy"

  policy = data.http.policy.body
}

# resource "aws_iam_service_account" "example" {
  
#   name = "my-service-account"
#   policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonS3FullAccess"
#   ]
# }

# resource "aws_iam_policy_attachment" "example" {
#   name       = "my-policy-attachment"
#   policy_arn = "arn:aws:iam::123456789012:policy/my-policy"
#   roles      = [aws_iam_service_account.example.name]
# }