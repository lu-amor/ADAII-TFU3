#!/bin/bash

# Demo Cleanup Script
# Stops containers and cleans up demo artifacts

echo "🧹 Cleaning up Flask API Demo"
echo "=============================="

# Stop and remove containers
echo "🛑 Stopping Docker containers..."
docker-compose down

# Remove any demo-created files
echo "📁 Cleaning up demo files..."
if [ -f "test_results.log" ]; then
    rm test_results.log
    echo "Removed test_results.log"
fi

# Remove any leftover log files
rm -f load_test_user_*.log 2>/dev/null

# Optional: Remove Docker volumes (uncomment if you want to reset database)
read -p "🗑️  Do you want to remove the database volume? This will delete all data (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose down -v
    echo "✅ Database volume removed"
else
    echo "ℹ️  Database volume preserved"
fi

# Optional: Remove Docker images (uncomment if you want to clean everything)
read -p "🗑️  Do you want to remove the built Docker images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rmi $(docker images "adaii-tfu3*" -q) 2>/dev/null
    echo "✅ Docker images removed"
else
    echo "ℹ️  Docker images preserved"
fi

echo ""
echo "✅ Cleanup completed!"
echo ""
echo "💡 To restart the demo:"
echo "   ./demo_setup.sh"