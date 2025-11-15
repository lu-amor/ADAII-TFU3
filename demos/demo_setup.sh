#!/bin/bash

# Demo Setup Script
# This script sets up the environment for the Flask API demo

echo "🚀 Setting up Flask API Demo Environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker compose down

# Build and start the services
echo "🔨 Building and starting services..."
docker compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."

# Helper: check URL with timeout
check_url() {
    local url="$1"
    local attempts=20
    local i=0
    while [ $i -lt $attempts ]; do
        if curl -sSf "$url" > /dev/null 2>&1; then
            return 0
        fi
        i=$((i+1))
        sleep 2
    done
    return 1
}

# Prefer gateway if present, else check individual services
API_PORT=$(docker compose port gateway 8000 2>/dev/null | cut -d: -f2 || true)
if [ -n "$API_PORT" ]; then
    API_URL="http://localhost:$API_PORT/"
    echo "Checking gateway at $API_URL"
    if check_url "$API_URL"; then
        echo "✅ Gateway is ready at $API_URL"
    else
        echo "⚠️  Gateway not reachable at $API_URL"
    fi
else
    echo "Gateway not exposed on host; checking services directly"
fi

# Check per-service endpoints as fallback
for svc_port in 8001 8002 8003; do
    svc_url="http://localhost:$svc_port/"
    echo -n "Checking service on $svc_url ... "
    if check_url "$svc_url"; then
        echo "OK"
    else
        echo "no response"
    fi
done

echo "✅ Demo environment checks completed"
echo "Run './demo_comprehensive.sh' to demonstrate deployment and SOAP flows"

echo ""
echo "🧩 Quick microservice notes"
echo "You can start or restart individual services to demonstrate microservice deployment and independent lifecycle. Examples:"
echo "  Start only the productos service:  docker compose up -d productos"
echo "  Start productos + recetas:          docker compose up -d productos recetas"
echo "  Stop a single service:              docker compose stop recetas"

echo "Service endpoints (local):"
echo "  Gateway:  http://localhost:8000"
echo "  Productos: http://localhost:8001 (CRUD)"
echo "  Recetas:   http://localhost:8002 (CRUD + optional SOAP at /soap/recetas)"
echo "  Listas:    http://localhost:8003 (CRUD)"

echo "SOAP endpoint example (gateway):"
echo "  POST to http://localhost:8000/soap/recetas with Content-Type: text/xml"
echo "  Example payload (one-line):"
echo "    <?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><CreateReceta><nombre>Demo SOAP Recipe</nombre><productos><nombre>Manzana</nombre><nombre>Harina</nombre></productos></CreateReceta></soap:Body></soap:Envelope>"

echo "You can also call the recetas service directly on port 8002 at /soap/recetas if you want the service-level SOAP endpoint."