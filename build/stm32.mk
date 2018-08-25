#
# stm32.mk - A simple makefile for STM32 microcontroller
# Copyright (C) 2018 Marius Greuel. All rights reserved.
#

ifndef CPU
    $(error error : variable CPU is not defined)
endif

ifndef SOURCES
    $(error error : variable SOURCES is not defined)
endif

# Default tools from the ARM toolchain
CC = arm-none-eabi-gcc
CXX = arm-none-eabi-g++
AS = arm-none-eabi-as
AR = arm-none-eabi-ar
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE = arm-none-eabi-size
NM = arm-none-eabi-nm

# C/C++ compiler flags
C_AND_CXX_FLAGS += -mcpu=$(CPU)
C_AND_CXX_FLAGS += -mthumb
C_AND_CXX_FLAGS += -MMD -MP
C_AND_CXX_FLAGS += $(OPTIMIZATION_FLAGS)
C_AND_CXX_FLAGS += -Wall
C_AND_CXX_FLAGS += -g

# C compiler flags
CFLAGS += -std=c99
CFLAGS += $(C_AND_CXX_FLAGS)
CFLAGS += -Wstrict-prototypes

# C++ compiler flags
CXXFLAGS += -std=c++11
CXXFLAGS += $(C_AND_CXX_FLAGS)
CXXFLAGS += -fno-exceptions

# Preprocessor flags
CPPFLAGS += -DF_CPU=$(F_CPU)

# Assembler flags
ASFLAGS += $(C_AND_CXX_FLAGS)
ASFLAGS += -x assembler-with-cpp

# Linker flags
LDFLAGS += $(C_AND_CXX_FLAGS)
LDFLAGS += -Wl,-Map=$(MAPFILE) -Wl,--relax -Wl,--gc-sections
LDLIBS += -lc -lm

# Make flags
MAKEFLAGS += -r

# Size flags
SIZEFLAGS +=

FLASH_TOOL ?= openocd

ifdef DEBUG
    OPTIMIZATION_FLAGS ?= -Og
else
    CPPFLAGS += -DNDEBUG
    OPTIMIZATION_FLAGS ?= -Os
endif

OBJDIR ?= objs
TARGET ?= main
ELFFILE ?= $(OBJDIR)/$(TARGET).elf
BINFILE ?= $(OBJDIR)/$(TARGET).bin
HEXFILE ?= $(OBJDIR)/$(TARGET).hex
MAPFILE ?= $(OBJDIR)/$(TARGET).map
LSTFILE ?= $(OBJDIR)/$(TARGET).lst

VPATH += $(dir $(SOURCES))
OBJECTS += $(addprefix $(OBJDIR)/,$(addsuffix .o, $(basename $(notdir $(SOURCES)))))
DEPENDENCIES += $(OBJECTS:.o=.d)

# Select the command-line tools used in this makefile.
# The enviroment variable 'ComSpec' implies cmd.exe on Windows
ifdef ComSpec
    RM = del
    MKDIR = mkdir
    RMDIR = rmdir /s /q
    ospath = $(subst /,\,$1)
else
    RM = rm -f
    MKDIR = mkdir -p
    RMDIR = rm -r -f
    ospath = $1
endif

all: $(BINFILE) size
	@echo Done: $(call ospath,$(abspath $(HEXFILE)))

$(ELFFILE): $(OBJECTS)
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS)

$(BINFILE): $(ELFFILE)
	$(OBJCOPY) -R .stack -O binary $< $@

$(HEXFILE): $(ELFFILE)
	$(OBJCOPY) -R .stack -O ihex $< $@

$(LSTFILE): $(ELFFILE)
	$(OBJDUMP) -h -S $< >$@

elf: $(ELFFILE)
bin: $(BINFILE)
hex: $(HEXFILE)
list: $(LSTFILE)

size: $(ELFFILE)
	@echo Project size:
	$(SIZE) $(SIZEFLAGS) $(ELFFILE)

flash: $(BINFILE) size
	$(FLASH_TOOL) $(OPENOCD_FLAGS)

clean:
	@echo Cleaning project...
	-$(RM) $(call ospath,$(ELFFILE)) $(call ospath,$(BINFILE)) $(call ospath,$(HEXFILE)) $(call ospath,$(LSTFILE)) 2>nul
	-$(RMDIR) $(call ospath,$(OBJDIR)) 2>nul

.PHONY: elf hex list size flash clean

$(OBJECTS): | $(OBJDIR)

$(OBJDIR):
	$(MKDIR) $(call ospath,$(OBJDIR))

$(OBJDIR)/%.o: %.c
	@echo $(call ospath,$<)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(OBJDIR)/%.o: %.cpp
	@echo $(call ospath,$<)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<

$(OBJDIR)/%.o: %.s
	@echo $(call ospath,$<)
	$(CC) $(ASFLAGS) $(CPPFLAGS) -c -o $@ $<

.SUFFIXES:

-include $(DEPENDENCIES)
