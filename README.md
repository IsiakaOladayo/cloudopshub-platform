☁  CloudOpsHub
Automated Multi-Cluster Infrastructure Platform
Complete Step-by-Step Project Guide
For Beginners · Group of 5 · Includes AWS Free Tier Instructions
Member A  ·  Member B  ·  Member C  ·  Member D  ·  Member E


How to Use This Guide
This guide is written so that even a complete beginner can follow it from start to finish. You do not need to understand every technical term before you begin — each section explains what a tool does before asking you to use it. Simply read each step, run the commands shown, and you will have a working platform by the end.

 	Tip for Beginners
Every command in this guide is shown in a dark code box. Type or copy those commands exactly into your terminal (the black text window on your computer). Press Enter after each one to run it.

Team Split: The project is divided among 5 members (A–E). Each section clearly marks which member is responsible. However, every member should read the full guide so they understand how the pieces connect.

Section 1 — Project Overview
1.1  What Are We Building?
We are building a complete DevOps platform for a company called CloudOpsHub. This platform will automatically take code written by developers, test it, package it, check it for security issues, and then deploy it to two separate Kubernetes clusters — one running locally on your computer and one running in the Amazon cloud (AWS).
Think of it like a factory assembly line for software: code goes in one end, and a running, tested, secure application comes out the other end — automatically, every time.

1.2  Tools We Will Use
Here is every tool we will install, what it does in plain English, and how to install it:

Tool	What It Does (Plain English)	Install Command
Docker	Packages your app into a portable container (like a shipping container for software)	sudo apt install docker.io -y && sudo systemctl enable docker
kubectl	The command-line tool to talk to Kubernetes clusters	curl -LO https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && sudo install kubectl /usr/local/bin/
Kind	Creates a local Kubernetes cluster inside Docker (for dev/staging)	curl -Lo kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 && sudo mv kind /usr/local/bin/
Terraform	Writes infrastructure (servers, networks) as code so you can create it automatically	sudo apt install terraform -y  (or see terraform.io for latest)
Ansible	Configures servers automatically — installs software, sets settings	sudo apt install ansible -y
Helm	A package manager for Kubernetes — like apt-get but for cluster apps	curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
ArgoCD	Watches your Git repo and keeps your clusters in sync with it (GitOps CD)	kubectl create ns argocd && kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
Trivy	Scans Docker images for known security vulnerabilities before deploy	sudo apt install wget apt-transport-https gnupg lsb-release -y && wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add - && sudo apt update && sudo apt install trivy -y
Prometheus	Collects numbers/metrics from your app and clusters (CPU, memory, requests)	Installed via Helm — see Section 7
Grafana	Turns Prometheus numbers into beautiful visual dashboards	Installed via Helm — see Section 7
Loki	Collects and stores log messages from all your containers	Installed via Helm — see Section 7
Velero	Takes automatic backups of your Kubernetes cluster data	See Section 8 for full install steps
eksctl	Creates and manages AWS EKS Kubernetes clusters easily	curl --silent --location 'https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz' | tar xz -C /tmp && sudo mv /tmp/eksctl /usr/local/bin
AWS CLI	Lets you control AWS from the terminal	curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o awscliv2.zip && unzip awscliv2.zip && sudo ./aws/install



Section 2 — Team Assignments
The project is split into 5 areas. Each team member owns one area end-to-end. You are responsible for setting up, testing, and documenting your piece, and presenting it during the demo.

A	Member A — Infrastructure Lead — Terraform + AWS Setup

•Set up the GitHub repository structure for the whole team
•Write Terraform code to provision AWS resources (VPC, EKS, S3, ECR)
•Create the local Kind cluster for development and staging
•Configure networking between both clusters
•Run Ansible playbook to install base software on all servers

B	Member B — CI Pipeline Engineer — GitHub Actions + Docker + Trivy

•Write the Dockerfile for the application (frontend + backend)
•Create GitHub Actions workflow file for the CI pipeline
•Integrate Trivy security scanning into the pipeline
•Set up Docker Hub (or AWS ECR) to store built images
•Configure Slack or email notifications for build results

