package sylva_test

import (
	"path/filepath"
	"runtime"
	"time"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gstruct"

	"sylva_test/tools"
)

var (
	_, thisFile, _, _ = runtime.Caller(0)
	testDir           = filepath.Dir(thisFile)
	rootDir           = filepath.Join(testDir, "..")
	chartDir          = filepath.Join(rootDir, "charts", "sylva-units")
)

var _ = Describe("Sylva units validation :", func() {

	Context("Building sylva units objects without custom values", func() {
		valueFiles := []string{}
		sylvaUnitYaml := tools.GetYamlFromHelmTemplate(chartDir, valueFiles, 5*time.Second)
		sylvaUnitObjects := tools.ParseAllObjects(sylvaUnitYaml)
		It("should produce ", func() {
			countObjects := tools.GetCountPerType(sylvaUnitObjects)
			Ω(countObjects).Should(MatchAllKeys(Keys{
				"total":                   Equal(60),
				"*v1.ConfigMap":           Equal(2),
				"*v1.Secret":              Equal(6),
				"*v1beta2.GitRepository":  Equal(4),
				"*v1beta2.HelmRepository": Equal(12),
				"*v1beta2.Kustomization":  Equal(36),
			}))
		})
		It("should not enable capo unit", func() {
			Ω(tools.IsUnitEnabled("capo", sylvaUnitObjects)).ShouldNot(BeTrue())
		})
		metallbK := tools.GetKustomization("metallb", sylvaUnitObjects)
		It("should produce a kustomization named 'metallb'", func() {
			Ω(tools.IsUnitEnabled("metallb", sylvaUnitObjects)).Should(BeTrue())
			Ω(metallbK).ShouldNot(BeNil())
			Ω(metallbK.Spec.Path).Should(Equal("./kustomize-units/metallb"))
		})
		It("'metallb' kustomization should produce ", func() {
			metallbManifests := tools.GetAllObjectsFromFluxKustomization(metallbK, rootDir, 5*time.Second)
			countObjects := tools.GetCountPerType(metallbManifests)
			Ω(countObjects).Should(MatchAllKeys(Keys{
				"total":                              Equal(25),
				"*v1.Certificate":                    Equal(1),
				"*v1.ClusterRole":                    Equal(2),
				"*v1.ClusterRoleBinding":             Equal(2),
				"*v1.CustomResourceDefinition":       Equal(7),
				"*v1.DaemonSet":                      Equal(1),
				"*v1.Deployment":                     Equal(1),
				"*v1.Namespace":                      Equal(1),
				"*v1.Role":                           Equal(2),
				"*v1.Issuer":                         Equal(1),
				"*v1.RoleBinding":                    Equal(2),
				"*v1.Secret":                         Equal(1),
				"*v1.Service":                        Equal(1),
				"*v1.ServiceAccount":                 Equal(2),
				"*v1.ValidatingWebhookConfiguration": Equal(1),
			}))

		})
	})

	Context("Building sylva units objects with capo_base.yaml values", func() {
		valueFiles := []string{filepath.Join(testDir, "units_validation", "capo_base.yaml")}
		sylvaUnitYaml := tools.GetYamlFromHelmTemplate(chartDir, valueFiles, 5*time.Second)
		sylvaUnitObjects := tools.ParseAllObjects(sylvaUnitYaml)
		It("should produce", func() {
			countObjects := tools.GetCountPerType(sylvaUnitObjects)
			Ω(countObjects).Should(MatchAllKeys(Keys{
				"total":                   Equal(65),
				"*v1.ConfigMap":           Equal(2),
				"*v1.Secret":              Equal(8),
				"*v1beta2.GitRepository":  Equal(4),
				"*v1beta2.HelmRepository": Equal(13),
				"*v1beta2.Kustomization":  Equal(38),
			}))
		})

	})

	Context("Building sylva units objects with capo_base.yaml and capo_rootVolume.yaml values", func() {
		valueFiles := []string{
			filepath.Join(testDir, "units_validation", "capo_base.yaml"),
			filepath.Join(testDir, "units_validation", "capo_rootVolume.yaml"),
		}
		sylvaUnitYaml := tools.GetYamlFromHelmTemplate(chartDir, valueFiles, 5*time.Second)
		sylvaUnitObjects := tools.ParseAllObjects(sylvaUnitYaml)
		It("should produce a 'capo-cluster-resources' kustomization ", func() {
			_ = tools.GetKustomization("cluster", sylvaUnitObjects)
			// TODO check cluster kustomization but `flux build --dry-run` skips variable substitutions from Secrets and ConfigMaps
			// clusterObjects := tools.GetAllObjectsFromFluxKustomization(clusterManifestKustomization, rootDir, 5*time.Second)
			// GinkgoWriter.Println(clusterObjects)

		})

	})

	Context("Building sylva units objects with unit_name_typo.yaml values", func() {
		It("should fail", func() {
			valueFiles := []string{filepath.Join(testDir, "units_validation", "unit_name_typo.yaml")}
			Ω(func() { tools.GetYamlFromHelmTemplate(chartDir, valueFiles, 5*time.Second) }).
				Should(PanicWith(MatchRegexp(`.*Error: values don't meet the specifications.*`)))
		})
	})
})
