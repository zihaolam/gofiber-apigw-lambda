package app

import "github.com/gofiber/fiber/v2"

func AddRoutes(app *fiber.App) {
	app.Get("/ping", func(c *fiber.Ctx) error {
		return c.SendString("pong")
	})
	app.Get("/motherfucker", func(c *fiber.Ctx) error {
		return c.SendString("Hello, MOther fucker!")
	})
}
