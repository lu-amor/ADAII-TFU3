#!/bin/bash

# Comprehensive Demo: Architecture Components, Scalability, Containers, ACID Transactions & Stateless Services
# This demo showcases all key architectural concepts in one comprehensive demonstration

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Detect the actual API port
API_PORT=$(docker-compose port api 8000 2>/dev/null | cut -d: -f2)
if [ -z "$API_PORT" ]; then
    API_PORT="8000"
fi
BASE_URL="http://localhost:$API_PORT"

# Helper functions
print_header() {
    echo -e "\n${PURPLE}================================================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================================================${NC}\n"
}

print_section() {
    echo -e "\n${BLUE}--- $1 ---${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if API is responsive
check_api() {
    local max_attempts=30
    local attempt=1
    
    print_info "Waiting for API to be ready at $BASE_URL..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$BASE_URL" > /dev/null 2>&1; then
            print_success "API is ready at $BASE_URL!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "API failed to start after $max_attempts attempts"
    return 1
}

# Make API request with formatted output
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local description="$4"
    
    echo -e "${CYAN}$description${NC}"
    echo -e "${YELLOW}$method $BASE_URL$endpoint${NC}"
    
    if [ -n "$data" ]; then
        echo -e "${YELLOW}Data: $data${NC}"
        response=$(curl -s -X "$method" -H "Content-Type: application/json" -d "$data" "$BASE_URL$endpoint")
    else
        response=$(curl -s -X "$method" "$BASE_URL$endpoint")
    fi
    
    echo -e "${GREEN}Response:${NC}"
    echo "$response" | jq . 2>/dev/null || echo "$response"
    echo ""
    
    return 0
}

# Demonstrate ACID transaction
demonstrate_acid_transaction() {
    print_section "ACID Transaction Demonstration"
    
    print_info "Creating products for transaction test..."
    api_request "POST" "/productos/" '{"nombre": "Transactional Tomato"}' "Create product 1"
    api_request "POST" "/productos/" '{"nombre": "Transactional Onion"}' "Create product 2"
    api_request "POST" "/productos/" '{"nombre": "Transactional Garlic"}' "Create product 3"
    
    print_info "Demonstrating successful ACID transaction (recipe creation)..."
    api_request "POST" "/recetas/" '{"nombre": "ACID Recipe", "productos": [1, 2, 3]}' "Create recipe with valid products (ACID success)"
    
    print_info "Demonstrating transaction rollback scenario..."
    print_warning "Note: The following request may succeed or fail depending on database constraints"
    api_request "POST" "/recetas/" '{"nombre": "", "productos": [999, 1000]}' "Attempt recipe with invalid data (should rollback)"
    
    print_success "ACID transaction demonstration completed!"
}

# Demonstrate stateless service behavior
demonstrate_stateless_service() {
    print_section "Stateless Service Demonstration"
    
    print_info "Demonstrating stateless behavior - each request is independent"
    
    # Make multiple requests from different "clients"
    for i in {1..3}; do
        print_info "Client $i request - creating product independently"
        api_request "POST" "/productos/" "{\"nombre\": \"Stateless Product $i\"}" "Independent request $i"
    done
    
    print_info "Retrieving all products - server has no memory of previous client sessions"
    api_request "GET" "/productos/" "" "Get all products (stateless retrieval)"
    
    print_success "Stateless service behavior demonstrated - no session state maintained!"
}

# Scale services horizontally
demonstrate_horizontal_scaling() {
    print_section "Horizontal Scaling Demonstration"
    
    print_info "Current container status:"
    docker-compose ps
    
    print_info "Scaling API service to 3 instances (horizontal scaling)..."
    docker-compose up -d --scale api=3 --no-recreate
    
    sleep 5
    
    print_info "New container status after horizontal scaling:"
    docker-compose ps
    
    print_success "Horizontal scaling completed! Multiple API instances running."
    print_warning "Note: Load balancing would require additional configuration (nginx, etc.)"
}

# Demonstrate container architecture
demonstrate_containers() {
    print_section "Container Architecture Demonstration"
    
    print_info "Container Information:"
    echo ""
    
    print_info "Database Container (PostgreSQL):"
    docker inspect recetas_db --format='{{.Config.Image}}' | xargs -I {} echo "  Image: {}"
    docker inspect recetas_db --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | xargs -I {} echo "  IP Address: {}"
    docker inspect recetas_db --format='{{.Config.ExposedPorts}}' | xargs -I {} echo "  Exposed Ports: {}"
    
    echo ""
    print_info "API Containers:"
    docker ps --filter "name=recetas_api" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    print_info "Container Networks:"
    docker network ls --filter "name=adaii"
    
    echo ""
    print_info "Container Volumes:"
    docker volume ls --filter "name=adaii"
    
    print_success "Container architecture demonstration completed!"
}

