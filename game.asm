# Darren Trieu - trieudar

# Display Configuration
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)

# Addresses
.eqv	BASE_ADDRESS	0x10008000
.eqv	KEY_ADDRESS	0xffff0000

# Colors
.eqv color_sky		0x000015
.eqv color_player 	0x00ff0000

.data
spacer:		.space		4096
#red:		.word 			0x00ff0000
xPos:		.word 		10	# Player x position
yPos:		.word 		50	# Player y position
falling:	.word		1	# Check if player is falling

.text
.globl main

main:
	li $t0, BASE_ADDRESS
	li $t9, KEY_ADDRESS
loop:
	# Get key input
	lw $t8, 0($t9)
	beq $t8, 1, key_pressed
	
after_key:
	jal refresh
	jal draw_player
	jal delay
	j loop
	
	

key_pressed:
	lw $t2, 4($t9)
	beq $t2, 0x61, a_key
	beq $t2, 0x64, d_key
	beq $t2, 0x77, w_key
	j after_key
	
a_key:
	lw $t1, xPos
	addi $t2, $t1, -1		# Test if input goes out of bounds
	bgt $t2, 62, after_key
	blt $t2, 1, after_key
	move $t1, $t2
	sw $t1, xPos
	j after_key
d_key:
	lw $t1, xPos
	addi $t2, $t1, 1		# Test if input goes out of bounds
	bgt $t2, 62, after_key
	blt $t2, 1, after_key
	move $t1, $t2
	sw $t1, xPos
	j after_key
	j after_key
w_key:
	j after_key
	
	
delay:
	li $v0, 32
	li $a0, 66
	syscall
	jr $ra
	
refresh:
	la $s0, BASE_ADDRESS		# Load address of bitmap to $s0
	li $s1, 4096			# Number of pixels in a 64x64 display
	li $s2, 0x00d3d3d3		# Light gray color for background
refresh_loop:
	sw $s2, 0($s0)
	addi $s0, $s0, 4
	addi $s1, $s1, -1
	bnez $s1, refresh_loop
	jr $ra
	
draw_player:
	la $s0, BASE_ADDRESS	# Load address of bitmap to $s0
	li $t8, 64		# Get player position
	lw $t7, yPos
	mult $t8, $t7
	mflo $t8
	sll $t8, $t8, 2
	lw $t7, xPos
	sll $t7, $t7, 2
	add $t8, $t8, $t7	# $t8 holds offset for player position
	
	li $t1, color_player	# Set first pixel to red
	add $s0, $s0, $t8
	sw $t1, 0($s0)
	sw $t1, 4($s0)
	sw $t1, -4($s0)
	sw $t1, -256($s0)
	sw $t1, -260($s0)
	sw $t1, -252($s0)
	sw $t1, -512($s0)
	sw $t1, -508($s0)
	sw $t1, -516($s0)
	
	jr $ra
	

end:
	li $v0, 10
	syscall
