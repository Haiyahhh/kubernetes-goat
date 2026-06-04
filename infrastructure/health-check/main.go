package main

import (
	"os/exec"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/template/html/v2"
)

func main() {
	engine := html.New("./views", ".html")
	app := fiber.New(fiber.Config{
		Views: engine,
	})

	app.Use(recover.New())

	app.Get("/", func(c *fiber.Ctx) error {
		//Rendering the templates
		return c.Render("index", fiber.Map{
			"Title": "Ping Your Servers",
		})
	})

	// a POST endpoint that takes in a Fiber Context 
	app.Post("/", func(c *fiber.Ctx) error {

		// Extract the value of the `endpoint` parameter from the request
		endpoint := c.FormValue("endpoint")

		// Prepare the ping command
		// VULNERABLE: OS Command Injection
		cmd := exec.Command("sh", "-c", "ping -c 2 "+endpoint)

		type error interface {
			Error() string
		}
		
		var finalOutput string

		//run the command
		if output, err := cmd.Output(); err != nil {
			finalOutput = err.Error()
		} else {
			finalOutput = string(output)
		}

		// Render the output of the file to the template.
		return c.Render("index", fiber.Map{
			"Title":  "Ping Your Servers",
			"Output": finalOutput,
		})
	})

	app.Listen("0.0.0.0:8080")
}
