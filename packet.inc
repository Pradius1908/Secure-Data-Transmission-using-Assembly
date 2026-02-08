; =========================
; packet.inc
; =========================

%define SYS_READ   0
%define SYS_WRITE  1
%define SYS_EXIT   60

%define STDIN      0
%define STDOUT     1

; ---- FLAGS (1 byte) ----
%define FLAG_ENCRYPTED 0x01
%define FLAG_CORRUPTED 0x02

; ---- CRYPTO ----
%define XOR_KEY 0xAA

; ---- PACKET OFFSETS ----
%define OFF_COUNTER  0
%define OFF_FLAGS    1
%define OFF_LEN      2
%define OFF_DATA     3
; HASH is after DATA dynamically