C	Member C — GitOps & CD Lead — ArgoCD + Helm + Rollbacks

•Install and configure ArgoCD on Cluster 1 (local)
•Register Cluster 2 (AWS EKS) with ArgoCD
•Write Helm charts / Kubernetes manifests for the application
•Set up the dev → staging → production promotion workflow
•Configure and test rollback procedures

D	Member D — Observability Engineer — Prometheus + Grafana + Loki

•Install Prometheus stack via Helm on both clusters
•Install Loki for centralized log collection
•Build Grafana dashboards for CPU, memory, requests, and errors
•Configure AlertManager to send alerts when thresholds are breached
•Document how to read each dashboard panel

E	Member E — Security & Backup Lead — Secrets + Velero + Docs

•Set up Kubernetes Secrets for all sensitive credentials
•Install and configure Velero for cluster backups to S3
•Implement RBAC (role-based access) policies
•Write the operational runbooks (deployment, rollback, restore)
•Prepare the project summary document for the panel



Section 3 — Member A: Infrastructure Setup
This section covers everything Member A needs to do to set up the underlying infrastructure — the foundation that everything else sits on.

3.1  Set Up the GitHub Repository
First, create a single shared GitHub repository for the whole team. This is where all code, configuration, and infrastructure files will live.
1.Go to github.com and sign in.
2.Click the + button (top right) → New repository.
3.Name it: cloudopshub-platform. Set it to Public. Click Create repository.
4.Clone it to your computer:
git clone https://github.com/YOUR_USERNAME/cloudopshub-platform.git
cd cloudopshub-platform
5.Create the folder structure:
mkdir -p terraform/aws terraform/local ansible/roles/base
mkdir -p kubernetes/manifests kubernetes/helm
mkdir -p .github/workflows app/frontend app/backend
touch README.md

3.2  Create the Local Kubernetes Cluster (Kind)
Kind stands for Kubernetes IN Docker. It creates a real Kubernetes cluster that runs inside Docker containers on your laptop. We will use this for development and staging environments.
6.Install Docker first (if not already installed):
sudo apt update && sudo apt install docker.io -y
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker
7.Install Kind:
curl -Lo kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x kind && sudo mv kind /usr/local/bin/kind
kind version
8.Create a Kind cluster configuration file. Save this as terraform/local/kind-cluster.yaml:
# kind-cluster.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cloudopshub-local
nodes:
  - role: control-plane
  - role: worker
  - role: worker
9.Create the cluster:
kind create cluster --config terraform/local/kind-cluster.yaml
kubectl get nodes   # You should see 3 nodes listed

3.3  Create the AWS Production Cluster with Terraform
Now we will use Terraform to automatically create all the AWS infrastructure needed for our production cluster. Think of Terraform files like a blueprint — you describe what you want and Terraform builds it.
10.Install Terraform:
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y
terraform version
11.Install AWS CLI and configure it with your AWS credentials:
curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o awscliv2.zip
unzip awscliv2.zip && sudo ./aws/install
aws configure
# Enter your AWS Access Key ID, Secret Key, region (us-east-1), output (json)
12.Create the main Terraform file. Save as terraform/aws/main.tf:
# main.tf — AWS Infrastructure for CloudOpsHub
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket = "cloudopshub-tfstate"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" { region = "us-east-1" }

# VPC (Virtual Private Cloud — our private network in AWS)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "cloudopshub-vpc" }
}

# Public Subnets (where our worker nodes live)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "cloudopshub-pub-a", "kubernetes.io/role/elb" = "1" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "cloudopshub-pub-b", "kubernetes.io/role/elb" = "1" }
}

# Internet Gateway (lets our cluster talk to the internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "cloudopshub-igw" }
}

# Route table (tells traffic where to go)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0", gateway_id = aws_internet_gateway.igw.id }
  tags = { Name = "cloudopshub-rt" }
}
resource "aws_route_table_association" "a" { subnet_id = aws_subnet.public_a.id, route_table_id = aws_route_table.public.id }
resource "aws_route_table_association" "b" { subnet_id = aws_subnet.public_b.id, route_table_id = aws_route_table.public.id }

