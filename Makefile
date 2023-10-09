GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
BUILD_DIR=bin
BINARY_NAME=bootstrap
ZIP_PACKAGE_NAME=$(BINARY_NAME).zip
AWS_PROFILE=genius
    
all: clean test build-lambda-prod

run-local:
	STAGE=dev air

build-local:
	$(GOBUILD) -o $(BUILD_DIR)/$(BINARY_NAME) -v ./cmd/

build: 
	GOARCH=arm64 GOOS=linux $(GOBUILD) -tags lambda.norpc -o $(BUILD_DIR)/$(BINARY_NAME) -v ./cmd/

validate:
	terraform validate

deploy: build
	export TF_VAR_STAGE=prod && terraform apply

deploy-uat: build
	export TF_VAR_STAGE=uat && terraform apply

test: 
	$(GOTEST) -v ./...

clean: 
	rm -f $(BUILD_DIR)/$(BINARY_NAME)