#!/bin/bash

# Advanced Demo Script
# Demonstrates complex scenarios and edge cases

BASE_URL="http://localhost:8000"

echo "🚀 Flask API Advanced Demo"
echo "=========================="
echo ""

# Function to make API calls with error handling
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo "📡 $description"
    echo "   $method $endpoint"
    if [ -n "$data" ]; then
        echo "   Data: $data"
    fi
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X "$method" \
            "$BASE_URL$endpoint")
    fi
    
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo "✅ Success (HTTP $http_code)"
        echo "$body" | jq . 2>/dev/null || echo "$body"
    else
        echo "❌ Error (HTTP $http_code)"
        echo "$body" | jq . 2>/dev/null || echo "$body"
    fi
    echo ""
}

echo "🧪 Scenario 1: Building a complete recipe database"
echo "=================================================="

# Create ingredients for different recipes
ingredients=(
    '{"nombre": "Pasta"}'
    '{"nombre": "Queso parmesano"}'
    '{"nombre": "Huevos"}'
    '{"nombre": "Panceta"}'
    '{"nombre": "Pollo"}'
    '{"nombre": "Arroz"}'
    '{"nombre": "Azafrán"}'
    '{"nombre": "Gambas"}'
    '{"nombre": "Pimientos"}'
    '{"nombre": "Chocolate"}'
    '{"nombre": "Harina"}'
    '{"nombre": "Azúcar"}'
)

echo "Creating ingredients for recipes..."
product_ids=()
for ingredient in "${ingredients[@]}"; do
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$ingredient" \
        "$BASE_URL/productos/")
    
    id=$(echo "$response" | jq -r '.id // empty')
    if [ -n "$id" ]; then
        product_ids+=("$id")
        name=$(echo "$ingredient" | jq -r '.nombre')
        echo "✅ Created: $name (ID: $id)"
    fi
done

echo ""
echo "📋 Current products in database:"
api_call "GET" "/productos/" "" "Listing all products"

# Create multiple recipes
echo "🍝 Creating recipe: Carbonara"
carbonara_ids=$(printf ",%s" "${product_ids[0]}" "${product_ids[1]}" "${product_ids[2]}" "${product_ids[3]}")
carbonara_ids=${carbonara_ids:1}  # Remove leading comma
api_call "POST" "/recetas/" "{\"nombre\": \"Carbonara\", \"productos\": [$carbonara_ids]}" "Creating Carbonara recipe"

echo "🥘 Creating recipe: Paella"
paella_ids=$(printf ",%s" "${product_ids[4]}" "${product_ids[5]}" "${product_ids[6]}" "${product_ids[7]}" "${product_ids[8]}")
paella_ids=${paella_ids:1}
api_call "POST" "/recetas/" "{\"nombre\": \"Paella\", \"productos\": [$paella_ids]}" "Creating Paella recipe"

echo "🍰 Creating recipe: Brownie"
brownie_ids=$(printf ",%s" "${product_ids[9]}" "${product_ids[10]}" "${product_ids[11]}" "${product_ids[2]}")
brownie_ids=${brownie_ids:1}
api_call "POST" "/recetas/" "{\"nombre\": \"Brownie\", \"productos\": [$brownie_ids]}" "Creating Brownie recipe"

echo ""
echo "🧪 Scenario 2: Creating and managing shopping lists"
echo "=================================================="

# Create themed lists
echo "🛒 Creating 'Cena italiana' list"
italian_dinner_ids=$(printf ",%s" "${product_ids[0]}" "${product_ids[1]}" "${product_ids[2]}" "${product_ids[3]}")
italian_dinner_ids=${italian_dinner_ids:1}
italian_response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"nombre\": \"Cena italiana\", \"productos\": [$italian_dinner_ids]}" \
    "$BASE_URL/listas/")
echo "$italian_response" | jq .
italian_list_id=$(echo "$italian_response" | jq -r '.id')

echo ""
echo "🛒 Creating 'Ingredientes repostería' list"
baking_ids=$(printf ",%s" "${product_ids[9]}" "${product_ids[10]}" "${product_ids[11]}")
baking_ids=${baking_ids:1}
api_call "POST" "/listas/" "{\"nombre\": \"Ingredientes repostería\", \"productos\": [$baking_ids]}" "Creating baking ingredients list"

echo ""
echo "📋 Viewing all shopping lists:"
api_call "GET" "/listas/" "" "Getting all shopping lists"

echo ""
echo "🧪 Scenario 3: Testing edge cases and error handling"
echo "=================================================="

echo "🚫 Testing duplicate product creation:"
api_call "POST" "/productos/" '{"nombre": "Pasta"}' "Trying to create duplicate product"

echo "🚫 Testing invalid recipe creation:"
api_call "POST" "/recetas/" '{"nombre": "Invalid Recipe", "productos": [999, 1000]}' "Creating recipe with non-existent products"

echo "🚫 Testing missing data:"
api_call "POST" "/productos/" '{}' "Creating product without name"

echo "🚫 Testing invalid JSON:"
echo "📡 Testing malformed JSON request"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"nombre": "Invalid JSON"' \
    "$BASE_URL/productos/")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
echo "❌ Expected error (HTTP $http_code)"
echo ""

echo "🧪 Scenario 4: Adding products to existing lists"
echo "=============================================="

if [ -n "$italian_list_id" ] && [ "$italian_list_id" != "null" ]; then
    echo "➕ Adding more products to 'Cena italiana' list (ID: $italian_list_id)"
    
    # Note: This endpoint seems to be incomplete in the listas.py file
    # We'll test it anyway to show what should happen
    additional_products=$(printf ",%s" "${product_ids[8]}" "${product_ids[5]}")
    additional_products=${additional_products:1}
    
    echo "📡 Adding products to existing list"
    echo "   POST /listas/$italian_list_id/productos/"
    echo "   Data: {\"productos\": [$additional_products]}"
    
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"productos\": [$additional_products]}" \
        "$BASE_URL/listas/$italian_list_id/productos/")
    
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo "✅ Success (HTTP $http_code)"
        echo "$body" | jq . 2>/dev/null || echo "$body"
    else
        echo "⚠️  Endpoint may be incomplete (HTTP $http_code)"
        echo "$body"
    fi
else
    echo "⚠️  Cannot test adding products - no valid list ID"
fi

echo ""
echo "📊 Final Summary"
echo "==============="

echo "📋 Final product inventory:"
api_call "GET" "/productos/" "" "Final product list"

echo "📋 Final shopping lists:"
api_call "GET" "/listas/" "" "Final shopping lists"

echo ""
echo "🎉 Advanced demo completed!"
echo ""
echo "📝 Summary of what was demonstrated:"
echo "   ✅ Bulk product creation"
echo "   ✅ Multiple recipe creation with different ingredients"
echo "   ✅ Themed shopping list creation"
echo "   ✅ Error handling for edge cases"
echo "   ✅ Database constraint testing (duplicates)"
echo "   ✅ Invalid data handling"
echo "   ⚠️  Adding products to existing lists (endpoint may need completion)"
echo ""
echo "💡 Next steps:"
echo "   - Complete the 'agregar_productos' endpoint in listas.py"
echo "   - Add GET endpoints for individual recipes"
echo "   - Add DELETE endpoints for cleanup operations"
echo "   - Add UPDATE endpoints for modifications"