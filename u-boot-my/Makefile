
CC      = arm-linux-gcc
LD      = arm-linux-ld
AR      = arm-linux-ar
OBJCOPY = arm-linux-objcopy
OBJDUMP = arm-linux-objdump

# INCLUDEDIR = $(shell pwd)/include
CFLAGS     = -Wall -O2
CPPFLAGS   = -nostdinc #-I$(INCLUDEDIR)

export CC LD AR OBJCOPY OBJDUMP INCLUDEDIR CFLAGS CPPFLAGS

objs := start.o init.o boot.o

boot.bin: $(objs)
	$(LD) -Tu-boot.lds -o boot.elf $^
	$(OBJCOPY) -O binary -S boot.elf $@
	$(OBJDUMP) -D -m arm boot.elf > boot.dis

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

%.o: %.S
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf *.o *.bin *.elf *.dis
