# Comprehensive Architecture Demo

This project demonstrates key software architecture concepts through a practical Flask API implementation.

## 🎯 Architecture Concepts Demonstrated

### 🏗️ **Components and Interfaces**
- **Microservices Architecture**: Separate service components for products, recipes, and shopping lists
- **REST API Interfaces**: Well-defined HTTP endpoints with JSON contracts
- **Service Separation**: Clear boundaries between business logic components
- **Interface Documentation**: Detailed API contracts and data models

### � **Containers**
- **Docker Containerization**: PostgreSQL database and Flask API in separate containers
- **Container Orchestration**: Docker Compose for multi-container deployment
- **Service Discovery**: Internal container networking and communication
- **Environment Configuration**: Container-specific environment variables

### ⚡ **Scalability**
- **Horizontal Scaling**: Multiple API instance deployment capability
- **Stateless Design**: No server-side session state for better scalability
- **Database Connection Pooling**: Efficient resource utilization
- **Performance Testing**: Concurrent request handling validation

### 🔒 **ACID Transactions**
- **Atomicity**: All-or-nothing transaction execution
- **Consistency**: Database constraint enforcement
- **Isolation**: Concurrent transaction handling
- **Durability**: Persistent data storage with rollback capability

### 🌐 **Stateless Services**
- **No Session State**: Each request processed independently
- **Horizontal Scaling Ready**: No server affinity requirements
- **Load Balancer Friendly**: Requests can be distributed to any instance
- **Independent Request Processing**: No memory of previous client interactions

## 🚀 Quick Start

1. **Setup Environment:**
   ```bash
   chmod +x demos/*.sh
   ./demos/demo_setup.sh
   ```

2. **Run Comprehensive Demo:**
   ```bash
   ./demos/demo_comprehensive.sh
   ```

3. **Cleanup:**
   ```bash
   ./demos/demo_cleanup.sh
   ```

## 📊 API Endpoints

| Method | Endpoint | Description | Architecture Concept |
|--------|----------|-------------|---------------------|
| GET | `/` | Health check | Stateless service |
| GET | `/productos/` | List all products | Component interface |
| POST | `/productos/` | Create product | ACID transaction |
| GET | `/productos/{id}` | Get specific product | Stateless operation |
| GET | `/recetas/` | List all recipes | Component interface |
| POST | `/recetas/` | Create recipe | ACID transaction |
| GET | `/listas/` | List shopping lists | Component interface |
| POST | `/listas/` | Create shopping list | ACID transaction |
| POST | `/listas/{id}/productos` | Add products to list | ACID transaction |

## 🔧 Technology Stack

- **Backend**: Flask (Python)
- **Database**: PostgreSQL 15
- **ORM**: SQLAlchemy
- **Containerization**: Docker & Docker Compose
- **API**: REST with JSON
- **Architecture**: Microservices, Stateless

## 📋 Data Models

```python
# Core entities with relationships
Producto: {id, nombre}
Receta: {id, nombre, productos[]}  
Lista: {id, nombre, productos[]}

# Many-to-many relationships
receta_producto: {receta_id, producto_id}
lista_producto: {lista_id, producto_id}
```

## 🧪 Demo Features

### Component Testing
- Individual service component validation
- Interface contract verification
- API endpoint functionality testing

### Container Demonstration
- Multi-container deployment
- Service networking
- Container scaling capabilities

### ACID Transaction Testing
- Successful transaction completion
- Transaction rollback scenarios
- Data consistency validation

### Stateless Service Validation
- Independent request processing
- No server-side session state
- Horizontal scaling preparation

### Performance Assessment
- Concurrent request handling
- Multiple instance scaling
- Load distribution testing

## 🛠️ Requirements

- Docker and Docker Compose
- `curl` command-line tool
- `jq` for JSON formatting (recommended)

## 🔍 Monitoring

The demo includes built-in monitoring for:
- Container health status
- API response times
- Transaction success/failure rates
- Concurrent request handling
- Database connection status

## 🎓 Learning Objectives

After running this demo, you will understand:

1. **Component-Based Architecture**: How to structure applications using loosely coupled components
2. **Container Deployment**: Benefits and practices of containerized applications
3. **Database Transactions**: ACID properties implementation and transaction management  
4. **Stateless Design**: Principles and benefits of stateless service architecture
5. **Horizontal Scaling**: Strategies for scaling applications across multiple instances