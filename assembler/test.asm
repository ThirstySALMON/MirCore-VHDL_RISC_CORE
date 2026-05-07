; Team 10 assembler test program
; This example creates program.mem directly in this folder.

.vector reset START
.vector hw_int HW_ISR
.vector int0 ISR0
.vector int1 ISR1

START:
    ; R1 = 5
    ;LDM R1, 5

    ; R2 = 10
    ;LDM R2, 10

    ; R3 = R1 + R2
    STD R1, 5(R2)
    LDD R2, 20(R3)

    IADD R4 ,R5 , 10
     
    ; OUT.PORT = R3
    OUT R3

    ; Test signed immediate: R4 = 0xFFFF
    LDM R4, -1

    ; Test unsigned immediate: R5 = 0xFFFF
    LDM R5, 0xFFFF

    HLT

ISR0:
    RTI

ISR1:
    RTI

HW_ISR:
    RTI
