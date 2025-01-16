; ==========================
; Group member 01: Lekisha_Chetty_21554995
; Group member 02: Tishana_Reddy_19072211
; Group member 03: Thuwayba_Dawood_22622668
; Group member 04: Bahiya_Hoosen_22598546
; ==========================

section .bss
    ; Reserve space for uninitialized data
    buffer resb 512              ; Buffer for reading the header
    width resq 1                 ; Width of the image
    height resq 1                ; Height of the image
    max_colour resq 1            ; Max colour value

    ; Buffers for pixel data and pointers
    pixel_buffer resq 1          ; Buffer to store the pixel values
    head resq 1                  ; Head of the linked list
    currRow resq 1               ; Current row
    prevRow resq 1               ; Previous row
    temp resq 1                  ; Temporary pointer
    node resq 1                  ; Temporary node pointer
    pixels resq 1                ; Reserved space for pixel values

section .data
struc PixelNode
    .p_red resb 1                ; Red
    .p_green resb 1              ; Green
    .p_blue resb 1               ; Blue 
    .p_cdf resb 1                ; CdfValue 
    align 8                       ; Align to a multiple of 8 for pointers
    .p_up resq 1                 ; Up (pointer to PixelNode struct)
    .p_down resq 1               ; Down (pointer to PixelNode struct)
    .p_left resq 1               ; Left (pointer to PixelNode struct)
    .p_right resq 1              ; Right (pointer to PixelNode struct)
endstruc

extern malloc
extern free

section .text
    global readPPM

readPPM:
    ; Your code for reading PPM files goes here.
    ; Ensure no labels or code outside of this section


    push rbp
    mov rbp, rsp
    mov rax, 2      ; syscall number for open
    mov rsi, 0     ; read only FLAG
    xor rdx, rdx    ; mode but not important because we are reading in read-only mode anyway
    syscall         ; open the file

    cmp rax, 0
    js .error       ; if rax is less than 0, there was an error opening the file
    mov r12d, eax   ; save the file descriptor in r12
    xor rcx, rcx    ; counter for header size 
    xor r13, r13    ; flag for dimensions vs max colour

    mov rax, 0      ; syscall number for read
    mov rdi, r12    ; file descriptor
    mov rsi, buffer ; buffer to read into
    mov rdx, 512    ; number of bytes to read
    syscall         ; read the header

    cmp rax, 0      ; if rax is 0, we have an error
    je .error

    xor rcx, rcx    ; counter for buffer

    .read_loop:
        cmp byte [buffer + rcx], '#'
        je .comment
        cmp byte [buffer + rcx], 'P'
        je .magic
        cmp byte [buffer + rcx], '0'
        jl .not_digit
        cmp byte [buffer + rcx], '9'
        jg .not_digit

        cmp r13, 0
        je .dimensions
        jmp .max_colour
        
        .not_digit:
            inc rcx
            jmp .read_loop

        .comment: 
            inc rcx
            cmp byte [buffer + rcx], 10
            je .read_loop
            inc rcx
            jmp .comment

        .magic:
            inc rcx
            cmp byte [buffer + rcx], '6'
            jne .error
            inc rcx
            inc rcx
            jmp .read_loop

        .dimensions:
            xor rbx, rbx    ; Clear rbx to store width
            .extract_width:
                movzx r14, byte [buffer + rcx]
                cmp r14, ' '
                je .width_done
                imul rbx, rbx, 10
                sub r14, '0'  ; Convert ASCII to integer
                add rbx, r14
                inc rcx
                jmp .extract_width
            .width_done:
                inc rcx
                mov [width], rbx

            ; Extract height
            xor rbx, rbx    ; Clear rdx to store height
            xor r14, r14   ; Clear r14 to store byte value
            .extract_height:
                movzx r14, byte [buffer + rcx]
                cmp r14, 10
                je .height_done
                imul rbx, rbx, 10
                sub r14, '0'  ; Convert ASCII to integer
                add rbx, r14
                inc rcx
                jmp .extract_height 
            .height_done:
                inc rcx
                mov [height], rbx

        .max_colour:
            xor rbx, rbx    ; Clear rbx to store max colour
            xor r14, r14
            .extract_max_colour:
                movzx r14, byte [buffer + rcx]
                cmp r14, 10
                je .max_colour_done
                imul rbx, rbx, 10
                sub r14, '0'  ; Convert ASCII to integer
                add rbx, r14
                inc rcx
                jmp .extract_max_colour
            .max_colour_done:
                inc rcx
                mov qword [max_colour], rbx
                jmp .header_done