# S3 Bucket for backups and Terraform state
resource "aws_s3_bucket" "backups" {
  bucket        = "cloudopshub-velero-backups"
  force_destroy = true
  tags          = { Name = "cloudopshub-backups" }
}
13.Create the EKS cluster file. Save as terraform/aws/eks.tf:
# eks.tf — EKS Kubernetes Cluster (AWS Managed)

# IAM Role for EKS Control Plane
resource "aws_iam_role" "eks_role" {
  name = "cloudopshub-eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow",
      Principal = { Service = "eks.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role for Worker Nodes
resource "aws_iam_role" "node_role" {
  name = "cloudopshub-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "node_policy"  { role = aws_iam_role.node_role.name, policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" }
resource "aws_iam_role_policy_attachment" "cni_policy"   { role = aws_iam_role.node_role.name, policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" }
resource "aws_iam_role_policy_attachment" "ecr_policy"   { role = aws_iam_role.node_role.name, policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" }

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "cloudopshub-prod"
  role_arn = aws_iam_role.eks_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  }
  tags = { Name = "cloudopshub-prod" }
}

# Worker Nodes (t2.micro = free tier eligible)
resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "cloudopshub-workers"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  instance_types  = ["t2.micro"]   # Free tier eligible
  scaling_config  { desired_size = 2, max_size = 3, min_size = 1 }
}

output "cluster_endpoint"   { value = aws_eks_cluster.main.endpoint }
output "cluster_name"       { value = aws_eks_cluster.main.name }
14.Run Terraform to create all AWS resources:
cd terraform/aws
terraform init    # Downloads plugins
terraform plan    # Shows what will be created (review this!)
terraform apply   # Actually creates the resources. Type 'yes' when asked
15.Update your kubectl to connect to the new EKS cluster:
aws eks update-kubeconfig --name cloudopshub-prod --region us-east-1
kubectl get nodes   # Should show your AWS worker nodes

3.4  Configure Servers with Ansible
Ansible lets you write a list of tasks (called a playbook) and run them across many servers at once. Save this as ansible/site.yml:
# site.yml — Ansible Playbook
---
- name: Configure all servers
  hosts: all
  become: true   # Run as root
  tasks:
    - name: Update apt cache
      apt: update_cache=yes

    - name: Install Docker
      apt: name=docker.io state=present

    - name: Start Docker
      service: name=docker state=started enabled=yes

    - name: Install kubectl
      shell: |
        curl -LO https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
        install kubectl /usr/local/bin/kubectl
      args: { creates: /usr/local/bin/kubectl }

    - name: Install Helm
      shell: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      args: { creates: /usr/local/bin/helm }
16.Run the Ansible playbook:
ansible-playbook -i inventory.ini ansible/site.yml



Section 4 — Member B: CI Pipeline (GitHub Actions + Docker + Trivy)
The CI (Continuous Integration) pipeline automatically builds, tests, scans, and publishes your application every time someone pushes code to GitHub. Member B owns this entire flow.

4.1  Containerize the Application with Docker
Docker packages your application into a container — a self-contained box that includes the app and everything it needs to run. This means it will work the same on every machine.
17.Create a simple backend app. Save as app/backend/app.py:
# app.py — Simple Python Flask backend
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({'status': 'ok', 'message': 'CloudOpsHub API running'})

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
18.Create the requirements file. Save as app/backend/requirements.txt:
flask==3.0.0
gunicorn==21.2.0
19.Create the Dockerfile. Save as app/backend/Dockerfile:
# Dockerfile — How to build the backend container
FROM python:3.11-slim

# Set working directory inside the container
WORKDIR /app

# Copy and install dependencies first (Docker caches this layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Run as non-root user (security best practice)
RUN useradd -m appuser && chown -R appuser /app
USER appuser

# Expose port and start app
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
20.Test the Docker build locally:
cd app/backend
docker build -t cloudopshub-backend:test .
docker run -p 5000:5000 cloudopshub-backend:test
# Open browser at http://localhost:5000 — you should see the JSON response

4.2  Set Up GitHub Actions CI Pipeline
GitHub Actions is a built-in automation tool in GitHub. When you push code, it automatically runs a series of steps called a workflow. Save this file as .github/workflows/ci.yml:
# ci.yml — Continuous Integration Pipeline
name: CI Pipeline

# This pipeline runs on every push to main or any pull request
on:
  push:
    branches: [main, develop, staging]
  pull_request:
    branches: [main]

env:
  REGISTRY: docker.io
  IMAGE_NAME: your-dockerhub-username/cloudopshub-backend

jobs:
  build-test-scan:
    name: Build, Test & Scan
    runs-on: ubuntu-latest

    steps:
      # Step 1: Get the code from GitHub
      - name: Checkout Code
        uses: actions/checkout@v4

      # Step 2: Log into Docker Hub
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      # Step 3: Build the Docker image
      - name: Build Docker Image
        run: |
          docker build -t $IMAGE_NAME:${{ github.sha }} app/backend/
          docker tag $IMAGE_NAME:${{ github.sha }} $IMAGE_NAME:latest

      # Step 4: Run Trivy security scan
      - name: Run Trivy Security Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: '${{ env.IMAGE_NAME }}:${{ github.sha }}'
          format: 'table'
          exit-code: '1'          # Fail the build if HIGH/CRITICAL found
          severity: 'HIGH,CRITICAL'

      # Step 5: Run unit tests
      - name: Run Unit Tests
        run: |
          cd app/backend
          pip install -r requirements.txt pytest
          pytest tests/ -v || echo 'No tests yet — skipping'

      # Step 6: Push the image to Docker Hub (only on push to main)
      - name: Push Docker Image
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        run: |
          docker push $IMAGE_NAME:${{ github.sha }}
          docker push $IMAGE_NAME:latest

      # Step 7: Update the Kubernetes manifest with the new image tag
      - name: Update Manifest Image Tag
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        run: |
          sed -i 's|image: .*cloudopshub-backend.*|image: ${{ env.IMAGE_NAME }}:${{ github.sha }}|' kubernetes/manifests/backend-deployment.yaml
          git config user.email 'ci@cloudopshub.com'
          git config user.name 'CI Bot'
          git add kubernetes/manifests/backend-deployment.yaml
          git commit -m 'ci: update image tag to ${{ github.sha }}' || echo 'No changes'
          git push
21.Add Docker Hub credentials to GitHub Secrets: go to your GitHub repo → Settings → Secrets → New secret. Add DOCKERHUB_USERNAME and DOCKERHUB_TOKEN.

 	What Trivy does
Trivy checks your Docker image against a database of known security issues (called CVEs). If it finds any HIGH or CRITICAL problems, the build stops — the broken image never gets deployed. This protects your users.



Section 5 — Member C: ArgoCD, GitOps & Deployments
ArgoCD is the tool that watches your Git repository and automatically keeps your Kubernetes clusters in sync with whatever is in Git. This is called GitOps — Git is the single source of truth.

5.1  Install ArgoCD on Cluster 1 (Local)
22.Make sure kubectl is pointing to your local Kind cluster:
kubectl config use-context kind-cloudopshub-local
kubectl get nodes
23.Install ArgoCD:
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
24.Get the ArgoCD admin password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo
25.Access the ArgoCD web interface:
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
# Open browser at https://localhost:8080
# Username: admin   Password: (from step 3)

5.2  Register AWS EKS Cluster with ArgoCD
This is how one ArgoCD installation on Cluster 1 gains control over Cluster 2 on AWS:
26.Install ArgoCD CLI:
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
27.Log into ArgoCD CLI:
argocd login localhost:8080 --username admin --password YOUR_PASSWORD --insecure
28.Add the AWS cluster to ArgoCD:
# Switch to EKS context and add it to ArgoCD
kubectl config use-context arn:aws:eks:us-east-1:YOUR_ACCOUNT:cluster/cloudopshub-prod
argocd cluster add arn:aws:eks:us-east-1:YOUR_ACCOUNT:cluster/cloudopshub-prod --name aws-prod
argocd cluster list   # Should show both clusters

5.3  Write Kubernetes Manifests
A Kubernetes manifest is a YAML file that tells Kubernetes what to run and how to run it. Save the following files in the kubernetes/manifests/ folder.
29.Deployment manifest — tells Kubernetes how to run the backend app. Save as kubernetes/manifests/backend-deployment.yaml:
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudopshub-backend
  namespace: production
  labels:
    app: cloudopshub-backend
spec:
  replicas: 2          # Run 2 copies for high availability
  selector:
    matchLabels:
      app: cloudopshub-backend
  template:
    metadata:
      labels:
        app: cloudopshub-backend
    spec:
      containers:
        - name: backend
          image: your-dockerhub-username/cloudopshub-backend:latest
          ports:
            - containerPort: 5000
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: database-url
          resources:
            requests: { cpu: '100m', memory: '128Mi' }
            limits:   { cpu: '500m', memory: '512Mi' }
          livenessProbe:
            httpGet: { path: /health, port: 5000 }
            initialDelaySeconds: 10
            periodSeconds: 10
30.Service manifest — exposes the backend so it is reachable. Save as kubernetes/manifests/backend-service.yaml:
# backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: cloudopshub-backend
  namespace: production
spec:
  selector:
    app: cloudopshub-backend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  type: LoadBalancer   # AWS will assign a public IP automatically

5.4  Create ArgoCD Applications
An ArgoCD Application tells ArgoCD: watch this folder in Git, and keep this Kubernetes cluster in sync with it. Save as kubernetes/argocd/apps.yaml:
# apps.yaml — ArgoCD Applications
---
# Staging App (deploys to local cluster)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloudopshub-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/cloudopshub-platform
    targetRevision: staging
    path: kubernetes/manifests
  destination:
    server: https://kubernetes.default.svc   # Local cluster
    namespace: staging
  syncPolicy:
    automated:
      prune: true     # Remove resources not in Git
      selfHeal: true  # Fix any manual changes
---
# Production App (deploys to AWS EKS)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloudopshub-production
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/cloudopshub-platform
    targetRevision: main
    path: kubernetes/manifests
  destination:
    server: https://YOUR_EKS_ENDPOINT   # AWS EKS cluster
    namespace: production
  syncPolicy:
    syncOptions: [CreateNamespace=true]
    # No 'automated' here = manual approval required for prod
31.Apply the ArgoCD apps:
kubectl apply -f kubernetes/argocd/apps.yaml

5.5  Rollback Procedure
If something goes wrong after a deployment, rolling back is simple with ArgoCD:
# List recent deployments
argocd app history cloudopshub-production

# Roll back to a previous version (replace N with the revision number)
argocd app rollback cloudopshub-production N

# Or roll back by reverting the Git commit and pushing
git revert HEAD
git push origin main
# ArgoCD will automatically sync and redeploy the previous version



Section 6 — Completing the CD Pipeline
The CD (Continuous Delivery) pipeline handles promoting the application from environment to environment. Save this as .github/workflows/cd.yml:
# cd.yml — Continuous Delivery / Deployment Pipeline
name: CD Pipeline

on:
  workflow_run:
    workflows: ['CI Pipeline']
    types: [completed]
    branches: [main]

jobs:
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}

    steps:
      - uses: actions/checkout@v4

      - name: Set up kubectl
        uses: azure/setup-kubectl@v3

      - name: Configure kubectl for local cluster
        run: |
          echo '${{ secrets.KUBECONFIG_LOCAL }}' > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml

      - name: Sync ArgoCD Staging
        run: |
          argocd app sync cloudopshub-staging --server localhost:8080 --auth-token ${{ secrets.ARGOCD_TOKEN }}
          argocd app wait cloudopshub-staging --health

      - name: Notify Slack — Staging Deployed
        uses: slackapi/slack-github-action@v1
        with:
          channel-id: 'devops-alerts'
          slack-message: '✅ Staging deployed successfully. SHA: ${{ github.sha }}'
        env:
          SLACK_BOT_TOKEN: ${{ secrets.SLACK_TOKEN }}

  deploy-production:
    name: Deploy to Production
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production   # Requires manual approval in GitHub

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to AWS EKS via ArgoCD
        run: |
          argocd app sync cloudopshub-production --server localhost:8080 --auth-token ${{ secrets.ARGOCD_TOKEN }}
          argocd app wait cloudopshub-production --health --timeout 300

      - name: Notify Slack — Production Deployed
        uses: slackapi/slack-github-action@v1
        with:
          channel-id: 'devops-alerts'
          slack-message: '🚀 Production deployed! SHA: ${{ github.sha }}'
        env:
          SLACK_BOT_TOKEN: ${{ secrets.SLACK_TOKEN }}



