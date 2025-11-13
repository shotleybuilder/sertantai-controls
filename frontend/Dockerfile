# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Build static site
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy built assets
COPY --from=builder /app/build ./build
COPY package*.json ./

# Install serve utility for static files
RUN npm install -g serve

EXPOSE 3000

# Serve static files
CMD ["serve", "-s", "build", "-l", "3000"]
