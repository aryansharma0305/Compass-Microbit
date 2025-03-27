.syntax unified
.thumb                   

@ Supports ASCII A-Z (65-90) and 0-9 (48-57)
@ Dependencies: led.S (init_leds, write_row_pins, write_column_pins)

.global init_text, display_char

.text

@ init_text: Initializes the LED matrix
@ Input: None
@ Output: None

init_text:
    push {lr}
    bl init_leds          @ Set up GPIO pins for LED matrix
    mov r0, #0b11111      @ Ensure all columns off (high)
    bl write_column_pins
    mov r0, #0            @ Ensure all rows off (low)
    bl write_row_pins
    pop {lr}
    bx lr

@ Input: r0 - ASCII character code (e.g., 'A' = 65)
@ Output: None
@ Notes: One multiplexing cycle 
display_char:
    push {r4-r7, lr}      
    mov r4, r0            @ Save character
    bl get_pattern        @ r0 = pattern address
    mov r5, r0            @ r5 = pattern pointer
    mov r6, #0            @ r6 = row counter
display_loop:
    cmp r6, #5
    bge display_done      @ Exit if row >= 5

    @ Reset all pins before setting new state
    mov r0, #0b11111      @ All columns off (high)
    bl write_column_pins
    mov r0, #0            @ All rows off (low)
    bl write_row_pins

    @ Activate current row
    mov r0, #1
    lsl r0, r6            @ r0 = 1 << row (activate current row)
    bl write_row_pins

    @ Set columns for this row
    ldrb r7, [r5, r6]     @ Load pattern byte (1 = on)
    mvn r7, r7            @ Invert: 1 -> 0 (on), 0 -> 1 (off)
    and r7, #0x1F         @ Mask to 5 bits
    mov r0, r7
    bl write_column_pins  @ Set columns (0 = LED on)

    @ Delay for visibility and settling
    mov r0, #5000         @ Increased delay to ensure LEDs turn off fully
    bl delay

    @ Explicitly turn off row before next cycle
    mov r0, #0
    bl write_row_pins

    add r6, #1            @ Next row
    b display_loop
display_done:
    @ Final reset to prevent residual glow
    mov r0, #0b11111      @ All columns off
    bl write_column_pins
    mov r0, #0            @ All rows off
    bl write_row_pins
    pop {r4-r7, lr}
    bx lr

@ Input: r4 - ASCII character code
@ Output: r0 - Address of 5-byte pattern
get_pattern:
    push {lr}
    cmp r4, #'A'
    blt try_digit         @ char < 'A'
    cmp r4, #'Z'
    bgt try_digit         @ char > 'Z'
    sub r0, r4, #'A'      @ index = char - 'A' (0-25)
    b compute_address
try_digit:
    cmp r4, #'0'
    blt invalid           @ char < '0'
    cmp r4, #'9'
    bgt invalid           @ char > '9'
    sub r0, r4, #'0'      @ temp = char - '0'
    add r0, #26           @ index = 26 + (char - '0') (26-35)
    b compute_address
invalid:
    ldr r0, =default_pattern
    b get_pattern_exit
compute_address:
    ldr r1, =font_table
    mov r2, #5
    mul r0, r0, r2        @ offset = index * 5
    add r0, r1, r0        @ r0 = font_table + offset
get_pattern_exit:
    pop {lr}
    bx lr

@ delay: Busy-wait delay for multiplexing
@ Input: r0 - Number of iterations
@ Output: None
delay:
    push {r4, lr}
    mov r4, r0
delay_loop:
    subs r4, #1
    bne delay_loop        @ Loop until r4 = 0
    pop {r4, lr}
    bx lr

@ --------------------- Data Section --------------------
.data

