package db

import (
	"database/sql"
	"log"

	_ "github.com/libsql/libsql-client-go/libsql"
	"github.com/zihaolam/gofiber-lambda-boilerplate/pkg/config"
	"github.com/glebarez/sqlite"
	"gorm.io/gorm"
)

var conn *gorm.DB

func InitializeConnection() (err error) {
	if conn != nil {
		return nil
	}

	if config.ENV.STAGE == "prod" {
		dbConn, err := sql.Open("libsql", config.ENV.DB_URI)
		if err != nil {
			log.Fatalf("Error connecting to database: %s", err.Error())
		}
		conn, err = gorm.Open(sqlite.Dialector{Conn: dbConn})
		if err != nil {
			log.Fatalf("Error connecting to database: %s", err.Error())
		}
		return nil
	}

	conn, err = gorm.Open(sqlite.Open(config.ENV.DB_URI))
	if err != nil {
		log.Fatalf("Error connecting to database: %s", err.Error())
	}
	return nil
}

func Migrate(models []interface{}) error {
	return conn.AutoMigrate(models...)
}