.header_done:
    movzx rbx, byte [buffer + rcx]    ; check if the next character is a newline
    mov rax, 8      ; syscall number for lseek
    mov rdi, r12    ; file descriptor
    mov rsi, rcx   ; offset
    mov rdx, 0      ; SEEK_SET
    syscall         ; move the file pointer to the end of the header

    mov rax, 8      ; syscall number for lseek
    mov rdi, r12    ; file descriptor
    xor rsi, rsi    ; offset 0
    mov rdx, 1      ; SEEK_CUR (get the current file position)
    syscall

    xor r14, r14
    mov r14, [width]
    mov r15, qword [height]
    imul r14, r15     ; r14 has the total number of pixels
    imul r14, r14, 3      ; 3 bytes per pixel so r14 has the total number of bytes to read
    mov rdi, r14
    call malloc
    mov [pixel_buffer], rax

    mov rsi, [pixel_buffer]
    mov rax, 0
    mov rdi, r12
    mov rdx, r14
    syscall             ; read the pixel values


    ; now we loop through the pixel values and create a linked list of PixelNode structs
    mov word [head], 0         ; set head to null for now
    mov r11, [pixel_buffer]
    ;mov [pixel_buffer], rax
    mov al, byte [r11 + 1]
    push r11

    xor r14, r14
    mov r14, [width]
    imul r14, r14, 8

    ; now get the two arrays of pointers to PIxelNode structs 
    mov rdi, r14
    call malloc
    mov [currRow], rax
    mov r12, [currRow]

    mov rdi, r14
    call malloc
    mov qword [prevRow], rax
    mov rbx, [prevRow]

    xor r15, r15            ; for outer loop, height. i
    xor r13, r13            ; for inner loop, width. j
    xor r14, r14 
    pop r11

 .outer_loop:
    cmp r15, [height]
    je .end
    xor r13, r13   ; Reset inner loop counter (j) to 0

    .inner_loop:
        push r11           ; Preserve r11 before modifying
        cmp r13, [width]   ; Compare j with width
        je .next_row

        mov rdi, PixelNode_size   ; size of PixelNode struct
        call malloc               ; Allocate memory for node
        pop r11                   ; Restore r11 after malloc
        mov qword [node], rax      ; Store the newly allocated node

        test rax, rax              ; Check if allocation was successful
        jz .end

        ; Calculate pixel position in the buffer: r8 = (i * width + j) * 3
        xor r10, r10
        mov r10, [width]
        xor rax, rax
        mov rax, r15
        imul rax, r10               ; rax = i * width
        mov r8, rax
        add r8, r13                 ; r8 = i * width + j
        imul r8, r8, 3              ; r8 = (i * width + j) * 3

        ; Populate PixelNode struct with pixel data
        mov rdx, [node]             ; rdx points to PixelNode
        movzx r14, byte [r11 + r8]  ; Red component
        mov byte [rdx + PixelNode.p_red], r14b
        movzx r14, byte [r11 + r8 + 1]  ; Green component
        mov byte [rdx + PixelNode.p_green], r14b
        movzx r14, byte [r11 + r8 + 2]  ; Blue component
        mov byte [rdx + PixelNode.p_blue], r14b
        mov byte [rdx + PixelNode.p_cdf], 0     ; Initialize CDF value

        ; Check if it's the first node (i == 0 && j == 0)
        cmp r13, 0
        jne .not_first
        cmp r15, 0
        jne .not_first
        mov [head], rdx        ; head = node
        xor r9, r9
        mov r9, [head]

    .not_first:
        ; Link node to the left (currRow[j-1]) if j > 0
        cmp r13, 0
        jle .upDown
        mov r9, r13
        dec r9
        imul r9, 8
        mov r10, [r12 + r9]            ; Load address of currRow[j-1] into rax
        mov qword [rdx + PixelNode.p_left], r10     ; node->left = currRow[j-1]
        mov qword [r10 + PixelNode.p_right], rdx    ; currRow[j-1]->right = node

    .upDown:
        ; Link node to the up (prevRow[j]) if i > 0
        cmp r15, 0
        jle .addToCurr
        mov r9, r13
        imul r9, 8
        mov rax, [rbx + r9]            ; Load address of prevRow[j] into rax
        mov qword [rdx + PixelNode.p_up], rax      ; node->up = prevRow[j]
        mov qword [rax + PixelNode.p_down], rdx    ; prevRow[j]->down = node

    .addToCurr:
        ; Add node to currRow[j]
        mov r9, r13
        imul r9, 8
        mov [r12 + r9], rdx         ; currRow[j] = node

        inc r13           ; Increment inner loop counter (j)
        jmp .inner_loop   ; Repeat inner loop

    .next_row:
        mov rax, r12
        mov r12, rbx
        mov rbx, rax


        inc r15                   ; Increment outer loop counter (i)
        jmp .outer_loop           ; Repeat outer loop


    .end:
        mov rax, [head]
        leave
        ret

    .error:
        mov rax, 60     ; syscall number for exit
        mov rdi, 1      ; exit code 1
        syscall