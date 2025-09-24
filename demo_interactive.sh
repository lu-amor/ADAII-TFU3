#!/bin/bash

# Interactive Demo Script
# Allows manual exploration of the API with guided prompts

BASE_URL="http://localhost:8000"

echo "🎯 Flask API Interactive Demo"
echo "============================="
echo ""

# Function to wait for user input
wait_for_user() {
    echo "Press Enter to continue..."
    read
    echo ""
}

# Function to make API calls with pretty output
demo_api_call() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    
    echo "🔍 $description"
    echo "📡 $method $BASE_URL$endpoint"
    if [ -n "$data" ]; then
        echo "📦 Data: $data"
    fi
    echo ""
    
    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint" | jq . || echo "Response received (not JSON)"
    else
        curl -s -X "$method" \
            "$BASE_URL$endpoint" | jq . || echo "Response received (not JSON)"
    fi
    echo ""
}

echo "Welcome to the interactive Flask API demo!"
echo "This will guide you through testing all endpoints step by step."
echo ""
wait_for_user

echo "Step 1: Testing API Health"
echo "========================="
demo_api_call "GET" "/" "Checking if API is running"
wait_for_user

echo "Step 2: Product Management"
echo "========================="
echo "Let's create some products first..."

demo_api_call "POST" "/productos/" "Creating product: Tomate" '{"nombre": "Tomate"}'
demo_api_call "POST" "/productos/" "Creating product: Cebolla" '{"nombre": "Cebolla"}'
demo_api_call "POST" "/productos/" "Creating product: Ajo" '{"nombre": "Ajo"}'
demo_api_call "POST" "/productos/" "Creating product: Aceite" '{"nombre": "Aceite de oliva"}'

wait_for_user

echo "Now let's see all products:"
demo_api_call "GET" "/productos/" "Listing all products"
wait_for_user

echo "Step 3: Recipe Creation"
echo "======================"
echo "Let's create a recipe using the products we just created..."
echo "Note: Make sure to use the correct product IDs from the previous step!"
echo ""

echo "Example recipe creation (you may need to adjust the IDs):"
demo_api_call "POST" "/recetas/" "Creating Sofrito recipe" '{"nombre": "Sofrito básico", "productos": [1, 2, 3, 4]}'
wait_for_user

echo "Step 4: Shopping List Creation"
echo "============================="
echo "Now let's create a shopping list..."

demo_api_call "POST" "/listas/" "Creating shopping list" '{"nombre": "Lista de la compra", "productos": [1, 2, 3]}'
wait_for_user

echo "Let's view all lists:"
demo_api_call "GET" "/listas/" "Viewing all shopping lists"
wait_for_user

echo "Step 5: Error Testing"
echo "===================="
echo "Let's see what happens when we try to create duplicate products..."

demo_api_call "POST" "/productos/" "Trying to create duplicate Tomate" '{"nombre": "Tomate"}'
wait_for_user

echo "Step 6: Manual Testing Suggestions"
echo "=================================="
echo ""
echo "🚀 You can now test the API manually using these curl commands:"
echo ""
echo "📋 List all products:"
echo "curl -X GET $BASE_URL/productos | jq ."
echo ""
echo "➕ Create a new product:"
echo "curl -X POST -H 'Content-Type: application/json' -d '{\"nombre\": \"Your Product\"}' $BASE_URL/productos | jq ."
echo ""
echo "🍳 Create a recipe:"
echo "curl -X POST -H 'Content-Type: application/json' -d '{\"nombre\": \"Your Recipe\", \"productos\": [1,2,3]}' $BASE_URL/recetas | jq ."
echo ""
echo "🛒 Create a shopping list:"
echo "curl -X POST -H 'Content-Type: application/json' -d '{\"nombre\": \"Your List\", \"productos\": [1,2]}' $BASE_URL/listas | jq ."
echo ""
echo "📋 View all lists:"
echo "curl -X GET $BASE_URL/listas | jq ."
echo ""

echo "🎯 Testing Ideas:"
echo "==============="
echo "Try creating:"
echo "• More products with different names"
echo "• Recipes with many ingredients"
echo "• Empty lists (productos: [])"
echo "• Lists with non-existent product IDs"
echo "• Products with special characters"
echo "• Very long product/recipe names"
echo ""

wait_for_user

echo "✅ Interactive demo completed!"
echo "The API is still running at $BASE_URL"
echo "Use 'docker-compose logs api' to see API logs"
echo "Use './demo_cleanup.sh' when you're done testing"