@ font_table: 5x5 patterns for A-Z and 0-9 (180 bytes)
@ Each character = 5 bytes, 1 per row
@ Bit 0 = col 0 (left), bit 4 = col 4 (right), 1 = LED on
@ font_table:
@     @ A: 00100 01010 11111 10001 10001
@     .byte 0b00100, 0b01010, 0b11111, 0b10001, 0b10001
@     @ B: 11100 10010 11100 10010 11100
@     .byte 0b11100, 0b10010, 0b11100, 0b10010, 0b11100
@     @ C: 01110 10000 10000 10000 01110
@     .byte 0b01110, 0b10000, 0b10000, 0b10000, 0b01110
@     @ D: 11100 10010 10010 10010 11100
@     .byte 0b11100, 0b10010, 0b10010, 0b10010, 0b11100
@     @ E: 11110 10000 11110 10000 11110
@     .byte 0b11110, 0b10000, 0b11110, 0b10000, 0b11110
@     @ F: 11110 10000 11110 10000 10000
@     .byte 0b11110, 0b10000, 0b11110, 0b10000, 0b10000
@     @ G: 01110 10000 10110 10010 01110
@     .byte 0b01110, 0b10000, 0b10110, 0b10010, 0b01110
@     @ H: 10001 10001 11111 10001 10001
@     .byte 0b10001, 0b10001, 0b11111, 0b10001, 0b10001
@     @ I: 01110 00100 00100 00100 01110
@     .byte 0b01110, 0b00100, 0b00100, 0b00100, 0b01110
@     @ J: 00111 00010 00010 10010 01100
@     .byte 0b00111, 0b00010, 0b00010, 0b10010, 0b01100
@     @ K: 10001 10010 11100 10010 10001
@     .byte 0b10001, 0b10010, 0b11100, 0b10010, 0b10001
@     @ L: 10000 10000 10000 10000 11111
@     .byte 0b10000, 0b10000, 0b10000, 0b10000, 0b11111
@     @ M: 10001 11011 10101 10001 10001
@     .byte 0b10001, 0b11011, 0b10101, 0b10001, 0b10001
@     @ N: 10001 11001 10101 10011 10001
@     .byte 0b10001, 0b11001, 0b10101, 0b10011, 0b10001
@     @ O: 01110 10001 10001 10001 01110
@     .byte 0b01110, 0b10001, 0b10001, 0b10001, 0b01110
@     @ P: 11110 10001 11110 10000 10000
@     .byte 0b11110, 0b10001, 0b11110, 0b10000, 0b10000
@     @ Q: 01110 10001 10001 01110 00001
@     .byte 0b01110, 0b10001, 0b10001, 0b01110, 0b00001
@     @ R: 11110 10001 11110 10010 10001
@     .byte 0b11110, 0b10001, 0b11110, 0b10010, 0b10001
@     @ S: 01111 10000 01110 00001 11110
@     .byte 0b01111, 0b10000, 0b01110, 0b00001, 0b11110
@     @ T: 11111 00100 00100 00100 00100
@     .byte 0b11111, 0b00100, 0b00100, 0b00100, 0b00100
@     @ U: 10001 10001 10001 10001 01110
@     .byte 0b10001, 0b10001, 0b10001, 0b10001, 0b01110
@     @ V: 10001 10001 10001 01010 00100
@     .byte 0b10001, 0b10001, 0b10001, 0b01010, 0b00100
@     @ W: 10001 10001 10101 11011 10001
@     .byte 0b10001, 0b10001, 0b10101, 0b11011, 0b10001
@     @ X: 10001 01010 00100 01010 10001
@     .byte 0b10001, 0b01010, 0b00100, 0b01010, 0b10001
@     @ Y: 10001 01010 00100 00100 00100
@     .byte 0b10001, 0b01010, 0b00100, 0b00100, 0b00100
@     @ Z: 11111 00010 00100 01000 11111
@     .byte 0b11111, 0b00010, 0b00100, 0b01000, 0b11111
@     @ 0: 01110 10001 10001 10001 01110
@     .byte 0b01110, 0b10001, 0b10001, 0b10001, 0b01110
    @ @ 1: 00100 01100 00100 00100 01110
    @ .byte 0b00100, 0b01100, 0b00100, 0b00100, 0b01110
    @ @ 2: 01110 00001 00110 01000 11111
    @ .byte 0b01110, 0b00001, 0b00110, 0b01000, 0b11111
    @ @ 3: 01110 00001 00110 00001 01110
    @ .byte 0b01110, 0b00001, 0b00110, 0b00001, 0b01110
    @ @ 4: 10001 10001 11111 00001 00001
    @ .byte 0b10001, 0b10001, 0b11111, 0b00001, 0b00001
    @ @ 5: 11111 10000 11110 00001 11110
    @ .byte 0b11111, 0b10000, 0b11110, 0b00001, 0b11110
    @ @ 6: 01110 10000 11110 10001 01110
    @ .byte 0b01110, 0b10000, 0b11110, 0b10001, 0b01110
    @ @ 7: 11111 00001 00010 00100 01000
    @ .byte 0b11111, 0b00001, 0b00010, 0b00100, 0b01000
    @ @ 8: 01110 10001 01110 10001 01110
    @ .byte 0b01110, 0b10001, 0b01110, 0b10001, 0b01110
    @ @ 9: 01110 10001 01111 00001 01110
    @ .byte 0b01110, 0b10001, 0b01111, 0b00001, 0b01110

