org 100h

start:
    mov ax, cs
    mov ds, ax

    call read_key
    call draw_ui

main_loop:
    call read_tx
    call build_expected
    call validate_packet
    call display_receiver
    call write_rx
    call delay
    jmp main_loop

; ================= READ KEY =================
read_key:
    mov ah, 3Dh
    mov al, 0
    mov dx, keyfile
    int 21h
    jc read_key

    mov bx, ax
    mov ah, 3Fh
    mov cx, 1
    mov dx, key
    int 21h

    mov ah, 3Eh
    int 21h
    ret

; ================= READ TX =================
read_tx:
    mov ah, 3Dh
    mov al, 0
    mov dx, txfile
    int 21h
    jc read_tx

    mov bx, ax
    mov ah, 3Fh
    mov cx, 6
    mov dx, packet
    int 21h

    mov ah, 3Eh
    int 21h

    ; ---------- DECRYPT PAYLOAD ----------
    ; Decrypt bytes [1..4]
    mov si, packet
    add si, 1
    mov cx, 4
dec_loop:
    mov al, [key]
    xor [si], al
    inc si
    loop dec_loop

    ret

; ================= BUILD EXPECTED PACKET =================
build_expected:
    mov al, [packet]
    mov [expected], al

    mov al, [packet]
    xor al, 55h
    mov [expected+1], al

    mov al, [packet]
    xor al, 0AAh
    mov [expected+2], al

    mov al, [packet]
    add al, 3
    mov [expected+3], al

    mov al, [expected+1]
    xor al, [expected+2]
    xor al, [expected+3]
    mov [expected+4], al

    xor bl, bl
    mov si, expected+1
    mov cx, 3
bp1:
    mov al, [si]
    mov dl, 8
bp2:
    shr al, 1
    jnc bp3
    inc bl
bp3:
    dec dl
    jnz bp2
    inc si
    loop bp1
    and bl, 1
    mov [expected+5], bl
    ret

; ================= VALIDATION =================
validate_packet:
    mov byte [rx_ok], 1

    mov si, packet
    mov di, expected
    mov cx, 6
cmp_loop:
    mov al, [si]
    cmp al, [di]
    jne bad
    inc si
    inc di
    loop cmp_loop
    ret

bad:
    mov byte [rx_ok], 0
    ret

; ================= WRITE RX =================
write_rx:
    mov ah, 3Ch
    mov cx, 0
    mov dx, rxfile
    int 21h
    mov bx, ax

    mov ah, 40h
    mov cx, 1
    cmp byte [rx_ok], 1
    je write_ack
    mov byte [reply], 'N'
    jmp wr_done
write_ack:
    mov byte [reply], 'A'
wr_done:
    mov dx, reply
    int 21h

    mov ah, 3Eh
    int 21h
    ret

; ================= DISPLAY =================
display_receiver:
    mov cx, 6
    mov si, packet
    mov di, expected
    mov dh, 7

row_loop:
    mov dl, 10
    call cur

    mov ah, 0Eh
    mov al, '['
    int 10h
    mov al, 6
    sub al, cl
    add al, '0'
    int 10h
    mov al, ']'
    int 10h

    mov al, ' '
    int 10h
    mov al, '|'
    int 10h
    mov al, ' '
    int 10h
    mov al, ' '
    int 10h
    mov al, ' '
    int 10h

    mov al, [si]
    call hex

    mov al, ' '
    int 10h
    mov al, ' '
    int 10h
    mov al, ' '
    int 10h
    mov al, ' '
    int 10h

    mov al, '|'
    int 10h
    mov al, ' '
    int 10h
    mov al, ' '
    int 10h
    mov al, ' '
    int 10h
    mov al, ' '
    int 10h

    mov al, [di]
    call hex

    inc si
    inc di
    inc dh
    loop row_loop

    mov dh, 14
    mov dl, 10
    call cur
    mov si, sep
    call print

    mov dh, 15
    call cur
    mov si, lbl_chk
    call print
    mov al, [expected+4]
    call hex

    mov dh, 16
    call cur
    mov si, lbl_par
    call print
    mov al, [expected+5]
    call hex

    mov dh, 18
    call cur
    cmp byte [rx_ok], 1
    je ok
    mov si, msg_bad
    jmp show
ok:
    mov si, msg_ok
show:
    call print
    ret

; ================= STATIC UI =================
draw_ui:
    call clear

    mov dh, 0
    mov dl, 0
    call cur
    mov si, topbar
    call print

    mov dh, 1
    mov dl, 18
    call cur
    mov si, title
    call print

    mov dh, 2
    mov dl, 0
    call cur
    mov si, topbar
    call print

    mov dh, 4
    mov dl, 10
    call cur
    mov si, tbl_hdr
    call print

    mov dh, 5
    mov dl, 10
    call cur
    mov si, sep
    call print
    ret

; ================= UTILS =================
clear:
    mov ax, 03h
    int 10h
    ret

cur:
    mov ah, 02h
    mov bh, 0
    int 10h
    ret

print:
.next:
    lodsb
    or al, al
    jz .done
    mov ah, 0Eh
    int 10h
    jmp .next
.done:
    ret

hex:
    push ax
    shr al, 4
    call hex_digit
    pop ax
    and al, 0Fh
hex_digit:
    add al, '0'
    cmp al, '9'
    jle hex_ok
    add al, 7
hex_ok:
    mov ah, 0Eh
    int 10h
    ret

delay:
    mov cx, 40000
d:
    loop d
    ret

; ================= DATA =================
packet   db 6 dup(0)
expected db 6 dup(0)
rx_ok    db 0
reply    db 0
key      db 0

txfile  db "TX.DAT",0
rxfile  db "RX.DAT",0
keyfile db "KEY.TXT",0

title   db " RECEIVER PANEL(Decrytpter, Validator)",0
topbar  db "==============================================================",0
tbl_hdr db "BYTE | RAW (RX) | EXPECTED (CALC)",0
sep     db "--------------------------------",0
lbl_chk db "Checksum CALC : ",0
lbl_par db "Parity   CALC : ",0
msg_ok  db "FINAL STATUS : VALID",0
msg_bad db "FINAL STATUS : CORRUPTED",0
