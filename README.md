# terraspace-aws-eks-cluster

This is a Terraspace project. It contains code to provision Cloud infrastructure built with [Terraform](https://www.terraform.io/) and the [Terraspace Framework](https://terraspace.cloud/).

## Package Installation

Terraspace install as a [standalone package](https://terraspace.cloud/docs/install/standalone/).

## Boot Hooks

Modify the Terraspace [TS_APP value](https://terraspace.cloud/docs/layering/app-layering/) in [config/boot.rb](https://terraspace.cloud/docs/config/boot/) for your environment.

    config/boot.rb # where TS_APP value represents you (example: your IAM username).

## Deploy

To deploy all the infrastructure stacks:

    terraspace all up

To deploy individual stacks:

    terraspace up vpc # where stack vpc is located under app/stacks/vpc

To deploy individual stacks in another region with environment prod and app myuser:

    AWS_REGION=us-gov-west-1 TS_ENV=prod TS_APP=myuser terraspace up vpc

## Terrafile

To use more modules, add them to the [Terrafile](https://terraspace.cloud/docs/terrafile/).


## Update kubeconfig

To update your ~/.kube/config for EKS:

    aws eks --region us-gov-east-1 update-kubeconfig --name my-app-dev

## Test config

Test your configuration:

    kubectl get svc

## Test API server

Test access to the Amazon EKS API server:

    aws eks describe-cluster \
        --name my-app-dev --region us-gov-east-1 \
        --query cluster.resourcesVpcConfig
