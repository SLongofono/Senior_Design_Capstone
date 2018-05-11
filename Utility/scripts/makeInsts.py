from instruction_masks import instructions

# By default, Python gives you the unsigned form with a negative sign instead
# of twos complement.
def binhelper(b):
    return b & 0xffffffff

# Slice constants
OP_S = 25
FUN3_S = 17
FUN3_E = 20 
FUN7_E = 7

# Mappings
registers = dict(zip(range(-32, 32), ["{:05b}".format(s) for s in range(-32, 32)]))
imm20s = dict(zip(range(-524288, 524288), ["{:020b}".format(binhelper(s)) for s in range(-524288,524288)]))
imm12s = dict(zip(range(-2048, 2048), ["{:012b}".format(binhelper(s)) for s in range(-2048,2048)]))

def gen_R_Type(name, rs1, rs2, rd):
    """
    Generates an R-Type formatted instruction as a 32-character string

    @param name A string representing the familiar name of the basic instruction
    as written in assembly

    @param rs1 An integer number representing which register holds the
    operand rs1

    @param rs2 An integer number representing which register holds the
    operand rs2

    @param rs3 An integer number representing which register holds the
    operand rs3

    @param rd An integer number representing which register gets the
    result

    """
    raw = instructions[name]
    return raw[0:FUN7_E] + registers[rs2] + registers[rs1] + raw[FUN3_S:FUN3_E] + registers[rd] + raw[OP_S:]

def gen_I_Type(name, rs1, rd, imm):
    """
    Generates an I-Type formatted instruction as a 32-character string.
    Assumes valid bounds on registers [0,31] and immediates [-2048, 2047]

    @param name A string representing the familiar name of the basic instruction
    as written in assembly

    @param rs1 An integer number representing which register holds the
    operand rs1

    @param rd An integer number representing which register gets the
    result
    
    @param imm An integer number representing the 12-bit immediate value

    """
    raw = instructions[name]
    immraw = imm12s[imm]
    return immraw + registers[rs1] + raw[FUN3_S:FUN3_E] + registers[rd] + raw[OP_S:]

def gen_S_Type(name, rs1, rs2, imm):
    """
    Generates a S-Type formatted instruction as a 32-character string.
    Assumes valid bounds on registers [0,31] and immediates [-2048, 2047]

    @param name A string representing the familiar name of the basic instruction
    as written in assembly

    @param rs1 An integer number representing which register holds the
    operand rs1

    @param rs2 An integer number representing which register holds the
    operand rs2

    @param imm An integer number representing the 12-bit immediate value

    """
    raw = instructions[name]
    immraw = imm12s[imm]
    return immraw[0:7] + registers[rs2] + registers[rs1] + raw[FUN3_S:FUN3_E] + immraw[8:] + raw[OP_S:]

def gen_B_Type(name, rs1, rs2, imm):
    """
    Generates a B-Type formatted instruction as a 32-character string.
    Assumes valid bounds on registers [0,31] and immediates [-2048, 2047]

    @param name A string representing the familiar name of the basic instruction
    as written in assembly

    @param rs1 An integer number representing which register holds the
    operand rs1

    @param rs2 An integer number representing which register holds the
    operand rs2

    @param imm An integer number representing the 12-bit immediate value

    """
    raw = instructions[name]
    immraw = imm12s[imm]
    return immraw[0] + immraw[2:8] + registers[rs2] + registers[rs1] + raw[FUN3_S:FUN3_E] + immraw[8:] + immraw[1] + raw[OP_S:]

def gen_U_Type(name, rd, imm):
    """
    Generates a U-Type formatted instruction as a 32-character string.
    Assumes valid bounds on registers [0,31] and immediates [-524288, 524287]

    @param name A string representing the familiar name of the basic instruction
    as written in assembly

    @param rd An integer number representing which register gets the
    result
    
    @param imm An integer number representing the 20-bit immediate value

    """
    raw = instructions[name]
    return imm20s[imm] + register[rd] + raw[OP_S:]

def gen_J_Type(name, rd, imm):
    """
    Generates an I-Type formatted instruction as a 32-character string.
    Assumes valid bounds on registers [0,31] and immediates [-524288, 524287]

    @param name A string representing the familiar name of the basic instruction
    as written in assembly

    @param rs1 An integer number representing which register holds the
    operand rs1

    @param rd An integer number representing which register gets the
    result
    
    @param imm An integer number representing the 20-bit immediate value

    """
    raw = instructions[name]
    immraw = imm20s[imm]
    return immraw[0] + immraw[10:] + immraw[8] + immraw[1:9] + registers[rd] + raw[OP_S:]



#ADDI x5 x0 15
print(gen_I_Type("ADDI", 0, 5, 15))

# ADDI x6 x0 16
print(gen_I_Type("ADDI", 0, 6, 16))

# ADD x6 x5 x6
print(gen_R_Type("ADD", 6, 5, 6))

# AND x6 x0 x5
print(gen_R_Type("AND", 6, 0, 5))

# OR x6 x5 x6
print(gen_R_Type("OR", 6, 5, 6))

