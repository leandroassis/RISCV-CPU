addi x7, x0, 16777215
add x6, x0, x0
add x5, x0, x6
sw x5, x6, 0
addi x6, x6, 1
bne x6, x7, -2
beq x0, x0, 0