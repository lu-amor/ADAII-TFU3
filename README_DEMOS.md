# Flask API Demo Scripts

This directory contains comprehensive demo scripts to showcase the Flask API functionality.

## Available Demo Scripts

### 🚀 `demo_setup.sh`
**Setup and initialization script**
- Builds and starts Docker containers
- Waits for services to be ready
- Performs health checks
- **Run this first!**

```bash
./demo_setup.sh
```

### 🎯 `demo_basic.sh`
**Basic functionality demonstration**
- Creates sample products
- Demonstrates recipe creation
- Shows shopping list functionality
- Perfect for first-time users

```bash
./demo_basic.sh
```

### 🚀 `demo_advanced.sh`
**Advanced scenarios and edge cases**
- Complex recipe database creation
- Multiple themed shopping lists
- Error handling demonstrations
- Database constraint testing
- **Most comprehensive demo**

```bash
./demo_advanced.sh
```

### 🎮 `demo_interactive.sh`
**Interactive guided demo**
- Step-by-step walkthrough
- Manual testing suggestions
- Perfect for learning the API
- Includes curl command examples

```bash
./demo_interactive.sh
```

### 🧪 `demo_test_suite.sh`
**Comprehensive API testing**
- Systematic endpoint testing
- Edge case validation
- Performance verification
- Generates detailed test reports
- **Use this for quality assurance**

```bash
./demo_test_suite.sh
```

### 🔥 `demo_load_test.sh`
**Performance and load testing**
- Concurrent user simulation
- Performance metrics collection
- Stress testing capabilities
- Response time analysis

```bash
./demo_load_test.sh
```

### 🧹 `demo_cleanup.sh`
**Environment cleanup**
- Stops Docker containers
- Removes temporary files
- Optional database/image cleanup
- **Run when finished**

```bash
./demo_cleanup.sh
```

## Quick Start

1. **Setup the environment:**
   ```bash
   chmod +x *.sh
   ./demo_setup.sh
   ```

2. **Run a basic demo:**
   ```bash
   ./demo_basic.sh
   ```

3. **Clean up when done:**
   ```bash
   ./demo_cleanup.sh
   ```

## API Endpoints Demonstrated

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API health check |
| GET | `/productos` | List all products |
| POST | `/productos` | Create new product |
| POST | `/recetas` | Create new recipe |
| GET | `/listas` | List all shopping lists |
| POST | `/listas` | Create new shopping list |
| POST | `/listas/{id}/productos` | Add products to list* |

*Note: Some endpoints may need completion in the source code.

## Demo Scenarios Covered

### Basic Operations
- ✅ Product CRUD operations
- ✅ Recipe creation with ingredients
- ✅ Shopping list management
- ✅ Data retrieval and listing

### Advanced Features
- ✅ Bulk data operations
- ✅ Complex recipe relationships
- ✅ Themed shopping lists
- ✅ Database transaction handling

### Error Handling
- ✅ Duplicate data validation
- ✅ Invalid input handling
- ✅ Missing data scenarios
- ✅ Malformed JSON requests

### Performance Testing
- ✅ Concurrent user simulation
- ✅ Response time measurement
- ✅ Load testing scenarios
- ✅ Database performance under stress

## Requirements

- Docker and Docker Compose
- `curl` command-line tool
- `jq` for JSON formatting (optional but recommended)
- `bc` for calculations (for load testing)

## Troubleshooting

### API Not Responding
```bash
# Check if containers are running
docker-compose ps

# Check API logs
docker-compose logs api

# Check database logs
docker-compose logs db
```

### Permission Issues
```bash
# Make scripts executable
chmod +x *.sh
```

### Port Conflicts
If ports 8000 or 5432 are already in use, modify `docker-compose.yaml`:
```yaml
ports:
  - "8001:8000"  # Change external port
  - "5433:5432"  # Change external port
```

## Development Notes

### Incomplete Features Found
During demo creation, these areas need attention:

1. **Incomplete endpoint in `listas.py`:**
   ```python
   # Line ends abruptly in agregar_productos function
   db.s  # Should be db.session.commit()
   ```

2. **Missing endpoints:**
   - GET `/productos/{id}` - Get single product
   - GET `/recetas/{id}` - Get single recipe
   - GET `/listas/{id}` - Get single list
   - DELETE endpoints for cleanup
   - PUT endpoints for updates

3. **Suggested improvements:**
   - Input validation
   - Error message standardization
   - Pagination for large datasets
   - Authentication/authorization
   - Request logging

## Contributing

To add new demo scenarios:

1. Create a new script file: `demo_your_scenario.sh`
2. Follow the existing script patterns
3. Add documentation to this README
4. Test thoroughly with the test suite

## Architecture

The demo environment consists of:
- **PostgreSQL Database** (port 5432)
- **Flask API Server** (port 8000)
- **Docker Compose** orchestration
- **Multiple demo scripts** for different scenarios

```
┌─────────────────┐    ┌─────────────────┐
│   Demo Scripts  │───▶│   Flask API     │
│                 │    │   (port 8000)   │
└─────────────────┘    └─────────┬───────┘
                                 │
                       ┌─────────▼───────┐
                       │   PostgreSQL    │
                       │   (port 5432)   │
                       └─────────────────┘
```

## Security Notes

⚠️ **This is a development/demo environment:**
- No authentication implemented
- Database credentials are in plain text
- API accepts all requests without validation
- **DO NOT use in production without security hardening**