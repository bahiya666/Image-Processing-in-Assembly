; ==========================
; Group member 01: Lekisha_Chetty_21554995
; Group member 02: Tishana_Reddy_19072211
; Group member 03: Thuwayba_Dawood_22622668
; Group member 04: Bahiya_Hoosen_22598546
; ==========================

section .data  
    c_0_299 dq 0.299
    c_0_587 dq 0.587
    c_0_114 dq 0.114
    struc PixelNode
        .p_red resb 1 ; Red
        .p_green resb 1 ; Green
        .p_blue resb 1 ; Blue 
        .p_cdf resb 1 ; CdfValue 
        align 8 ; align to a multiple of 8 for pointers
        .p_up resq 1 ; up (pointer to PixelNode struct)
        .p_down resq 1 ; down (pointer to PixelNode struct)
        .p_left resq 1 ; left (pointer to PixelNode struct)
        .p_right resq 1 ; right (pointer to PixelNode struct)
    endstruc

section .bss
    histogram resq 256 ; histogram array. 
    cumulative_histogram resq 256 ; cumulative histogram array

section .text
    global computeCDFValues

computeCDFValues:
    push rbp
    mov rbp, rsp

    xor r12, r12
    xor r13, r13
    xor r8, r8
    xor r9, r9
    
    lea r12, [histogram]
    mov rcx, 0                   ; counter
    mov r13, rdi                ; head is passed to function. now stored in r13
    mov r8, r13                 ; r8 is a copy of r13

    .initialize_loop:
        cmp rcx, 256
        jz .compute
        mov rdx, [r12 + rcx]
        mov rdx, 0
        mov [r12 + rcx], rdx
        inc rcx
        jmp .initialize_loop

    .compute:
        ;mov r15, [r12 + 236]
        mov rcx, 0                  ; counter for height
        mov rdi, 0
        ; r8 is row pointer
        .outer_loop:
            cmp r8, 0           ; check if row is null
            je .endCompute
            mov r9, r8           ; r9 is column pointer
            mov r10, 0          ; counter for width
            .inner_loop:
                cmp r9, 0      ; check if column is null
                je .next_row
                xorps xmm0, xmm0        ; clear xmm0. will store gray value

                movzx rax, byte [r9 + PixelNode.p_red] ; load red value
                cvtsi2sd xmm0, rax     ; convert to double precision
                mulsd xmm0, qword [c_0_299] ; multiply by 0.299

                movzx rax, byte [r9 + PixelNode.p_green] ; load green value
                xorps xmm1, xmm1        ; clear xmm1
                cvtsi2sd xmm1, rax     ; convert to double precision
                mulsd xmm1, qword [c_0_587] ; multiply by 0.587
                addsd xmm0, xmm1       ; add to xmm0

                movzx rax, byte [r9 + PixelNode.p_blue] ; load blue value
                xorps xmm1, xmm1        ; clear xmm1
                cvtsi2sd xmm1, rax     ; convert to double precision
                mulsd xmm1, qword [c_0_114] ; multiply by 0.114
                addsd xmm0, xmm1       ; add to xmm0

                ; convert to integer
                cvttsd2si rax, xmm0    ; convert xmm0 to integer and store in rax
                cmp rax, 255
                jle .storeGray
                mov rax, 255

                .storeGray:
                mov byte [r9 + PixelNode.p_cdf], al ; store the cdf value in the node. line 82
                movzx rdx, al ; zero-extend al to rdx (rdx now contains the index)
                xor rax, rax ; clear rax
                mov rax, [r12 + rdx*8] ; load the histogram value at index rdx
                inc rax ; increment the histogram value
                mov [r12 + rdx*8], rax ; store the updated histogram value
                mov r15, [r12 + rdx*8] ; load the updated histogram value to debug (hopefully)
                mov r9, [r9 + PixelNode.p_right] ; move to the next column
                inc r10
                inc rdi
                jmp .inner_loop

            .next_row:
                mov r8, [r8 + PixelNode.p_down] ; move to the next row
                inc rcx
                jmp .outer_loop

    .endCompute:
        ; r12 has histogram. r13 has head. r14 has cumulative_histogram. rcx has height. r10 has width. 
        ; r15 is freeee
        xor r15, r15
        lea r15, [cumulative_histogram]
        xor r11, r11            ; to store cumulative sum
        xor r8, r8              ; counter
        .cumulative_loop:
            cmp r8, 256
            jz .endCumulative
            xor rax, rax
            mov rax, [r12 + r8*8] ; load histogram value
            add r11, rax        ; add to cumulative sum
            mov [r15 + r8*8], r11 ; store the cumulative sum
            xor r9, r9
            mov r9, [r15 + r8*8] ; load the cumulative sum to debug (hopefully)
            inc r8
            jmp .cumulative_loop

    
    .endCumulative:
            ;mov r9, [r15 + 32]
            ; need to find the minimum cumulative cdf value
            mov r11, 0xFFFFFFFFFFFFFFFF         ; max number...
            xor r8, r8        ; counter
            .find_min:
                cmp r8, 256
                jz .endFindMin
                xor rdx, rdx
                mov rdx, [r12 + r8*8] ; load histogram value
                cmp rdx, 0
                je .next_min
                xor rax, rax
                mov rax, [r15 + r8*8] ; load cumulative sum
                cmp rax, 0
                je .next_min
                cmp rax, r11
                jae .next_min
                mov r11, rax
                .next_min:
                    inc r8
                    jmp .find_min

        .endFindMin:
            ; second pass. rcx has height. r10 has width. r11 has min value
            ; r13 has head. r15 has cumulative histogram 
            mov rdi, [r15 + 255*8]
            xor r8, r8
            mov r8, r13         ; r8 is row pointer
            mov r12, r10 
            imul r12, rcx       ; r12 is total number of pixels
            xor r9, r9
            .outerLoop:
                cmp r8, 0
                je .endSecondPass
                mov r9, r8          ; r9 is column pointer
                .innerLoop:
                    cmp r9, 0
                    je .nextRow
                    xor rax, rax
                    xor rsi, rsi
                    xor r14, r14
                    xor rbx, rbx
                    movzx rsi, byte [r9 + PixelNode.p_cdf] ; load cdf value
                    mov r14, [r15 + rsi*8] ; load cumulative sum
                    sub r14, r11            ; cumulativeHistogram[intensity] - cdfMin
                    mov rbx, r12 
                    sub rbx, r11           ; totalPixels - cdfMin
                    mov rax, r14 
                    imul rax, 255
                    cmp rbx, 0
                    je .divZero
                    cdq
                    idiv rbx            ; (cumulativeHistogram[i] - cdfMin) / (totalPixels - cdfMin)    
                    ;imul rax, 255      ; (cumulativeHistogram[i] - cdfMin) / (totalPixels - cdfMin) * 255
                    cmp rax, 255
                    jle .storeCdf
                    mov rax, 255
                .divZero:
                    mov rax, rsi
                    .storeCdf:
                        mov [r9 + PixelNode.p_cdf], rax ; store the updated cdf value
                        mov r9, [r9 + PixelNode.p_right] ; move to the next column
                        jmp .innerLoop
                .nextRow:
                    mov r8, [r8 + PixelNode.p_down] ; move to the next row
                    jmp .outerLoop
        
        .endSecondPass:
            mov rax, r13
            leave
            ret

            

        