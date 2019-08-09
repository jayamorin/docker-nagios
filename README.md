# docker-nagios

Dockerized nagios.

## Build
```bash
docker build --build-arg nagios_password=P@ssw0rd -t docker-nagios:latest .
```

## Run
```bash
docker run -d --rm --name "nagios" -p 8080:80 -t docker-nagios:latest
```

