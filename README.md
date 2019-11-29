# Deploy AWS EKS stack using Terraform and Bash

In this project, we're going to deploy AWS EKS, 2xEC2 instances (It will be the K8S workers), helm/tiller, Kubernetes Dashboard and create two users (1x admin and 1x user just for the default namespace).

## How to use

You can run the initial Bash script, it will look for dependencies (terraform, helm, etc) and you can choose between Deploy and Destroy.

Example:

```text
./deploy_eks_stack.sh
2019-07-14 19:07:24 Checking for dependencies
What action you want to execute?
1) Deploy
2) Destroy
Default: Deploy
-> 1
```

or

```text
./deploy_eks_stack.sh Deploy
2019-07-14 20:31:40 Checking for dependencies
2019-07-14 20:31:40 Starting to deploy the AWS EKS stack
```

## Getting my Token

By default, this automation will create two users. One is `mlozano-admin` (Cluster admin) and another `mlozano-user` (For default namespace).

To get the token, you can run this command.

```bash
my_user=mlozano
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | awk '/'"${my_user}"'/ { rc = 1; print $1 }; END { exit !rc }' || echo "${my_user}")
```

## Accessing K8s Dashboard

The dashboard is configured to be "public" (Allowed just for few external IPs) and with HTTP over TLS.

Run this command to get the external address.

```bash
kubectl -n kube-system get service
```

The output will be something like this

```text
NAME              TYPE           CLUSTER-IP      EXTERNAL-IP                                       PORT(S)          AGE
kube-dns          ClusterIP      <CLUSTER_IP>    <none>                                            53/UDP,53/TCP    166m
k8s-dashboard     LoadBalancer   <CLUSTER_IP>    <MY_LoadBalancer>.<REGION>.elb.amazonaws.com      8080:32225/TCP   7m22s
tiller-deploy     ClusterIP      <CLUSTER_IP>    <none>                                            44134/TCP        55m
```

> The URL structre is `https://<MY_LoadBalancer>.<REGION>.elb.amazonaws.com:8080/`
