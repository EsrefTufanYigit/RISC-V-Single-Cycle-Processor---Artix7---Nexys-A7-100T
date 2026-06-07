# Verification Makefile for Single-Cycle RISC-V Architecture

# Relative path to hardware definition files
VERILOG_SOURCES = $(wildcard ../HDL/*.v)

# Simulator configuration
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Top-level Verilog module name
TOPLEVEL = single_cycle

# Python testbench module name
MODULE = Single_Cycle_Test

# Simulation time parameters
COCOTB_HDL_TIMEUNIT = 1us
COCOTB_HDL_TIMEPRECISION = 1us

# Cocotb inclusion
include $(shell cocotb-config --makefiles)/Makefile.sim