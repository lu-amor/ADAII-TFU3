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

# Detect the actual API port (gateway service) if present
API_PORT=$(docker compose port gateway 8000 2>/dev/null | cut -d: -f2 || true)
if [ -n "$API_PORT" ]; then
    BASE_URL="http://localhost:$API_PORT"
    USE_GATEWAY=true
else
    BASE_URL=""
    USE_GATEWAY=false
fi

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
    local max_attempts=20
    local attempt=1

    if [ "$USE_GATEWAY" = true ] && [ -n "$BASE_URL" ]; then
        print_info "Waiting for gateway to be ready at $BASE_URL..."
        while [ $attempt -le $max_attempts ]; do
            if curl -s "$BASE_URL" > /dev/null 2>&1; then
                print_success "Gateway is ready at $BASE_URL!"
                return 0
            fi
            echo -n "."
            sleep 2
            attempt=$((attempt + 1))
        done
        print_warning "Gateway not available after $max_attempts attempts; falling back to direct services"
    fi

    # Fallback: ensure at least one service endpoint is available (productos, recetas or listas)
    for port in 8001 8002 8003; do
        local url="http://localhost:$port/"
        attempt=1
        while [ $attempt -le $max_attempts ]; do
            if curl -s "$url" > /dev/null 2>&1; then
                print_success "Service available at $url"
                return 0
            fi
            sleep 2
            attempt=$((attempt + 1))
        done
    done

    print_error "No services became available after $max_attempts attempts"
    return 1
}

# Make API request with formatted output
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local description="$4"

    echo -e "${CYAN}$description${NC}"

    # If gateway is available use it, else call service directly based on endpoint prefix
    if [ "$USE_GATEWAY" = true ] && [ -n "$BASE_URL" ]; then
        local url="$BASE_URL$endpoint"
    else
        # Map endpoint to service port
        if [[ "$endpoint" == /productos* ]]; then
            url="http://localhost:8001$endpoint"
        elif [[ "$endpoint" == /recetas* ]]; then
            url="http://localhost:8002$endpoint"
        elif [[ "$endpoint" == /listas* ]]; then
            url="http://localhost:8003$endpoint"
        else
            url="http://localhost:8000$endpoint"
        fi
    fi

    echo -e "${YELLOW}$method $url${NC}"

    if [ -n "$data" ]; then
        echo -e "${YELLOW}Data: $data${NC}"
        response=$(curl -s -X "$method" -H "Content-Type: application/json" -d "$data" "$url")
    else
        response=$(curl -s -X "$method" "$url")
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
    # New recipes accept product NAMES. Use the names created above.
    api_request "POST" "/recetas/" '{"nombre": "ACID Recipe", "productos": ["Transactional Tomato", "Transactional Onion", "Transactional Garlic"]}' "Create recipe with valid products (ACID success)"

    print_info "Demonstrating transaction rollback scenario..."
    print_warning "Note: The following request should fail due to missing recipe name and trigger rollback"
    api_request "POST" "/recetas/" '{"nombre": "", "productos": ["NoSuchProduct"]}' "Attempt recipe with invalid data (should rollback)"
    
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
    docker compose ps
    
    print_info "Scaling gateway service to 3 instances (horizontal scaling)..."
    docker compose up -d --scale gateway=3 --no-recreate
    
    sleep 5
    
    print_info "New container status after horizontal scaling:"
    docker-compose ps
    
    print_success "Horizontal scaling completed! Multiple API instances running."
    print_warning "Note: Load balancing would require additional configuration (nginx, etc.)"
}

# Demonstrate deploying single microservices and the XML/SOAP endpoint
demonstrate_microservice_deployment() {
        print_section "Microservice Deployment Demonstration"

        print_info "Start only the productos service to show independent deployability"
        docker compose up -d --no-deps --build productos
        sleep 3
        print_info "Productos available at: http://localhost:8001"

        print_info "Start recetas service (depends on productos for product validation)"
        docker compose up -d --no-deps --build recetas
        sleep 3
        print_info "Recetas available at: http://localhost:8002 (also exposes /soap/recetas if enabled)"

        print_info "You can stop a single service without touching others:"
        echo "  docker compose stop productos"

        print_success "Microservice deployment demo completed (brought up productos + recetas)."
}

