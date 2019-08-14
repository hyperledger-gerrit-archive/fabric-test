package logger

import (
	
	"os"
)

type Logger struct{}

//INFO -- To print the info logs
func (l Logger) INFO(message ...string) {
	info := log.New(os.Stdout,
		"INFO: ",
		log.Ldate|log.Ltime)
	info.Println(message)
}

//ERROR -- To print the error logs
func (l Logger) ERROR(err error, message ...string) {
	error := log.New(os.Stderr,
		"ERROR: ",
		log.Ldate|log.Ltime|log.Lshortfile)
	if err == nil {
		error.Fatalln(message)
	}
	error.Fatalf("%s; err: %s", message, err)
}
