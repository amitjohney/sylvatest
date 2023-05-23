package tools

import (
	"bytes"
	"context"
	"fmt"
	"os/exec"
)

// Run a command
func run(context context.Context, cmd exec.Cmd) ([]byte, []byte, error) {
	// log.Printf("Running command: %s", cmd.Args)

	stdout := bytes.Buffer{}
	cmd.Stdout = &stdout
	stderr := bytes.Buffer{}
	cmd.Stderr = &stderr

	if err := cmd.Start(); err != nil {
		return nil, nil, fmt.Errorf("starting command %v: %w", cmd, err)
	}

	if err := cmd.Wait(); err != nil {
		return stdout.Bytes(), stderr.Bytes(), err
	}

	return stdout.Bytes(), stderr.Bytes(), nil
}
