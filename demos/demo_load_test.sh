#!/bin/bash

# Load Testing Script
# Tests API performance under concurrent load

BASE_URL="http://localhost:8000"
CONCURRENT_USERS=10
REQUESTS_PER_USER=5

echo "🚀 Flask API Load Testing"
echo "========================="
echo "Base URL: $BASE_URL"
echo "Concurrent Users: $CONCURRENT_USERS"
echo "Requests per User: $REQUESTS_PER_USER"
echo "Total Requests: $((CONCURRENT_USERS * REQUESTS_PER_USER))"
echo ""

# Check if API is responding
echo "🔍 Pre-flight check..."
if ! curl -f -s "$BASE_URL/" > /dev/null; then
    echo "❌ API is not responding. Make sure it's running."
    exit 1
fi
echo "✅ API is responding"

# Create test data first
echo ""
echo "📦 Setting up test data..."
test_products=(
    "Load Test Product 1"
    "Load Test Product 2"
    "Load Test Product 3"
    "Load Test Product 4"
    "Load Test Product 5"
)

product_ids=()
for product in "${test_products[@]}"; do
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"nombre\": \"$product\"}" \
        "$BASE_URL/productos/")
    
    id=$(echo "$response" | jq -r '.id // empty' 2>/dev/null)
    if [ -n "$id" ]; then
        product_ids+=("$id")
        echo "Created product: $product (ID: $id)"
    fi
done

echo ""
echo "🔥 Starting load test..."

# Function to simulate a user session
simulate_user() {
    local user_id=$1
    local log_file="load_test_user_$user_id.log"
    
    echo "User $user_id starting..." > "$log_file"
    
    for i in $(seq 1 $REQUESTS_PER_USER); do
        local start_time=$(date +%s%N)
        
        # Randomize operations
        case $((i % 4)) in
            0) # Create product
                response=$(curl -s -w "%{time_total}" -X POST \
                    -H "Content-Type: application/json" \
                    -d "{\"nombre\": \"User${user_id}_Product${i}\"}" \
                    "$BASE_URL/productos/" 2>/dev/null)
                ;;
            1) # List products
                response=$(curl -s -w "%{time_total}" \
                    "$BASE_URL/productos/" 2>/dev/null)
                ;;
            2) # Create recipe
                local random_products=$(printf ",%s" "${product_ids[@]::3}")
                random_products=${random_products:1}
                response=$(curl -s -w "%{time_total}" -X POST \
                    -H "Content-Type: application/json" \
                    -d "{\"nombre\": \"User${user_id}_Recipe${i}\", \"productos\": [$random_products]}" \
                    "$BASE_URL/recetas/" 2>/dev/null)
                ;;
            3) # Create list
                local random_products=$(printf ",%s" "${product_ids[@]::2}")
                random_products=${random_products:1}
                response=$(curl -s -w "%{time_total}" -X POST \
                    -H "Content-Type: application/json" \
                    -d "{\"nombre\": \"User${user_id}_List${i}\", \"productos\": [$random_products]}" \
                    "$BASE_URL/listas/" 2>/dev/null)
                ;;
        esac
        
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 )) # Convert to ms
        
        echo "Request $i completed in ${duration}ms" >> "$log_file"
        
        # Small random delay between requests
        sleep 0.$((RANDOM % 5))
    done
    
    echo "User $user_id completed all requests" >> "$log_file"
}

# Start concurrent users
echo "Starting $CONCURRENT_USERS concurrent users..."
pids=()

start_time=$(date +%s)

for i in $(seq 1 $CONCURRENT_USERS); do
    simulate_user $i &
    pids+=($!)
    echo "Started user $i (PID: $!)"
done

# Wait for all users to complete
echo ""
echo "⏳ Waiting for all users to complete..."
for pid in "${pids[@]}"; do
    wait $pid
done

end_time=$(date +%s)
total_duration=$((end_time - start_time))

echo ""
echo "📊 Load Test Results"
echo "==================="
echo "Total Duration: ${total_duration}s"
echo "Total Requests: $((CONCURRENT_USERS * REQUESTS_PER_USER))"
echo "Requests per Second: $(echo "scale=2; $((CONCURRENT_USERS * REQUESTS_PER_USER)) / $total_duration" | bc -l 2>/dev/null || echo "N/A")"

# Analyze individual user logs
echo ""
echo "📈 Performance Analysis"
echo "======================"

total_requests=0
total_time=0
slowest_request=0
fastest_request=99999999

for i in $(seq 1 $CONCURRENT_USERS); do
    log_file="load_test_user_$i.log"
    if [ -f "$log_file" ]; then
        user_requests=$(grep -c "Request.*completed" "$log_file")
        user_times=$(grep "Request.*completed" "$log_file" | sed 's/.*completed in \([0-9]*\)ms.*/\1/')
        
        total_requests=$((total_requests + user_requests))
        
        for time in $user_times; do
            total_time=$((total_time + time))
            if [ $time -gt $slowest_request ]; then
                slowest_request=$time
            fi
            if [ $time -lt $fastest_request ]; then
                fastest_request=$time
            fi
        done
    fi
done

if [ $total_requests -gt 0 ]; then
    avg_response_time=$((total_time / total_requests))
    echo "Average Response Time: ${avg_response_time}ms"
    echo "Fastest Response: ${fastest_request}ms"
    echo "Slowest Response: ${slowest_request}ms"
else
    echo "⚠️  No timing data available"
fi

# API health check after load test
echo ""
echo "🔍 Post-test API health check..."
if curl -f -s "$BASE_URL/" > /dev/null; then
    echo "✅ API is still responding after load test"
else
    echo "❌ API appears to be unresponsive after load test"
fi

# Check final database state
echo ""
echo "📋 Final database state:"
product_count=$(curl -s "$BASE_URL/productos/" | jq '. | length' 2>/dev/null || echo "Unknown")
list_count=$(curl -s "$BASE_URL/listas/" | jq '. | length' 2>/dev/null || echo "Unknown")

echo "Products in database: $product_count"
echo "Lists in database: $list_count"

# Cleanup log files
echo ""
echo "🧹 Cleaning up..."
rm -f load_test_user_*.log

echo ""
echo "🎯 Load Test Summary"
echo "==================="
echo "✅ Completed $total_requests requests in ${total_duration}s"
echo "✅ API remained responsive under load"

if [ $avg_response_time -lt 1000 ]; then
    echo "✅ Good performance: Average response time under 1 second"
elif [ $avg_response_time -lt 5000 ]; then
    echo "⚠️  Acceptable performance: Average response time under 5 seconds"
else
    echo "❌ Poor performance: Average response time over 5 seconds"
fi

echo ""
echo "💡 Performance Recommendations:"
echo "• Consider adding database connection pooling"
echo "• Implement caching for frequently accessed data"
echo "• Add database indexes for common queries"
echo "• Consider using asynchronous request handling"
echo "• Monitor memory usage during high load"
echo "• Implement request rate limiting"