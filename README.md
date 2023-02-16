# IAC-using-terraform
## Terraform

> ## aws configuration

>=================

> To configure aws for the first time give credentials in aws cli by typing the command aws config.
> this will create a .aws folder in user directory containing credentials for connecting aws
> or else in provider block you can give the access client and access secret in provider.tf file.

> ## variables
>====================

> Variables in Terraform are used to define centrally controlled reusable values. 
The information in Terraform variables is saved independently from the deployment plans.
> ### input variables

> Input Variables serve as parameters for a Terraform module, so users can customize behavior without editing the source
> Here input variables are defined for a particular resource or module in resource-variables.tf files

> ## .tfvar files
> These files hold the definition of variables.
> These helps in changing value of a parameter dynamically at the runtime.

# Terraform Commands

--> terraform init
--> terraform validate
--> terraform plan
--> terraform apply
--> terraform destroy

> Flow of the containarization of the services
> ===============================================


  gitlab(Raw code) ------> pull code to the local repository --------> Build the package ------> dockerfile -------> Docker build(build the image) 
  
  ---------> Push the Image to AWS ECR(repository) --------> create the Helm chart ---------> Deploy the Image on kubernetes using Helm 

  charts--------> using Endpoint enduser will access the services.


>    ALB Ingress controller deployment 
 >   ===============================================

     step-1: create an IAM OIDC provider and associate it with your cluster.
             
             eksctl utils associate-iam-oidc-provider --cluster=cluster-name --approve
     
   
     step-2: create RBAC roles and role bindings for AWS ALB Ingress controller.
  
             kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/rbac-role.yaml
             
     step-3: create an IAM policy named ALBIngressControllerIAMPolicy
  
            aws iam create-policy \
                --policy-name ALBIngressControllerIAMPolicy \
                --policy-document https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/iam-policy.json    
                
     step-4:  create service account and IAM role for the pod running the AWS ALB Ingress controller
                  
             eksctl create iamserviceaccount \
                    --cluster=cluster-name \
                    --namespace=kube-system \
                    --name=alb-ingress-controller \
                    --attach-policy-arn=$PolicyARN \ (replace $policyARN with policy ARN generated from step-2)
                   --override-existing-serviceaccounts \
                   --approve
                   
     step-5: Deploy the AWS ALB Ingress Controller
              
              curl -sS "https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/alb-ingress-controller.yaml" \
              | sed "s/# - --cluster-name=devCluster/- --cluster-name=cluster-name/g" \
              | kubectl apply -f - 
        
     step-6: To verify that the deployment was successful and the controller started
  
             kubectl logs -n kube-system $(kubectl get po -n kube-system | egrep -o alb-ingress[a-zA-Z0-9-]+)
             
             
 >  ELB Ingress Controller deployment
>   ====================================

 step-1: wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.34.1/deploy/static/provider/aws/deploy-tls-termination.yaml
 
 step-2: Edit the file and change:

       --> VPC CIDR in use for the Kubernetes cluster:

           proxy-real-ip-cidr: XXX.XXX.XXX/XX

        --> AWS Certificate Manager (ACM) ID
            arn:aws:acm:us-west-2:XXXXXXXX:certificate/XXXXXX-XXXXXXX-XXXXXXX-XXXXXXXX
            
 step-3:    kubectl apply -f deploy-tls-termination.yaml  
  > After creating the helm chart run the helm chart
>   ====================================================


           helm install chartname ./chartname
           

     Once the helm chart is deployed use the below commands to check the pod status

     kubectl config get-contexts ------> To check the cluster details
     
     kubectl config use-context cluster-name ------> To switch from one cluster to another cluster.
     
     kubectl get po  -n namespace------>   to check the pod  status

     kubectl get po -n namespace -o wide ---->  to check the detailed info about pod
     
     kubectl describe po podid -n namespace ----> To check the pod details
     
     kubectl get hpa -n namespace -----> To check the HPA of in namespace

     kubectl get logs -f podid -n namespace------->    to check the pod logs

     kubectl cluster-info -----> to check the cluster information

     kubectl get svc  -n namespace -----> to check the service status

     kubectl get deployment -n namespace ----> to check the deployment pod status

     kubectl get ing -n namespace ----> to check the ingress status

     kubectl get nodes -n namespace ----> to check the node status
        kubectl get nodes -n namespace ----> to check the node status

     kubectl get nodes -n namespace -o wide ----> to check the detailed info about node

     kubectl get cm -n namespace ----> to check the configmap in a particular namespace

     kubectl get secret -n namespace ----> to check the secret files.

     kubectl edit po/svc/deployment -n namespace ----> to edit the po/svc/deployment yaml files

     kubectl exec -it podid -n namespace  ----> to login to the pod

     kubectl delete po/svc/deployment -n namespace ----> to delete the pod/svc/deployment
     
     helm upgrade keycloak-cluster codecentric/keycloak -f keyclock-dev.yaml -n dev -------> Update the helm charts 

     (Note: when we have multiple applications to expose outside for routing we are using Ingress controller(nlb/alb) and with domain name end user will Access the application.
     2) if we have multiple namespaces we can use namespace to search the object .for default namespace no need to mention the namespace.





helm -dev pipeline. added fitler for master branch test.


> Continuous Delivery using Spinnaker on Amazon EKS
> ==================================================

please follow the below document link to setup spinnaker in cluster and UAT and QA env

https://aws.amazon.com/blogs/opensource/continuous-delivery-spinnaker-amazon-eks/
