// main.go
package main

import (
	"context"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	fiberadapter "github.com/awslabs/aws-lambda-go-api-proxy/fiber"
	"github.com/zihaolam/gofiber-lambda-boilerplate/pkg/app"
	"github.com/zihaolam/gofiber-lambda-boilerplate/pkg/config"
	"github.com/zihaolam/gofiber-lambda-boilerplate/pkg/db"
	"github.com/zihaolam/gofiber-lambda-boilerplate/pkg/db/models"
)

var fiberLambda *fiberadapter.FiberLambda

// init the Fiber Server
func init() {
	db.InitializeConnection()

	// add new models here for auto migrate
	if err := db.Migrate([]interface{}{&models.Course{}}); err != nil {
		panic(err)
	}
}

// Handler will deal with Fiber working with Lambda
func Handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// If no name is provided in the HTTP request body, throw an error
	return fiberLambda.ProxyWithContext(ctx, req)
}

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	log.Println("fiber coldstart")
	fiberApp := app.New()
	if config.ENV.STAGE == "prod" {
		fiberLambda = fiberadapter.New(fiberApp)
		lambda.Start(Handler)
	} else {
		log.Fatal(fiberApp.Listen("localhost:8085"))
	}
}
