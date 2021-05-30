DEVICE = atmega328p
# DEVICE = attiny85
# DEVICE = atmega8

# settings of writer
AVRDUDE = avrdude
AVRWRITER = sparkfun
AVRDUDEBAUDRATE = 2400

# ------------------------------------------------------------
AS = avra
ASFLAGS = -I ..

OBJCOPY = avr-objcopy

SIZE = avr-size

# ------------------------------------------------------------
.SUFFIXES: .asm .hex

all: $(TARGET).hex

flash: $(TARGET).hex
	$(AVRDUDE) -c $(AVRWRITER) -p $(DEVICE) -b $(AVRDUDEBAUDRATE) -e -U flash:w:$<

clean:
	-rm -f *.hex *.obj *~

# ------------------------------------------------------------
.asm.hex:
	$(AS) $(ASFLAGS) $<
