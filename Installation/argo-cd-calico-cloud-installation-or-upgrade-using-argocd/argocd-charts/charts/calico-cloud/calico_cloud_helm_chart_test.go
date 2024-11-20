// Package calicocloudcharttest uses 'helm template' to render the helm package with various input values,
// unmarshals the resulting yaml into kubernetes resource types, and then tests that the correct fields
// are set accordingly.
package calicocloudcharttest

import (
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	operatorv1 "github.com/tigera/cc-operator/api/v1"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"

	"github.com/gruntwork-io/terratest/modules/helm"
	"github.com/stretchr/testify/require"
)

type resources struct {
	Deployment appsv1.Deployment
	Installer  operatorv1.Installer
}

// render is a helper method with renders the chart with the specified options
// and returns the deployment and the installer resource, which are the two most important
// resources to test.
func render(t *testing.T, options *helm.Options) resources {
	t.Helper()

	_, err := exec.LookPath("helm")
	if err != nil {
		t.Skip("skipping exec tests since 'helm' is not installed")
	}

	helmChartPath, err := filepath.Abs("../calico-cloud")
	releaseName := "calico-cloud"
	require.NoError(t, err)

	output := strings.Split(helm.RenderTemplate(t, options, helmChartPath, releaseName, []string{"templates/deployment.yaml", "templates/installer.yaml"}), "---")

	var deployment appsv1.Deployment
	helm.UnmarshalK8SYaml(t, output[1], &deployment)

	var installer operatorv1.Installer
	helm.UnmarshalK8SYaml(t, output[2], &installer)

	return resources{
		Deployment: deployment,
		Installer:  installer,
	}
}

// defaultOptions is a helper method to set all the required values by the helm chart.
func defaultOptions() *helm.Options {
	return &helm.Options{
		// all required fields are set here by default
		SetValues: map[string]string{
			"installer.clusterName": "default-cluster-1",
			"apiKey":                "default:api:key",
		},
	}
}

func TestHelm(t *testing.T) {
	t.Run("default options", func(t *testing.T) {
		r := render(t, defaultOptions())

		deploymentContainers := r.Deployment.Spec.Template.Spec.Containers
		require.Equal(t, len(deploymentContainers), 1)
		require.Equal(t, deploymentContainers[0].Image, "quay.io/tigera/cc-operator:v0.0.0-0")
		require.Len(t, r.Deployment.Spec.Template.Spec.Volumes, 0)
		require.Equal(t, r.Installer.Spec.ClusterName, "default-cluster-1")
	})

	t.Run("custom tls cert", func(t *testing.T) {
		options := defaultOptions()
		options.SetValues["caBundleSecretName"] = "my-certs"

		const (
			expectedVolumeName = "ca-certificates"
			expectedVolumePath = "/etc/ssl/certs"
		)

		r := render(t, options)
		require.Len(t, r.Deployment.Spec.Template.Spec.Volumes, 1)
		require.Equal(t, corev1.Volume{
			Name: expectedVolumeName,
			VolumeSource: corev1.VolumeSource{
				Secret: &corev1.SecretVolumeSource{
					SecretName: "my-certs",
				},
			},
		}, r.Deployment.Spec.Template.Spec.Volumes[0])

		require.Equal(t, len(r.Deployment.Spec.Template.Spec.Containers), 1)
		require.Equal(t, []corev1.VolumeMount{{
			Name:      expectedVolumeName,
			MountPath: expectedVolumePath,
		}}, r.Deployment.Spec.Template.Spec.Containers[0].VolumeMounts)

	})

	t.Run("image pull secret", func(t *testing.T) {
		options := defaultOptions()
		options.SetValues["imagePullSecrets[0].name"] = "my-secret"
		r := render(t, options)

		require.Equal(t, []corev1.LocalObjectReference{{
			Name: "my-secret",
		}}, r.Deployment.Spec.Template.Spec.ImagePullSecrets)

		require.Len(t, r.Deployment.Spec.Template.Spec.Volumes, 1)
		require.Equal(t, corev1.Volume{
			Name: "my-secret",
			VolumeSource: corev1.VolumeSource{
				Secret: &corev1.SecretVolumeSource{
					SecretName: "my-secret",
				},
			},
		}, r.Deployment.Spec.Template.Spec.Volumes[0])

		require.Equal(t, len(r.Deployment.Spec.Template.Spec.Containers), 1)
		require.Equal(t, []corev1.VolumeMount{{
			Name:      "my-secret",
			MountPath: "/image-pull-secrets/my-secret",
		}}, r.Deployment.Spec.Template.Spec.Containers[0].VolumeMounts)
	})

	t.Run("private registry", func(t *testing.T) {
		t.Run("no imagePath", func(t *testing.T) {
			options := defaultOptions()
			options.SetValues["installer.registry"] = "myreg.io"
			r := render(t, options)

			require.Equal(t, len(r.Deployment.Spec.Template.Spec.Containers), 1)
			require.Equal(t, "myreg.io/calico-cloud-public/cc-operator:v0.0.0-0", r.Deployment.Spec.Template.Spec.Containers[0].Image)
			require.Equal(t, "myreg.io", r.Installer.Spec.Registry)
		})

		t.Run("with trailing slash", func(t *testing.T) {
			options := defaultOptions()
			options.SetValues["installer.registry"] = "myreg.io/"
			r := render(t, options)

			require.Equal(t, len(r.Deployment.Spec.Template.Spec.Containers), 1)
			require.Equal(t, "myreg.io/calico-cloud-public/cc-operator:v0.0.0-0", r.Deployment.Spec.Template.Spec.Containers[0].Image)
		})

		t.Run("with image path", func(t *testing.T) {
			options := defaultOptions()
			options.SetValues["installer.registry"] = "myreg.io"
			options.SetValues["installer.imagePath"] = "myimagepath"
			r := render(t, options)

			require.Equal(t, len(r.Deployment.Spec.Template.Spec.Containers), 1)
			require.Equal(t, "myreg.io/myimagepath/cc-operator:v0.0.0-0", r.Deployment.Spec.Template.Spec.Containers[0].Image)
			require.Equal(t, "myreg.io", r.Installer.Spec.Registry)
			require.Equal(t, "myimagepath", r.Installer.Spec.ImagePath)
		})
		t.Run("with app v0.0.0-0+hash", func(t *testing.T) {
			options := defaultOptions()
			options.SetValues["image.tag"] = "v0.0.0-0+hash"
			r := render(t, options)

			require.Equal(t, len(r.Deployment.Spec.Template.Spec.Containers), 1)
			require.Equal(t, "quay.io/tigera/cc-operator:v0.0.0-0-ghash", r.Deployment.Spec.Template.Spec.Containers[0].Image)
		})
	})
}
