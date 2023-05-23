package tools

import (
	"bytes"
	"io"
	"log"

	"gopkg.in/yaml.v3"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/serializer"
	"k8s.io/client-go/kubernetes/scheme"

	fluxhelmv2 "github.com/fluxcd/helm-controller/api/v2beta1"
	fluxkustomizev1 "github.com/fluxcd/kustomize-controller/api/v1beta2"
	fluxsourcev1 "github.com/fluxcd/source-controller/api/v1beta2"
	certmanagerv1 "github.com/jetstack/cert-manager/pkg/apis/certmanager/v1"
	corev1 "k8s.io/api/core/v1"
	apiextv1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
)

func ParseK8sObject(yamlObject []byte) interface{} {

	sch := runtime.NewScheme()
	_ = scheme.AddToScheme(sch)
	_ = apiextv1.AddToScheme(sch)
	_ = fluxsourcev1.AddToScheme(sch)
	_ = fluxhelmv2.AddToScheme(sch)
	_ = fluxkustomizev1.AddToScheme(sch)
	_ = certmanagerv1.AddToScheme(sch)

	Parse := serializer.NewCodecFactory(sch).UniversalDeserializer().Decode

	obj, _, err := Parse(yamlObject, nil, nil)
	// log.Printf("groupKindVersion: %v\n", groupKindVersion)

	if err != nil {
		log.Panicf("Unable to Parse yaml object: %s", yamlObject)
	}

	return obj
}

func SplitYAMLDocuments(rawYaml []byte) ([][]byte, error) {

	dec := yaml.NewDecoder(bytes.NewReader(rawYaml))
	var result [][]byte
	for {
		var value interface{}
		err := dec.Decode(&value)
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
		valueBytes, err := yaml.Marshal(value)
		if err != nil {
			return nil, err
		}
		result = append(result, valueBytes)
	}
	return result, nil
}

func ParseAllObjects(yamlObjects [][]byte) []interface{} {
	var result []interface{}
	for _, yamlObject := range yamlObjects {
		obj := ParseK8sObject(yamlObject)
		result = append(result, obj)
	}
	return result
}

func GetKustomization(name string, k8sObjects []interface{}) *fluxkustomizev1.Kustomization {
	for _, obj := range k8sObjects {
		if obj, ok := obj.(*fluxkustomizev1.Kustomization); ok {
			// log.Printf("%s - %s \n", reflect.TypeOf(obj), obj.Name)
			if obj.Name == name {
				return obj
			}
		}
	}
	return nil
}

func GetConfigmap(name string, k8sObjects []interface{}) *corev1.ConfigMap {
	for _, obj := range k8sObjects {
		if obj, ok := obj.(*corev1.ConfigMap); ok {
			// log.Printf("%s - %s \n", reflect.TypeOf(obj), obj.Name)
			if obj.Name == name {
				return obj
			}
		}
	}
	return nil
}

func GetSecret(name string, k8sObjects []interface{}) *corev1.Secret {
	for _, obj := range k8sObjects {
		if obj, ok := obj.(*corev1.Secret); ok {
			// log.Printf("%s - %s \n", reflect.TypeOf(obj), obj.Name)
			if obj.Name == name {
				return obj
			}
		}
	}
	return nil
}

func GetObjectYaml(obj interface{}) string {
	objByte, err := yaml.Marshal(&obj)
	if err != nil {
		panic("Unable to marshell to yaml")
	}
	return string(objByte)
}
