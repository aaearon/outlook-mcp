FROM node:20-slim

WORKDIR /app

# Install dependencies first for better layer caching
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy application source
COPY . .

# Token storage persists in /data (mounted as volume)
ENV HOME=/data

EXPOSE 3939

CMD ["npx", "-y", "supergateway", \
    "--stdio", "node index.js", \
    "--outputTransport", "streamableHttp", \
    "--port", "3939", \
    "--healthEndpoint", "/health"]
