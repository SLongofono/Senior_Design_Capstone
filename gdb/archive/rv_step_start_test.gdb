set $rv_string_buffer_0 = "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   "

set $rv_string_buffer_1 = "                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   "

set $rv_prv = 0
set $rv_mip = 1
set $rv_satp = 2
set $rv_mstatus = 3
set $rv_medeleg = 4
set $rv_scause = 5
set $rv_mepc = 6
set $rv_mideleg = 7
set $rv_fflags = 8
set $rv_mtval = 9
set $rv_mcounteren = 10
set $rv_frm = 11
set $rv_mscratch = 12
set $rv_scounteren = 13
set $rv_ld_reserv = 14
set $rv_mtvec = 15
set $rv_sepc = 16
set $rv_id = 17
set $rv_mcause = 18
set $rv_stval = 19
set $rv_isa = 20
set $rv_minstret = 21
set $rv_sscratch = 22
set $rv_mtime = 23
set $rv_mie = 24
set $rv_stvec = 25
set $rv_mtimecmp = 26

define rv_csr
    if $argc == 0
        printf "    prv         : 0x%016lX", p->mmu->sim->procs[0]->state.prv
        printf "    mip         : 0x%016lX", p->mmu->sim->procs[0]->state.mip
        printf "    satp        : 0x%016lX\n", p->mmu->sim->procs[0]->state.sptbr
        printf "    mstatus     : 0x%016lX", p->mmu->sim->procs[0]->state.mstatus
        printf "    medeleg     : 0x%016lX", p->mmu->sim->procs[0]->state.medeleg
        printf "    scause      : 0x%016lX\n", p->mmu->sim->procs[0]->state.scause
        printf "    mepc        : 0x%016lX", p->mmu->sim->procs[0]->state.mepc
        printf "    mideleg     : 0x%016lX", p->mmu->sim->procs[0]->state.mideleg
        printf "    fflags      : 0x%016lX\n", p->mmu->sim->procs[0]->state.fflags
        printf "    mtval       : 0x%016lX", p->mmu->sim->procs[0]->state.mbadaddr
        printf "    mcounteren  : 0x%016lX", p->mmu->sim->procs[0]->state.mcounteren
        printf "    frm         : 0x%016lX\n", p->mmu->sim->procs[0]->state.frm
        printf "    mscratch    : 0x%016lX", p->mmu->sim->procs[0]->state.mscratch
        printf "    scounteren  : 0x%016lX", p->mmu->sim->procs[0]->state.scounteren
        printf "    ld_reserv   : 0x%016lX\n", p->mmu->sim->procs[0]->state.load_reservation
        printf "    mtvec       : 0x%016lX", p->mmu->sim->procs[0]->state.mtvec
        printf "    sepc        : 0x%016lX", p->mmu->sim->procs[0]->state.sepc
        printf "    id          : 0x%016lX\n", p->mmu->sim->procs[0]->id
        printf "    mcause      : 0x%016lX", p->mmu->sim->procs[0]->state.mcause
        printf "    stval       : 0x%016lX", p->mmu->sim->procs[0]->state.sbadaddr
        printf "    isa         : 0x%016lX\n", p->mmu->sim->procs[0]->isa
        printf "    minstret    : 0x%016lX", p->mmu->sim->procs[0]->state.minstret
        printf "    sscratch    : 0x%016lX", p->mmu->sim->procs[0]->state.sscratch
        printf "    mtime       : 0x%016lX\n", (*(p->sim->clint.get())).mtime
        printf "    mie         : 0x%016lX", p->mmu->sim->procs[0]->state.mie
        printf "    stvec       : 0x%016lX", p->mmu->sim->procs[0]->state.stvec
        printf "    mtimecmp    : 0x%016lX\n", (*(p->sim->clint.get())).mtimecmp[0]
    else
        if $argc == 1
            if $arg0 == $rv_prv
                printf "    prv  : 0x%016lX => ", p->mmu->sim->procs[0]->state.prv
                if p->mmu->sim->procs[0]->state.prv == 0x03
                    printf "Machine\n"
                end
                if p->mmu->sim->procs[0]->state.prv == 0x01
                    printf "Supervisor\n"
                end
                if p->mmu->sim->procs[0]->state.prv == 0x00
                    printf "User\n"
                end
            end
            if $arg0 == $rv_mstatus
                printf "    mstatus  : 0x%016lX\n", p->mmu->sim->procs[0]->state.mstatus
                printf "           [ 1] =>  SIE   => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 -  1) >> (64 - 1)
                printf "           [ 3] =>  MIE   => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 -  3) >> (64 - 1)
                printf "           [ 5] =>  SPIE  => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 -  5) >> (64 - 1)
                printf "           [ 7] =>  MPIE  => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 -  7) >> (64 - 1)
                printf "           [ 8] =>  SPP   => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 -  8) >> (64 - 1)
                printf "        [12:11] =>  MPP   => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 12) >> (64 - 2)
                printf "        [14:13] =>  FS    => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 14) >> (64 - 2)
                printf "        [16:14] =>  XS    => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 16) >> (64 - 2)
                printf "           [17] =>  MPRV  => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 17) >> (64 - 1)
                printf "           [18] =>  SUM   => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 18) >> (64 - 1)
                printf "           [19] =>  MXR   => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 19) >> (64 - 1)
                printf "           [20] =>  TVM   => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 20) >> (64 - 1)
                printf "           [21] =>  TW    => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 21) >> (64 - 1)
                printf "           [22] =>  TSR   => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 22) >> (64 - 1)
                printf "        [33:32] =>  UXL   => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 33) >> (64 - 2)
                printf "        [35:34] =>  SXL   => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 35) >> (64 - 2)
                printf "           [63] =>  SD    => %i\n", p->mmu->sim->procs[0]->state.mstatus << (63 - 63) >> (64 - 1)
            end
            if $arg0 == $rv_mepc
                printf "    mepc  : 0x%016lX\n", p->mmu->sim->procs[0]->state.mepc
            end
            if $arg0 == $rv_mtval
                printf "    mtval  : 0x%016lX\n", p->mmu->sim->procs[0]->state.mbadaddr
            end
            if $arg0 == $rv_mscratch
                printf "    mscratch : 0x%016lX\n", p->mmu->sim->procs[0]->state.mscratch
            end
            if $arg0 == $rv_mtvec
                printf "    mtvec  : 0x%016lX\n", p->mmu->sim->procs[0]->state.mtvec
                printf "        [63: 2] =>  BASE  => 0x%lX\n", p->mmu->sim->procs[0]->state.mtvec << (63 - 63) >> (64 - 62)
                printf "        [ 1: 0] =>  MODE  => "
                set $rv_mtvec_mode = p->mmu->sim->procs[0]->state.mtvec << (63 - 1) >> (64 - 2)
                if $rv_mtvec_mode == 0
                    printf "Direct\n"
                end
                if $rv_mtvec_mode == 1
                    printf "Vectored\n"
                end
            end
            if $arg0 == $rv_mcause
                printf "    mcause  : 0x%016lX\n", p->mmu->sim->procs[0]->state.mcause
                set $rv_mcause_int = p->mmu->sim->procs[0]->state.mcause << (63 - 63) >> (64 - 1)
                set $rv_mcause_EC  = p->mmu->sim->procs[0]->state.mcause << (63 - 62) >> (64 - 63)
                printf "        [63] =>  Interrupt       => %i\n", $rv_mcause_int
                printf "      [62:0] =>  Exception Code  => 0x%lX\n", $rv_mcause_EC
                if $rv_mcause_int == 1
                    if $rv_mcause_EC == 0
                        printf "                                 => User software interrupt\n"
                    end
                    if $rv_mcause_EC == 1
                        printf "                                 => Supervisor software interrupt\n"
                    end
                    if $rv_mcause_EC == 3
                        printf "                                 => Machine software interrupt\n"
                    end
                    if $rv_mcause_EC == 4
                        printf "                                 => User timer interrupt\n"
                    end
                    if $rv_mcause_EC == 5
                        printf "                                 => Supervisor timer interrupt\n"
                    end
                    if $rv_mcause_EC == 7
                        printf "                                 => Machine timer interrupt\n"
                    end
                    if $rv_mcause_EC == 8
                        printf "                                 => User external interrupt\n"
                    end
                    if $rv_mcause_EC == 9
                        printf "                                 => Supervisor external interrupt\n"
                    end
                    if $rv_mcause_EC == 11
                        printf "                                 => Machine external interrupt\n"
                    end
                else
                    if $rv_mcause_EC == 0
                        printf "                                 => Instruction address misaligned\n"
                    end
                    if $rv_mcause_EC == 1
                        printf "                                 => Instruction access fault\n"
                    end
                    if $rv_mcause_EC == 2
                        printf "                                 => Illegal instruction\n"
                    end
                    if $rv_mcause_EC == 3
                        printf "                                 => Breakpoint\n"
                    end
                    if $rv_mcause_EC == 4
                        printf "                                 => Load address misaligned\n"
                    end
                    if $rv_mcause_EC == 5
                        printf "                                 => Load access fault\n"
                    end
                    if $rv_mcause_EC == 6
                        printf "                                 => Store/AMO address misaligned\n"
                    end
                    if $rv_mcause_EC == 7
                        printf "                                 => Store/AMO access fault\n"
                    end
                    if $rv_mcause_EC == 8
                        printf "                                 => Environment call from U-mode\n"
                    end
                    if $rv_mcause_EC == 9
                        printf "                                 => Environment call from S-mode\n"
                    end
                    if $rv_mcause_EC == 11
                        printf "                                 => Environment call from M-mode\n"
                    end
                    if $rv_mcause_EC == 12
                        printf "                                 => Instruction page fault\n"
                    end
                    if $rv_mcause_EC == 13
                        printf "                                 => Load page fault\n"
                    end
                    if $rv_mcause_EC == 15
                        printf "                                 => Store/AMO page fault\n"
                    end
                end
            end
            if $arg0 == $rv_minstret
                printf "    minstret  : 0x%016lX\n", p->mmu->sim->procs[0]->state.minstret
            end
            if $arg0 == $rv_mie
                printf "    mie  : 0x%016lX\n", p->mmu->sim->procs[0]->state.mie
                printf "           [ 1] =>  SSIE  => %i\n", p->mmu->sim->procs[0]->state.mie << (63 -  1) >> (64 - 1)
                printf "           [ 3] =>  MSIE  => %i\n", p->mmu->sim->procs[0]->state.mie << (63 -  3) >> (64 - 1)
                printf "           [ 5] =>  STIE  => %i\n", p->mmu->sim->procs[0]->state.mie << (63 -  5) >> (64 - 1)
                printf "           [ 7] =>  MTIE  => %i\n", p->mmu->sim->procs[0]->state.mie << (63 -  7) >> (64 - 1)
                printf "           [ 9] =>  SEIE  => %i\n", p->mmu->sim->procs[0]->state.mie << (63 -  9) >> (64 - 1)
                printf "           [11] =>  MEIE  => %i\n", p->mmu->sim->procs[0]->state.mie << (63 - 11) >> (64 - 1)
            end
            if $arg0 == $rv_mip
                printf "    mip  : 0x%016lX\n", p->mmu->sim->procs[0]->state.mip
                printf "           [ 1] =>  SSIP  => %i\n", p->mmu->sim->procs[0]->state.mip << (63 -  1) >> (64 - 1)
                printf "           [ 3] =>  MSIP  => %i\n", p->mmu->sim->procs[0]->state.mip << (63 -  3) >> (64 - 1)
                printf "           [ 5] =>  STIP  => %i\n", p->mmu->sim->procs[0]->state.mip << (63 -  5) >> (64 - 1)
                printf "           [ 7] =>  MTIP  => %i\n", p->mmu->sim->procs[0]->state.mip << (63 -  7) >> (64 - 1)
                printf "           [ 9] =>  SEIP  => %i\n", p->mmu->sim->procs[0]->state.mip << (63 -  9) >> (64 - 1)
                printf "           [11] =>  MEIP  => %i\n", p->mmu->sim->procs[0]->state.mip << (63 - 11) >> (64 - 1)
            end
            if $arg0 == $rv_medeleg
                printf "    medeleg  : 0x%016lX\n", p->mmu->sim->procs[0]->state.medeleg
                printf "           [ 0] =>  Instruction address misaligned  => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 -  0) >> (64 - 1)
                printf "           [ 1] =>  Instruction access fault        => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 -  1) >> (64 - 1)
                printf "           [ 2] =>  Illegal instruction             => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 -  2) >> (64 - 1)
                printf "           [ 3] =>  Breakpoint                      => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 -  3) >> (64 - 1)
                printf "           [ 4] =>  Load address misaligned         => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 -  4) >> (64 - 1)
                printf "           [ 5] =>  Load access fault               => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 -  5) >> (64 - 1)
                printf "           [ 6] =>  Store/AMO address misaligned    => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 -  6) >> (64 - 1)
                printf "           [ 7] =>  Store/AMO access fault          => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 -  7) >> (64 - 1)
                printf "           [ 8] =>  Environment call from U-mode    => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 -  8) >> (64 - 1)
                printf "           [ 9] =>  Environment call from S-mode    => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 -  9) >> (64 - 1)
                printf "           [11] =>  Environment call from M-mode    => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 - 11) >> (64 - 1)
                printf "           [12] =>  Instruction page fault          => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 - 12) >> (64 - 1)
                printf "           [13] =>  Load page fault                 => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 - 13) >> (64 - 1)
                printf "           [15] =>  Store/AMO page fault            => %i\n", p->mmu->sim->procs[0]->state.medeleg << (63 - 15) >> (64 - 1)
            end
            if $arg0 == $rv_mideleg
                printf "    mideleg  : 0x%016lX\n", p->mmu->sim->procs[0]->state.mideleg
                printf "           [ 1] =>  SSIP  => %i\n", p->mmu->sim->procs[0]->state.mideleg << (63 -  1) >> (64 - 1)
                printf "           [ 3] =>  MSIP  => %i\n", p->mmu->sim->procs[0]->state.mideleg << (63 -  3) >> (64 - 1)
                printf "           [ 5] =>  STIP  => %i\n", p->mmu->sim->procs[0]->state.mideleg << (63 -  5) >> (64 - 1)
                printf "           [ 7] =>  MTIP  => %i\n", p->mmu->sim->procs[0]->state.mideleg << (63 -  7) >> (64 - 1)
                printf "           [ 9] =>  SEIP  => %i\n", p->mmu->sim->procs[0]->state.mideleg << (63 -  9) >> (64 - 1)
                printf "           [11] =>  MEIP  => %i\n", p->mmu->sim->procs[0]->state.mideleg << (63 - 11) >> (64 - 1)
            end
            if $arg0 == $rv_mcounteren
                printf "    mcounteren  : 0x%016lX\n", p->mmu->sim->procs[0]->state.mcounteren
                printf "           [ 0] =>  CY  => %i\n", p->mmu->sim->procs[0]->state.mcounteren << (63 -  0) >> (64 - 1)
                printf "           [ 1] =>  TM  => %i\n", p->mmu->sim->procs[0]->state.mcounteren << (63 -  1) >> (64 - 1)
                printf "           [ 2] =>  IR  => %i\n", p->mmu->sim->procs[0]->state.mcounteren << (63 -  2) >> (64 - 1)
            end
            if $arg0 == $rv_scounteren
                printf "    scounteren  : 0x%016lX\n", p->mmu->sim->procs[0]->state.scounteren
                printf "           [ 0] =>  CY  => %i\n", p->mmu->sim->procs[0]->state.scounteren << (63 -  0) >> (64 - 1)
                printf "           [ 1] =>  TM  => %i\n", p->mmu->sim->procs[0]->state.scounteren << (63 -  1) >> (64 - 1)
                printf "           [ 2] =>  IR  => %i\n", p->mmu->sim->procs[0]->state.scounteren << (63 -  2) >> (64 - 1)
            end
            if $arg0 == $rv_sepc
                printf "    sepc  : 0x%016lX\n", p->mmu->sim->procs[0]->state.sepc
            end
            if $arg0 == $rv_stval
                printf "    stval  : 0x%016lX\n", p->mmu->sim->procs[0]->state.sbadaddr
            end
            if $arg0 == $rv_sscratch
                printf "    sscratch  : 0x%016lX\n", p->mmu->sim->procs[0]->state.sscratch
            end
            if $arg0 == $rv_stvec
                printf "    stvec  : 0x%016lX\n", p->mmu->sim->procs[0]->state.stvec
                printf "        [63: 2] =>  BASE  => 0x%lX\n", p->mmu->sim->procs[0]->state.stvec << (63 - 63) >> (64 - 62)
                printf "        [ 1: 0] =>  MODE  => "
                set $rv_stvec_mode = p->mmu->sim->procs[0]->state.stvec << (63 - 1) >> (64 - 2)
                if $rv_stvec_mode == 0
                    printf "Direct\n"
                end
                if $rv_stvec_mode == 1
                    printf "Vectored\n"
                end
            end
            if $arg0 == $rv_satp
                printf "    satp  : 0x%016lX\n", p->mmu->sim->procs[0]->state.sptbr
                set $rv_satp_mode = p->mmu->sim->procs[0]->state.sptbr << (63 - 63) >> (64 - 4)
                printf "        [63:60] =>  MODE  => 0x%lX\n", $rv_satp_mode
                if $rv_satp_mode == 0
                        printf "                          => Bare\n"
                end
                if $rv_satp_mode == 8
                        printf "                          => Sv39\n"
                end
                if $rv_satp_mode == 9
                        printf "                          => Sv48\n"
                end
                printf "        [59:44] =>  ASID  => 0x%lX\n", p->mmu->sim->procs[0]->state.sptbr << (63 - 59) >> (64 - 16)
                printf "        [43: 0] =>  PPN   => 0x%lX\n", p->mmu->sim->procs[0]->state.sptbr << (63 - 43) >> (64 - 44)
            end
            if $arg0 == $rv_scause
                printf "    scause  : 0x%016lX\n", p->mmu->sim->procs[0]->state.scause
                set $rv_scause_int = p->mmu->sim->procs[0]->state.scause << (63 - 63) >> (64 - 1)
                set $rv_scause_EC  = p->mmu->sim->procs[0]->state.scause << (63 - 62) >> (64 - 63)
                printf "        [63] =>  Interrupt       => %i\n", $rv_scause_int
                printf "      [62:0] =>  Exception Code  => 0x%lX\n", $rv_scause_EC
                if $rv_scause_int == 1
                    if $rv_scause_EC == 0
                        printf "                                 => User software interrupt\n"
                    end
                    if $rv_scause_EC == 1
                        printf "                                 => Supervisor software interrupt\n"
                    end
                    if $rv_scause_EC == 4
                        printf "                                 => User timer interrupt\n"
                    end
                    if $rv_scause_EC == 5
                        printf "                                 => Supervisor timer interrupt\n"
                    end
                    if $rv_scause_EC == 8
                        printf "                                 => User external interrupt\n"
                    end
                    if $rv_scause_EC == 9
                        printf "                                 => Supervisor external interrupt\n"
                    end
                else
                    if $rv_scause_EC == 0
                        printf "                                 => Instruction address misaligned\n"
                    end
                    if $rv_scause_EC == 1
                        printf "                                 => Instruction access fault\n"
                    end
                    if $rv_scause_EC == 2
                        printf "                                 => Illegal instruction\n"
                    end
                    if $rv_scause_EC == 3
                        printf "                                 => Breakpoint\n"
                    end
                    if $rv_scause_EC == 4
                        printf "                                 => Load address misaligned\n"
                    end
                    if $rv_scause_EC == 5
                        printf "                                 => Load access fault\n"
                    end
                    if $rv_scause_EC == 6
                        printf "                                 => Store/AMO address misaligned\n"
                    end
                    if $rv_scause_EC == 7
                        printf "                                 => Store/AMO access fault\n"
                    end
                    if $rv_scause_EC == 8
                        printf "                                 => Environment call\n"
                    end
                    if $rv_scause_EC == 12
                        printf "                                 => Instruction page fault\n"
                    end
                    if $rv_scause_EC == 13
                        printf "                                 => Load page fault\n"
                    end
                    if $rv_scause_EC == 15
                        printf "                                 => Store/AMO page fault\n"
                    end
                end
            end
            if $arg0 == $rv_fflags
                printf "    fflags  : 0x%016lX\n", p->mmu->sim->procs[0]->state.fflags
            end
            if $arg0 == $rv_frm
                printf "    frm  : 0x%016lX\n", p->mmu->sim->procs[0]->state.frm
            end
            if $arg0 == $rv_ld_reserv
                printf "    load_reservation  : 0x%016lX\n", p->mmu->sim->procs[0]->state.load_reservation
            end
            if $arg0 == $rv_id
                printf "    id  : 0x%016lX\n", p->mmu->sim->procs[0]->id
            end
            if $arg0 == $rv_isa
                printf "    isa  : 0x%016lX\n", p->mmu->sim->procs[0]->isa
            end
            if $arg0 == $rv_mtime
                printf "    mtime  : 0x%016lX\n", (*(p->sim->clint.get())).mtime
            end
            if $arg0 == $rv_mtimecmp
                printf "    mtimecmp  : 0x%016lX\n", (*(p->sim->clint.get())).mtimecmp[0]
            end
        end
    end