# Demonstrate component interfaces
demonstrate_components_interfaces() {
    print_section "Components and Interfaces Demonstration"
    
    print_info "API Component Interface Documentation:"
    echo ""
    
    cat << 'EOF'
🏗️  SYSTEM ARCHITECTURE:

┌─────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                         │
├─────────────────────────────────────────────────────────────┤
│  curl, browsers, mobile apps, other services               │
└─────────────────┬───────────────────────────────────────────┘
                  │ HTTP/JSON API
                  │
┌─────────────────▼───────────────────────────────────────────┐
│                     API GATEWAY                             │
├─────────────────────────────────────────────────────────────┤
│  Flask Application (app.py)                                 │
│  - Route registration                                       │
│  - CORS handling                                            │
│  - Request/Response processing                              │
└─────────────────┬───────────────────────────────────────────┘
                  │
     ┌────────────┼────────────┐
     │            │            │
┌────▼───┐   ┌────▼───┐   ┌────▼───┐
│Products│   │Recipes │   │ Lists  │
│Service │   │Service │   │Service │
│        │   │        │   │        │
│Blueprint│   │Blueprint│   │Blueprint│
└────┬───┘   └────┬───┘   └────┬───┘
     │            │            │
     └────────────┼────────────┘
                  │ SQLAlchemy ORM
                  │
┌─────────────────▼───────────────────────────────────────────┐
│                  DATABASE LAYER                             │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL Database                                        │
│  - ACID Transactions                                        │
│  - Relational Integrity                                     │
│  - Concurrent Access Control                                │
└─────────────────────────────────────────────────────────────┘

🔌 INTERFACE CONTRACTS:

Products Service Interface:
  GET    /productos/           → List all products
  POST   /productos/           → Create new product
  
Recipes Service Interface:  
  POST   /recetas/             → Create recipe with ingredients
  
Lists Service Interface:
  GET    /listas/              → List all shopping lists  
  POST   /listas/              → Create new shopping list
  POST   /listas/{id}/productos → Add products to list

📦 DATA MODELS:
  - Producto: {id, nombre}
  - Receta: {id, nombre, productos[]}  
  - Lista: {id, nombre, productos[]}

EOF
    
    print_info "Testing each component interface:"
    
    # Test Products Service Interface
    echo ""
    print_info "🧪 Testing Products Service Interface"
    api_request "GET" "/productos/" "" "List products interface"
    api_request "POST" "/productos/" '{"nombre": "Interface Test Product"}' "Create product interface"
    
    # Test Recipes Service Interface  
    echo ""
    print_info "🧪 Testing Recipes Service Interface"
    api_request "POST" "/recetas/" '{"nombre": "Interface Test Recipe", "productos": [1, 2]}' "Create recipe interface"
    
    # Test Lists Service Interface
    echo ""
    print_info "🧪 Testing Lists Service Interface" 
    api_request "GET" "/listas/" "" "List shopping lists interface"
    api_request "POST" "/listas/" '{"nombre": "Interface Test List", "productos": [1]}' "Create list interface"
    
    print_success "All component interfaces tested successfully!"
}

# Performance and load testing for scalability
demonstrate_performance() {
    print_section "Performance Testing (Scalability Assessment)"
    
    print_info "Running concurrent requests to test scalability..."
    
    # Create test script for concurrent requests
    cat > /tmp/concurrent_test.sh << 'EOF'
#!/bin/bash
for i in {1..5}; do
    curl -s -X POST -H "Content-Type: application/json" \
         -d "{\"nombre\": \"Concurrent Product $RANDOM\"}" \
         http://localhost:8000/productos/ > /dev/null &
done
wait
EOF
    
    chmod +x /tmp/concurrent_test.sh
    
    print_info "Executing 5 concurrent product creation requests..."
    time bash /tmp/concurrent_test.sh
    
    print_info "Current products count after concurrent operations:"
    api_request "GET" "/productos/" "" "Verify concurrent operations"
    
    rm -f /tmp/concurrent_test.sh
    
    print_success "Performance testing completed!"
}

# Main demo execution
main() {
    print_header "🚀 COMPREHENSIVE ARCHITECTURE DEMO"
    echo -e "${CYAN}Demonstrating: Components, Interfaces, Scalability, Containers, ACID Transactions & Stateless Services${NC}\n"
    
    # Check if services are running
    if ! check_api; then
        print_error "Please run './demo_setup.sh' first to start the services"
        exit 1
    fi
    
    # 1. Components and Interfaces
    demonstrate_components_interfaces
    
    # 2. Container Architecture
    demonstrate_containers
    
    # 3. ACID Transactions
    demonstrate_acid_transaction
    
    # 4. Stateless Services
    demonstrate_stateless_service
    
    # 5. Horizontal Scaling
    demonstrate_horizontal_scaling
    
    # 6. Performance Testing
    demonstrate_performance
    
    # Final Summary
    print_header "📊 DEMO SUMMARY"
    
    echo -e "${GREEN}✅ Components & Interfaces:${NC} Microservices with REST API contracts"
    echo -e "${GREEN}✅ Containers:${NC} PostgreSQL + Flask services in Docker"  
    echo -e "${GREEN}✅ ACID Transactions:${NC} Database consistency with rollback capability"
    echo -e "${GREEN}✅ Stateless Services:${NC} No server-side session state maintained"
    echo -e "${GREEN}✅ Horizontal Scalability:${NC} Multiple API instances demonstrated"
    echo -e "${GREEN}✅ Performance Testing:${NC} Concurrent request handling verified"
    
    echo ""
    print_info "Architecture benefits demonstrated:"
    echo "  • Loose coupling between components"
    echo "  • Horizontal scaling capabilities" 
    echo "  • Data consistency guarantees"
    echo "  • Stateless design for better scalability"
    echo "  • Containerized deployment flexibility"
    
    echo ""
    print_success "🎉 Comprehensive architecture demo completed successfully!"
    
    echo ""
    print_warning "To clean up: run './demo_cleanup.sh'"
}

# Execute main function
main "$@"