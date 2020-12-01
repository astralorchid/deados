;pdt - program descriptor table
;pdt starts at 0x0000:0x0500

pdt:


.map:
    push es
    mov ax, 0x0000
    mov es, ax

    mov al, 0x00
    mov bx, word PDT_START
    mov di, bx
    mov cx, 0x100
    rep stosb
    ;mov ax, 1; pdt offset
    ;push ax
    cmp [IS_BOCHS], byte 1
    je .BochsDriver

    .RigDriver:

        mov [HEAD0_SECTORS], byte 6
        call .readHead0
        jmp .endDriver

    .BochsDriver:

        mov [HEAD0_SECTORS], byte 4 ;do not change
        call .readHead0
        call .readHeads

    .endDriver:
    pop es
ret

.readHead0:
    xor bh, bh ;clear bh
    mov bl, 1 ;Sector offset
    push bx

    .readLoop:
        mov dh, 0x00 ;head
        mov ah, 0; 0 - head0 check, 1 - all other heads
        
        call [readProgram]
        call .isProgram

        cmp bx, 0
        jz .noProgramHead0

        call .PDTEntry
        call newLine

        .noProgramHead0:

            cmp [PDT_ENTRY], word 0
            jz NoPrograms_Error

            pop ax
            push ax

            call convertPDTEntry
            
            cmp [bx], byte 1 ;funny sector exploit
            jg .contreadLoop

            add al, byte [KERNEL_SIZE]
            mov byte [bx], al ;save start sector
            mov byte [bx+1], ah ;save head
            
            pusha
            call hprep
            call hprint
            call newLine
            popa

            call writeProgramName

        .contreadLoop:
        pop bx
            cmp bl, [HEAD0_SECTORS]
            je .readDone
            inc bl
        push bx
        jmp .readLoop

        .readDone:
    ret

.readHeads:
    mov bh, 1; head
    mov bl, 1; sector
    push bx

    .mainReadLoop:
        mov dh, bh ;head
        mov ah, 1; 0 - head0 check, 1 - all other heads

        call [readProgram]
        call .isProgram

        cmp bx, 0
        jz .noProgramHeads

        call .PDTEntry
        call newLine

        .noProgramHeads:
            cmp [PDT_ENTRY], word 0
            jz NoPrograms_Error

            pop ax
            push ax

            call convertPDTEntry

            cmp [bx], byte 0 ;funny sector exploit
            jnz .contreadLoop2

            mov bx, word [PDT_ENTRY]

            mov byte [bx], al
            mov byte [bx+1], ah ;save head

            pusha
            call hprep
            call hprint
            call newLine
            popa

            call writeProgramName

        .contreadLoop2:
        pop bx
        cmp bl, 4 ;#sectors to read
        jl .incSector
        je .incHead

    .incSector:
        inc bl
        push bx
        jmp .mainReadLoop

    .incHead:
        cmp bh, 1; amount of heads to read
        jl .moveHead
        je .endHead

    .moveHead:
        inc bh ;move head
        mov bl, 1 ;reset sector count
        push bx
        jmp .mainReadLoop

    .endHead:
ret

    .isProgram:
        mov cx, PROGRAM_STR_LEN  
        ;cld           
        mov si, PROGRAM_READ_OFFSET
        mov di, PROGRAM_STR
        rep cmpsb 

        cmp cx, 0
        jz .equ_str 

        mov si, msg_noprogram
        ;call sprint
        ;call newLine
        mov bx, 0
        ret

        .equ_str:
        mov si, msg_hasprogram
        ;call sprint
        ;call newLine
        mov bx, 1
    ret
ret

.PDTEntry:
    mov ax, PDT_OFFSET
    mov bx, PDT_START
    mov cx, 0

    .addPDTOffset:
        cmp cx, [PDT_ENTRY]
        je .addedPDTOffset
        add bx, ax ;bx = start of entry
        inc cx
        jmp .addPDTOffset

    .addedPDTOffset:
        mov al, [PDT_ENTRY]
        inc al
        mov [PDT_ENTRY], al
        mov ax, bx
        call hprep
        call hprint
ret


.print:
pusha
    mov ax, word PDT_OFFSET
    mov bx, word PDT_START
    .printProgramName:
   push bx
   push ax
    .pdtprintLoop:
    push bx
    inc bx
    inc bx

    cmp [bx], byte 0
    jz .nopdtprintLoop

    mov ah, 0x0e
    mov al, byte [bx]
    int 0x10
    inc bx

    pop bx
    inc bx
    jmp .pdtprintLoop
    .nopdtprintLoop:
    mov si, EMPTY_STR
    call sprint
    pop bx
    sub bx, 8 ;dirty
    mov al, [bx]
    mov ah, [bx+1]

    pusha
    call hprep
    call hprint
    popa

    call newLine

    pop ax
    pop bx
    add bx, ax
    cmp [bx], byte 0
    jz .endprint
    jmp .printProgramName
    .endprint:
popa
ret

NoPrograms_Error:
    mov si, [NoproErrorStr]
    call sprint
    jmp $
ret

writeProgramName:
    pusha
    mov si, PROGRAM_READ_OFFSET+PROGRAM_STR_LEN

    push bx
    inc bx
    inc bx
    mov di, bx
    pop bx

    xor cx, cx
    .writePgrmNameByte:
        mov al, [si]
        mov [di], al

        cmp cx, word PROGRAM_NAME_MAXLEN
        je .endName
        inc cx

        cmp [si], byte 0
        je .endName
        inc si
        inc di
        jmp .writePgrmNameByte
    .endName:
        mov [di], byte 0 ;force null term
        push bx
        inc bx
        inc bx
        mov si, bx
        pop bx
        call sprint
        call newLine
    popa
ret

convertPDTEntry:
push ax
    mov al, PDT_OFFSET
    mov bl, [PDT_ENTRY]
    dec bl
    mul bl
    add ax, PDT_START
    mov bx, ax
pop ax
ret

PROGRAM_STR db 'program', 0
PROGRAM_STR_LEN equ $-PROGRAM_STR
msg_hasprogram db 'program found', 0
msg_noprogram db 'program not found', 0
NoproErrorStr db 'PDT Entry Fail: No initial program.', 0
SectorOffset db 1
MAX_SECTORS equ 63
PROGRAM_READ_OFFSET equ 0x1000
HEAD0_SECTORS db 4
IS_BOCHS db 1
PDT_START equ 0x0500
PDT_OFFSET equ 0x0B
PDT_ENTRY db 0
CURRENT_PDT_ENTRY db 0
PROGRAM_NAME_MAXLEN equ 8
EMPTY_STR db '   ', 0