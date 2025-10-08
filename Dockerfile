# ---- Builder ----
FROM node:18-alpine AS builder
WORKDIR /app


# Install build dependencies and copy package files
COPY package.json package-lock.json* ./
RUN npm ci --silent


# Copy sources and build
COPY . .
RUN npm run build


# ---- Runner ----
FROM node:18-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production


# Copy package files (so `node_modules` more deterministic) and production deps
COPY package.json package-lock.json* ./
RUN npm ci --only=production --silent || true

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/next.config.js ./next.config.js


EXPOSE 3000
CMD ["npm", "start"]
