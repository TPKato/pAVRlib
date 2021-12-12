DEVICE = atmega328p
# DEVICE = attiny85
# DEVICE = atmega8

# settings of writer
AVRDUDE = avrdude
AVRWRITER = sparkfun
AVRDUDEBAUDRATE = 2400

PAVRLIBDIR = ..

# ------------------------------------------------------------
AS = avra
ASFLAGS = -I $(PAVRLIBDIR)

OBJCOPY = avr-objcopy

SIZE = avr-size

# ------------------------------------------------------------
.SUFFIXES: .asm .hex

ifdef TARGET
all: $(TARGET).hex
else
all:
	@echo "Invoke make with TARGET (make TARGET=...)"
	@echo "Targets:"
	@ls *-test.asm | sed -e 's/^/    /' -e 's/.asm$$//'
endif


flash: $(TARGET).hex
	$(AVRDUDE) -c $(AVRWRITER) -p $(DEVICE) -b $(AVRDUDEBAUDRATE) -e -U flash:w:$<

clean:
	-rm -f *.hex *.obj *~

# ------------------------------------------------------------
.asm.hex:
	$(AS) $(ASFLAGS) $<
