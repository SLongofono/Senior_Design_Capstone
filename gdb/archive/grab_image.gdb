set $image_buffer = "                                                                                                                                                                                                                                                                                                                                   "

set $image_index = 0

while( $image_index < 0x1000 )
    set $i = 0
    set $image_buffer = ""
    while ( $i < 16 )
        eval "set $image_buffer = \"%s%d, \"", $image_buffer, (*(p->mmu->sim->boot_rom)).data[$image_index]
        set $image_index++
        set $i++
    end
    eval "shell echo %s >> /home/babypaw/riscv/gdb/Image.pm", $image_buffer
end

set $image_index = 0
while( $image_index < 0x400000 )
    set $i = 0
    set $image_buffer = ""
    while ( $i < 16 )
        eval "set $image_buffer = \"%s%d, \"", $image_buffer, (p->mmu->sim->mems[0].second).data[$image_index]
        set $image_index++
        set $i++
    end
    eval "shell echo %s >> /home/babypaw/riscv/gdb/Image.pm", $image_buffer
end
