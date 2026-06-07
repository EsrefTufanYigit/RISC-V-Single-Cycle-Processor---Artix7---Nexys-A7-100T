import cocotb.handle
from tabulate import tabulate
# Convert to hex only if signal is longer than 8 bits. Also handled "Z" and "X" values!
def ToHex(obj): 
    binary_str = str(obj)
    binary_str = binary_str.strip()
    if(len(binary_str)>=8  and  binary_str.replace("1","").replace("0","") == ""): # Convert to hex only if value is longer than 16 bits, and doesn't contain 'x' or 'z' bits.
        value = int(binary_str,2)
        hex_len = (len(binary_str)+3)//4
        hex_str = format(value, '0{}x'.format(hex_len))
        return "0x"+hex_str
    else:
        return binary_str

# This functions scans a module instance, and prints values of every internal signal it finds
def Log_Everything(instance, logger, log_submodules=False):
    instance_name = instance._name
    submodules = []
    log_data = []
    #Check each attribute of the given module (all submodules, wires, regs)
    for attribute in instance:
        if(type(attribute) is cocotb.handle.LogicObject):        # wire / reg
            log_data.append([attribute._name, attribute.get()])
        elif(type(attribute) is cocotb.handle.LogicArrayObject):  # wire / reg array
            log_data.append([attribute._name, ToHex(attribute.get())])
        elif(type(attribute) is cocotb.handle.HierarchyObject):       # submodule
            submodules.append(attribute )
        elif(type(attribute) is cocotb.handle.HierarchyArrayObject):  # submodule array
            submodules.append(attribute)

    table = tabulate(log_data, headers=["Signal", "Current Val"], tablefmt="github")
    logger.debug(table)
    if(log_submodules):
        for sub in submodules:
            logger.debug(f"Submodule Detected: {sub._name}")

#Populate the below functions as in the example lines of code to print your values for debugging
def Log_Datapath(dut,logger):
    #Log whatever signal you want from the datapath, called before positive clock edge
    logger.debug("\n"+"************ DUT DATAPATH Signals ***************")
    Log_Everything(dut.datapath_inst, logger)
    #dut._log.info("reset:%s", ToHex(dut.my_datapath.reset))
    #dut._log.info("ALUSrc:%s", ToHex(dut.my_datapath.ALUSrc))
    #dut._log.info("MemWrite:%s", ToHex(dut.my_datapath.MemWrite))
    #dut._log.info("RegWrite:%s", ToHex(dut.my_datapath.RegWrite))
    #dut._log.info("PCSrc:%s", ToHex(dut.my_datapath.PCSrc))
    #dut._log.info("MemtoReg:%s", ToHex(dut.my_datapath.MemtoReg))
    #dut._log.info("RegSrc:%s", ToHex(dut.my_datapath.RegSrc))
    #dut._log.info("ImmSrc:%s", ToHex(dut.my_datapath.ImmSrc))
    #dut._log.info("ALUControl:%s", ToHex(dut.my_datapath.ALUControl))
    #dut._log.info("CO:%s", ToHex(dut.my_datapath.CO))
    #dut._log.info("OVF:%s", ToHex(dut.my_datapath.OVF))
    #dut._log.info("N:%s", ToHex(dut.my_datapath.N))
    #dut._log.info("Z:%s", ToHex(dut.my_datapath.Z))
    #dut._log.info("CarryIN:%s", ToHex(dut.my_datapath.CarryIN))
    #dut._log.info("ShiftControl:%s", ToHex(dut.my_datapath.ShiftControl))
    #dut._log.info("shamt:%s", ToHex(dut.my_datapath.shamt))
    #dut._log.info("PC:%s", ToHex(dut.my_datapath.PC))
    #dut._log.info("Instruction:%s", ToHex(dut.my_datapath.Instruction))

def Log_Controller(dut,logger):
    #Log whatever signal you want from the controller, called before positive clock edge
    logger.debug("\n"+"************ DUT Controller Signals ***************")
    Log_Everything(dut.control_inst, logger)
    #dut._log.info("Op:%s", ToHex(dut.my_controller.Op))
    #dut._log.info("Funct:%s", ToHex(dut.my_controller.Funct))
    #dut._log.info("Rd:%s", ToHex(dut.my_controller.Rd))
    #dut._log.info("Src2:%s", ToHex(dut.my_controller.Src2))
    #dut._log.info("PCSrc:%s", ToHex(dut.my_controller.PCSrc))
    #dut._log.info("RegWrite:%s", ToHex(dut.my_controller.RegWrite))
    #dut._log.info("MemWrite:%s", ToHex(dut.my_controller.MemWrite))
    #dut._log.info("nPCSrc:%s", ToHex(dut.my_controller.nPCSrc))
    #dut._log.info("nRegWrite:%s", ToHex(dut.my_controller.nRegWrite))
    #dut._log.info("nMemWrite:%s", ToHex(dut.my_controller.nMemWrite))
    #dut._log.info("ALUSrc:%s", ToHex(dut.my_controller.ALUSrc))
    #dut._log.info("MemtoReg:%s", ToHex(dut.my_controller.MemtoReg))
    #dut._log.info("ALUControl:%s", ToHex(dut.my_controller.ALUControl))
    #dut._log.info("FlagWrite:%s", ToHex(dut.my_controller.FlagWrite))
    #dut._log.info("ImmSrc:%s", ToHex(dut.my_controller.ImmSrc))
    #dut._log.info("RegSrc:%s", ToHex(dut.my_controller.RegSrc))
    #dut._log.info("ALUFlags:%s", ToHex(dut.my_controller.ALUFlags))
    #dut._log.info("ShiftControl:%s", ToHex(dut.my_controller.ShiftControl))
    #dut._log.info("shamt:%s", ToHex(dut.my_controller.shamt))
    #dut._log.info("CondEx:%s", ToHex(dut.my_controller.CondEx))