end


set $rv_zero =  0
set $rv_s0   =  8
set $rv_fp   = 32
set $rv_a6   = 16
set $rv_s8   = 24
set $rv_ra   =  1
set $rv_s1   =  9
set $rv_a7   = 17
set $rv_s9   = 25
set $rv_sp   =  2
set $rv_a0   = 10
set $rv_s2   = 18
set $rv_s10  = 26
set $rv_gp   =  3
set $rv_a1   = 11
set $rv_s3   = 19
set $rv_s11  = 27
set $rv_tp   =  4
set $rv_a2   = 12
set $rv_s4   = 20
set $rv_t3   = 28
set $rv_t0   =  5
set $rv_a3   = 13
set $rv_s5   = 21
set $rv_t4   = 29
set $rv_t1   =  6
set $rv_a4   = 14
set $rv_s6   = 22
set $rv_t5   = 30
set $rv_t2   =  7
set $rv_a5   = 15
set $rv_s7   = 23
set $rv_t6   = 31

define rv_reg
    if $argc == 0
        printf "    zero  : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[ 0]
        printf "    s0/fp : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[ 8]
        printf "    a6    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[16]
        printf "    s8    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[24]
        printf "    ra    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[ 1]
        printf "    s1    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[ 9]
        printf "    a7    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[17]
        printf "    s9    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[25]
        printf "    sp    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[ 2]
        printf "    a0    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[10]
        printf "    s2    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[18]
        printf "    s10   : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[26]
        printf "    gp    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[ 3]
        printf "    a1    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[11]
        printf "    s3    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[19]
        printf "    s11   : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[27]
        printf "    tp    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[ 4]
        printf "    a2    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[12]
        printf "    s4    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[20]
        printf "    t3    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[28]
        printf "    t0    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[ 5]
        printf "    a3    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[13]
        printf "    s5    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[21]
        printf "    t4    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[29]
        printf "    t1    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[ 6]
        printf "    a4    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[14]
        printf "    s6    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[22]
        printf "    t5    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[30]
        printf "    t2    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[ 7]
        printf "    a5    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[15]
        printf "    s7    : 0x%016lX",   p->mmu->sim->procs[0]->state.XPR.data[23]
        printf "    t6    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[31]
    else
        if $argc == 1
            if $arg0 == $rv_zero
                printf "    zero  : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[ 0]
            end
            if $arg0 == $rv_s0
                printf "    s0/fp : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[ 8]
            end
            if $arg0 == $rv_fp
                printf "    s0/fp : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[ 8]
            end
            if $arg0 == $rv_a6
                printf "    a6    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[16]
            end
            if $arg0 == $rv_s8
                printf "    s8    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[24]
            end
            if $arg0 == $rv_ra
                printf "    ra    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[ 1]
            end
            if $arg0 == $rv_s1
                printf "    s1    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[ 9]
            end
            if $arg0 == $rv_a7
                printf "    a7    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[17]
            end
            if $arg0 == $rv_s9
                printf "    s9    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[25]
            end
            if $arg0 == $rv_sp
                printf "    sp    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[ 2]
            end
            if $arg0 == $rv_a0
                printf "    a0    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[10]
            end
            if $arg0 == $rv_s2
                printf "    s2    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[18]
            end
            if $arg0 == $rv_s10
                printf "    s10   : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[26]
            end
            if $arg0 == $rv_gp
                printf "    gp    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[ 3]
            end
            if $arg0 == $rv_a1
                printf "    a1    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[11]
            end
            if $arg0 == $rv_s3
                printf "    s3    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[19]
            end
            if $arg0 == $rv_s11
                printf "    s11   : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[27]
            end
            if $arg0 == $rv_tp
                printf "    tp    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[ 4]
            end
            if $arg0 == $rv_a2
                printf "    a2    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[12]
            end
            if $arg0 == $rv_s4
                printf "    s4    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[20]
            end
            if $arg0 == $rv_t3
                printf "    t3    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[28]
            end
            if $arg0 == $rv_t0
                printf "    t0    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[ 5]
            end
            if $arg0 == $rv_a3
                printf "    a3    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[13]
            end
            if $arg0 == $rv_s5
                printf "    s5    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[21]
            end
            if $arg0 == $rv_t4
                printf "    t4    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[29]
            end
            if $arg0 == $rv_t1
                printf "    t1    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[ 6]
            end
            if $arg0 == $rv_a4
                printf "    a4    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[14]
            end
            if $arg0 == $rv_s6
                printf "    s6    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[22]
            end
            if $arg0 == $rv_t5
                printf "    t5    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[30]
            end
            if $arg0 == $rv_t2
                printf "    t2    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[ 7]
            end
            if $arg0 == $rv_a5
                printf "    a5    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[15]
            end
            if $arg0 == $rv_s7
                printf "    s7    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[23]
            end
            if $arg0 == $rv_t6
                printf "    t6    : 0x%016lX\n", p->mmu->sim->procs[0]->state.XPR.data[31]
            end
        else
            p "usage: rv_regs or rv_regs regname"
        end
    end