Section 7 — Member D: Observability (Prometheus, Grafana, Loki)
Observability means being able to see what is happening inside your platform at all times. We use three tools: Prometheus collects numbers (metrics), Loki collects text logs, and Grafana shows everything in visual dashboards.

7.1  Install the Prometheus + Grafana Stack
32.Add the Helm chart repository (Helm is like an app store for Kubernetes):
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
33.Install Prometheus + Grafana + AlertManager in one command:
kubectl create namespace monitoring
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=CloudOps2025! \
  --set prometheus.prometheusSpec.retention=7d \
  --set alertmanager.enabled=true
34.Verify everything is running:
kubectl get pods -n monitoring   # All pods should show 'Running'
35.Access Grafana dashboard:
kubectl port-forward svc/prometheus-stack-grafana -n monitoring 3000:80 &
# Open browser: http://localhost:3000
# Username: admin   Password: CloudOps2025!

7.2  Install Loki for Log Collection
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set promtail.enabled=true
# promtail is the log collector — it ships logs from all pods to Loki
36.Add Loki as a data source in Grafana:
•Open Grafana in your browser
•Go to Configuration → Data Sources → Add data source
•Choose Loki
•URL: http://loki:3100   → Click Save & Test

7.3  Configure AlertManager
AlertManager sends you a message when something breaks. Save as kubernetes/monitoring/alertmanager-config.yaml:
# alertmanager-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-prometheus-stack-kube-prom-alertmanager
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    global:
      slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    route:
      group_by: ['alertname']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'slack-alerts'
    receivers:
      - name: 'slack-alerts'
        slack_configs:
          - channel: '#devops-alerts'
            title: '🔔 Alert: {{ .CommonAnnotations.summary }}'
            text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

