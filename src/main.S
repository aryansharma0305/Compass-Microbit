.syntax unified
.global main

.type main, %function
main:

bl audio_init
bl play_c4              
bl play_e4              
bl play_g4              
bl play_a4              
bl play_g4              
bl play_e4              
bl play_c4              
bl play_d4              
bl play_e4              
bl play_g4              
bl play_b4              
bl play_a4              
bl play_g4              
bl play_e4              
bl play_c4              
bl play_stop            

bl init_text      @ library function for initializing LEDs


bl magnetometer_init   @ library function for initializing I2C protocol with Internal Bus , and configuring magnetometer to start measuring



loop:

bl magnetometer_read  @ returns magnetic field values of  X-axis in R4 , Y-axis in R6 and Z-axis in R5

bl calculate_heading  @ uses the above values to calculate Azimutal Angle and stores them in R0


@ Since the calculation is not accurate, and the magnetometer is also not calibrated
@ I have calibrated the compass as per my observations , you can tweek the values below:

CMP R0, #0x60          
BLT east              
CMP R0, #0xa7         
BLT  north            
CMP R0, #0xcd          
BLT west              
CMP R0, #0x100        
BLT south             
B east                



east:
  
    ldr r0 , =#'E'
    bl display_char
    B continue

south:


  
    ldr r0 , =#'S'
    bl display_char    
    B continue

west:

    
    ldr r0 , =#'W'
    bl display_char    
    B continue

north:
    
    ldr r0 , =#'N'
    bl display_char    
    B continue




continue:
    B loop                @ Return to start of loop















.type calculate_heading, %function

calculate_heading:
    @ Inputs: R4 = X-axis data , R5 = Z-axis data
    @ Output: R0 = Heading angle in degrees (0–359)
    
    @ since I have observed that X axis magnetometer doesnt give full 00 to ff values , and same with Z axis , we have to sclame them
    @ Max values: X = 0xB5 (181), Z = 0xDF (53)

    @ Sign-extend 16-bit X and Y to 32 bits
    SXTH    R4, R4          
    SXTH    R5, R5          



    
    MOV     R6, R4          
    CMP     R6, #0
    BPL     scale_x_positive
    RSBS    R6, R6, #0      

scale_x_positive:
    LSL     R8, R6, #8      
    MOV     R10, #180       
    SDIV    R6, R8, R10     
    CMP     R4, #0
    BPL     x_scaled
    RSBS    R6, R6, #0      

x_scaled:
    MOV     R4, R6          
    MOV     R7, R5         
    CMP     R7, #0
    BPL     scale_y_positive
    RSBS    R7, R7, #0     

scale_y_positive:
    LSL     R8, R7, #8     
    MOV     R10, #200      
    SDIV    R7, R8, R10    
    CMP     R5, #0
    BPL     y_scaled
    RSBS    R7, R7, #0     

y_scaled:
    MOV     R5, R7          
    CMP     R4, #0
    BNE     x_not_zero

    CMP     R5, #0
    BGT     y_positive      
    BLT     y_negative      
    MOV     R0, #0          
    B       end
y_positive:
    MOV     R0, #90         
    B       end
y_negative:
    MOV     R0, #270        
    B       end

x_not_zero:
    MOV     R6, R4          
    CMP     R6, #0
    BPL     abs_x_done
    RSBS    R6, R6, #0      

abs_x_done:

    MOV     R7, R5          
    CMP     R7, #0
    BPL     abs_y_done
    RSBS    R7, R7, #0      

abs_y_done:

    CMP     R7, R6
    BLE     y_le_x          
    LSL     R8, R6, #8      
    SDIV    R8, R8, R7      
    LDR     R10, =table     
    LDRB    R9, [R10, R8]   
    MOV     R11, #90
    SUB     R9, R11, R9     
    B       quadrant_adjust

y_le_x:
    LSL     R8, R7, #8      
    SDIV    R8, R8, R6      
    LDR     R10, =table
    LDRB    R9, [R10, R8]   

quadrant_adjust:

    CMP     R4, #0
    BGT     x_positive      
    CMP     R5, #0
    BGE     y_ge_zero_x_neg
    MOV     R11, #180
    ADD     R0, R11, R9     
    B       end

y_ge_zero_x_neg:
    MOV     R11, #180
    SUB     R0, R11, R9     
    B       end

x_positive:
    CMP     R5, #0
    BGE     angle_done
    MOV     R11, #360
    SUB     R0, R11, R9     
    B       end

angle_done:
    MOV     R0, R9          

end:



    BX      LR              


.size calculate_heading, .-calculate_heading




