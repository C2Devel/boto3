.PHONY: clean clean-spec copr rpm sources spec srpm tests lint lint-cmt-msg lint-help-msg
.SILENT: help lint-cmt-msg lint-help-msg

DIST       ?= epel-7-x86_64
PROJECT    ?= boto3
PACKAGE    := python-$(PROJECT)
VERSION     = $(shell rpm -q --qf "%{version}\n" --specfile $(PACKAGE).spec | head -1)
RELEASE     = $(shell rpm -q --qf "%{release}\n" --specfile $(PACKAGE).spec | head -1)

GIT        := $(shell which git)
ASPELL     := $(shell which aspell)
RPMLINT    := $(shell which rpmlint)

ifdef GIT
HEAD_SHA := $(shell git rev-parse --short --verify HEAD)
TAG      := $(shell git show-ref --tags -d | grep $(HEAD_SHA) | \
                    git name-rev --tags --name-only $$(awk '{print $2}'))

BUILDID := %{nil}
ifndef TAG
BUILDID := .$(shell date --date="$$(git show -s --format=%ci $(HEAD_SHA))" '+%Y%m%d%H%M').git$(HEAD_SHA)
endif

help: ## show help
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "%-30s %s\n", $$1, $$2}'

ifdef ASPELL
lint-cmt-msg: ## lint commit messages
	git log --oneline HEAD...master | \
	cut -d ' ' -f 2- | \
	aspell --master en list | \
	sort -nr | \
	uniq

lint-help-msg: ## check help comments spelling
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	aspell --master en list | sort -nr | uniq
endif

ifdef RPMLINT
lint-spec: ## lint spec file
lint-spec: spec
lint-spec: ; $(RPMLINT) $(PACKAGE).spec
endif

lint: lint-cmt-msg lint-help-msg lint-spec

spec: ## create spec file
	@git cat-file -p $(HEAD_SHA):$(PACKAGE).spec | sed -e 's,@BUILDID@,$(BUILDID),g' > $(PACKAGE).spec

sources: ## archive sources
sources: clean spec
	@git archive --format=tar --prefix=$(PROJECT)-$(VERSION)/ $(HEAD_SHA) | \
	     gzip > $(PROJECT)-$(VERSION).tar.gz

srpm: ## create srpm
srpm: sources
	@mkdir -p srpms/
	@rpmbuild -bs --define "_sourcedir $(CURDIR)" \
	          --define "_srcrpmdir $(CURDIR)/srpms" $(PACKAGE).spec

rpm: ## create rpm
rpm: srpm
	@mkdir -p rpms/$(DIST)
	/usr/bin/mock -r $(DIST) --resultdir rpms/$(DIST) \
	              --rebuild srpms/$(PACKAGE)-$(VERSION)-$(RELEASE).src.rpm \

ifdef TAG
copr: ## build package in copr repo
copr: srpm
	@copr-cli build --nowait c2devel/c2-sdk \
	          srpms/$(PACKAGE)-$(VERSION)-$(RELEASE).src.rpm
else
copr: ## build package in copr testing repo
copr: srpm
	@copr-cli build --nowait c2devel/c2-sdk-testing \
	          srpms/$(PACKAGE)-$(VERSION)-$(RELEASE).src.rpm
endif
endif

tests: ## run tests
tests:
	@tox

ifdef GIT
clean-spec:
	@git checkout $(PACKAGE).spec
endif

clean: ## clean build files
clean: clean-spec
	@rm -rf build dist srpms rpms $(PROJECT).egg-info $(PROJECT)-*.tar.gz *.egg
