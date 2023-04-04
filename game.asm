#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Darren Trieu, 1008403611, trieudar, d.trieu@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Health/score
# 2. Fail condition
# 3. Win condition
# 4. Moving objects
# 5. Moving platforms
# 6. Pick up effects
# 
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

# Addresses
.eqv	BASE_ADDRESS	0x10008000
.eqv	KEY_ADDRESS	0xffff0000

# Colors
.eqv color_sky		0x000015
.eqv color_player 	0x00ff0000
.eqv color_skin		0x00FEE3D4
.eqv color_black	0x00000000
.eqv color_platform	0x003f3f3f
.eqv color_cell		0x00FCE205
.eqv color_gray		0x80808080
.eqv roof		4

.data
spacer:		.space		4096
# red:		.word 			0x00ff0000
xPos:		.word 		8	# Player x position
yPos:		.word 		45	# Player y position
facingRight:	.word		1	# Check if player is facing right
grounded:	.word		0	# Check if player is grounded
jumping:	.word		0	# Check if the player is jumping
canJump:	.word		1	# Check if player can jump	
jumpDuration:	.word		6	# How long the jump lasts for	
lives:		.word		3	# Player lives, if 0 then game over
hasCell:	.word		1	# Check if player has power cell
xCell:		.word		8	# Cell x position
yCell:		.word		47	# Cell y position

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
	jal draw_platforms
	jal update_player
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
	bgt $t2, 61, after_key
	blt $t2, 2, after_key
	move $t1, $t2
	sw $t1, xPos
	li $t1, 0
	sw $t1, facingRight
	j after_key
d_key:
	lw $t1, xPos
	addi $t2, $t1, 1		# Test if input goes out of bounds
	bgt $t2, 61, after_key
	blt $t2, 2, after_key
	move $t1, $t2
	sw $t1, xPos
	li $t1, 1
	sw $t1, facingRight
	j after_key
w_key:
	lw $t1, canJump
	beq $t1, 0, after_key
	li $t1, 0
	sw $t1, canJump
	li $t1, 1
	sw $t1, jumping
	li $t2, 10
	sw $t2, jumpDuration
	j after_key

update_player:
	la $s0, BASE_ADDRESS
	li $t8, 64		# Get player position
	lw $t7, yPos
	mult $t8, $t7
	mflo $t8
	sll $t8, $t8, 2
	lw $t7, xPos
	sll $t7, $t7, 2
	add $t8, $t8, $t7	# $t8 holds offset for player position
	add $s1, $s0, $t8	# Set $s1 to position of player (middle bottom pixel)
	addi $s2, $s1, 256	# Set $s2 to pixel below player (middle bottom pixel)
	
	#li $t9, 0xffffffff
	#sw $t9, 0($s1)
	
	lw $t1, 0($s2)
	beq $t1, color_platform, on_ground
	lw $t1, -4($s2)
	beq $t1, color_platform, on_ground
	lw $t1, 4($s2)
	beq $t1, color_platform, on_ground
	li $t2, 0
	sw $t2, grounded
	sw $t2, canJump
after_ground_check:
	lw $t1, grounded
	beq $t1, 0, fall
after_falling_check:
	lw $t1, jumping
	beq $t1, 1, jump
after_jump_check:
	jr $ra
	
	
fall:
	lw $t1, jumping
	beq $t1, 1, after_falling_check
	lw $t1, yPos		# Get Y pos
	addi $t2, $t1, 1
	blt $t2, roof, after_falling_check		# Check if yPos + 1 breaks vertical boundaries
	bgt $t2, 63, after_falling_check
	sw $t2, yPos		
	j after_falling_check
on_ground:
	li $t2, 1
	sw $t2, canJump
	li $t2, 1
	sw $t2, grounded
	j after_ground_check
jump:
	lw $t1, jumpDuration
	addi $t1, $t1, -1
	sw $t1, jumpDuration
	li $t4, 0
	sw $t4, canJump
	beqz $t1, stopJump
	lw $t2, yPos
	addi $t3, $t2, -1
	blt $t3, roof, after_jump_check
	bgt $t3, 63, after_jump_check
	sw $t3, yPos
	j after_jump_check
stopJump:
	li $t2, 0
	sw $t2, jumping
	j after_jump_check
	
	
delay:
	li $v0, 32
	li $a0, 33
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
	add $s0, $s0, $t8	# Set $s0 to position of player (middle bottom pixel)
	
	li $t1, color_player	# Set $t1 to red
	li $t2, color_skin	# Set $t2 to skin color
	li $t3, color_black	# Set $t3 to black
	lw $t4, facingRight
	lw $t5, hasCell
	li $t6, color_cell	
	li $t7, color_gray
	
	#sw $t1, 0($s0)		# Body bottom row
	sw $t1, 4($s0)
	sw $t1, -4($s0)
	sw $t1, -256($s0)	# Body top row
	sw $t1, -260($s0)
	sw $t1, -252($s0)
	sw $t2, -512($s0)	# Head bottom row
	sw $t2, -508($s0)
	sw $t2, -516($s0)
	sw $t3, -768($s0)	# Head middle row
	sw $t2, -772($s0)
	sw $t2, -764($s0)
	sw $t2, -1024($s0)	# Head top row
	sw $t2, -1028($s0)
	sw $t2, -1020($s0)
	
	beq $t4, 0, draw_left	# Draw facing direction
	sw $t3, -760($s0)
	beqz $t5, jump_back_from_draw
	
	sw $t6, -520($s0)
	sw $t7, -264($s0)
	sw $t7, -776($s0)
	j jump_back_from_draw
	
draw_left:
	sw $t3, -776($s0)
	beqz $t5, jump_back_from_draw
	sw $t6, -504($s0)
	sw $t7, -248($s0)
	sw $t7, -760($s0)
	j jump_back_from_draw
jump_back_from_draw:
	jr $ra

draw_life:

draw_platforms:
	la $s0, BASE_ADDRESS	# Load address of bitmap
	li $t1, color_platform	# Load color of platforms
	li $t4, 64
	addi $s1, $s0, 16128	# Set $s1 to first pixel of last row

floor_loop:
	sw $t1, 0($s1)
	addi $s1, $s1, 4
	addi $t4, $t4, -1
	bnez $t4, floor_loop


	addi $s1, $s0, 14120	# Platform at 10, 55
	sw $t1, 0($s1)
	sw $t1, 4($s1)
	sw $t1, 8($s1)
	sw $t1, 12($s1)
	sw $t1, 16($s1)
	sw $t1, 20($s1)
	sw $t1, 24($s1)
	
	addi $s1, $s0, 13648	# Platform at 20, 53
	sw $t1, 0($s1)
	sw $t1, 4($s1)
	sw $t1, 8($s1)
	sw $t1, 12($s1)
	sw $t1, 16($s1)
	sw $t1, 20($s1)
	sw $t1, 24($s1)
	
	addi $s1, $s0, 11580	# Platform at 15, 45
	sw $t1, 0($s1)
	sw $t1, 4($s1)
	sw $t1, 8($s1)
	sw $t1, 12($s1)
	sw $t1, 16($s1)
	sw $t1, 20($s1)
	sw $t1, 24($s1)
	
	jr $ra
end:
	li $v0, 10
	syscall
