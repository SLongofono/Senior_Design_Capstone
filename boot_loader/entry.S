#define STACK_TOP 0x80700000
    
    
    
    .option norvc
    .section .text.init,"ax",@progbits
    .globl reset_vector
reset_vector:
    li sp, STACK_TOP
    j start
