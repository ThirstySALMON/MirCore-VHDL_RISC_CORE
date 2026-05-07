; Team 10 assembler test program
; This example creates program.mem directly in this folder.

.vector reset START
.vector hw_int HW_ISR
.vector int0 ISR0
.vector int1 ISR1

START:
   ldm r1 , 5
   nop 
   nop 
   nop
   nop
   nop
   ldm r2 , 5
   nop 
   nop 
   nop
   nop
   nop
   iadd r3 , r1 , 10
   nop 
   nop 
   nop
   nop
   nop
   nop

    HLT

ISR0:
    RTI

ISR1:
    RTI

HW_ISR:
    RTI
