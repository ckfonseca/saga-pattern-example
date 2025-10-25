FROM mysql/mysql-server

ARG DB_NAME
ARG ROOT_PWD
ARG APP_USERNAME
ARG APP_USER_PWD

ENV MYSQL_ROOT_PASSWORD=${ROOT_PWD}
ENV MYSQL_DATABASE=${DB_NAME}
ENV APP_USERNAME=${APP_USERNAME}
ENV APP_USER_PWD=${APP_USER_PWD}

COPY init-users.sh /docker-entrypoint-initdb.d/init-root.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-root.sh

EXPOSE 3306

CMD ["mysqld"]
