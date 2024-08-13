
The repository structure
```
.
├── aws_eks
│   ├── backend.tf
│   ├── input.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── provider.tf
└── eksctl
    ├── cluster.yaml
    ├── commands.txt
    ├── deployment.yaml
    ├── ingress.yaml
    ├── logs.log
    ├── service.yaml
    └── terraform.tfstate
```
**Terraform Configuration:**
1. Used terraform to create the AWS VPC.
main.tf
```
resource "aws_vpc" "test-vpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "pub_sub1" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"
  tags = {
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_subnet" "pub_sub2" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "true"
  tags = {
    "kubernetes.io/role/elb" = 1 
  }
}


resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.test-vpc.id
}

resource "aws_route_table" "routetable1" {
  vpc_id = aws_vpc.test-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "association1" {
  subnet_id = aws_subnet.pub_sub1.id
  route_table_id = aws_route_table.routetable1.id
}

resource "aws_route_table_association" "association2" {
  subnet_id = aws_subnet.pub_sub2.id
  route_table_id = aws_route_table.routetable1.id
}

resource "aws_security_group" "mysg" {
  name_prefix = "eks-cluster-sg-tf-"
  vpc_id = aws_vpc.test-vpc.id
}

resource "aws_security_group_rule" "ingress_rule_1" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  source_security_group_id = aws_security_group.mysg.id
  security_group_id = aws_security_group.mysg.id
}

resource "aws_security_group_rule" "egress_rule_1" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = aws_security_group.mysg.id
  security_group_id = aws_security_group.mysg.id
}

resource "aws_security_group_rule" "egress_rule_2" {
  type              = "egress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  source_security_group_id = aws_security_group.mysg.id
  security_group_id = aws_security_group.mysg.id
}

resource "aws_security_group_rule" "egress_rule_3" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  source_security_group_id = aws_security_group.mysg.id
  security_group_id = aws_security_group.mysg.id
}


resource "aws_eip" "eip1" {
}

resource "aws_eip" "eip2" {
}

resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.eip1.allocation_id
  subnet_id = aws_subnet.pub_sub1.id
  depends_on = [ aws_internet_gateway.my_igw ]
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.eip2.allocation_id
  subnet_id = aws_subnet.pub_sub2.id
  depends_on = [ aws_internet_gateway.my_igw ]
}

resource "aws_subnet" "pvt_sub1" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_subnet" "pvt_sub2" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
    tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_route_table" "pvt_routetable1" {
  vpc_id = aws_vpc.test-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat1.id
  }
}

resource "aws_route_table" "pvt_routetable2" {
  vpc_id = aws_vpc.test-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat2.id
  }
}

resource "aws_route_table_association" "pvt_association1" {
  subnet_id = aws_subnet.pvt_sub1.id
  route_table_id = aws_route_table.pvt_routetable1.id
}

resource "aws_route_table_association" "pvt_association2" {
  subnet_id = aws_subnet.pvt_sub2.id
  route_table_id = aws_route_table.pvt_routetable2.id
}
```

**Eksctl Configuration**
2. The above one creates the networking stack and outputs the subnets and I used the outputs in the below cluster.yaml
```
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
vpc:
  clusterEndpoints:
    publicAccess:  true
    privateAccess: true
  subnets:
    private:
      us-east-1a: { id: subnet-0c10055fc4725045c }
      us-east-1b: { id: subnet-07f654788821df94f }
    public:
      us-east-1a: { id: subnet-06f24b6837d202731 }
      us-east-1b: { id: subnet-0960cf4d6b3f318f4 }

metadata:
  name: dev-cluster
  region: us-east-1

nodeGroups:
  - name: ng-dev-1
    instanceType: m5.large
    desiredCapacity: 2
    privateNetworking: true
    iam:
      attachPolicyARNs:
        - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
        - arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
        - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
        - arn:aws:iam::aws:policy/AmazonSSMFullAccess
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
        - arn:aws:iam::aws:policy/AmazonSSMPatchAssociation
        - arn:aws:iam::aws:policy/AmazonEC2FullAccess

cloudWatch:
  clusterLogging:
    enableTypes: ["audit", "authenticator", "controllerManager", "api", "scheduler"]
    logRetentionInDays: 7

addons:
- name: vpc-cni # no version is specified so it deploys the default version
  attachPolicyARNs:
    - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
- name: coredns
  version: latest # auto discovers the latest available
- name: kube-proxy
  version: latest
- name: aws-ebs-csi-driver
  wellKnownPolicies:      # add IAM and service account
    ebsCSIController: true
```

3. Installed the eksctl with the below commands
```
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
```

4. Created the cluster `dev-cluster`
```
eksctl create cluster -f cluster.yaml
```

 **Kubernetes Configuration:**
5. Created kubernetes resources as suggested.
Deployment
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

Service
```
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  type: LoadBalancer
```

5. Output for the command `kubectl get all`
```
% kubectl get all
NAME                         READY   STATUS    RESTARTS   AGE
pod/netshoot                 1/1     Running   0          145m
pod/nginx-77d8468669-25rwf   1/1     Running   0          117m
pod/nginx-77d8468669-h4cmm   1/1     Running   0          117m
pod/nginx-77d8468669-lqklg   1/1     Running   0          117m

NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP                                                                    PORT(S)        AGE
service/kubernetes       ClusterIP      172.20.0.1       <none>                                                                         443/TCP        16h
service/nginx            LoadBalancer   172.20.255.133   k8s-default-nginx-6a724326aa-57fb3ec14f19379b.elb.us-east-1.amazonaws.com      80:32399/TCP   80m

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   3/3     3            3           118m

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-77d8468669   3         3         3       118m
```

**Additionally, I created AWS ALB ingress resources as wel as below**
- Created OIDC for the cluster `eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=dev-cluster --approve`
- Creaed service account for ingress controller `eksctl create iamserviceaccount --cluster=dev-cluster --namespace=kube-system --name=aws-load-balancer-controller --role-name AmazonEKSLoadBalancerControllerRole --attach-policy-arn=arn:aws:iam::aws:policy/AdministratorAccess --approve`
- Added helm repo `helm repo add eks https://aws.github.io/eks-charts`
- Installed using below command
  ```
  helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=dev-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 
  ```
- Checked the ingress controller deployment using `kubectl get deployment -n kube-system aws-load-balancer-controller`
- Further, created a NodePort service and created ingress resource.
