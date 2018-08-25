#
# boards.mk
# Copyright (C) 2018 Marius Greuel. All rights reserved.
#

ifeq ($(BOARD),BluePill)
    CPU = cortex-m3
    CPPFLAGS += -DSTM32F103xB
    LDFLAGS += --specs=nano.specs
    LDFLAGS += --specs=nosys.specs 
    LDFLAGS += -TSTM32F103C8Tx_FLASH.ld
    LDLIBS += -lnosys
    OPENOCD_FLAGS += -f openocd.cfg -c "init" -c "reset halt" -c "program $(BINFILE) verify reset exit 0x08000000"
else
    $(warning warning : variable BOARD is not defined)
endif
