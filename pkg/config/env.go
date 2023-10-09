package config

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
)

type envVars struct {
	STAGE  string `json:"STAGE"`
	DB_URI string `json:"DB_URI"`
}

var ENV = loadEnv()

var REQUIRED_ENV_VARIABLES = []string{"DB_URI"}

func checkExist(key string) error {
	if _, ok := os.LookupEnv(key); !ok {
		return fmt.Errorf("missing env variable: %s", key)
	}
	return nil
}

func checkExists() (err error) {
	for _, env_key := range REQUIRED_ENV_VARIABLES {
		if err = checkExist(env_key); err != nil {
			log.Println(err.Error())
			return err
		}
	}
	return nil
}

func loadEnv() *envVars {
	if os.Getenv("STAGE") == "dev" {
		var env envVars
		data, err := os.ReadFile(".env.json")
		if err != nil {
			panic(err)
		}
		if err := json.Unmarshal(data, &env); err != nil {
			panic(err)
		}
		return &env
	}

	godotenv.Overload(".env")

	if err := checkExists(); err != nil {
		log.Fatalf("Missing env variable")
	}
	return &envVars{
		STAGE:  os.Getenv("STAGE"),
		DB_URI: os.Getenv("DB_URI"),
	}
}