end

define rv_mem
    if $argc != 2
        p "usage: rv_mem address bytes"
    else
        set $rv_mem_address_start = $arg0
        set $rv_mem_num_bytes = $arg1
        set $rv_mem_address_end = $rv_mem_address_start + $rv_mem_num_bytes - 1
        set $rv_mem_error = 0
        set $rv_mem_offset = 0
        set $rv_mem_total = (unsigned long)0
        
        if $rv_mem_num_bytes < 1
            set $rv_mem_error = 1
            set $rv_string_buffer_0 = "Error: Number of bytes must be positive integer\n\n"
        end
        
        if $rv_mem_num_bytes > 8
            set $rv_mem_error = 1
            set $rv_string_buffer_0 = "Error: Number of bytes must be <= 8\n\n"
        end
        
        if $rv_mem_error == 1
            p $rv_string_buffer_0
        else
            if $rv_mem_address_start >= 0x1000 && $rv_mem_address_start < 0x2000
                if $rv_mem_address_end < $rv_mem_address_start || $rv_mem_address_end >= 0x2000
                    set $rv_mem_error = 1
                    set $rv_string_buffer_0 = "Error: Invalid end address\n\n"
                else
                    set $rv_string_buffer_1 = "(*(p->mmu->sim->boot_rom)).data"
                    set $rv_mem_offset = $rv_mem_address_end - 0x1000
                end
            else
                if $rv_mem_address_start >= 0x80000000 && $rv_mem_address_start < 0xA0000000
                    if $rv_mem_address_end < $rv_mem_address_start || $rv_mem_address_end >= 0xA0000000
                        set $rv_mem_error = 1
                        set $rv_string_buffer_0 = "Error: Invalid end address\n\n"
                    else
                        set $rv_string_buffer_1 = "(p->mmu->sim->mems[0].second).data"
                        set $rv_mem_offset = $rv_mem_address_end - 0x80000000
                    end
                else
                    set $rv_mem_error = 1
                    set $rv_string_buffer_0 = "Error: Address not in valid code memory\n\n"
                end
            end
            
            if $rv_mem_error == 1
                p $rv_string_buffer_0
            else
                eval "set $rv_mem_total = (unsigned long)((unsigned char)%s[%i])", $rv_string_buffer_1, $rv_mem_offset--
                while --$rv_mem_num_bytes > 0
                    set $rv_mem_total = $rv_mem_total << 8
                    eval "set $rv_mem_total = $rv_mem_total += (unsigned long)((unsigned char)%s[%i])", $rv_string_buffer_1, $rv_mem_offset--
                end
                printf "\n"
                p/x $rv_mem_total
                printf "\n"
            end
        end
    end
