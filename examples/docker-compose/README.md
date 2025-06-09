# Docker Compose Example

This example demonstrates how to use Liquibase with Docker Compose to manage database changes alongside a PostgreSQL database.

## Prerequisites

- Docker and Docker Compose installed
- Basic understanding of Liquibase and database migrations

## Quick Start

### Option 1: Using Published Image (Recommended for End Users)

1. **Start the services:**
   ```bash
   docker-compose up
   ```

### Option 2: Building from Local Dockerfile (For Development/Testing)

1. **Start the services with local build:**
   ```bash
   docker-compose -f docker-compose.local.yml up --build
   ```

2. **Verify the migration:**
   The Liquibase service will automatically run the `update` command after PostgreSQL is ready. Check the logs to see the migration results:
   ```bash
   docker-compose logs liquibase
   ```

3. **Connect to the database to verify:**
   ```bash
   docker-compose exec postgres psql -U liquibase -d liquibase_demo -c "SELECT * FROM users;"
   ```

4. **Stop the services:**
   ```bash
   docker-compose down
   ```

## What This Example Does

- **PostgreSQL**: Runs a PostgreSQL 15 Alpine container with a database named `liquibase_demo`
- **Liquibase**: Uses the official Alpine Liquibase image to run database migrations
- **Sample Migration**: Creates a `users` table and inserts sample data
- **Health Checks**: Ensures PostgreSQL is ready before running Liquibase migrations

## File Structure

```
docker-compose/
├── docker-compose.yml          # Docker Compose with published image
├── docker-compose.local.yml    # Docker Compose with local build
├── liquibase.properties        # Liquibase configuration
├── changelog/
│   ├── db.changelog-master.xml # Master changelog file
│   ├── 001-create-users-table.xml
│   └── 002-insert-sample-data.xml
└── README.md                   # This file
```

## Configuration

### Environment Variables

The example uses environment variables for database connection:
- `LIQUIBASE_COMMAND_URL`: Database connection URL
- `LIQUIBASE_COMMAND_USERNAME`: Database username  
- `LIQUIBASE_COMMAND_PASSWORD`: Database password

### Volumes

- `./changelog:/liquibase/changelog`: Mounts local changelog files
- `./liquibase.properties:/liquibase/liquibase.properties`: Mounts configuration file
- `postgres_data`: Persists PostgreSQL data

## Running Other Liquibase Commands

To run other Liquibase commands, you can override the default command:

```bash
# Generate SQL for review
docker-compose run --rm liquibase --defaults-file=/liquibase/liquibase.properties update-sql

# Rollback last changeset
docker-compose run --rm liquibase --defaults-file=/liquibase/liquibase.properties rollback-count 1

# Check status
docker-compose run --rm liquibase --defaults-file=/liquibase/liquibase.properties status
```

## Customization

To adapt this example for your use case:

1. **Change Database**: Modify the `postgres` service in `docker-compose.yml`
2. **Update Connection**: Modify `liquibase.properties` with your database details
3. **Add Your Migrations**: Replace the sample changelog files with your own
4. **Environment**: Adjust environment variables as needed