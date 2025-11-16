Availability check demo

This demo automates a simple fault-isolation test to show how availability differs
between the monolithic branch (`main`) and the microservices branch (`tfu5`).

Prerequisites:
- Docker and docker compose installed and running
- A clean git working tree (the script runs `git checkout`)

How to run:

1. Make the script executable:

```bash
chmod +x demos/availability_check.sh
```

2. Run the check for the monolith (example: stop `api`):

```bash
./demos/availability_check.sh main api
```

3. Run the check for microservices (example: stop `productos`):

```bash
./demos/availability_check.sh tfu5 productos
```

4. Results are written to `demos/results/availability-<branch>-<target>-<timestamp>.txt`.

What the script does:
- Checks out the requested branch
- Brings up docker-compose
- Probes a set of endpoints (gateway, productos, recetas, listas)
- Stops the requested target service
- Re-runs probes to show which endpoints are affected
- Restarts the target service and performs a final probe

Notes:
- The script is intentionally non-destructive: it does not change project source files.
- It may print warnings if a target service name is not found in the branch's compose file.
- The script is intended for demo/testing only and assumes local ports 8000-8003 are used by the services.