end

define rv_dis
    if $argc == 0
        p "need at least 1 argument"
    else
        set $rv_dis_num_bytes = $arg0
        set $rv_dis_address_start = pc
        set $rv_dis_address_end = pc + $rv_dis_num_bytes - 1
        set $rv_dis_error = 0
        set $rv_dis_offset = 0
        set $rv_dis_byte = 0
        
        if $rv_dis_num_bytes < 1
            set $rv_dis_error = 1
            set $rv_string_buffer_0 = "Error: Number of bytes must be positive integer\n\n"
        end
        
        if $rv_dis_num_bytes > 64
            set $rv_dis_error = 1
            set $rv_string_buffer_0 = "Error: Number of bytes must be <= 64\n\n"
        end
        
        if $rv_dis_error == 1
            p $rv_string_buffer_0
        else
            if $rv_dis_address_start >= 0x1000 && $rv_dis_address_start < 0x2000
                if $rv_dis_address_end < $rv_dis_address_start || $rv_dis_address_end >= 0x2000
                    set $rv_dis_error = 1
                    set $rv_string_buffer_0 = "Error: Invalid end address\n\n"
                else
                    set $rv_string_buffer_1 = "(*(p->mmu->sim->boot_rom)).data"
                    set $rv_dis_offset = $rv_dis_address_start - 0x1000
                end
            else
                if $rv_dis_address_start >= 0x80000000 && $rv_dis_address_start < 0xA0000000
                    if $rv_dis_address_end < $rv_dis_address_start || $rv_dis_address_end >= 0xA0000000
                        set $rv_dis_error = 1
                        set $rv_string_buffer_0 = "Error: Invalid end address\n\n"
                    else
                        set $rv_string_buffer_1 = "(p->mmu->sim->mems[0].second).data"
                        set $rv_dis_offset = $rv_dis_address_start - 0x80000000
                    end
                else
                    set $rv_dis_error = 1
                    set $rv_string_buffer_0 = "Error: Address not in valid code memory\n\n"
                end
            end
            
            if $rv_dis_error == 1
                p $rv_string_buffer_0
            else
                set $rv_string_buffer_0 = "shell /home/babypaw/riscv/gdb/riscv_assemble.pl"
                while $rv_dis_num_bytes-- > 0
                    eval "set $rv_dis_byte = %s[%i]", $rv_string_buffer_1, $rv_dis_offset++
                    eval "set $rv_string_buffer_0 = \"%s %i\"", $rv_string_buffer_0, $rv_dis_byte
                end
                printf "\npc -> 0x%X\n\n", pc
                eval "%s", $rv_string_buffer_0
                printf "\n"
            end
        end
    end
