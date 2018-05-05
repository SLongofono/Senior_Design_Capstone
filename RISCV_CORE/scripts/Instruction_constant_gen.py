instructions = [
    'LUI',
    'AUIPC',
    'JAL',
    'JALR',
    'BEQ',
    'BNE',
    'BLT',
    'BGE',
    'BLTU',
    'BGEU',
    'LB',
    'LH',
    'LW',
    'LBU',
    'LHU',
    'SB',
    'SH',
    'SW',
    'ADDI',
    'SLTI',
    'SLTIU',
    'XORI',
    'ORI',
    'ANDI',
    'SLLI',
    'SRLI',
    'SRAI',
    'ADD',
    'SUB',
    'SLL',
    'SLT',
    'SLTU',
    'XOR',
    'SRL',
    'SRA',
    'OR',
    'AND',
    'FENCE',
    'FENCEI',
    'ECALL',
    'EBREAK',
    'CSRRW',
    'CSRRS',
    'CSRRC',
    'CSRRWI',
    'CSRRSI',
    'CSRRCI',
    'LWU',
    'LD',
    'SD',
    'SLLI6',
    'SRLI6',
    'SRAI6',
    'ADDIW',
    'SLLIW',
    'SRLIW',
    'SRAIW',
    'ADDW',
    'SUBW',
    'SLLW',
    'SRLW',
    'SRAW',
    'MUL',
    'MULH',
    'MULHSU',
    'MULHU',
    'DIV',
    'DIVU',
    'REM',
    'REMU',
    'MULW',
    'DIVW',
    'DIVUW',
    'REMW',
    'REMUW',
    'LRW',
    'SCW',
    'AMOSWAPW',
    'AMOADDW',
    'AMOXORW',
    'AMOANDW',
    'AMOORW',
    'AMOMINW',
    'AMOMAXW',
    'AMOMINUW',
    'AMOMAXUW',
    'LRD',
    'SCD',
    'AMOSWAPD',
    'AMOADDD',
    'AMOXORD',
    'AMOANDD',
    'AMOORD',
    'AMOMIND',
    'AMOMAXD',
    'AMOMINUD',
    'AMOMAXUD',
    'FLW',
    'FSW',
    'FMADDS',
    'FMSUBS',
    'FNMSUBS',
    'FNMADDS',
    'FADDS',
    'FSUBS',
    'FMULS',
    'FDIVS',
    'FSQRTS',
    'FSGNJS',    'FSGNJNS',
    'FSGNJXS',
    'FMINS',
    'FMAXS',
    'FCVTWS',
    'FCVTWUS',
    'FMVXW',
    'FEQS',
    'FLTS',
    'FLES',
    'FCLASSS',
    'FCVTSW',
    'FCVTSWU',
    'FMVWX',
    'FCVTLS',
    'FCVTLUS',
    'FCVTSL',
    'FCVTSLU',
    'FLD',
    'FSD',
    'FMADDD',
    'FMSUBD',
    'FNMSUBD',
    'FNMADDD',
    'FADDD',
    'FSUBD',
    'FMULD',
    'FDIVD',
    'FSQRTD',
    'FSGNJD',
    'FSGNJND',
    'FSGNJXD',
    'FMIND',
    'FMAXD',
    'FCVTSD',
    'FCVTDS',
    'FEQD',
    'FLTD',
    'FLED',
    'FCLASSD',
    'FCVTWD',
    'FCVTWUD',
    'FCVTDW',
    'FCVTDWU',
    'FCVTLD',
    'FCVTLUD',
    'FMVXD',
    'FCVTDL',
    'FCVTDLU',
    'FMVDX',
    'URET',
    'SRET',
    'MRET',
    'WFI',
    'SFENCEVM'
]

for i in range(len(instructions)):
    print('constant instr_{} : instr_t := "{}";'.format(instructions[i], format(i,'08b')))