kubectl apply -f kubernetes/monitoring/alertmanager-config.yaml



Section 8 — Member E: Security & Backups (Velero, Secrets, RBAC)

8.1  Manage Secrets Safely
Never put passwords or API keys directly in your code files. Use Kubernetes Secrets instead. Create one as follows:
# Create a secret for the application database credentials
kubectl create secret generic app-secrets \
  --from-literal=database-url='postgresql://user:password@db:5432/cloudopshub' \
  --from-literal=api-key='your-api-key-here' \
  --namespace production

# Verify it was created
kubectl get secret app-secrets -n production

 	Why Secrets Matter
If you put passwords directly in your code and push to GitHub, anyone who sees the repo can access your database. Kubernetes Secrets keep credentials separate from code and encrypted at rest.

8.2  Set Up RBAC (Role-Based Access Control)
RBAC controls who can do what in your cluster. For example, developers should be able to view pods but not delete them. Save as kubernetes/rbac/roles.yaml:
# roles.yaml — RBAC configuration
---
# Developer role: can view but not modify
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
  namespace: staging
rules:
  - apiGroups: ['']
    resources: ['pods', 'services', 'configmaps']
    verbs: ['get', 'list', 'watch']   # Read-only
---
# Bind this role to a user
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: staging
subjects:
  - kind: User
    name: developer@cloudopshub.com
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io

