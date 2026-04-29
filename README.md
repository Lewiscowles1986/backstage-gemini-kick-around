# Backstage Playground

This is a customized Backstage instance with support for external TechDocs, Minio (S3) storage, and Kroki diagrams.

## 🚀 Quick Start (Local Development)

```sh
yarn install
yarn start
```

## 🐳 Docker Usage (recommended)

To start the entire platform with fresh builds:

```sh
docker compose up --build -d
```

To stop the platform and completely clean up (including volumes):

```sh
docker compose down --remove-orphans --volumes
```

| Service | URL |
| :--- | :--- |
| **Backstage** | http://localhost:7007 |
| **Minio (S3) UI** | http://localhost:9001 (minioadmin / minioadmin) |
| **Kroki** | http://localhost:8000 |

## 📚 Documentation Workflow

This project uses an **External TechDocs** model. Documentation is built and "pushed" to S3 storage independently of the Backstage app.

### 1. Build and Publish Docs
Use the dedicated docs-builder container to generate and upload documentation for a repo:

```bash
docker-compose up docs-build-repo-a
```

### 2. Register a New Repo via API
Instead of modifying config files, use the Backstage Catalog API to register your component:

```bash
curl -X POST -H "Content-Type: application/json" \
     -d '{
           "type": "file",
           "target": "/app/sample-repos/your-repo/catalog-info.yaml"
         }' \
     http://localhost:7007/api/catalog/locations
```

### 3. Force a Refresh
If you updated documentation and want to see changes immediately:

```bash
curl -X POST -H "Content-Type: application/json" \
     -d '{ "entityRef": "component:default/repo-a" }' \
     http://localhost:7007/api/catalog/refresh
```

## 🧪 Testing

Run Playwright E2E tests against the running services:

```bash
CI=true npx playwright test
```
