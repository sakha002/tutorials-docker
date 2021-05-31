FROM golang:alpine AS build-env



RUN apk update && apk add protoc 
RUN apk update && apk add make

RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.26 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1

ENV PATH="$PATH:$(go env GOPATH)/bin"


WORKDIR /home
COPY helloworld/ ./helloworld
COPY greeter_server/ greeter_server
RUN cd helloworld &&  make proto_server
   

RUN mkdir /app


WORKDIR /home/greeter_server

RUN cp -r ./*  ../../app

WORKDIR /app
RUN apk add git
RUN go mod download

RUN go get google.golang.org/grpc/examples/helloworld/helloworld
RUN go get google.golang.org/grpc@v1.36.0
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o /go/bin/app


FROM scratch

COPY --from=build-env /go/bin/app /go/bin/app
CMD [ "/go/bin/app" ]
EXPOSE 50051