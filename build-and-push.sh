#!/bin/bash
set -e

# Load registry configuration
if [ -f .env.registry ]; then
    source .env.registry
else
    echo "Error: .env.registry file not found!"
    echo "Please create .env.registry with your registry configuration."
    exit 1
fi

# Validate required variables
if [ -z "$REGISTRY_URL" ] || [ -z "$IMAGE_NAME" ] || [ -z "$IMAGE_TAG" ]; then
    echo "Error: Missing required variables in .env.registry"
    echo "Required: REGISTRY_URL, IMAGE_NAME, IMAGE_TAG"
    exit 1
fi

FULL_IMAGE="${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "================================="
echo "Building and Pushing Docker Image"
echo "================================="
echo "Registry: $REGISTRY_URL"
echo "Image: $IMAGE_NAME"
echo "Tag: $IMAGE_TAG"
echo "Full Image: $FULL_IMAGE"
echo "================================="
echo ""

# Optional: Login to registry if credentials are provided
if [ ! -z "$REGISTRY_USERNAME" ] && [ ! -z "$REGISTRY_PASSWORD" ]; then
    echo "Logging in to registry..."
    echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY_URL" -u "$REGISTRY_USERNAME" --password-stdin
fi

# Build the image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME:$IMAGE_TAG" .

# Tag for registry
echo "Tagging image for registry..."
docker tag "$IMAGE_NAME:$IMAGE_TAG" "$FULL_IMAGE"

# Push to registry
echo "Pushing image to registry..."
docker push "$FULL_IMAGE"

echo ""
echo "================================="
echo "✓ Successfully pushed: $FULL_IMAGE"
echo "================================="
echo ""
echo "Next steps:"
echo "1. Copy docker-compose.prod.yml and .env.registry to your server"
echo "2. On server, update .env.registry with correct REGISTRY_URL"
echo "3. Run: docker-compose -f docker-compose.prod.yml pull"
echo "4. Run: docker-compose -f docker-compose.prod.yml up -d"
echo "5. Configure your server's nginx (see server-configs/nginx-site.conf)"
