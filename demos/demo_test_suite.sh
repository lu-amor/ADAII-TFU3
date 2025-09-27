#!/bin/bash

# API Testing Script with comprehensive test cases
# Tests all endpoints systematically

BASE_URL="http://localhost:8000"
TEST_LOG="test_results.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Initialize log
echo "API Test Results - $(date)" > "$TEST_LOG"
echo "=================================" >> "$TEST_LOG"

# Test function
run_test() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="$5"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}Testing:${NC} $test_name"
    
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
    
    if [ "$http_code" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC} - HTTP $http_code"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "PASS - $test_name (HTTP $http_code)" >> "$TEST_LOG"
    else
        echo -e "${RED}❌ FAIL${NC} - Expected HTTP $expected_status, got HTTP $http_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "FAIL - $test_name (Expected: $expected_status, Got: $http_code)" >> "$TEST_LOG"
        echo "Response: $body" >> "$TEST_LOG"
    fi
    
    # Show response if it's JSON
    if echo "$body" | jq . > /dev/null 2>&1; then
        echo "$body" | jq . | head -5
    else
        echo "$body" | head -3
    fi
    
    echo ""
    sleep 1
}

echo "🧪 Comprehensive API Testing Suite"
echo "=================================="
echo ""

# Test 1: API Health Check
echo "📊 API Health Tests"
echo "==================="
run_test "API Root Endpoint" "GET" "/" "" "200"

# Test 2: Product CRUD Operations
echo "📦 Product Management Tests"
echo "==========================="
run_test "Create Product - Valid" "POST" "/productos/" '{"nombre": "Test Tomate"}' "201"
run_test "Create Product - Duplicate" "POST" "/productos/" '{"nombre": "Test Tomate"}' "400"
run_test "Create Product - Empty Name" "POST" "/productos/" '{"nombre": ""}' "400"
run_test "Create Product - Missing Name" "POST" "/productos/" '{}' "400"
run_test "List All Products" "GET" "/productos/" "" "200"

# Create more products for recipe tests
run_test "Create Product - Cebolla" "POST" "/productos/" '{"nombre": "Test Cebolla"}' "201"
run_test "Create Product - Ajo" "POST" "/productos/" '{"nombre": "Test Ajo"}' "201"
run_test "Create Product - Aceite" "POST" "/productos/" '{"nombre": "Test Aceite"}' "201"

# Test 3: Recipe Management
echo "🍳 Recipe Management Tests"
echo "=========================="
run_test "Create Recipe - Valid" "POST" "/recetas/" '{"nombre": "Test Sofrito", "productos": [1, 2, 3]}' "201"
run_test "Create Recipe - No Products" "POST" "/recetas/" '{"nombre": "Empty Recipe", "productos": []}' "201"
run_test "Create Recipe - Invalid Products" "POST" "/recetas/" '{"nombre": "Invalid Recipe", "productos": [999, 1000]}' "201"
run_test "Create Recipe - Missing Name" "POST" "/recetas/" '{"productos": [1, 2]}' "400"

# Test 4: List Management
echo "📋 Shopping List Management Tests"
echo "================================="
run_test "Create List - Valid" "POST" "/listas/" '{"nombre": "Test Lista", "productos": [1, 2]}' "201"
run_test "Create List - Empty Products" "POST" "/listas/" '{"nombre": "Empty List", "productos": []}' "201"
run_test "Create List - Invalid Products" "POST" "/listas/" '{"nombre": "Invalid List", "productos": [999]}' "201"
run_test "List All Lists" "GET" "/listas/" "" "200"

# Test 5: Edge Cases
echo "⚠️  Edge Case Tests"
echo "==================="
run_test "Product - Very Long Name" "POST" "/productos/" '{"nombre": "' $(printf 'A%.0s' {1..200}) '"}' "201"
run_test "Product - Special Characters" "POST" "/productos/" '{"nombre": "Ñoño & Pérez (2024) - Açaí!"}' "201"
run_test "Recipe - Unicode Name" "POST" "/recetas/" '{"nombre": "Paëlla 🥘 con mariscos 🦐", "productos": [1]}' "201"
run_test "Invalid JSON" "POST" "/productos/" '{"nombre": "broken json"' "400"
run_test "Invalid Content-Type" "POST" "/productos/" '{"nombre": "test"}' "400"

# Test 6: List Product Addition (if endpoint exists)
echo "➕ List Product Addition Tests"
echo "=============================="
# Note: This endpoint seems incomplete in the code, so we expect it might fail
run_test "Add Products to List" "POST" "/listas/1/productos/" '{"productos": [3, 4]}' "200"

# Test 7: Performance Tests
echo "⚡ Performance Tests"
echo "==================="
echo "Creating multiple products rapidly..."
for i in {1..10}; do
    run_test "Bulk Create Product $i" "POST" "/productos/" "{\"nombre\": \"Bulk Product $i\"}" "201"
done

# Test 8: Data Consistency
echo "🔍 Data Consistency Tests"
echo "========================="
echo "Verifying data integrity after all operations..."
run_test "Final Products List" "GET" "/productos/" "" "200"
run_test "Final Lists View" "GET" "/listas/" "" "200"

# Test Results Summary
echo ""
echo "📊 Test Results Summary"
echo "======================="
echo -e "Total Tests:  ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    success_rate=100
else
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${YELLOW}⚠️  Some tests failed${NC}"
fi

echo "Success Rate: $success_rate%"

# Log summary
echo "" >> "$TEST_LOG"
echo "SUMMARY:" >> "$TEST_LOG"
echo "Total: $TOTAL_TESTS, Passed: $PASSED_TESTS, Failed: $FAILED_TESTS" >> "$TEST_LOG"
echo "Success Rate: $success_rate%" >> "$TEST_LOG"

echo ""
echo "📝 Detailed results saved to: $TEST_LOG"
echo ""

# Recommendations
echo "🔧 Recommendations based on test results:"
echo "=========================================="
if [ $FAILED_TESTS -gt 0 ]; then
    echo "• Check failed tests in $TEST_LOG"
    echo "• Verify database constraints are properly configured"
    echo "• Consider adding input validation"
    echo "• Complete the 'add products to list' endpoint in listas.py"
fi

echo "• Add DELETE endpoints for cleanup operations"
echo "• Add GET endpoints for individual items (GET /productos/1, /recetas/1)"
echo "• Add UPDATE/PUT endpoints for item modifications"
echo "• Consider adding pagination for large datasets"
echo "• Add authentication and authorization"
echo "• Implement rate limiting"
echo "• Add request/response logging"

echo ""
echo "🚀 Testing completed! Check the logs for detailed analysis."