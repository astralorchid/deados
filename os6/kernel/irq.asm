irq:
    .driver:
        cli
            mov al, 0x36 ;enable pit
            out 0x43, al

            mov al, 0xFF ;freq
            out 0x40, al
            mov al, 0xFF
            out 0x40, al

            ;set kernel ivt
            call irq.MAP_KERNEL

            mov bl, [IRQ_MASKS]
            call .ENABLE_IRQx

            mov bl, [IRQ_MASKS+1]
            call .ENABLE_IRQx

            mov al, [IRQ_FLAGS] ;enable pic
            out 0xa1, al
            out 0x21, al
        sti
    ret

    ;mov ax, handler
    ;mov bx, 0x0100 (interrupt hex # ivt offset)


    .MAP_KERNEL:
        mov ax, word .irq0
        mov bx, word irq0_ivt
        call irq.MAP_IRQx

        mov ax, word .irq1
        mov bx, word irq1_ivt
        call irq.MAP_IRQx
    ret

    .printEnabledIRQ:
        in al, 0x21
        xor ah, ah
        call hprep
        call hprint
    ret

    .irq0:
        pusha
            ;scheduler
            ;maybe next year

            mov al, 0x20
            out PIC0, al  
        popa
    iret

    .map_irq0:
        mov [ds:irq0_ivt], word .irq0
        mov [ds:irq0_ivt+2], word 0x00
    ret

    ;mov ax, word .irq#
    ;mov bx, word irq # (ivt offset based)
    .MAP_IRQx:
        mov [ds:bx], word ax
        mov [ds:bx+2], word ds
    ret

    .ENABLE_IRQx:
        push ax
        push bx

        mov al, [IRQ_FLAGS]
        xor al, bl

        mov [IRQ_FLAGS], al

        pop bx
        pop ax
    ret

    ;mov bl, IRQx_DISABLE_MASK
    .DISABLE_IRQx:
        push ax
        push bx

        mov al, [IRQ_FLAGS]
        or al, bl ;BOOL!
        
        mov [IRQ_FLAGS], al

        pop bx
        pop ax
    ret

    .irq1:
        push ax

        in al, 01100000b

        test al, 10000000b
        jnz .inputEnd
        
        push ax
        call SCANCODE_TO_ASCII
        call charInt
        pop ax
        mov ah, 0

        call hprep
        call hprint
        call newLine

        .inputEnd:
            mov al, 01100001b
            out PIC0, al
        pop ax
    iret

    .map_irq1:
        mov [ds:irq1_ivt], word .irq1
        mov [ds:irq1_ivt+2], word 0x00
    ret

%include '../keymap.asm'
irq0_ivt equ 0x0020
irq1_ivt equ 0x0024

IRQ_MASKS:
    db 00000001b
    db 00000010b

IRQ_FLAGS:
    db 01111111b

PIC0 equ 0x20 ;also 
PIC1 equ 0xa0 ;command ports