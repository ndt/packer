# Output Images
IMAGE_BASENAME=gentoo64
IMAGES=$(IMAGE_BASENAME).zip

# Sources
MIRROR=http://distfiles.gentoo.org/releases/amd64/autobuilds/
ISO_LATEST=latest-install-amd64-minimal
STAGE_LATEST=latest-stage3-amd64-systemd


ISO_RELPATH=$(shell curl -s $(MIRROR)$(ISO_LATEST).txt | \
	tail -1 | \
	cut -d " " -f 1)
STAGE_RELPATH=$(shell curl -s $(MIRROR)$(STAGE_LATEST).txt | \
	tail -1 | \
	cut -d " " -f 1)

ISO=$(notdir $(ISO_RELPATH))
STAGE=$(notdir $(STAGE_RELPATH))


# Don't go parallel
#.NOTPARALLEL:
# Don't waste time searching for files
.SUFFIXES:


all: $(IMAGES)

download: $(STAGE) $(ISO)

.PHONY: $(ISO)
$(ISO):
	@echo Downloading stage: "$(ISO)"
	@wget --continue --no-verbose $(MIRROR)$(ISO_RELPATH)

.PHONY: $(STAGE)
$(STAGE):
	@echo Downloading stage: "$(STAGE)"
	@wget --continue --no-verbose $(MIRROR)$(STAGE_RELPATH)

$(IMAGES): $(STAGE) $(ISO)
	PACKER_LOG=1 PACKER_LOG_PATH="packer.log" packer build \
		-on-error=ask \
		-var "mirror=$(MIRROR)$(dir $(ISO_RELPATH))" \
		-var "iso=$(ISO)" \
		-var "stage=$(STAGE)" \
		virtualbox.json

.PHONY: clean
clean:
	rm stage3-*.tar.bz2
