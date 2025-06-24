# Randie's Conda Base Image (WIP)

A lightweight, public Docker base image for Conda-based Python applications — powered by [Micromamba](https://github.com/mamba-org/micromamba). Published to the GitHub Container Registry (GHCR) for seamless use in any project requiring a Conda environment.

---

## 📦 Image Location

**Public GHCR image**:  
[`ghcr.io/randie/randies-conda-base:latest`](https://github.com/users/randie/packages/container/randies-conda-base)

No authentication required for pull access.

---

## 🔧 Features

- ✅ **Fast environment creation** with Micromamba (compact conda replacement)
- ✅ **Non-root, user-friendly setup** (e.g. `/home/trader`)
- ✅ **Auto-activation of Conda environment**
- ✅ Suitable as a base for:
  - Python CLI tools
  - Data science workloads
  - API services
  - Trading bots or financial modeling apps
- ✅ Clean layer caching for efficient Docker builds

---

## 🐍 Conda Environment

The image includes a default Conda environment defined by [`conda_base.yml`](./conda_base.yml). You can override or extend this environment in your own Dockerfiles.

---

## 🚀 Usage

### Use in your own Dockerfile:

```dockerfile
FROM ghcr.io/randie/randies-conda-base:latest

# Optionally install additional packages
COPY conda_app_lock.yml .
RUN micromamba install -f conda_app_lock.yml

# Copy your app
COPY . /app
WORKDIR /app

ENTRYPOINT ["micromamba", "run", "-n", "randies-env"]
CMD ["python", "main.py"]

