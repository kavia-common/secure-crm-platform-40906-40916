# secure-crm-platform-40906-40916

This workspace includes the crm_database container. There are no references to any db_visualizer folders or steps.

Quick commands:
- Build DB image: docker build -t crm_database:dev secure-crm-platform-40906-40916/crm_database
- Run DB: docker run --rm -d --name crm_database -e POSTGRES_DB=crm -e POSTGRES_USER=crm_admin -e POSTGRES_PASSWORD=change_me_strong -p 5432:5432 crm_database:dev