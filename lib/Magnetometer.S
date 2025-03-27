.syntax unified
.global magnetometer_init , magnetometer_read 


.set I2CBase, 0x40004000
.set Buffer_Recieve , 0x20000000
.set Buffer_Transmit , 0x20000060



@ PLEASE REFER TO DATA SHEET OF BOTH THE MAGNETOMETER AND MCU TO UNDERSTAND THE FOLLOWING CODE.

@===================================================================================================

@ FUNCTION for initializing magnetometer over I2C

.type magnetometer_init, %function
magnetometer_init:


@ Giving Board Time to get powered up correctly.
ldr r0 , =20000000
custom_loop3:
sub r0 , r0 , #1
cmp r0 ,#1
bne custom_loop3



ldr r2 , =I2CBase


@ diabling TWIM 0x500
ldr r3 , =0
str r3 , [r2, #0x500]

@ wating few clk cycles for TWIM to get disbaled and enabled again (according to datasheet , it takes 2 clk cyles)
nop 
nop
nop
nop


@ enabling TWIM 0x500
ldr r3 , =6
str r3 , [r2, #0x500]


@setting Pin Sel SCL 0x508    (SCL PIN ON BOARD = PIN0.8)
ldr r3 , =0b00000000000000000000000000001000
str r3 , [r2, #0x508]
   

@setting Pin Sel SDA 0x50C   (SCL PIN ON BOARD = PIN0.16)
ldr r3 , =0b00000000000000000000000000010000
str r3 , [r2, #0x50C]   


@setting FREQ 0x524
ldr r3 , =0x01980000
str r3 , [r2, #0x524]   


@setting addr of slave  (magnetometer addr 0x1E)
ldr r3 , =0x1E
str r3 , [r2, #0x588]


@ Reset "Transmit" Pointer to starting addres
ldr r3, =Buffer_Transmit
str r3, [r2, #0x544]


@set the data that we want to send (ARRD of  REG)
ldr r3 ,=0x60
ldr r4 , =Buffer_Transmit
str r3, [r4]


@set the data that we want to send (CONTENT TO SEND)
ldr r3 ,=0b00000000
ldr r4 , =Buffer_Transmit
str r3, [r4 , #0x1]


@ Set max bytes to send
ldr r3, =2
str r3, [r2, #0x548]


@ Sending Write Sequence
ldr r3, =0x1
str r3, [r2 , #0x008]

@ waiting for trasmission to get completed
wait_tx_init:
    ldr r3 , [r2 , #0x160]
    cmp r3 , #1
    bne wait_tx_init


@ Sending STOP 
ldr r3, =0x1
str r3, [r2 , #0x014]


ldr r3, =0
str r3, [r2, #0x15C]  @ Clear EVENTS_LASTRX
str r3, [r2, #0x160]  @ Clear EVENTS_LASTTX


@ again waiting some more time for board to get settled.
ldr r0 , =5000000
custom_loop2:
sub r0 , r0 , #1
cmp r0 ,#1
bne custom_loop2


bx lr

.size magnetometer_init, .-magnetometer_init










@===================================================================================================

@ FUNCTION for reading values from magnetometer 
@ OUTPUT    R4 = X-axis data     R5 = Z-axis data     R6 = Y-axis data

.type magnetometer_read, %function

magnetometer_read:


    ldr r2 , =I2CBase


    @ Disable TWIM before interaction
    ldr r3, =0
    str r3, [r2, #0x500]


    nop 
    nop 
    nop 
    nop


    @ Reset "Receive" Pointer to starting address
    ldr r3, =Buffer_Recieve
    str r3, [r2, #0x534]


    @ Reset "Transmit" Pointer to starting address
    ldr r3, =Buffer_Transmit
    str r3, [r2, #0x544]


    @ Set max bytes to read
    ldr r3, =6
    str r3, [r2, #0x538]


    @ Set max bytes to send
    ldr r3, =1
    str r3, [r2, #0x548]


    @ Re-enable TWIM
    ldr r3, =6
    str r3, [r2, #0x500]

    nop
    nop
    nop
    nop

    @set the data that we want to send (ADDR of OUTPUT REG)
    ldr r3 ,=0b11101000
    ldr r4 , =Buffer_Transmit
    str r3, [r4]


    @ Sending Write Sequence
    ldr r3, =0x1
    str r3, [r2 , #0x008]


wait_tx:
    ldr r3 , [r2 , #0x160]
    cmp r3 , #1
    bne wait_tx


    @ Sending Read Sequence
    ldr r3, =0x1
    str r3, [r2 , #0x000]
        
        
wait_rx:
    ldr r3 , [r2 , #0x15C]
    cmp r3 , #1
    bne wait_rx

   

    @ Sending STOP 
    ldr r3, =0x1
    str r3, [r2 , #0x014]


    @ Clear EVENTS_LASTRX/TX
    ldr r3, =0
    str r3, [r2, #0x15C]  
    str r3, [r2, #0x160]  



    ldr r3, =Buffer_Recieve
    ldrh r4 , [r3]
    ldrh r6  , [r3,#0x2] 
    ldrh r5 , [r3,#0x4]

bx lr
.size magnetometer_read, .-magnetometer_read