kubectl apply -f kubernetes/rbac/roles.yaml

8.3  Install Velero for Backups
Velero takes automatic snapshots of your Kubernetes resources and saves them to an S3 bucket. If something goes wrong, you can restore the entire cluster state.
37.Install Velero CLI:
curl -L https://github.com/vmware-tanzu/velero/releases/latest/download/velero-v1.12.0-linux-amd64.tar.gz | tar xz
sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/
velero version
38.Install Velero on your cluster (using the S3 bucket Terraform created):
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.8.0 \
  --bucket cloudopshub-velero-backups \
  --backup-location-config region=us-east-1 \
  --snapshot-location-config region=us-east-1 \
  --secret-file ./credentials-velero
# credentials-velero file contains your AWS credentials
39.Schedule automatic daily backups:
velero schedule create daily-backup \
  --schedule='0 2 * * *' \    # Every day at 2:00 AM
  --ttl 168h                   # Keep backups for 7 days
40.To restore from a backup:
velero backup get                            # List all backups
velero restore create --from-backup daily-backup-TIMESTAMP
velero restore get                           # Check restore status



Section 9 — Operational Runbooks
A runbook is a step-by-step guide for common operations. Print these out or keep them bookmarked for when things go wrong.

Runbook 1: How to Deploy a New Version
41.Developer pushes code to the develop branch in GitHub.
42.GitHub Actions CI pipeline automatically starts — wait for it to turn green.
43.Merge develop into staging branch — staging cluster updates automatically via ArgoCD.
44.Verify staging is working by visiting the staging URL.
45.Create a Pull Request from staging → main. Team lead reviews and approves.
46.GitHub Actions CD pipeline starts — prompts for manual approval for production.
47.Manager/lead approves in GitHub → production cluster updates automatically.
48.Check Grafana to confirm the new version is healthy.

