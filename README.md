# Kubernetes DevSecOps PoC

A minimal Maven WAR that renders **CI/CD working!**, packaged into Tomcat, with GitHub Actions, Jenkins, Terraform, Ansible, Argo CD, Trivy, Checkov, and an optional Prometheus/Grafana/Alertmanager/Loki/Alloy stack.

## Scope and important limitations

This is a **starter kit, not a verified one-command deployment**. You must supply a valid Kubernetes kubeconfig, a public/pullable OCI image, Git repository URL, Jenkins agent and registry credentials. Argo CD and monitoring are **not automatically installed**. The GitHub Actions workflow validates Maven and security; Jenkins builds/pushes separately. Checkov is report-only (`--soft-fail`) in CI, while Trivy blocks HIGH/CRITICAL filesystem findings. The Jenkins image scan also blocks HIGH/CRITICAL. Do not mistake the soft-fail Checkov job for a security gate.

## Prerequisites

- A Kubernetes cluster with `kubectl` access (for example kind, minikube or Docker Desktop Kubernetes). Run the Bash scripts from WSL2/Linux with tools and kubeconfig available in that environment.
- `terraform`, `helm`, `git`, `curl`, `python3`, `mvn` (Java 17), `podman` or Docker, and optional `ansible-playbook`.
- Cluster privileges to create namespaces, quota, and (if used) install Argo CD or monitoring CRDs.
- An accessible OCI registry, e.g. Quay.io. Kubernetes imagePullSecrets must be configured for private images.
- Sufficient resources; observability is heavy for small local clusters.

## 1. Check cluster and build WAR

```bash
export KUBECONFIG="$HOME/.kube/config" # absolute path in WSL2
./scripts/preflight.sh
mvn -B -f app/pom.xml clean package
```

## 2. Build and push an image

```bash
export IMAGE_REPO=quay.io/YOUR_ACCOUNT/devsecops-poc
podman build -t "$IMAGE_REPO:v1" .
podman login quay.io
podman push "$IMAGE_REPO:v1"
```

Use a registry repository that is publicly pullable for the first PoC. The application image and Deployment run as UID/GID 1001, with writable Tomcat runtime directories. The base manifests use only standard Kubernetes APIs.

## 3. Terraform + application bootstrap

```bash
export IMAGE="$IMAGE_REPO:v1"
./scripts/bootstrap.sh
kubectl -n devsecops-demo port-forward service/tomcat-demo 8080:8080
# In a second terminal with the same kubeconfig:
./scripts/smoke-test.sh
```

The bootstrap runs Terraform to create three namespaces and quota, then applies manifests with `kubectl apply -k` **for initial validation only**. Do not keep managing the same app with `kubectl apply` once Argo CD owns it.

Open http://127.0.0.1:8080 while port-forward is running. The base Service is ClusterIP; no ingress controller is required for local access.

For optional external access, edit `gitops/ingress/ingress.yaml`: set your DNS host and `spec.ingressClassName` to your installed controller's class (or use its default class). Configure DNS to reach the controller, then apply:

```bash
kubectl apply -k gitops/ingress
APP_URL=http://tomcat.local ./scripts/smoke-test.sh
```

An [Ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress/) must be installed separately. HTTPS requires a TLS secret and `spec.tls`; there is no automatic edge TLS termination. If Argo CD should own the Ingress, set its application source path to `gitops/ingress` instead of `gitops/base`.

The standalone examples in `oc-poc/` retain their existing paths for compatibility and now contain standard Kubernetes Deployment and Service resources. Their stock Tomcat image does not include the demo WAR; use the main GitOps deployment for the application and smoke test.

## 4. Ansible (optional)

```bash
terraform -chdir=terraform init
ansible-playbook -i ansible/inventory.ini ansible/site.yml
```

Ansible verifies Kubernetes connectivity and runs Terraform to reconcile base namespaces. Do not run it concurrently with another Terraform apply. The playbook intentionally does not own application deployments.

## 5. GitHub Actions

Push the project to GitHub. `.github/workflows/ci.yml` runs Maven, Checkov and Trivy and uploads `ROOT.war`. GitHub-hosted runners cannot directly reach a private local Kubernetes cluster. This workflow does not require that connectivity. Review pinned action versions and Checkov version before long-term use.

## 6. Jenkins

`jenkins/Jenkinsfile` is a reference pipeline requiring a Jenkins agent labeled `linux-container-build` with Maven, Podman and Trivy installed, and a Jenkins username/password credential named `registry-creds`. Change `IMAGE_REPO`. The job needs Git SCM checkout configuration and a webhook or polling trigger. It does **not** automatically run from GitHub Actions. Buildah can replace Podman if your agent supports it; nested builds inside Kubernetes need suitable agent permissions and container runtime configuration.

## 7. Argo CD GitOps

Install Argo CD in the `argocd` namespace first (or use an existing installation and adjust `metadata.namespace`). Update `gitops/application.yaml` with your actual public GitHub URL, ensure Argo CD has namespace permissions, then:

```bash
kubectl apply -f gitops/application.yaml
```

After pushing a new image, update the manifest **by digest**, commit and push:

```bash
export IMAGE='quay.io/YOUR_ACCOUNT/devsecops-poc@sha256:YOUR_REAL_DIGEST'
./scripts/update-gitops.sh
git add gitops/base/deployment.yaml
git commit -m 'chore(gitops): deploy new image'
git push
```

The update step is deliberately manual to avoid distributing a misleading pipeline with unconfigured Git write credentials. Argo CD detects the Git change and reconciles the Deployment. Do not push placeholder image or repository values.

## 8. Observability

See [observability/README.md](observability/README.md). Includes sample Helm values for Prometheus, Grafana, Alertmanager, Loki and Alloy, and an alert rule. **These are optional integration examples, not a tested, automatically provisioned full stack.** The app has no JMX exporter, so JVM-specific metrics are not yet available.

## Troubleshooting

```bash
kubectl -n devsecops-demo get all,ingress
kubectl -n devsecops-demo describe deployment tomcat-demo
kubectl -n devsecops-demo logs deployment/tomcat-demo
kubectl -n devsecops-demo get events --sort-by=.lastTimestamp
kubectl -n argocd get applications
```

Common causes: registry image is private; Pod Security policies deny the workload; insufficient node RAM; missing default StorageClass; Argo CD absent; invalid Argo CD repository URL; Jenkins has no suitable build agent; chart versions differ from sample values.

## Ownership boundaries

- Terraform: base namespaces and quota.
- Ansible: local orchestration/preflight.
- GitHub Actions: Maven and security checks.
- Jenkins: image build, scan, push.
- Argo CD: desired app state after bootstrap.
- Observability: optional Helm-managed platform components.

## Cleanup

```bash
kubectl delete -f gitops/application.yaml --ignore-not-found
kubectl -n devsecops-demo delete ingress tomcat-demo --ignore-not-found
kubectl delete -k gitops/base --ignore-not-found
terraform -chdir=terraform destroy -var="kubeconfig=$KUBECONFIG"
```

Cleanup removes namespaces and resources, including data inside those namespaces. Do not run on shared namespaces.