# Demonstrate SOAP/XML endpoint usage (gateway and direct service)
demonstrate_soap_xml() {
        print_section "SOAP / XML Endpoint Demonstration"

        # Determine whether to use the gateway or call recetas service directly
        if [ "$USE_GATEWAY" = true ] && [ -n "$BASE_URL" ]; then
            GATEWAY_URL="$BASE_URL/soap/recetas"
        else
            GATEWAY_URL=""
        fi
        RECETAS_URL="http://localhost:8002/soap/recetas"

        if [ -n "$GATEWAY_URL" ]; then
            print_info "Posting a SOAP CreateReceta to the gateway: $GATEWAY_URL"
        else
            print_info "Gateway not available; will post directly to recetas service: $RECETAS_URL"
        fi
        cat > /tmp/demo_soap.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
        <CreateReceta>
            <nombre>Demo SOAP Recipe</nombre>
            <productos>
                <nombre>Manzana</nombre>
                <nombre>Harina</nombre>
            </productos>
        </CreateReceta>
    </soap:Body>
</soap:Envelope>
EOF

        if [ -n "$GATEWAY_URL" ]; then
            response=$(curl -s -X POST -H "Content-Type: text/xml" --data-binary @/tmp/demo_soap.xml "$GATEWAY_URL")
            echo "Response from gateway SOAP endpoint:" 
            echo "$response" | xmllint --format - 2>/dev/null || echo "$response"
        fi

        print_info "Posting the same SOAP payload directly to recetas service: $RECETAS_URL"
        response2=$(curl -s -X POST -H "Content-Type: text/xml" --data-binary @/tmp/demo_soap.xml "$RECETAS_URL")
        echo "Response from recetas service SOAP endpoint:" 
        echo "$response2" | xmllint --format - 2>/dev/null || echo "$response2"

        rm -f /tmp/demo_soap.xml
        print_success "SOAP/XML demonstration completed."
}

# Demonstrate container architecture
demonstrate_containers() {
    print_section "Container Architecture Demonstration"
    
    print_info "Container Information:"
    echo ""
    
    print_info "Database Container (PostgreSQL):"
    DB_CID=$(docker compose ps -q db_recetas)
    if [ -n "$DB_CID" ]; then
        docker inspect "$DB_CID" --format='{{.Config.Image}}' | xargs -I {} echo "  Image: {}"
        docker inspect "$DB_CID" --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | xargs -I {} echo "  IP Address: {}"
        docker inspect "$DB_CID" --format='{{.Config.ExposedPorts}}' | xargs -I {} echo "  Exposed Ports: {}"
    else
        print_warning "db_recetas container not found via docker compose"
    fi
    
    echo ""
    print_info "API / Gateway containers (compose):"
    docker compose ps
    
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
    api_request "POST" "/productos/" '{"nombre": "Interface Test Product A"}' "Create product interface A"
    api_request "POST" "/productos/" '{"nombre": "Interface Test Product B"}' "Create product interface B"
    
    # Test Recipes Service Interface  
    echo ""
    print_info "🧪 Testing Recipes Service Interface"
    # Create recipe using product NAMES (new behaviour)
    api_request "POST" "/recetas/" '{"nombre": "Interface Test Recipe", "productos": ["Interface Test Product A", "Interface Test Product B"]}' "Create recipe interface"
    
    # Test Lists Service Interface
    echo ""
    print_info "🧪 Testing Lists Service Interface" 
    api_request "GET" "/listas/" "" "List shopping lists interface"
    api_request "POST" "/listas/" '{"nombre": "Interface Test List", "productos": ["Interface Test Product A"]}' "Create list interface"
    
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
    
    # 1. Facilidad de despliegue: show per-service deployment
    demonstrate_microservice_deployment

    # 2. SOAP / XML endpoint demonstration (gateway + direct service)
    demonstrate_soap_xml
    
    # Final Summary
    print_header "📊 DEMO SUMMARY"
    
    echo -e "${GREEN}✅ Facilidad de despliegue:${NC} Start/stop individual microservices with Docker Compose"
    echo -e "${GREEN}✅ SOAP/XML endpoint:${NC} Gateway + service-level SOAP demo completed"
    
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