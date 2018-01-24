FROM ubuntu:17.10 as builder

RUN apt update \
&& apt install -y     \
     binutils  \
     nasm      \
     grub-pc-bin \
     xorriso   \
     qemu \
     make

CMD make && make iso
