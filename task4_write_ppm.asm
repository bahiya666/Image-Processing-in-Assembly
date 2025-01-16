; ==========================
; Group member 01: Lekisha_Chetty_21554995
; Group member 02: Tishana_Reddy_19072211
; Group member 03: Thuwayba_Dawood_22622668
; Group member 04: Bahiya_Hoosen_22598546
; ==========================

section .data
    struc PixelNode
        .p_red resb 1        ; Red
        .p_green resb 1      ; Green
        .p_blue resb 1       ; Blue 
        .p_cdf resb 1        ; CdfValue 
        align 8              ; align to a multiple of 8 for pointers
        .p_up resq 1         ; up (pointer to PixelNode struct)
        .p_down resq 1       ; down (pointer to PixelNode struct)
        .p_left resq 1       ; left (pointer to PixelNode struct)
        .p_right resq 1      ; right (pointer to PixelNode struct)
    endstruc

    magic db "P6", 0xA
    magic_len equ $ - magic
    max_colour db "255", 0xA
    max_colour_len equ $ - max_colour
    space db " "
    space_len equ $ - space
    newline db 0xA
    newline_len equ $ - newline

section .bss
    width_buffer resb 8        ; buffer to store the resulting string
    height_buffer resb 8       ; buffer to store the resulting string
    pixel_buffer resb 3275520   ; buffer to store pixel data

section .text
    global writePPM

writePPM:
    push rbp
    mov rbp, rsp

    ; rdi has output file name. rsi has head
    mov r12, rsi        ; save head in r12

    ; Open the file
    mov rax, 2          ; syscall number for open
    mov rdi, rdi        ; output file name
    mov rsi, 0x41       ; O_CREAT | O_WRONLY
    mov rdx, 0644       ; mode
    syscall             ; open the file
    mov r13, rax        ; save the file descriptor in r13

    ; Write the magic number
    mov rax, 1          ; syscall number for write
    mov rdi, r13        ; file descriptor
    lea rsi, [magic]    ; buffer to write
    mov rdx, magic_len  ; number of bytes to write
    syscall             ; write the magic number

    ; Get width and height 
    mov r8, r12         ; row pointer
    mov r11, 0          ; counter for height

.outer_loop:
    cmp r8, 0
    je .convertNumbers
    mov r9, r8          ; column pointer
    mov r10, 0          ; counter for width

.inner_loop:
    cmp r9, 0
    je .next_row
    inc r10
    mov r9, [r9 + PixelNode.p_right]
    jmp .inner_loop

.next_row:
    inc r11
    mov r8, [r8 + PixelNode.p_down]
    jmp .outer_loop

.convertNumbers:
    mov r15, r10
    imul r15, r11
    imul r15, 3         ; 3 bytes per pixel

    ; Convert width to string
    lea r14, [width_buffer + 8]
    mov rax, r10
    mov rbx, r14        ; store the buffer
    call intToStrWidth  ; Convert integer to string for width

.writeWidth:
    mov rax, 1          ; syscall number for write
    mov rdi, r13        ; file descriptor
    lea rsi, [width_buffer]
    sub rdx, rbx        ; calculate the length
    syscall             ; write width

    ; Write space 
    mov rax, 1          ; syscall number for write
    mov rdi, r13        ; file descriptor
    lea rsi, [space]
    mov rdx, space_len
    syscall             ; write space

    xor rdx, rdx
    xor r14, r14
    xor rbx, rbx
    lea r14, [height_buffer + 8]
    mov rax, r11
    mov rbx, r14        ; store the buffer
    call intToStrHeight ; Convert integer to string for height

.writeHeight:
    mov rax, 1          ; syscall number for write
    mov rdi, r13        ; file descriptor
    lea rsi, [height_buffer]
    sub rdx, rbx        ; calculate the length
    syscall             ; write height

    ; Write newline after height
    mov rax, 1          ; syscall number for write
    mov rdi, r13        ; file descriptor
    lea rsi, [newline]
    mov rdx, newline_len
    syscall             ; write newline

    ; Write max colour
    mov rax, 1          ; syscall number for write
    mov rdi, r13        ; file descriptor
    lea rsi, [max_colour] ; buffer to write
    mov rdx, max_colour_len ; number of bytes to write
    syscall             ; write the max colour value

    ; Now for the pixels 
    xor r8, r8
    xor r9, r9
    xor r14, r14        ; to store all the pixel data 
    xor rbx, rbx        ; to store the byte counter

    mov r8, r12         ; row pointer
    lea r14, [pixel_buffer]

.outerLoop:
    cmp r8, 0
    je .collectedPixels
    mov r9, r8          ; column pointer

.innerLoop:
    cmp r9, 0
    je .nextRow
    movzx r10, byte [r9 + PixelNode.p_red]
    mov [r14 + rbx], r10
    inc rbx
    movzx r10, byte [r9 + PixelNode.p_green]
    mov [r14 + rbx], r10
    inc rbx
    movzx r10, byte [r9 + PixelNode.p_blue]
    mov [r14 + rbx], r10
    inc rbx
    mov r9, [r9 + PixelNode.p_right]
    jmp .innerLoop

.nextRow:
    mov r8, [r8 + PixelNode.p_down]
    jmp .outerLoop

.collectedPixels:
    ; Write pixel data to file
    mov rax, 1          ; syscall number for write
    mov rdi, r13        ; file descriptor
    lea rsi, [pixel_buffer]
    mov rdx, rbx        ; number of bytes to write (number of pixels * 3)
    syscall             ; write pixel data

    ; Close the file
    mov rax, 3          ; syscall number for close
    mov rdi, r13        ; file descriptor
    syscall             ; close the file

    pop rbp
    ret

; Convert integer to string for width
intToStrWidth:
    mov rax, r10          ; get the width
    mov rbx, r14          ; buffer pointer
    xor rdx, rdx          ; clear rdx

.intWidthLoop:
    xor rdx, rdx
    mov rcx, 10
    div rcx              ; divide rax by 10
    add dl, '0'          ; convert remainder to ASCII
    dec rbx              ; move buffer pointer back
    mov [rbx], dl        ; store the ASCII value
    test rax, rax
    jnz .intWidthLoop

    mov rbx, r14         ; reset buffer pointer
    ret

; Convert integer to string for height
intToStrHeight:
    mov rax, r11          ; get the height
    mov rbx, r14          ; buffer pointer
    xor rdx, rdx          ; clear rdx

.intHeightLoop:
    xor rdx, rdx
    mov rcx, 10
    div rcx              ; divide rax by 10
    add dl, '0'          ; convert remainder to ASCII
    dec rbx              ; move buffer pointer back
    mov [rbx], dl        ; store the ASCII value
    test rax, rax
    jnz .intHeightLoop

    mov rbx, r14         ; reset buffer pointer
    ret
