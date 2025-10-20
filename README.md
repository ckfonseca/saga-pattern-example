# saga-pattern-choreography
## Create sales-service database image
`` docker build --build-arg DB_NAME=sales_db --build-arg ROOT_PWD=p@ssw0rd --build-arg APP_USERNAME=sales_app_user --build-arg APP_USER_PWD=123456 . -t  sales-db:latest ``
## Start infrastructure
``docker-compose up -d --build``
