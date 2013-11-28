package utils

import (
	"fmt"
	"log/syslog"
	"os"
)

//checkError basic error handling
func CheckError(err error, logger *syslog.Writer) {
	if err != nil {
		logger.Crit(fmt.Sprintln("Fatal error", err.Error()))
		os.Exit(1)
	}
}

