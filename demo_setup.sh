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
until curl -f http://localhost:8000/ > /dev/null 2>&1; do
    echo "Waiting for API to be ready..."
    sleep 5
done

echo "✅ Demo environment is ready!"
echo "📍 API running at: http://localhost:8000"
echo "📍 Database running at: localhost:5432"
echo ""
echo "Run './demo_basic.sh' for a basic demo"
echo "Run './demo_advanced.sh' for an advanced demo"
echo "Run './demo_cleanup.sh' when finished"