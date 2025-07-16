GITROOT:=$(shell git rev-parse --show-toplevel)
all: application/v1alpha1/types_gen.cue appproject/v1alpha1/types_gen.cue

application-crd.yaml:
	curl -sSLO https://github.com/argoproj/argo-cd/raw/master/manifests/crds/application-crd.yaml

appproject-crd.yaml:
	curl -sSLO https://github.com/argoproj/argo-cd/raw/master/manifests/crds/appproject-crd.yaml

application/v1alpha1/types_gen.cue: application-crd.yaml
	cd $(GITROOT)/devops && timoni mod vendor crd -f cue.mod/gen/argoproj.io/$<
	sed -i '' 's/!:/:/g' $@

appproject/v1alpha1/types_gen.cue: appproject-crd.yaml
	cd $(GITROOT)/devops && timoni mod vendor crd -f cue.mod/gen/argoproj.io/$<
	sed -i '' 's/!:/:/g' $@

clean:
	rm application/v1alpha1/types_gen.cue appproject/v1alpha1/types_gen.cue application-crd.yaml appproject-crd.yaml