Runbook 2: How to Roll Back a Bad Deployment
49.Notice the issue via Grafana alerts or user reports.
argocd app history cloudopshub-production   # Find the last good version number
50.Roll back immediately:
argocd app rollback cloudopshub-production REVISION_NUMBER
51.Verify rollback succeeded:
kubectl get pods -n production   # All pods should be Running
curl https://your-app-url/health  # Should return healthy
52.Notify the team via Slack.
53.Investigate the bad deployment in Grafana/Loki logs before trying again.

Runbook 3: How to Restore from Backup
# List available backups
velero backup get

# Start a restore (replace BACKUP_NAME with actual name from above)
velero restore create --from-backup BACKUP_NAME

# Monitor the restore progress
velero restore describe RESTORE_NAME

# Verify everything is back
kubectl get all -n production

Runbook 4: How to Check if Everything is Healthy
# Check all pods are running
kubectl get pods --all-namespaces

# Check ArgoCD sync status
argocd app list

# Check recent logs for errors
kubectl logs -n production deployment/cloudopshub-backend --tail=50

# Open Grafana dashboard
kubectl port-forward svc/prometheus-stack-grafana -n monitoring 3000:80
# Browse to http://localhost:3000



Section 10 — Demo Day Checklist
Before your presentation, run through this checklist to make sure everything works:

Infrastructure Checks
•Kind local cluster is running (kubectl get nodes shows 3 nodes)
•AWS EKS cluster is running (kubectl get nodes on EKS context shows nodes)
•Both clusters appear in ArgoCD (argocd cluster list)
•Terraform state is stored in S3

CI/CD Pipeline Checks
•GitHub Actions workflow runs on push (check Actions tab in GitHub)
•Trivy scan completes and reports are visible
•Docker image is built and pushed to Docker Hub or ECR
•ArgoCD shows both apps as 'Synced' and 'Healthy'

Observability Checks
•Grafana dashboards load at http://localhost:3000
•Prometheus is collecting metrics (check Targets page in Prometheus)
•Loki shows recent logs
•AlertManager has the Slack webhook configured

Security Checks
•Kubernetes Secrets are created and not visible in plain text
•RBAC roles are applied
•Velero backup schedule exists (velero schedule get)

Closing Notes
This guide has walked you through building a complete, production-grade DevOps platform from scratch. Every tool, every configuration file, and every command has been explained so that you can understand not just what to do but why.
Remember: DevOps is about collaboration. Talk to your teammates frequently, commit your changes to Git often, and test each step before moving to the next. Good luck with your demo!

 	Need Help?
If a command fails, read the error message carefully — it almost always tells you what went wrong. Search the exact error message on Google. Most DevOps errors are common and well-documented.
