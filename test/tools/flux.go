package tools

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"k8s.io/cli-runtime/pkg/printers"

	fluxkustomizev1 "github.com/fluxcd/kustomize-controller/api/v1beta2"
)

func runFluxBuildDry(name string, kustomizationObject interface{}, kustomizationPath string, timeout time.Duration) ([]byte, []byte, error) {

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	kustomizationFile := printKustomizationToTmpFile(kustomizationObject)
	args := []string{"build", "kustomization", name, "--kustomization-file", kustomizationFile, "--path", kustomizationPath, "--dry-run"}

	cmd := exec.CommandContext(ctx, "flux", args...)
	return run(ctx, *cmd)

}

func printKustomizationToTmpFile(obj interface{}) string {
	file, _ := os.CreateTemp("", "sylva-test-*")
	if k, ok := obj.(*fluxkustomizev1.Kustomization); ok {
		y := printers.YAMLPrinter{}
		y.PrintObj(k, file)
	} else {
		panic(fmt.Sprintf("Object is not a kustomization: \n %v", obj))
	}
	return file.Name()
}

func GetAllObjectsFromFluxKustomization(kustomizationObject *fluxkustomizev1.Kustomization, kustomizationPathRoot string, timeout time.Duration) []interface{} {
	name := kustomizationObject.Name
	path := filepath.Join(kustomizationPathRoot, kustomizationObject.Spec.Path)

	rawYamlObjects, stderr, err := runFluxBuildDry(name, kustomizationObject, path, timeout)
	if err != nil {
		panic(fmt.Sprintf("Flux build rendering failed: \n %s \n %s", stderr, err))
	}
	splittedYamlObjects, err := SplitYAMLDocuments(rawYamlObjects)
	if err != nil {
		panic(fmt.Sprintf("Yaml objects parsing failed: %s", err))
	}
	return ParseAllObjects(splittedYamlObjects)
}
