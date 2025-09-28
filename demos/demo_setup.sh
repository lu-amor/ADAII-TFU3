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
docker-compose down

# Build and start the services
echo "🔨 Building and starting services..."
docker-compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 15

# Check if API is responding
echo "🔍 Checking API health..."
# Get the actual port that Docker assigned to the API
API_PORT=$(docker-compose port api 8000 2>/dev/null | cut -d: -f2)
if [ -z "$API_PORT" ]; then
    API_PORT="8000"
fi

echo "API running on port: $API_PORT"
until curl -f http://localhost:$API_PORT/ > /dev/null 2>&1; do
    echo "Waiting for API to be ready..."
    sleep 5
done

echo "✅ Demo environment is ready!"
echo "📍 API running at: http://localhost:8000"
echo "📍 Database running at: localhost:5432"
echo ""
echo "🎯 Run './demo_comprehensive.sh' for the complete architecture demo"
echo "🧹 Run './demo_cleanup.sh' when finished"