# OpenShift DevSecOps PoC

A minimal Maven WAR that renders **CI/CD working!**, packaged into Tomcat, with GitHub Actions, Jenkins, Terraform, Ansible, Argo CD, Trivy, Checkov, and an optional Prometheus/Grafana/Alertmanager/Loki/Alloy stack.

## Scope and important limitations

This is a **starter kit, not a verified one-command deployment**. OpenShift is not accessible from the ZIP build environment. You must supply a valid OpenShift kubeconfig, a public/pullable OCI image, Git repository URL, Jenkins agent and registry credentials. Argo CD and monitoring are **not automatically installed**. The GitHub Actions workflow validates Maven and security; Jenkins builds/pushes separately. Checkov is report-only (`--soft-fail`) in CI, while Trivy blocks HIGH/CRITICAL filesystem findings. The Jenkins image scan also blocks HIGH/CRITICAL. Do not mistake the soft-fail Checkov job for a security gate.

## Prerequisites

- OpenShift with `oc` access (OpenShift Local/CRC on Windows + WSL2 is fine).
- `terraform`, `helm`, `git`, `curl`, `mvn` (Java 17), `podman` or Docker, and optional `ansible-playbook`.
- Cluster privileges to create namespaces, quota, and (if used) install operators.
- An accessible OCI registry, e.g. Quay.io. OpenShift pull access must be configured for private images.
- Sufficient resources; observability is heavy for single-node CRC.

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

Use a registry repository that is publicly pullable for the first PoC. The Tomcat base image runs as UID 1001; verify compatibility with your OpenShift SCC. On some clusters the image or pod security settings may need adjustment.

## 3. Terraform + application bootstrap

```bash
export IMAGE="$IMAGE_REPO:v1"
./scripts/bootstrap.sh
./scripts/smoke-test.sh
```

The bootstrap runs Terraform to create three namespaces and quota, then applies manifests with `oc apply -k` **for initial validation only**. Do not keep managing the same app with `oc apply` once Argo CD owns it.

## 4. Ansible (optional)

```bash
terraform -chdir=terraform init
ansible-playbook -i ansible/inventory.ini ansible/site.yml
```

Ansible verifies `oc` authentication and runs Terraform to reconcile base namespaces. Do not run it concurrently with another Terraform apply. The playbook intentionally does not own application deployments.

## 5. GitHub Actions

Push the project to GitHub. `.github/workflows/ci.yml` runs Maven, Checkov and Trivy and uploads `ROOT.war`. GitHub-hosted runners cannot directly reach a private local CRC cluster. This workflow does not require that connectivity. Review pinned action versions and Checkov version before long-term use.

## 6. Jenkins

`jenkins/Jenkinsfile` is a reference pipeline requiring a Jenkins agent labeled `linux-container-build` with Maven, Podman and Trivy installed, and a Jenkins username/password credential named `registry-creds`. Change `IMAGE_REPO`. The job needs Git SCM checkout configuration and a webhook or polling trigger. It does **not** automatically run from GitHub Actions. Buildah can replace Podman if your agent supports it; nested builds inside OpenShift need explicit SCC/agent engineering.

## 7. Argo CD GitOps

Install OpenShift GitOps Operator via OperatorHub first (or use an existing Argo CD). Update `gitops/application.yaml` with your actual public GitHub URL, ensure Argo CD has namespace permissions, then:

```bash
oc apply -f gitops/application.yaml
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
oc -n devsecops-demo get all,route
oc -n devsecops-demo describe deployment tomcat-demo
oc -n devsecops-demo logs deployment/tomcat-demo
oc -n devsecops-demo get events --sort-by=.lastTimestamp
oc -n openshift-gitops get applications
```

Common causes: registry image is private; OpenShift restricted SCC denies writes; insufficient node RAM; missing default StorageClass; GitOps operator absent; invalid Argo CD repository URL; Jenkins has no suitable build agent; chart versions differ from sample values.

## Ownership boundaries

- Terraform: base namespaces and quota.
- Ansible: local orchestration/preflight.
- GitHub Actions: Maven and security checks.
- Jenkins: image build, scan, push.
- Argo CD: desired app state after bootstrap.
- Observability: optional Helm-managed platform components.

## Cleanup

```bash
oc delete -f gitops/application.yaml --ignore-not-found
oc delete -k gitops/base --ignore-not-found
terraform -chdir=terraform destroy -var="kubeconfig=$KUBECONFIG"
```

Cleanup removes namespaces and resources, including data inside those namespaces. Do not run on shared namespaces.
