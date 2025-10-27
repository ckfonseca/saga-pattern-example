# saga-pattern-choreography
## Create sales-service database image
`` docker build --build-arg DB_NAME=sales_db --build-arg ROOT_PWD=p@ssw0rd --build-arg APP_USERNAME=sales_app_user --build-arg APP_USER_PWD=123456 . -t  custom-sale-db:latest ``
## Create inventory-service database image
`` docker build --build-arg DB_NAME=inventory_db --build-arg ROOT_PWD=p@ssw0rd --build-arg APP_USERNAME=inventory_app_user --build-arg APP_USER_PWD=123456 . -t  custom-inventory-db:latest ``
## Create payment-service database image
`` docker build --build-arg DB_NAME=payment_db --build-arg ROOT_PWD=p@ssw0rd --build-arg APP_USERNAME=payment_app_user --build-arg APP_USER_PWD=123456 . -t  custom-payment-db:latest ``
## Start infrastructure
``docker-compose up -d --build``
