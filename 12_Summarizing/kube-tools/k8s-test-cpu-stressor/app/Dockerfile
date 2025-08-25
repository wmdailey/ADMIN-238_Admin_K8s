FROM golang:1.25-alpine AS build

WORKDIR /app

COPY . .

RUN go build -o cpu-stressor .

FROM alpine:latest

COPY --from=build /app/cpu-stressor /usr/local/bin/cpu-stressor

ENTRYPOINT ["cpu-stressor"]
