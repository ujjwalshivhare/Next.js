# 🚀 Containerize and Deploy a Next.js Application using Docker, GitHub Actions, and Minikube

## 📘 Overview

This project demonstrates **end-to-end DevOps automation** — from containerizing a modern web application to deploying it on a local Kubernetes cluster. It is designed to showcase practical skills in **Docker**, **GitHub Actions (CI/CD)**, **GitHub Container Registry (GHCR)**, and **Kubernetes (Minikube)**.

---

## 🎯 Objective

The goal of this assessment is to:

* Containerize a **Next.js** application using **Docker best practices**
* Automate the build and image push using **GitHub Actions** and **GHCR**
* Deploy the containerized app to **Minikube (Kubernetes)** using declarative manifests

---

## 🏗️ Tech Stack

| Tool                      | Purpose                                     |
| ------------------------- | ------------------------------------------- |
| **Next.js**               | React-based frontend framework              |
| **Docker**                | Containerization                            |
| **GitHub Actions**        | CI/CD automation pipeline                   |
| **GHCR**                  | GitHub Container Registry for image storage |
| **Kubernetes (Minikube)** | Container orchestration                     |
| **kubectl**               | CLI tool to manage Kubernetes resources     |

---

## 📂 Project Structure

```
nextjs-docker-k8s-assessment/
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions workflow for CI/CD
├── k8s/
│   ├── deployment.yaml         # Kubernetes Deployment manifest
│   └── service.yaml            # Kubernetes Service manifest
├── pages/                      # Next.js app pages
│   ├── index.js
│   └── api/hello.js
├── public/                     # Static assets
├── .dockerignore               # Files to ignore while building Docker image
├── Dockerfile                  # Multi-stage Docker build
├── package.json                # App dependencies and scripts
└── README.md                   # Documentation (this file)
```

---

## ⚙️ Step 1: Create a Simple Next.js App

You can use the Next.js starter template:

```bash
npx create-next-app@latest nextjs-docker-k8s-assessment
```

Or use the minimal example included in this repo (`pages/index.js` & `pages/api/hello.js`).

Run locally to verify:

```bash
npm install
npm run dev
# Visit http://localhost:3000
```

---

## 🐳 Step 2: Containerize with Docker

A multi-stage `Dockerfile` is used for optimal build size and performance:

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
EXPOSE 3000
CMD ["npm", "start"]
```

Build and run locally:

```bash
docker build -t nextjs-app:latest .
docker run -p 3000:3000 nextjs-app:latest
```

Open **[http://localhost:3000](http://localhost:3000)** to verify the container is working.

---

## ⚡ Step 3: Automate CI/CD with GitHub Actions

The GitHub Actions workflow builds the Docker image and pushes it to **GHCR** whenever code is pushed to the `main` branch.

### `.github/workflows/ci.yml`

```yaml
name: CI - Build and Push Docker Image
on:
  push:
    branches: [ main ]
permissions:
  contents: read
  packages: write
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      - name: Log in to GHCR
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          push: true
          tags: |
            ghcr.io/${{ github.repository_owner }}/${{ github.event.repository.name }}:latest
            ghcr.io/${{ github.repository_owner }}/${{ github.event.repository.name }}:${{ github.sha }}
```

✅ **Result:** On every push to `main`, GitHub automatically builds the image and uploads it to `ghcr.io`.

---

## ☸️ Step 4: Kubernetes Deployment on Minikube

The app is deployed using manifests in the `k8s/` directory.

### `k8s/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nextjs-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nextjs-app
  template:
    metadata:
      labels:
        app: nextjs-app
    spec:
      containers:
        - name: nextjs
          image: ghcr.io/YOUR_GH_USER/YOUR_REPO:latest
          ports:
            - containerPort: 3000
          readinessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 5
          livenessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 15
```

### `k8s/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nextjs-svc
spec:
  type: NodePort
  selector:
    app: nextjs-app
  ports:
    - port: 80
      targetPort: 3000
      nodePort: 30080
```

Apply manifests:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Get service URL:

```bash
minikube service nextjs-svc --url
```

Open the displayed URL in your browser to view the deployed app.

---

## 💡 Step 5: Deploy Options

### Option A: Use GHCR Image

If your image is public on GHCR:

```bash
kubectl apply -f k8s/
```

If private, create a pull secret:

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_PAT
```

And reference it in `deployment.yaml`:

```yaml
imagePullSecrets:
  - name: ghcr-secret
```

### Option B: Use Minikube’s Local Docker

```bash
eval $(minikube docker-env)
docker build -t nextjs-local:latest .
kubectl apply -f k8s/
```

Change `imagePullPolicy` to `Never` to use local images.

---

## 🧹 Cleanup

```bash
kubectl delete -f k8s/
minikube stop
```

---

## 📄 Key Learnings

✅ Docker multi-stage builds reduce image size and improve efficiency.
✅ GitHub Actions automate CI/CD pipelines seamlessly with GHCR integration.
✅ Kubernetes manifests provide declarative deployment and scaling.
✅ Minikube enables local testing of production-grade Kubernetes setups.

---

## 🧠 Bonus Enhancements

* Add **Ingress** + TLS for realistic local domain.
* Integrate **Prometheus + Grafana** for monitoring.
* Use **Distroless base image** for better security.
* Configure **resource limits** and **horizontal pod autoscaling (HPA)**.

---

## 👨‍💻 Author

**Ujjwal Shivhare**
DevOps Enthusiast | Docker | Kubernetes | Jenkins | Terraform | AWS | GitHub Actions
[GitHub](https://github.com/ujjwalshivhare) | [LinkedIn](https://www.linkedin.com/in/ujjwal-shivhare)

---

### 🏁 Final Note

This project demonstrates a **complete CI/CD and Kubernetes deployment workflow** suitable for real-world applications and is prepared for **assessment/interview demonstration**.

> "Automation is not just a tool — it's the mindset that drives modern DevOps."