end

define rv_step
    set $rv_step_break = 0
    if $argc == 1
        set $rv_step_break = 1
        set $rv_step_address = $arg0
    end
    set breakpoint pending on
    set logging overwrite on
    set logging on
    set logging redirect on
    set pagination off
    b add.cc:15
        commands
        rv_dis 16
        end
    b addi.cc:15
        commands
        rv_dis 16
        end
    b addiw.cc:15
        commands
        rv_dis 16
        end
    b addw.cc:15
        commands
        rv_dis 16
        end
    b amoadd_d.cc:15
        commands
        rv_dis 16
        end
    b amoadd_w.cc:15
        commands
        rv_dis 16
        end
    b amoand_d.cc:15
        commands
        rv_dis 16
        end
    b amoand_w.cc:15
        commands
        rv_dis 16
        end
    b amomax_d.cc:15
        commands
        rv_dis 16
        end
    b amomaxu_d.cc:15
        commands
        rv_dis 16
        end
    b amomaxu_w.cc:15
        commands
        rv_dis 16
        end
    b amomax_w.cc:15
        commands
        rv_dis 16
        end
    b amomin_d.cc:15
        commands
        rv_dis 16
        end
    b amominu_d.cc:15
        commands
        rv_dis 16
        end
    b amominu_w.cc:15
        commands
        rv_dis 16
        end
    b amomin_w.cc:15
        commands
        rv_dis 16
        end
    b amoor_d.cc:15
        commands
        rv_dis 16
        end
    b amoor_w.cc:15
        commands
        rv_dis 16
        end
    b amoswap_d.cc:15
        commands
        rv_dis 16
        end
    b amoswap_w.cc:15
        commands
        rv_dis 16
        end
    b amoxor_d.cc:15
        commands
        rv_dis 16
        end
    b amoxor_w.cc:15
        commands
        rv_dis 16
        end
    b and.cc:15
        commands
        rv_dis 16
        end
    b andi.cc:15
        commands
        rv_dis 16
        end
    b auipc.cc:15
        commands
        rv_dis 16
        end
    b beq.cc:15
        commands
        rv_dis 16
        end
    b bge.cc:15
        commands
        rv_dis 16
        end
    b bgeu.cc:15
        commands
        rv_dis 16
        end
    b blt.cc:15
        commands
        rv_dis 16
        end
    b bltu.cc:15
        commands
        rv_dis 16
        end
    b bne.cc:15
        commands
        rv_dis 16
        end
    b c_add.cc:15
        commands
        rv_dis 16
        end
    b c_addi4spn.cc:15
        commands
        rv_dis 16
        end
    b c_addi.cc:15
        commands
        rv_dis 16
        end
    b c_addw.cc:15
        commands
        rv_dis 16
        end
    b c_and.cc:15
        commands
        rv_dis 16
        end
    b c_andi.cc:15
        commands
        rv_dis 16
        end
    b c_beqz.cc:15
        commands
        rv_dis 16
        end
    b c_bnez.cc:15
        commands
        rv_dis 16
        end
    b c_ebreak.cc:15
        commands
        rv_dis 16
        end
    b c_fld.cc:15
        commands
        rv_dis 16
        end
    b c_fldsp.cc:15
        commands
        rv_dis 16
        end
    b c_flw.cc:15
        commands
        rv_dis 16
        end
    b c_flwsp.cc:15
        commands
        rv_dis 16
        end
    b c_fsd.cc:15
        commands
        rv_dis 16
        end
    b c_fsdsp.cc:15
        commands
        rv_dis 16
        end
    b c_fsw.cc:15
        commands
        rv_dis 16
        end
    b c_fswsp.cc:15
        commands
        rv_dis 16
        end
    b c_jal.cc:15
        commands
        rv_dis 16
        end
    b c_jalr.cc:15
        commands
        rv_dis 16
        end
    b c_j.cc:15
        commands
        rv_dis 16
        end
    b c_jr.cc:15
        commands
        rv_dis 16
        end
    b c_li.cc:15
        commands
        rv_dis 16
        end
    b c_lui.cc:15
        commands
        rv_dis 16
        end
    b c_lw.cc:15
        commands
        rv_dis 16
        end
    b c_lwsp.cc:15
        commands
        rv_dis 16
        end
    b c_mv.cc:15
        commands
        rv_dis 16
        end
    b c_or.cc:15
        commands
        rv_dis 16
        end
    b c_slli.cc:15
        commands
        rv_dis 16
        end
    b c_srai.cc:15
        commands
        rv_dis 16
        end
    b c_srli.cc:15
        commands
        rv_dis 16
        end
    b csrrc.cc:15
        commands
        rv_dis 16
        end
    b csrrci.cc:15
        commands
        rv_dis 16
        end
    b csrrs.cc:15
        commands
        rv_dis 16
        end
    b csrrsi.cc:15
        commands
        rv_dis 16
        end
    b csrrw.cc:15
        commands
        rv_dis 16
        end
    b csrrwi.cc:15
        commands
        rv_dis 16
        end
    b c_sub.cc:15
        commands
        rv_dis 16
        end
    b c_subw.cc:15
        commands
        rv_dis 16
        end
    b c_sw.cc:15
        commands
        rv_dis 16
        end
    b c_swsp.cc:15
        commands
        rv_dis 16
        end
    b c_xor.cc:15
        commands
        rv_dis 16
        end
    b div.cc:15
        commands
        rv_dis 16
        end
    b divu.cc:15
        commands
        rv_dis 16
        end
    b divuw.cc:15
        commands
        rv_dis 16
        end
    b divw.cc:15
        commands
        rv_dis 16
        end
    b dret.cc:15
        commands
        rv_dis 16
        end
    b ebreak.cc:15
        commands
        rv_dis 16
        end
    b ecall.cc:15
        commands
        rv_dis 16
        end
    b fadd_d.cc:15
        commands
        rv_dis 16
        end
    b fadd_s.cc:15
        commands
        rv_dis 16
        end
    b fclass_d.cc:15
        commands
        rv_dis 16
        end
    b fclass_s.cc:15
        commands
        rv_dis 16
        end
    b fcvt_d_l.cc:15
        commands
        rv_dis 16
        end
    b fcvt_d_lu.cc:15
        commands
        rv_dis 16
        end
    b fcvt_d_s.cc:15
        commands
        rv_dis 16
        end
    b fcvt_d_w.cc:15
        commands
        rv_dis 16
        end
    b fcvt_d_wu.cc:15
        commands
        rv_dis 16
        end
    b fcvt_l_d.cc:15
        commands
        rv_dis 16
        end
    b fcvt_l_s.cc:15
        commands
        rv_dis 16
        end
    b fcvt_lu_d.cc:15
        commands
        rv_dis 16
        end
    b fcvt_lu_s.cc:15
        commands
        rv_dis 16
        end
    b fcvt_s_d.cc:15
        commands
        rv_dis 16
        end
    b fcvt_s_l.cc:15
        commands
        rv_dis 16
        end
    b fcvt_s_lu.cc:15
        commands
        rv_dis 16
        end
    b fcvt_s_w.cc:15
        commands
        rv_dis 16
        end
    b fcvt_s_wu.cc:15
        commands
        rv_dis 16
        end
    b fcvt_w_d.cc:15
        commands
        rv_dis 16
        end
    b fcvt_w_s.cc:15
        commands
        rv_dis 16
        end
    b fcvt_wu_d.cc:15
        commands
        rv_dis 16
        end
    b fcvt_wu_s.cc:15
        commands
        rv_dis 16
        end
    b fdiv_d.cc:15
        commands
        rv_dis 16
        end
    b fdiv_s.cc:15
        commands
        rv_dis 16
        end
    b fence.cc:15
        commands
        rv_dis 16
        end
    b fence_i.cc:15
        commands
        rv_dis 16
        end
    b feq_d.cc:15
        commands
        rv_dis 16
        end
    b feq_s.cc:15
        commands
        rv_dis 16
        end
    b fld.cc:15
        commands
        rv_dis 16
        end
    b fle_d.cc:15
        commands
        rv_dis 16
        end
    b fle_s.cc:15
        commands
        rv_dis 16
        end
    b flt_d.cc:15
        commands
        rv_dis 16
        end
    b flt_s.cc:15
        commands
        rv_dis 16
        end
    b flw.cc:15
        commands
        rv_dis 16
        end
    b fmadd_d.cc:15
        commands
        rv_dis 16
        end
    b fmadd_s.cc:15
        commands
        rv_dis 16
        end
    b fmax_d.cc:15
        commands
        rv_dis 16
        end
    b fmax_s.cc:15
        commands
        rv_dis 16
        end
    b fmin_d.cc:15
        commands
        rv_dis 16
        end
    b fmin_s.cc:15
        commands
        rv_dis 16
        end
    b fmsub_d.cc:15
        commands
        rv_dis 16
        end
    b fmsub_s.cc:15
        commands
        rv_dis 16
        end
    b fmul_d.cc:15
        commands
        rv_dis 16
        end
    b fmul_s.cc:15
        commands
        rv_dis 16
        end
    b fmv_d_x.cc:15
        commands
        rv_dis 16
        end
    b fmv_w_x.cc:15
        commands
        rv_dis 16
        end
    b fmv_x_d.cc:15
        commands
        rv_dis 16
        end
    b fmv_x_w.cc:15
        commands
        rv_dis 16
        end
    b fnmadd_d.cc:15
        commands
        rv_dis 16
        end
    b fnmadd_s.cc:15
        commands
        rv_dis 16
        end
    b fnmsub_d.cc:15
        commands
        rv_dis 16
        end
    b fnmsub_s.cc:15
        commands
        rv_dis 16
        end
    b fsd.cc:15
        commands
        rv_dis 16
        end
    b fsgnj_d.cc:15
        commands
        rv_dis 16
        end
    b fsgnjn_d.cc:15
        commands
        rv_dis 16
        end
    b fsgnjn_s.cc:15
        commands
        rv_dis 16
        end
    b fsgnj_s.cc:15
        commands
        rv_dis 16
        end
    b fsgnjx_d.cc:15
        commands
        rv_dis 16
        end
    b fsgnjx_s.cc:15
        commands
        rv_dis 16
        end
    b fsqrt_d.cc:15
        commands
        rv_dis 16
        end
    b fsqrt_s.cc:15
        commands
        rv_dis 16
        end
    b fsub_d.cc:15
        commands
        rv_dis 16
        end
    b fsub_s.cc:15
        commands
        rv_dis 16
        end
    b fsw.cc:15
        commands
        rv_dis 16
        end
    b jal.cc:15
        commands
        rv_dis 16
        end
    b jalr.cc:15
        commands
        rv_dis 16
        end
    b lb.cc:15
        commands
        rv_dis 16
        end
    b lbu.cc:15
        commands
        rv_dis 16
        end
    b ld.cc:15
        commands
        rv_dis 16
        end
    b lh.cc:15
        commands
        rv_dis 16
        end
    b lhu.cc:15
        commands
        rv_dis 16
        end
    b lr_d.cc:15
        commands
        rv_dis 16
        end
    b lr_w.cc:15
        commands
        rv_dis 16
        end
    b lui.cc:15
        commands
        rv_dis 16
        end
    b lw.cc:15
        commands
        rv_dis 16
        end
    b lwu.cc:15
        commands
        rv_dis 16
        end
    b mret.cc:15
        commands
        rv_dis 16
        end
    b mul.cc:15
        commands
        rv_dis 16
        end
    b mulh.cc:15
        commands
        rv_dis 16
        end
    b mulhsu.cc:15
        commands
        rv_dis 16
        end
    b mulhu.cc:15
        commands
        rv_dis 16
        end
    b mulw.cc:15
        commands
        rv_dis 16
        end
    b or.cc:15
        commands
        rv_dis 16
        end
    b ori.cc:15
        commands
        rv_dis 16
        end
    b rem.cc:15
        commands
        rv_dis 16
        end
    b remu.cc:15
        commands
        rv_dis 16
        end
    b remuw.cc:15
        commands
        rv_dis 16
        end
    b remw.cc:15
        commands
        rv_dis 16
        end
    b sb.cc:15
        commands
        rv_dis 16
        end
    b sc_d.cc:15
        commands
        rv_dis 16
        end
    b sc_w.cc:15
        commands
        rv_dis 16
        end
    b sd.cc:15
        commands
        rv_dis 16
        end
    b sfence_vma.cc:15
        commands
        rv_dis 16
        end
    b sh.cc:15
        commands
        rv_dis 16
        end
    b sll.cc:15
        commands
        rv_dis 16
        end
    b slli.cc:15
        commands
        rv_dis 16
        end
    b slliw.cc:15
        commands
        rv_dis 16
        end
    b sllw.cc:15
        commands
        rv_dis 16
        end
    b slt.cc:15
        commands
        rv_dis 16
        end
    b slti.cc:15
        commands
        rv_dis 16
        end
    b sltiu.cc:15
        commands
        rv_dis 16
        end
    b sltu.cc:15
        commands
        rv_dis 16
        end
    b sra.cc:15
        commands
        rv_dis 16
        end
    b srai.cc:15
        commands
        rv_dis 16
        end
    b sraiw.cc:15
        commands
        rv_dis 16
        end
    b sraw.cc:15
        commands
        rv_dis 16
        end
    b sret.cc:15
        commands
        rv_dis 16
        end
    b srl.cc:15
        commands
        rv_dis 16
        end
    b srli.cc:15
        commands
        rv_dis 16
        end
    b srliw.cc:15
        commands
        rv_dis 16
        end
    b srlw.cc:15
        commands
        rv_dis 16
        end
    b sub.cc:15
        commands
        rv_dis 16
        end
    b subw.cc:15
        commands
        rv_dis 16
        end
    b sw.cc:15
        commands
        rv_dis 16
        end
    b wfi.cc:15
        commands
        rv_dis 16
        end
    b xor.cc:15
        commands
        rv_dis 16
        end
    b xori.cc:15
        commands
        rv_dis 16
        end
    set logging off
    set pagination on
end