@ @ default_pattern: All LEDs off for invalid characters
@ default_pattern:
@     .byte 0, 0, 0, 0, 0
font_table:
    @ A
    .byte 0b01110, 0b10001, 0b11111, 0b10001, 0b10001
    @ B
    .byte 0b01111, 0b10001, 0b01111, 0b10001, 0b01111
    @ C
    .byte 0b01110, 0b00001, 0b00001, 0b00001, 0b01110
    @ D
    .byte 0b01111, 0b10001, 0b10001, 0b10001, 0b01111
    @ E
    .byte 0b11111, 0b00001, 0b01111, 0b00001, 0b11111
    @ F
    .byte 0b11111, 0b00001, 0b01111, 0b00001, 0b00001
    @ G
    .byte 0b01110, 0b00001, 0b11101, 0b10001, 0b11110
    @ H
    .byte 0b10001, 0b10001, 0b11111, 0b10001, 0b10001
    @ I
    .byte 0b01110, 0b00100, 0b00100, 0b00100, 0b01110
    @ J
    .byte 0b11100, 0b01000, 0b01000, 0b01001, 0b00110
    @ K
    .byte 0b10001, 0b01001, 0b00111, 0b01001, 0b10001
    @ L
    .byte 0b00001, 0b00001, 0b00001, 0b00001, 0b11111
    @ M
    .byte 0b10001, 0b11011, 0b10101, 0b10001, 0b10001
    @ N
    .byte 0b10001, 0b10011, 0b10101, 0b11001, 0b10001
    @ O
    .byte 0b01110, 0b10001, 0b10001, 0b10001, 0b01110
    @ P
    .byte 0b01111, 0b10001, 0b01111, 0b00001, 0b00001
    @ Q
    .byte 0b01110, 0b10001, 0b10001, 0b11110, 0b01000
    @ R
    .byte 0b01111, 0b10001, 0b01111, 0b01001, 0b10001
    @ S
    .byte 0b11110, 0b00001, 0b01110, 0b10000, 0b01111
    @ T
    .byte 0b11111, 0b00100, 0b00100, 0b00100, 0b00100
    @ U
    .byte 0b10001, 0b10001, 0b10001, 0b10001, 0b01110
    @ V
    .byte 0b10001, 0b10001, 0b10001, 0b01010, 0b00100
    @ W
    .byte 0b10001, 0b10001, 0b10101, 0b11011, 0b10001
    @ X
    .byte 0b10001, 0b01010, 0b00100, 0b01010, 0b10001
    @ Y
    .byte 0b10001, 0b01010, 0b00100, 0b00100, 0b00100
    @ Z
    .byte 0b11111, 0b01000, 0b00100, 0b00010, 0b11111


    @ 0
    .byte 0b01110, 0b10011, 0b10101, 0b11001, 0b01110
    @ 1
    .byte 0b00100, 0b00110, 0b00100, 0b00100, 0b01110
    @ 2
    .byte 0b01110, 0b10000, 0b01100, 0b00010, 0b11111
    @ 3
    .byte 0b01110, 0b10000, 0b01100, 0b10000, 0b01110
    @ 4
    .byte 0b10001, 0b10001, 0b11111, 0b10000, 0b10000
    @ 5
    .byte 0b11111, 0b00001, 0b01111, 0b10000, 0b01111
    @ 6
    .byte 0b01110, 0b00001, 0b01111, 0b10001, 0b01110
    @ 7
    .byte 0b11111, 0b10000, 0b01000, 0b00100, 0b00010
    @ 8
    .byte 0b01110, 0b10001, 0b01110, 0b10001, 0b01110
    @ 9
    .byte 0b01110, 0b10001, 0b11110, 0b10000, 0b01110













       








    @ default pattern for invalid characters
default_pattern:
    .byte 0, 0, 0, 0, 0