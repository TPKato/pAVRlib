.SUFFIXES: .asm .hex

DEVICE = atmega8
F_CPU = 1000000UL
USART_BAUD = 4800
F_SCL=100000

AVRDUDE = avrdude
AVRWRITER = sparkfun
AVRDUDEBAUDRATE = 2400

PAVRLIBDIR = ..

# ------------------------------------------------------------
# The lines after this should not be changed.

VPATH=$(PAVRLIBDIR)/devices:$(PAVRLIBDIR)

CC = avr-gcc
OBJCOPY = avr-objcopy
SIZE = avr-size

DEVICEINFO = -mmcu=$(DEVICE) -DF_CPU=$(F_CPU)
DEVICEINFO += -DBAUD=$(USART_BAUD)
DEVICEINFO += -DF_SCL=$(F_SCL)

CFLAGS  = -Wall -I$(PAVRLIBDIR) -Os $(DEVICEINFO)
ASFLAGS = -Wall -I$(PAVRLIBDIR) -I. -x assembler-with-cpp $(DEVICEINFO)
LDFLAGS = -mmcu=$(DEVICE)

ifdef TARGET
all: $(TARGET).hex
else
all:
	@echo "Invoke make with TARGET (make TARGET=...)"
	@echo "Targets:"
	@ls *-test.c | sed -e 's/^/    /' -e 's/.c$$//'
endif


$(TARGET).hex: $(TARGET)

flash: $(TARGET).hex
	$(AVRDUDE) -c $(AVRWRITER) -p $(DEVICE) -b $(AVRDUDEBAUDRATE) -e -U flash:w:$<

clean:
	rm -f *.o *.hex $(TARGET)

.asm.o:
	$(CC) $(ASFLAGS) -c $<

%.hex: %
	$(OBJCOPY) -j .text -j .data -O ihex $< $@
	$(SIZE) $@

# ------------------------------------------------------------
# dependencies
# ------------------------------------------------------------
# am2302-test
am2302-test: am2302-test.o am2302.o wait.o
am2302.o: $(PAVRLIBDIR)/devices/am2302.asm am2302config.h
	$(CC) $(ASFLAGS) --include=$(basename $@)config.h -c $<

# wait-test
wait-test: wait-test.o wait.o
wait-test.o: wait-test.c waitconfig.h

# common
wait.o: $(PAVRLIBDIR)/wait.asm
