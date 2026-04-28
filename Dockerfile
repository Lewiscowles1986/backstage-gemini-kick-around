# Stage 1 - Build the app
FROM node:24-bookworm AS build
WORKDIR /app

# Enable Corepack
RUN corepack enable

# Install build dependencies (still needed for some headers)
RUN apt-get update && apt-get install -y python3 python3-dev python-is-python3 g++ build-essential libsqlite3-dev pkg-config libv8-dev cmake

# Some native modules like isolated-vm may need specific compiler flags or headers
ENV CXXFLAGS="-Wno-error=unused-variable"

# Ensure node-gyp uses python3
ENV npm_config_python=python3

# Copy files needed by Yarn
COPY .yarn ./.yarn
COPY .yarnrc.yml ./
COPY package.json yarn.lock backstage.json ./

# Copy workspaces (must include all paths defined in root package.json)
COPY packages ./packages


# Install dependencies
RUN yarn install --immutable || cat /tmp/xfs-*/build.log; exit 1

# Build the app
RUN yarn tsc
RUN yarn build:backend

# Stage 2 - Run the app
FROM node:24
WORKDIR /app

# Install Python and MkDocs for TechDocs
RUN apt-get update && apt-get install -y python3 python3-pip python3-venv libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

# Set up virtualenv for MkDocs
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip
RUN pip install mkdocs-techdocs-core==1.3.1 mkdocs-kroki-plugin

# Copy built backend
COPY --from=build /app/packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz
COPY --from=build /app/packages/backend/dist/bundle.tar.gz ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

# Copy config files
COPY app-config.yaml app-config.production.yaml ./
COPY examples ./examples

# This switches many Node.js dependencies to production mode.
ENV NODE_ENV=production
ENV NODE_OPTIONS="--no-node-snapshot"

CMD ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]
