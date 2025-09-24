#!/bin/bash

# Basic Demo Script
# Demonstrates basic CRUD operations for the Flask API

BASE_URL="http://localhost:8000"

echo "🎯 Flask API Basic Demo"
echo "======================="
echo ""

# Test API connection
echo "1️⃣  Testing API connection..."
response=$(curl -s -w "%{http_code}" -o /tmp/response.json "$BASE_URL/")
if [ "$response" = "200" ]; then
    echo "✅ API is responding"
    cat /tmp/response.json | jq .
else
    echo "❌ API is not responding (HTTP $response)"
    exit 1
fi

echo ""
echo "2️⃣  Creating sample products..."

# Create products
products=(
    '{"nombre": "Tomate"}'
    '{"nombre": "Cebolla"}'
    '{"nombre": "Ajo"}'
    '{"nombre": "Aceite de oliva"}'
    '{"nombre": "Sal"}'
    '{"nombre": "Pimienta"}'
)

product_ids=()
for product in "${products[@]}"; do
    echo "Creating product: $product"
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$product" \
        "$BASE_URL/productos/")
    echo "$response" | jq .
    
    # Extract product ID
    id=$(echo "$response" | jq -r '.id')
    if [ "$id" != "null" ]; then
        product_ids+=("$id")
    fi
    sleep 1
done

echo ""
echo "3️⃣  Listing all products..."
curl -s "$BASE_URL/productos/" | jq .

echo ""
echo "4️⃣  Creating a recipe..."
recipe_data="{\"nombre\": \"Sofrito básico\", \"productos\": [${product_ids[0]}, ${product_ids[1]}, ${product_ids[2]}, ${product_ids[3]}]}"
echo "Creating recipe with data: $recipe_data"
recipe_response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$recipe_data" \
    "$BASE_URL/recetas/")
echo "$recipe_response" | jq .

echo ""
echo "5️⃣  Creating a shopping list..."
list_data="{\"nombre\": \"Lista de la compra\", \"productos\": [${product_ids[0]}, ${product_ids[1]}, ${product_ids[4]}, ${product_ids[5]}]}"
echo "Creating list with data: $list_data"
list_response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$list_data" \
    "$BASE_URL/listas/")
echo "$list_response" | jq .

echo ""
echo "6️⃣  Viewing all lists..."
curl -s "$BASE_URL/listas/" | jq .

echo ""
echo "✅ Basic demo completed!"
echo "💡 Check the API endpoints manually at:"
echo "   - GET  $BASE_URL/productos/"
echo "   - POST $BASE_URL/productos/"
echo "   - POST $BASE_URL/recetas/"
echo "   - GET  $BASE_URL/listas/"
echo "   - POST $BASE_URL/listas/"