@ pre calulcated Tan inverse values
.section .data
.align 2
table:
.byte 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3
.byte 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 6, 7, 7
.byte 7, 7, 8, 8, 8, 8, 8, 9, 9, 9, 9, 10, 10, 10, 10, 10
.byte 11, 11, 11, 11, 11, 12, 12, 12, 12, 13, 13, 13, 13, 13, 14, 14
.byte 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16, 17, 17, 17, 17
.byte 17, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20
.byte 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 23, 23, 23, 23, 23
.byte 24, 24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26
.byte 27, 27, 27, 27, 27, 27, 28, 28, 28, 28, 28, 29, 29, 29, 29, 29
.byte 29, 30, 30, 30, 30, 30, 30, 31, 31, 31, 31, 31, 31, 32, 32, 32
.byte 32, 32, 32, 32, 33, 33, 33, 33, 33, 33, 34, 34, 34, 34, 34, 34
.byte 35, 35, 35, 35, 35, 35, 35, 36, 36, 36, 36, 36, 36, 36, 37, 37
.byte 37, 37, 37, 37, 37, 38, 38, 38, 38, 38, 38, 38, 39, 39, 39, 39
.byte 39, 39, 39, 39, 40, 40, 40, 40, 40, 40, 40, 41, 41, 41, 41, 41
.byte 41, 41, 41, 42, 42, 42, 42, 42, 42, 42, 42, 43, 43, 43, 43, 43
.byte 43, 43, 43, 44, 44, 44, 44, 44, 44, 44, 44, 44, 45, 45, 45, 45
.byte 45

















.syntax unified

/* Data section for global phase accumulator */
.section .data
.align 2
.global phase
phase: .word 0          // 32-bit phase accumulator, persists across calls

/* Code section */
.section .text

/* Play a note with a given phase increment in r0
 * Input: r0 = phase increment (e.g., 548288 for C4)
 * Duration: 1900 samples (~0.2375s at 8000 Hz)
 */
.type play_note, %function
.global play_note
play_note:
    push {r4, r5, r6, lr}
    ldr r6, =phase         // Load phase address
    ldr r6, [r6]           // Load current phase
    mov r5, r0             // r5 = increment
    mov r4, #1900          // 1900 samples at 8000 Hz (~0.2375s)
play_note_loop:
    lsr r0, r6, #16        // Bits 23-16 for sample
    and r0, #0xFF          // 8-bit sample (0-255)
    bl audio_play_sample   // Play sample (external function)
    add r6, r6, r5         // Update phase
    subs r4, r4, #1        // Decrease counter
    bne play_note_loop     // Loop until done
    ldr r0, =phase
    str r6, [r0]           // Save updated phase
    pop {r4, r5, r6, pc}

/* Play C4 (260 Hz) */
.type play_c4, %function
.global play_c4
play_c4:
    push {lr}
    ldr r0, =548288        // Increment for C4
    bl play_note
    pop {pc}

/* Play D4 (290Hz) */
.type play_d4, %function
.global play_d4
play_d4:
    push {lr}
    ldr r0, =615424        // Increment for D4
    bl play_note
    pop {pc}

/* Play E4 (320 Hz) */
.type play_e4, %function
.global play_e4
play_e4:
    push {lr}
    ldr r0, =690880        // Increment for E4
    bl play_note
    pop {pc}

/* Play F4 (350 Hz) */
.type play_f4, %function
.global play_f4
play_f4:
    push {lr}
    ldr r0, =731904        // Increment for F4
    bl play_note
    pop {pc}

/* Play G4 (390 Hz) */
.type play_g4, %function
.global play_g4
play_g4:
    push {lr}
    ldr r0, =821248        // Increment for G4
    bl play_note
    pop {pc}

/* Play A4 (440.00 Hz) */
.type play_a4, %function
.global play_a4
play_a4:
    push {lr}
    ldr r0, =921600        // Increment for A4
    bl play_note
    pop {pc}

/* Play B4 (490 Hz) */
.type play_b4, %function
.global play_b4
play_b4:
    push {lr}
    ldr r0, =1034240       // Increment for B4
    bl play_note
    pop {pc}


.type play_stop, %function
.global play_stop
play_stop:
    push {r4, lr}
    mov r4, #1900         
play_stop_loop:
    mov r0, #128           
    bl audio_play_sample
    subs r4, r4, #1        // Decrease counter
    bne play_stop_loop     // Loop until done
    pop {r4, pc}

.size play_note, .-play_note
.size play_c4, .-play_c4
.size play_d4, .-play_d4
.size play_e4, .-play_e4
.size play_f4, .-play_f4
.size play_g4, .-play_g4
.size play_a4, .-play_a4
.size play_b4, .-play_b4
.size play_stop, .-play_stop

.end