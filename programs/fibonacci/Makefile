all:
	/home/babypaw/riscv/riscv/bin/riscv64-unknown-linux-gnu-gcc -Wall -Werror -mcmodel=medany -march='rv64im' -mabi=lp64 -std=gnu99 -Wno-unused -Wno-attributes -fno-delete-null-pointer-checks -c entry.S
	/home/babypaw/riscv/riscv/bin/riscv64-unknown-linux-gnu-gcc -O2 -Wall -Werror -mcmodel=medany -march='rv64im' -mabi=lp64 -std=gnu99 -Wno-unused -Wno-attributes -fno-delete-null-pointer-checks -c test.c
	/home/babypaw/riscv/riscv/bin/riscv64-unknown-linux-gnu-gcc -nostartfiles -nostdlib -static -o fib_elf entry.o test.o -T test.lds -Xlinker -Map=output.map
	/home/babypaw/riscv/riscv/bin/riscv64-unknown-linux-gnu-objcopy -O binary fib_elf fib.bin --pad-to 0x90001000

clean:
	rm fib.bin fib_elf entry.o test.o output.map
