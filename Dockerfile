FROM ubuntu:24.04
RUN apt-get update -y && apt-get install -y wget unzip python3 python3-venv
WORKDIR /app/
COPY . .
RUN ln -s /usr/bin/python3 /usr/bin/python
ENTRYPOINT ["./entrypoint.sh"]
