package app

import "github.com/gofiber/fiber/v2"

func New() *fiber.App {
	app := fiber.New()
	AddRoutes(app)
	return app
}
