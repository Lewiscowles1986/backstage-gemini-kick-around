# Stage 1 - Build the app
FROM node:24-bookworm AS build
WORKDIR /app

# Enable Corepack
RUN corepack enable

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-dev \
    python-is-python3 \
    g++ \
    build-essential \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Ensure node-gyp uses python3
ENV npm_config_python=python3
ENV PYTHON=python3

# Some native modules like isolated-vm may need specific compiler flags or headers
ENV CXXFLAGS="-Wno-error=unused-variable"

# Copy files needed by Yarn
COPY .yarn ./.yarn
COPY .yarnrc.yml ./
COPY package.json yarn.lock backstage.json tsconfig.json ./

# Copy workspaces
COPY packages ./packages

# Install dependencies
RUN yarn install --immutable

# Build the app
RUN yarn tsc
RUN yarn build:backend

# Stage 2 - Production dependencies
FROM node:24-bookworm-slim AS deps
WORKDIR /app
RUN corepack enable

COPY .yarn ./.yarn
COPY .yarnrc.yml ./
COPY package.json yarn.lock backstage.json ./
COPY packages/backend/package.json ./packages/backend/package.json
COPY packages/app/package.json ./packages/app/package.json

# Install production dependencies only
RUN yarn workspaces focus backend --production

# Stage 3 - Run the app
FROM node:24-bookworm-slim
WORKDIR /app

# Install Python, MkDocs for TechDocs, and curl for health checks
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    libsqlite3-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set up virtualenv for MkDocs
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip
RUN pip install mkdocs-techdocs-core==1.3.1 mkdocs-kroki-plugin

# Copy production node_modules (hoisted to root)
COPY --from=deps /app/node_modules ./node_modules
# packages/backend/node_modules might not exist if everything is hoisted, 
# but we can copy the whole packages dir if needed or just skip it if not present.
# For Backstage, most things are hoisted to the root.

# Copy built backend
COPY --from=build /app/packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz
COPY --from=build /app/packages/backend/dist/bundle.tar.gz ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

# Copy config files
COPY app-config.yaml app-config.production.yaml ./

# This switches many Node.js dependencies to production mode.
ENV NODE_ENV=production
ENV NODE_OPTIONS="--no-node-snapshot"

CMD ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]
