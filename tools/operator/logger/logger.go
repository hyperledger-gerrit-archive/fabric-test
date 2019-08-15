package logger

import (
	"log"
	"os"
	"strings"
)

//INFO -- To print the info logs
func INFO(message ...string) {
	info := log.New(os.Stdout,
		"INFO: ",
		log.Ldate|log.Ltime)
	info.Println(strings.Join(message, ""))
}

//ERROR -- To print the error logs
func ERROR(err error, message ...string) {
	error := log.New(os.Stderr,
		"ERROR: ",
		log.Ldate|log.Ltime|log.Lshortfile)
	if err == nil {
		error.Fatalln(strings.Join(message, ""))
	}
	error.Fatalf("%s; err: %s", strings.Join(message, ""), err)
}
