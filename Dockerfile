FROM avtoappru/postgis:latest

ADD files/ /

VOLUME /var/lib/postgresql/data

EXPOSE 5432
ENTRYPOINT ["/opt/bin/docker-entrypoint.sh"]
CMD ["postgres"]
