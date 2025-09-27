# Scripts de Demostración de la API Flask

Este directorio contiene scripts de demostración completos para mostrar la funcionalidad de la API Flask.

## Scripts de Demostración Disponibles

### 🚀 `demo_setup.sh`
**Script de configuración e inicialización**
- Construye y levanta los contenedores Docker
- Espera a que los servicios estén listos
- Realiza chequeos de salud
- **¡Ejecuta este primero!**

```bash
./demos/demo_setup.sh
```

### 🎯 `demo_basic.sh`
**Demostración de funcionalidad básica**
- Crea productos de ejemplo
- Demuestra la creación de recetas
- Muestra la funcionalidad de listas de compras
- Perfecto para usuarios primerizos

```bash
./demos/demo_basic.sh
```

### 🚀 `demo_advanced.sh`
**Escenarios avanzados y casos límite**
- Creación de una base de datos de recetas compleja
- Múltiples listas de compras temáticas
- Demostraciones de manejo de errores
- Pruebas de restricciones de base de datos
- **La demo más completa**

```bash
./demos/demo_advanced.sh
```

### 🎮 `demo_interactive.sh`
**Demostración guiada interactiva**
- Recorrido paso a paso
- Sugerencias para pruebas manuales
- Perfecto para aprender la API
- Incluye ejemplos de comandos curl

```bash
./demos/demo_interactive.sh
```

### 🧪 `demo_test_suite.sh`
**Pruebas completas de la API**
- Pruebas sistemáticas de endpoints
- Validación de casos límite
- Verificación de rendimiento
- Genera reportes de prueba detallados
- **Úsalo para aseguramiento de calidad**

```bash
./demos/demo_test_suite.sh
```

### 🔥 `demo_load_test.sh`
**Pruebas de rendimiento y carga**
- Simulación de usuarios concurrentes
- Recolección de métricas de rendimiento
- Capacidades de pruebas de estrés
- Análisis de tiempos de respuesta

```bash
./demos/demo_load_test.sh
```

### 🧹 `demo_cleanup.sh`
**Limpieza del entorno**
- Detiene los contenedores Docker
- Elimina archivos temporales
- Limpieza opcional de base de datos/imágenes
- **Ejecuta al finalizar**

```bash
./demos/demo_cleanup.sh
```

## Inicio Rápido

1. **Configura el entorno:**
   ```bash
   chmod +x *.sh
   ./demos/demo_setup.sh
   ```

2. **Ejecuta una demo básica:**
   ```bash
   ./demos/demo_basic.sh
   ```

3. **Limpia al terminar:**
   ```bash
   ./demos/demo_cleanup.sh
   ```

## Endpoints de la API Demostrados

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/` | Chequeo de salud de la API |
| GET | `/productos` | Listar todos los productos |
| POST | `/productos` | Crear nuevo producto |
| POST | `/recetas` | Crear nueva receta |
| GET | `/listas` | Listar todas las listas de compras |
| POST | `/listas` | Crear nueva lista de compras |
| POST | `/listas/{id}/productos` | Agregar productos a la lista* |

*Nota: Algunos endpoints pueden requerir completarse en el código fuente.

## Escenarios de Demostración Cubiertos

### Operaciones Básicas
- ✅ Operaciones CRUD de productos
- ✅ Creación de recetas con ingredientes
- ✅ Gestión de listas de compras
- ✅ Recuperación y listado de datos

### Funcionalidades Avanzadas
- ✅ Operaciones masivas de datos
- ✅ Relaciones complejas de recetas
- ✅ Listas de compras temáticas
- ✅ Manejo de transacciones en base de datos

### Manejo de Errores
- ✅ Validación de datos duplicados
- ✅ Manejo de entradas inválidas
- ✅ Escenarios de datos faltantes
- ✅ Solicitudes JSON malformadas

### Pruebas de Rendimiento
- ✅ Simulación de usuarios concurrentes
- ✅ Medición de tiempos de respuesta
- ✅ Escenarios de pruebas de carga
- ✅ Rendimiento de la base de datos bajo estrés

## Requisitos

- Docker y Docker Compose
- Herramienta de línea de comandos `curl`
- `jq` para formateo de JSON (opcional pero recomendado)
- `bc` para cálculos (para pruebas de carga)

## Resolución de Problemas

### La API no responde
```bash
# Verifica si los contenedores están en ejecución
docker-compose ps

# Revisa los logs de la API
docker-compose logs api

# Revisa los logs de la base de datos
docker-compose logs db
```

### Problemas de permisos
```bash
# Haz ejecutables los scripts
chmod +x *.sh
```

### Conflictos de puertos
Si los puertos 8000 o 5432 ya están en uso, modifica `docker-compose.yaml`:
```yaml
ports:
  - "8001:8000"  # Cambia el puerto externo
  - "5433:5432"  # Cambia el puerto externo
```

## Notas de Desarrollo

### Funcionalidades Incompletas Encontradas
Durante la creación de las demos, se detectaron estas áreas a revisar:

1. **Endpoint incompleto en `listas.py`:**
   ```python
   # La línea termina abruptamente en la función agregar_productos
   db.s  # Debería ser db.session.commit()
   ```

2. **Endpoints faltantes:**
   - GET `/productos/{id}` - Obtener un producto
   - GET `/recetas/{id}` - Obtener una receta
   - GET `/listas/{id}` - Obtener una lista
   - Endpoints DELETE para limpieza
   - Endpoints PUT para actualizaciones

3. **Mejoras sugeridas:**
   - Validación de entradas
   - Estandarización de mensajes de error
   - Paginación para grandes volúmenes de datos
   - Autenticación/autorización
   - Registro de solicitudes

## Contribuciones

Para agregar nuevos escenarios de demo:

1. Crea un nuevo archivo de script: `demos/demo_tu_escenario.sh`
2. Sigue el patrón de los scripts existentes
3. Agrega documentación en este README
4. Prueba exhaustivamente con el test suite

## Arquitectura

El entorno de demostración consiste en:
- **Base de datos PostgreSQL** (puerto 5432)
- **Servidor API Flask** (puerto 8000)
- **Orquestación con Docker Compose**
- **Múltiples scripts de demo** para diferentes escenarios

```
┌─────────────────┐    ┌─────────────────┐
│  Scripts Demo   │───▶│    API Flask    │
│                 │    │   (puerto 8000) │
└─────────────────┘    └─────────┬───────┘
                                 │
                       ┌─────────▼───────┐
                       │   PostgreSQL    │
                       │   (puerto 5432) │
                       └─────────────────┘
```

## Notas de Seguridad

⚠️ **Este es un entorno de desarrollo/demostración:**
- No se implementa autenticación
- Las credenciales de la base de datos están en texto plano
- La API acepta todas las solicitudes sin validación
- **NO usar en producción sin endurecimiento de seguridad**