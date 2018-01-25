DOCKER ?= docker
GDB ?= gdb
QEMU ?= qemu-system-x86_64
DIR := ${CURDIR}
BUILDMNT = /os
BUILD_IMAGE ?= hausdorff/os

arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/os-$(arch).iso

linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg
assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
	build/arch/$(arch)/%.o, $(assembly_source_files))

# try to generate a unique GDB port
GDBPORT	:= $(shell expr `id -u` % 5000 + 25000)

# Make QEMUOPTS
QEMUOPTS = -M q35 -serial mon:stdio -gdb tcp::$(GDBPORT)
QEMUOPTS += $(shell if $(QEMU) -nographic -help | grep -q '^-D '; then echo '-D qemu.log'; fi)
# Use a legacy IDE controller for the kernel
# QEMUOPTS += -drive file=$(OBJDIR)/kern/kernel.img,format=raw,if=none,id=kernel \
# 	    -device piix4-ide,id=piix4-ide -device ide-hd,drive=kernel,bus=piix4-ide.0
QEMUOPTS += $(QEMUEXTRA)

.PHONY: all clean run iso build

all: $(kernel)

clean:
	@rm -r build .gdbinit

.gdbinit: .gdbinit.tmpl
	sed "s/localhost:1234/localhost:$(GDBPORT)/" < $^ > $@

pre-qemu: .gdbinit build

qemu: pre-qemu
	$(QEMU) $(QEMUOPTS) -cdrom $(iso)

qemu-nox: pre-qemu
	@echo "***"
	@echo "*** Use Ctrl-a x to exit qemu"
	@echo "***"
	$(QEMU) -nographic $(QEMUOPTS) -cdrom $(iso)

qemu-gdb: pre-qemu
	@echo "***"
	@echo "*** Now run 'make gdb'." 1>&2
	@echo "***"
	$(QEMU) $(QEMUOPTS) -cdrom $(iso) -S

qemu-nox-gdb: pre-qemu
	@echo "***"
	@echo "*** Now run 'make gdb'." 1>&2
	@echo "***"
	$(QEMU) -nographic $(QEMUOPTS) -cdrom $(iso) -S

gdb:
	$(GDB) $(QEMU)

iso: $(iso)

# Create GRUB2-bootable image.
$(iso): $(kernel) $(grub_cfg)
	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.bin
	@cp $(grub_cfg) build/isofiles/boot/grub
	@grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	# @rm -r build/isofiles

# Compile the kernel.
$(kernel): $(assembly_object_files) $(linker_script)
	@ld -n -T $(linker_script) -o $(kernel) $(assembly_object_files)

# Assemble all x86 files.
build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -felf64 $< -o $@

build:
	$(DOCKER) build -t $(BUILD_IMAGE) .
	$(DOCKER) run -it --rm -v $(DIR):$(BUILDMNT) -w $(BUILDMNT) $(BUILD_IMAGE)
