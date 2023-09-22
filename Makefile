#===============================================================================
# Condig
#-------------------------------------------------------------------------------
VSIM                := iverilog
#VSIM                := verilator

#TRACE_VCD           := 1
TRACE_VCD_FILE      := dump.vcd

#TRACE_FST           := 1
TRACE_FST_FILE      := dump.fst

CLK_FREQ_MHZ        := 10
BAUD_RATE           := 921600

TIMEOUT             := 5000

#===============================================================================
# Sources
#-------------------------------------------------------------------------------
SRC_DIR             := src
SRCS                += $(wildcard $(SRC_DIR)/*.v)
INC_DIR             += $(SRC_DIR)

SIM_SRC_DIR         := sim
SIM_SRCS            += $(wildcard $(SIM_SRC_DIR)/*.v)
CXX_SIM_SRCS        += $(wildcard $(SIM_SRC_DIR)/*.cpp)

#===============================================================================
# Common to Verilator and Icarus Verilog
#-------------------------------------------------------------------------------
VFLAGS              := $(addprefix -I,$(INC_DIR))

ifdef TRACE_VCD
TRACE_VCD_FILE      ?= dump.vcd
VFLAGS              += -DTRACE_VCD
VFLAGS              += -DTRACE_VCD_FILE=\"$(TRACE_VCD_FILE)\"
endif

ifdef TRACE_FST
TRACE_FST_FILE      ?= dump.fst
VFLAGS              += -DTRACE_FST
VFLAGS              += -DTRACE_FST_FILE=\"$(TRACE_FST_FILE)\"
endif

VFLAGS              += -DNO_IP

ifdef CLK_FREQ_MHZ
VFLAGS              += -DCLK_FREQ_MHZ=$(CLK_FREQ_MHZ)
endif

ifdef BAUD_RATE
VFLAGS              += -DBAUD_RATE=$(BAUD_RATE)
endif

ifdef TIMEOUT
VFLAGS              += -DTIMEOUT=$(TIMEOUT)
endif

#===============================================================================
# Verilator
#-------------------------------------------------------------------------------
VERILATOR           := verilator

VERILATOR_FLAGS     += --cc
VERILATOR_FLAGS     += --exe
VERILATOR_FLAGS     += --build
VERILATOR_FLAGS     += --x-assign unique

ifdef TRACE_VCD
VERILATOR_FLAGS     += --trace
endif

ifdef TRACE_FST
VERILATOR_FLAGS     += --trace-fst
endif

VERILATOR_FLAGS     += --Wno-width
VERILATOR_FLAGS     += $(VFLAGS)

VERILATOR_INPUT     += $(CXX_SIM_SRCS) $(SIM_SRCS) $(SRCS)

#===============================================================================
# Icarus Verilog
#-------------------------------------------------------------------------------
IVERILOG            := iverilog

IVERILOG_FLAGS      += -Wall
IVERILOG_FLAGS      += $(VFLAGS)

IVERILOG_INPUT      += $(SIM_SRCS) $(SRCS)

ifdef TRACE_FST
VVP_FLAGS           += -fst
endif

#===============================================================================
# Build rules
#-------------------------------------------------------------------------------
.PHONY: default build run clean
default: build run

build:
ifeq ($(VSIM),verilator)
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT) > /dev/null
else ifeq ($(VSIM),iverilog)
	@$(IVERILOG) $(IVERILOG_FLAGS) $(IVERILOG_INPUT)
else
	$(error Invalid verilog simulator!!)
endif

run:
ifeq ($(VSIM),verilator)
	@obj_dir/Vtop
else ifeq ($(VSIM),iverilog)
	@vvp a.out $(VVP_FLAGS)
else
	$(error Invalid verilog simulator!!)
endif

clean:
	rm -f a.out
	rm -rf obj_dir
	rm -f *.vcd *.fst
