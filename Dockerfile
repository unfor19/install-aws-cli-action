FROM python:3.12-slim
RUN apt-get update -y && apt-get install -y wget unzip gnupg
WORKDIR /app/
COPY . .
ENTRYPOINT ["./entrypoint.sh"]
