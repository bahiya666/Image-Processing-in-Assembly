; ==========================
; Group member 01: Lekisha_Chetty_21554995
; Group member 02: Tishana_Reddy_19072211
; Group member 03: Thuwayba_Dawood_22622668
; Group member 04: Bahiya_Hoosen_22598546
; ==========================

struc PixelNode
    .Red resb 1              ; 1 byte for Red
    .Green resb 1            ; 1 byte for Green
    .Blue resb 1             ; 1 byte for Blue
    .CdfValue resb 1         ; 1 byte for CdfValue
    .up resq 1               ; 8 bytes for a pointer (up)
    .down resq 1             ; 8 bytes for a pointer (down)
    .left resq 1             ; 8 bytes for a pointer (left)
    .right resq 1            ; 8 bytes for a pointer (right)
endstruc

global applyHistogramEqualisation

; Function to traverse the linked list and apply histogram equalization.
applyHistogramEqualisation:
    push rbp                 ; Save the base pointer
    mov rbp, rsp             ; Set up stack frame
    sub rsp, 16              ; Reserve stack space

    mov rax, rdi             ; Load the head of the 2D linked list into rax

.loop_row:
    cmp rax, 0               ; Check if current row is null (end of rows)
    je .end

    mov rbx, rax             ; Set rbx to traverse horizontally

.loop_column:
    cmp rbx, 0               ; Check if the current node is NULL
    je .next_row             ; Move to the next row if NULL

    ; Retrieve CdfValue safely (only if the node is valid)
    movzx rcx, byte [rbx + 3]

    ; Set the RGB values to the CdfValue
    mov byte [rbx], cl       ; Red
    mov byte [rbx + 1], cl   ; Green
    mov byte [rbx + 2], cl   ; Blue

    ; Move to the next node in the row (right pointer at offset 32)
    mov rbx, [rbx + 32]      ; Move to the right node

    jmp .loop_column         ; Continue to the next column



.safe_end_column:
    ; Move to the next node in the row
    mov rbx, [rbx + 32]      ; Move to the right node

    ; Continue to the next column
    jmp .loop_column

.next_row:
    ; Move to the next row
    mov rax, [rax + 16]      ; Move to the next row (down pointer)
    cmp rax, 0               ; Check if it's the end of the rows
    je .end                  ; If NULL, end the loop

    jmp .loop_row 


.clamp_below_255:
    cmp rcx, 0
    jge .set_pixel_value
    mov rcx, 0             ; Clamp to 0 if less than 0

.set_pixel_value:
    ; Set Red, Green, and Blue to the newPixelValue (grayscale)
    mov byte [rbx], cl     ; Red
    mov byte [rbx + 1], cl ; Green
    mov byte [rbx + 2], cl ; Blue

    ; Move to the next node in the row
    mov rbx, [rbx + 32]    ; Move to the right node (assuming correct offset)

    jmp .loop_column        ; Continue to next column



.end:
    leave                   ; Restore stack and base pointer
    ret                     ; Return from function