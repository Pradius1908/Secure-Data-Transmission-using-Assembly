org 100h

start:
    mov ax, cs
    mov ds, ax

    call read_key
    call clear
    call generate_packet
    call draw_ui

main_loop:
    mov ah, 00h
    int 16h

    cmp al, 27
    je exit

    cmp al, 'N'
    je send_packet
    cmp al, 'n'
    je send_packet

    cmp al, 'P'
    je toggle_corrupt
    cmp al, 'p'
    je toggle_corrupt

    cmp al, 'D'
    je select_data
    cmp al, 'd'
    je select_data

    cmp al, 'B'
    je select_bit
    cmp al, 'b'
    je select_bit

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

; ================= PACKET GENERATION =================
generate_packet:
    inc byte [pkt]

    mov al, [pkt]
    mov [packet], al

    mov al, [pkt]
    xor al, 55h
    mov [packet+1], al

    mov al, [pkt]
    xor al, 0AAh
    mov [packet+2], al

    mov al, [pkt]
    add al, 3
    mov [packet+3], al

    mov al, [packet+1]
    xor al, [packet+2]
    xor al, [packet+3]
    mov [packet+4], al

    xor bl, bl
    mov si, packet+1
    mov cx, 3
p1:
    mov al, [si]
    mov dl, 8
p2:
    shr al, 1
    jnc p3
    inc bl
p3:
    dec dl
    jnz p2
    inc si
    loop p1
    and bl, 1
    mov [packet+5], bl
    ret

; ================= SEND PACKET =================
send_packet:

    ; generate NEW packet for this send
    call generate_packet

    ; ----- OPTIONAL CORRUPTION -----
    cmp byte [corrupt], 1
    jne no_err

    mov al, 1
    mov cl, [bit_sel]
    shl al, cl
    mov si, packet
    add si, [data_sel]
    xor byte [si], al

no_err:
    ; ----- ENCRYPT PACKET (bytes 1–4) -----
    mov si, packet
    add si, 1
    mov cx, 4
enc_loop:
    mov al, [key]
    xor [si], al
    inc si
    loop enc_loop

    call write_tx
    call read_rx
    call draw_ui
    jmp main_loop

toggle_corrupt:
    xor byte [corrupt], 1
    call draw_ui
    jmp main_loop

select_data:
    inc byte [data_sel]
    cmp byte [data_sel], 4
    jne sdok
    mov byte [data_sel], 1
sdok:
    call draw_ui
    jmp main_loop

select_bit:
    inc byte [bit_sel]
    cmp byte [bit_sel], 8
    jne sbok
    mov byte [bit_sel], 0
sbok:
    call draw_ui
    jmp main_loop

; ================= FILE I/O =================
write_tx:
    mov ah, 3Ch
    mov cx, 0
    mov dx, txfile
    int 21h
    mov bx, ax

    mov ah, 40h
    mov cx, 6
    mov dx, packet
    int 21h

    mov ah, 3Eh
    int 21h
    ret

read_rx:
    mov ah, 3Dh
    mov al, 0
    mov dx, rxfile
    int 21h
    jc read_rx

    mov bx, ax
    mov ah, 3Fh
    mov cx, 1
    mov dx, rx
    int 21h

    mov ah, 3Eh
    int 21h
    ret

; ================= UI =================
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
    mov dl, 2
    call cur
    mov si, left_head
    call print

    mov dl, 40
    call cur
    mov si, right_head
    call print

    mov dh, 5
    mov dl, 0
    call cur
    mov si, midbar
    call print

    mov dh, 6
    mov dl, 2
    call cur
    mov si, s1
    call print
    mov al, [packet]
    call hex

    mov dh, 7
    call cur
    mov si, s2
    call print
    mov al, [packet+1]
    call hex

    mov dh, 8
    call cur
    mov si, s3
    call print
    mov al, [packet+2]
    call hex

    mov dh, 9
    call cur
    mov si, s4
    call print
    mov al, [packet+3]
    call hex

    mov dh, 10
    call cur
    mov si, s5
    call print
    mov al, [packet+4]
    call hex

    mov dh, 11
    call cur
    mov si, s6
    call print
    mov al, [packet+5]
    call hex

    mov dh, 13
    mov dl, 2
    call cur
    mov si, s7
    call print
    cmp byte [corrupt], 1
    je son
    mov si, off
    jmp sc
son:
    mov si, on
sc:
    call print

    mov dh, 14
    call cur
    mov si, s8
    call print
    mov al, [data_sel]
    add al, '0'
    int 10h

    mov dh, 15
    call cur
    mov si, s9
    call print
    mov al, [bit_sel]
    add al, '0'
    int 10h

    mov dh, 16
    call cur
    mov si, s10
    call print
    cmp byte [rx], 'A'
    je ok
    mov si, nack
    jmp sr
ok:
    mov si, ack
sr:
    call print

    mov dh, 18
    mov dl, 2
    call cur
    mov si, help
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

exit:
    mov ah, 4Ch
    int 21h

; ================= DATA =================
pkt db 0
corrupt db 0
data_sel db 1
bit_sel db 0
packet db 6 dup(0)
rx db 0
key db 0

txfile db "TX.DAT",0
rxfile db "RX.DAT",0
keyfile db "KEY.TXT",0

title db "SENDER PANEL(Encrypter, Checksum)",0
topbar db "==============================================================",0
midbar db "------------------------------+------------------------------",0

left_head  db "PACKET FIELDS",0
right_head db "RAW PACKET (HEX)",0

s1 db "Counter        : ",0
s2 db "Data Byte 1    : ",0
s3 db "Data Byte 2    : ",0
s4 db "Data Byte 3    : ",0
s5 db "Checksum (TX)  : ",0
s6 db "Parity (TX)    : ",0
s7 db "Corruption     : ",0
s8 db "Data Select    : ",0
s9 db "Bit Select     : ",0
s10 db "Receiver Resp  : ",0

on   db "ON",0
off  db "OFF",0
ack  db "ACK  [OK]",0
nack db "NACK [ERR]",0

help db "[N] Send  [P] Corrupt  [D] Data  [B] Bit  [ESC] Exit",0
