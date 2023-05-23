package tools

import (
	"context"
	"fmt"
	"os/exec"
	"regexp"
	"time"
)

func RunHelmTemplate(chartDir string, valueFiles []string, timeout time.Duration) []byte {

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	args := []string{"template", chartDir}
	for _, v := range valueFiles {
		args = append(args, "--values", v)
	}
	cmd := exec.CommandContext(ctx, "helm", args...)
	stdout, stderr, err := run(ctx, *cmd)
	stderr = removeFoundSymbolicLinkFromHelmStderr(stderr)
	if err != nil {
		panic(fmt.Sprintf("Helm template rendering failed: \n %s \n %s", stderr, err))
	}
	return stdout
}

func GetYamlFromHelmTemplate(chartDir string, valueFiles []string, timeout time.Duration) [][]byte {
	rawYamlObjects := RunHelmTemplate(chartDir, valueFiles, timeout)
	splittedYamlObjects, err := SplitYAMLDocuments(rawYamlObjects)
	if err != nil {
		panic(fmt.Sprintf("Yaml objects parsing failed: %s", err))
	}
	return splittedYamlObjects

}

func removeFoundSymbolicLinkFromHelmStderr(input []byte) []byte {
	warning := "found symbolic link in path"
	re := regexp.MustCompile("(?m)^.*" + warning + ".*$[\r\n]+")
	res := re.ReplaceAllString(string(input), "")
	return []byte(res)
}
