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
.eqv color_sky		0x00ADD8E6
.eqv color_player 	0x00ff0000
.eqv color_red		0x00ff0000
.eqv color_skin		0x00FEE3D4
.eqv color_black	0x00000000
.eqv color_platform	0x003f3f3f
.eqv color_cell		0x00FCE205
.eqv color_gray		0x80808080
.eqv color_light_gray	0x00e0e0e0
.eqv color_green	0x0000FF00
.eqv color_dark_blue	0x001c2e4a

.eqv roof		4

.data
spacer:		.space		4096
# red:		.word 			0x00ff0000
xPos:		.word 		5	# Player x position
yPos:		.word 		45	# Player y position
facingRight:	.word		1	# Check if player is facing right
grounded:	.word		0	# Check if player is grounded
jumping:	.word		0	# Check if the player is jumping
canJump:	.word		1	# Check if player can jump	
jumpDuration:	.word		6	# How long the jump lasts for	
lives:		.word		3	# Player lives, if 0 then game over
hasCell:	.word		0	# Check if player has power cell
xCell:		.word		18	# Cell x position
yCell:		.word		43	# Cell y position
xStation:	.word		5	# Station x position
yStation:	.word		62	# Station y position
stationOn:	.word		0	# Check if station is powered
xMovingPlatform:	.word	50	# Moving platform x position
yMovingPlatform:	.word	40	# Moving platform y position
movingPlatformRight:	.word	1	# Check if moving platform is going right
platformTimer:		.word	2	# Delay for platform
hit:		.word		0	# Check if player was hit
dead:		.word		0	# Check if player has died
xDoor:		.word		28	# Door x position
yDoor:		.word		26	# Door y position
xHeart:		.word		5
yHeart:		.word		33
hasHeart:	.word		0
heartMovingRight:	.word	1	

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
	jal draw_bg_objects
	jal draw_objects
	jal update_player
	jal update_objects
	jal draw_player
	jal delay
	j loop
	
	

key_pressed:
	lw $t2, 4($t9)
	beq $t2, 0x61, a_key
	beq $t2, 0x64, d_key
	beq $t2, 0x66, f_key
	beq $t2, 0x77, w_key
	beq $t2, 0x70, p_key
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
	
p_key:
	li $t1, 5
	sw $t1, xPos
	li $t1, 45
	sw $t1, yPos
	li $t1, 3
	sw $t1, lives
	li $t1, 18
	sw $t1, xCell
	li $t1, 43
	sw $t1, yCell
	li $t1, 2
	sw $t1, platformTimer
	li $t1, 50
	sw $t1, xMovingPlatform
	li $t1, 40
	sw $t1, yMovingPlatform
	li $t1, 1
	sw $t1, movingPlatformRight
	li $t1, 0
	sw $t1, jumping
	sw $t1, hasCell
	li $t1, 1
	sw $t1, facingRight
	li $t1, 6
	sw $t1, jumpDuration
	li $t1, 0
	sw $t1, hasHeart
	li $t1, 5
	sw $t1, xHeart
	li $t1, 33
	sw $t1, yHeart
	li $t1, 0
	sw $t1, hit
	j main
	
f_key:
	lw $t1, hasCell
	beq $t1, 1, drop_cell
pickup_cell:
	lw $t1, xPos
	lw $t2, yPos
	lw $t3, xCell
	lw $t4, yCell
	addi $t5, $t1, 2	# Horizontal Check
	bgt $t3, $t5, after_key
	addi $t5, $t1, -2
	blt $t3, $t5, after_key
	
	addi $t5, $t2, 2	# Vertical Check
	bgt $t4, $t5, after_key
	addi $t5, $t2, -2
	blt $t4, $t5, after_key
				
	li $t5, 1		# Pickup Cell
	sw $t5, hasCell
	j after_key
drop_cell:
	lw $t1, xPos
	lw $t2, yPos
	addi $t2, $t2, -1
	li $t5, 0
	sw $t5, hasCell
	sw $t1, xCell
	sw $t2, yCell
	j after_key
	
update_objects:
update_heart:
	lw $t1, xHeart
	lw $t2, yHeart
	lw $t3, hasHeart
	lw $t4, heartMovingRight
	lw $a1, lives
	beq $t3, 1, update_door
	bge $a1, 3, move_heart
	lw $t7, xPos
	lw $t8, yPos
	addi $t7, $t7, 3
	bgt $t1, $t7, move_heart
	addi $t7, $t7, -6
	blt $t1, $t7, move_heart
	addi $t8, $t8, 3
	bgt $t2, $t8, move_heart
	addi $t8, $t8, -6
	blt $t2, $t8, move_heart
	j pickup_heart
pickup_heart:
	li $t1, 1
	sw $t1, hasHeart
	lw $t1, lives
	addi $t1, $t1, 1
	sw $t1, lives
	j update_door
move_heart:
	beqz $t4, move_heart_left
	addi $t1, $t1, 1
	sw $t1, xHeart
	bgt $t1, 34, dir_heart_left
	j update_door
move_heart_left:
	addi $t1, $t1, -1
	sw $t1, xHeart
	blt $t1, 5, dir_heart_right
dir_heart_left:
	li $t5, 0
	sw $t5, heartMovingRight
	j update_door
dir_heart_right:
	li $t5, 1
	sw $t5, heartMovingRight
	j update_door
update_door:
	lw $t1, xDoor
	lw $t2, yDoor
	lw $t3, xPos
	lw $t4, yPos
	bne $t1, $t3, update_moving_platform
	bne $t2, $t4, update_moving_platform
	j win
update_moving_platform:
	lw $t1, platformTimer
	bgtz $t1, update_cell
	lw $t1, stationOn
	beqz $t1, update_cell
	lw $t2, xMovingPlatform
	lw $t3, yMovingPlatform
	lw $t4, movingPlatformRight
	beqz $t4, moving_platform_left
	
	addi $t2, $t2, 1
	sw $t2, xMovingPlatform
	bgt $t2, 56, dir_platform_left
	j update_cell
moving_platform_left:
	addi $t2, $t2, -1
	sw $t2, xMovingPlatform
	blt $t2, 18, dir_platform_right
	j update_cell
dir_platform_right:
	li $t4, 1
	sw $t4, movingPlatformRight
	j update_cell
dir_platform_left:
	li $t4, 0
	sw $t4, movingPlatformRight
	j update_cell
update_cell:
	lw $t1, hasCell		# Update cell position
	beqz $t1, update_station
	lw $t2, xPos
	lw $t3, yPos
	sw $t2, xCell
	sw $t3, yCell
	
update_station:
	lw $t1, xStation	# Update station state
	lw $t2, yStation
	lw $t3, xCell
	lw $t4, yCell
	lw $t5, stationOn
	li $t6, 0
	sw $t6, stationOn
	
	
	addi $t6, $t3, 2
	bgt $t1, $t6, jump_back
	addi $t6, $t3, -2
	blt $t1, $t6, jump_back
	addi $t6, $t4, 2
	bgt $t2, $t6, jump_back
	addi $t6, $t4, -2
	blt $t2, $t6, jump_back
	
	li $t6, 1
	sw $t6, stationOn	
	
	jr $ra

update_player:
	la $s0, BASE_ADDRESS
	li $t8, 64		# Get player position
	lw $t7, yPos
	bgt $t7, 62, playerHit
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
	
	lw $t1, 0($s2)				# Floor detection
	beq $t1, color_platform, on_ground
	lw $t1, -4($s2)
	beq $t1, color_platform, on_ground
	lw $t1, 4($s2)
	beq $t1, color_platform, on_ground
after_collision_check:
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
	lw $t1, hit
	beq $t1, 1, reset_player
	jr $ra
	

reset_player:
	li $t1, 5
	li $t2, 45
	lw $t3, lives
	addi $t3, $t3, -1
	sw $t3, lives
	beqz $t3, game_over
	sw $t1, xPos
	sw $t2, yPos
	sw $t3, lives
	li $t1, 0
	sw $t1, hit
	j jump_back
playerHit:
	li $t2, 1
	sw $t2, hit
	j after_collision_check
	
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
delay_platform:
	lw $t1, platformTimer
	beqz $t1, reset_platform_timer
	addi $t1, $t1, -1
	sw $t1, platformTimer
	j delay_fps
reset_platform_timer:
	li $t1, 2
	sw $t1, platformTimer
	j delay_fps
delay_fps:
	li $v0, 32	
	li $a0, 41			# Delay in milliseconds
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
	beqz $t5, jump_back
	
	sw $t6, -520($s0)
	sw $t7, -264($s0)
	sw $t7, -776($s0)
	j jump_back
	
draw_left:
	sw $t3, -776($s0)
	beqz $t5, jump_back
	sw $t6, -504($s0)
	sw $t7, -248($s0)
	sw $t7, -760($s0)
	j jump_back
jump_back:
	jr $ra


draw_objects:
draw_heart:
	lw $t1, hasHeart
	beq $t1, 1, draw_door
	la $s0, BASE_ADDRESS
	lw $t1, xHeart
	lw $t2, yHeart
	li $t3, color_red
	sll $t2, $t2, 8
	sll $t1, $t1, 2
	add $t1, $t1, $t2
	add $s1, $s0, $t1
	sw $t3, 0($s1)
	sw $t3, 4($s1)
	sw $t3, -4($s1)
	sw $t3, 256($s1)
	sw $t3, -256($s1)
	
draw_door:
	la $s0, BASE_ADDRESS
	li $t3, 0xffffffff
	lw $t1, yDoor
	sll $t1, $t1, 8
	lw $t2, xDoor
	sll $t2, $t2, 2
	add $t1, $t1, $t2
	add $s1, $s0, $t1
	sw $t3, 0($s1)
	sw $t3, -4($s1)
	sw $t3, 4($s1)
	sw $t3, -256($s1)
	sw $t3, -260($s1)
	sw $t3, -252($s1)
	sw $t3, -512($s1)
	sw $t3, -508($s1)
	sw $t3, -516($s1)
	sw $t3, -768($s1)
	sw $t3, -772($s1)
	sw $t3, -764($s1)
	sw $t3, -1024($s1)
	sw $t3, -1028($s1)
	sw $t3, -1020($s1)
	sw $t3, -1280($s1)
draw_life:
	lw $t1, lives
	li $t2, color_red
	la $s0, BASE_ADDRESS
	addi $s1, $s0, 780
	sw $t2, 0($s1)
	sw $t2, -4($s1)
	sw $t2, 4($s1)
	sw $t2, 256($s1)
	sw $t2, -260($s1)
	sw $t2, -252($s1)
	
	blt $t1, 2, draw_power_cell
	addi $s1, $s0, 796
	sw $t2, 0($s1)
	sw $t2, -4($s1)
	sw $t2, 4($s1)
	sw $t2, 256($s1)
	sw $t2, -260($s1)
	sw $t2, -252($s1)
	
	blt $t1, 3, draw_power_cell
	addi $s1, $s0, 812
	sw $t2, 0($s1)
	sw $t2, -4($s1)
	sw $t2, 4($s1)
	sw $t2, 256($s1)
	sw $t2, -260($s1)
	sw $t2, -252($s1)
	
	j draw_power_cell
	
draw_power_cell:
	lw $t1, hasCell
	beq $t1, 1, jump_back
	li $t7, color_cell	
	li $t8, color_gray
	la $s0, BASE_ADDRESS
	lw $t1, xCell
	lw $t2, yCell
	li $t3, 64
	mult $t2, $t3
	mflo $t3
	sll $t3, $t3, 2
	sll $t1, $t1, 2
	add $t1, $t1, $t3
	
	add $s1, $s0, $t1	# $s1 contains address of cell position
	sw $t7, 0($s1)
	sw $t8, 4($s1)
	sw $t8, -4($s1)
	
	j jump_back
draw_bg_objects:
draw_station:
	lw $t1, xStation
	lw $t2, yStation
	li $t3, color_sky
	li $t4, color_dark_blue
	li $t5, color_red
	li $t6, color_green
	la $s0, BASE_ADDRESS
	li $t8, 64
	mult $t8, $t2
	mflo $t8
	sll $t8, $t8, 2
	move $t7, $t1
	sll $t7, $t7, 2
	add $t8, $t8, $t7
	add $s1, $s0, $t8
	
	sw $t4, 0($s1)
	sw $t4, -4($s1)
	sw $t4, 4($s1)
	sw $t3, -256($s1)
	sw $t4, -260($s1)
	sw $t4, -252($s1)
	sw $t4, -512($s1)
	sw $t4, -516($s1)
	sw $t4, -508($s1)
	sw $t4, -768($s1)
	sw $t4, -772($s1)
	sw $t4, -764($s1)
	sw $t4, -1024($s1)
	sw $t4, -1280($s1)
	sw $t4, -1536($s1)
	
	
	lw $t8, stationOn
	beq $t8, 1, draw_station_on
	sw $t5, -1792($s1)
	j draw_moving_platform
draw_station_on:
	sw $t6, -1792($s1)
draw_moving_platform:
	lw $t1, xMovingPlatform
	lw $t2, yMovingPlatform
	li $t3, color_red
	li $t4, color_green
	li $t5, color_platform
	lw $t8, stationOn
	la $s0, BASE_ADDRESS
	sll $t2, $t2, 8
	sll $t1, $t1, 2
	add $t1, $t2, $t1
	add $s1, $s0, $t1
	sw $t5, -4($s1)
	sw $t5, -8($s1)
	sw $t5, -12($s1)
	sw $t5, -16($s1)
	sw $t5, -20($s1)
	sw $t5, -24($s1)
	sw $t5, 4($s1)
	sw $t5, 8($s1)
	sw $t5, 12($s1)
	sw $t5, 16($s1)
	sw $t5, 20($s1)
	sw $t5, 24($s1)
	sw $t3, 0($s1)
	beqz $t8, jump_back
	sw $t4, 0($s1)
	j jump_back

draw_platforms:
	la $s0, BASE_ADDRESS	# Load address of bitmap
	li $t1, color_platform	# Load color of platforms
	li $t4, 32
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
	
	addi $s1, $s0, 8924		# Platform at 55, 34
	sw $t1, 0($s1)
	sw $t1, 4($s1)
	sw $t1, 8($s1)
	sw $t1, 12($s1)
	
	addi $s1, $s0, 7096		# Platform at 46, 27
	sw $t1, 0($s1)
	sw $t1, 4($s1)
	sw $t1, 8($s1)
	sw $t1, 12($s1)
	sw $t1, -4($s1)
	sw $t1, -8($s1)
	sw $t1, -12($s1)
	sw $t1, -16($s1)
	addi $s1, $s1, -16
	
	sw $t1, -28($s1)
	sw $t1, -32($s1)
	sw $t1, -36($s1)
	sw $t1, -40($s1)
	sw $t1, -44($s1)
	sw $t1, -48($s1)
	sw $t1, -52($s1)
	sw $t1, -56($s1)
	sw $t1, -60($s1)
	sw $t1, -64($s1)
	
	jr $ra

delay_short:
	li $v0, 32	
	li $a0, 1			# Delay in milliseconds
	syscall
	jr $ra
	
delay_long:
	li $v0, 32	
	li $a0, 1500			# Delay in milliseconds
	syscall
	jr $ra

win:	
	jal refresh
	la $s0, BASE_ADDRESS
	addi $s1, $s0, 0
	addi $s2, $s0, 16380
	li $t1, 0xffffffff
	li $t2, 320
draw_win:
	sw $t1, 0($s1)
	addi $s1, $s1, 12
	addi $t2, $t2, -1
	jal delay_short
	sw $t1, 0($s2)
	addi $s2, $s2, -12
	jal delay_short
	bnez $t2, draw_win
	jal write_win
	j end
	
game_over:
	jal refresh
	la $s0, BASE_ADDRESS
	addi $s1, $s0, 0
	addi $s2, $s0, 16380
	li $t1, color_black
	li $t2, 640
draw_bars:
	sw $t1, 0($s1)
	addi $s1, $s1, 4
	addi $t2, $t2, -1
	jal delay_short
	sw $t1, 0($s2)
	addi $s2, $s2, -4
	jal delay_short
	bnez $t2, draw_bars
	
	jal write_game
	jal delay_long
	jal write_over

	j end	
write_win:
	la $s0, BASE_ADDRESS
	addi $s1, $s0, 7992
	li $t1, color_green
	sw $t1, 4($s1)		# Letter Y
	sw $t1, -4($s1)
	sw $t1, 256($s1)
	sw $t1, 512($s1)
	sw $t1, -264($s1)
	sw $t1, -248($s1)
	sw $t1, -520($s1)
	sw $t1, -504($s1)
	
	addi $s1, $s1, 24
	sw $t1, 8($s1)		# Letter O
	sw $t1, -8($s1)
	sw $t1, 264($s1)
	sw $t1, 248($s1)
	sw $t1, 512($s1)
	sw $t1, 516($s1)
	sw $t1, 508($s1)
	sw $t1, -264($s1)
	sw $t1, -248($s1)
	sw $t1, -512($s1)
	sw $t1, -516($s1)
	sw $t1, -508($s1)
	
	addi $s1, $s1, 24
	sw $t1, 8($s1)		# Letter U
	sw $t1, -8($s1)
	sw $t1, 264($s1)
	sw $t1, 248($s1)
	sw $t1, 512($s1)
	sw $t1, 516($s1)
	sw $t1, 508($s1)
	sw $t1, -264($s1)
	sw $t1, -248($s1)
	sw $t1, -520($s1)
	sw $t1, -504($s1)
	
	addi $s1, $s1, 40
	sw $t1, 0($s1)		# Letter W
	sw $t1, 8($s1)	
	sw $t1, -8($s1)
	sw $t1, 252($s1)
	sw $t1, 260($s1)
	sw $t1, 248($s1)
	sw $t1, 264($s1)
	sw $t1, 504($s1)
	sw $t1, 520($s1)
	sw $t1, -264($s1)
	sw $t1, -248($s1)
	sw $t1, -504($s1)
	sw $t1, -520($s1)
	
	addi $s1, $s1, 24
	sw $t1, 0($s1)		# Letter I
	sw $t1, 256($s1)
	sw $t1, 512($s1)
	sw $t1, 516($s1)
	sw $t1, 520($s1)
	sw $t1, 508($s1)
	sw $t1, 504($s1)
	sw $t1, -256($s1)
	sw $t1, -512($s1)
	sw $t1, -516($s1)
	sw $t1, -520($s1)
	sw $t1, -508($s1)
	sw $t1, -504($s1)
	
	addi $s1, $s1, 24
	sw $t1, 0($s1)		# Letter W
	sw $t1, 8($s1)	
	sw $t1, -8($s1)
	sw $t1, -260($s1)
	sw $t1, 260($s1)
	sw $t1, 248($s1)
	sw $t1, 264($s1)
	sw $t1, 504($s1)
	sw $t1, 520($s1)
	sw $t1, -264($s1)
	sw $t1, -248($s1)
	sw $t1, -504($s1)
	sw $t1, -520($s1)
	
	jr $ra
	
write_game:
	la $s0, BASE_ADDRESS
	addi $s1, $s0, 7252
	li $t1, color_red
	sw $t1, 4($s1)		# Letter G
	sw $t1, 8($s1)
	sw $t1, -8($s1)
	sw $t1, 264($s1)
	sw $t1, 248($s1)
	sw $t1, 512($s1)
	sw $t1, 516($s1)
	sw $t1, 508($s1)
	sw $t1, -264($s1)
	sw $t1, -512($s1)
	sw $t1, -516($s1)
	sw $t1, -508($s1)
	
	addi $s1, $s1, 24
	sw $t1, 0($s1)		# Letter A
	sw $t1, 4($s1)
	sw $t1, 8($s1)
	sw $t1, -4($s1)
	sw $t1, -8($s1)
	sw $t1, 264($s1)
	sw $t1, 248($s1)
	sw $t1, 504($s1)
	sw $t1, 520($s1)
	sw $t1, -264($s1)
	sw $t1, -248($s1)
	sw $t1, -512($s1)
	sw $t1, -516($s1)
	sw $t1, -508($s1)
	
	addi $s1, $s1, 24
	sw $t1, 0($s1)		# Letter M
	sw $t1, 8($s1)
	sw $t1, -8($s1)
	sw $t1, 264($s1)
	sw $t1, 248($s1)
	sw $t1, 520($s1)
	sw $t1, 504($s1)
	sw $t1, -260($s1)
	sw $t1, -252($s1)
	sw $t1, -264($s1)
	sw $t1, -248($s1)
	sw $t1, -520($s1)
	sw $t1, -504($s1)
	
	addi $s1, $s1, 24
	sw $t1, 0($s1)		# Letter E
	sw $t1, -4($s1)
	sw $t1, -8($s1)
	sw $t1, 248($s1)
	sw $t1, 512($s1)
	sw $t1, 516($s1)
	sw $t1, 520($s1)
	sw $t1, 508($s1)
	sw $t1, 504($s1)
	sw $t1, -264($s1)
	sw $t1, -512($s1)
	sw $t1, -516($s1)
	sw $t1, -520($s1)
	sw $t1, -508($s1)
	sw $t1, -504($s1)
	
	jr $ra

write_over:
	la $s0, BASE_ADDRESS
	addi $s1, $s0, 8788
	li $t1, color_red
	
	sw $t1, 8($s1)		# Letter O
	sw $t1, -8($s1)
	sw $t1, 264($s1)
	sw $t1, 248($s1)
	sw $t1, 512($s1)
	sw $t1, 516($s1)
	sw $t1, 508($s1)
	sw $t1, -264($s1)
	sw $t1, -248($s1)
	sw $t1, -512($s1)
	sw $t1, -516($s1)
	sw $t1, -508($s1)
	
	addi $s1, $s1, 24
	sw $t1, 8($s1)		# Letter V
	sw $t1, -8($s1)
	sw $t1, 260($s1)
	sw $t1, 252($s1)
	sw $t1, 512($s1)
	sw $t1, -264($s1)
	sw $t1, -248($s1)
	sw $t1, -520($s1)
	sw $t1, -504($s1)
	
	addi $s1, $s1, 24
	sw $t1, 0($s1)		# Letter E
	sw $t1, -4($s1)
	sw $t1, -8($s1)
	sw $t1, 248($s1)
	sw $t1, 512($s1)
	sw $t1, 516($s1)
	sw $t1, 520($s1)
	sw $t1, 508($s1)
	sw $t1, 504($s1)
	sw $t1, -264($s1)
	sw $t1, -512($s1)
	sw $t1, -516($s1)
	sw $t1, -520($s1)
	sw $t1, -508($s1)
	sw $t1, -504($s1)
	
	addi $s1, $s1, 24
	sw $t1, 0($s1)		# Letter R
	sw $t1, 4($s1)
	sw $t1, 8($s1)
	sw $t1, -4($s1)
	sw $t1, -8($s1)
	sw $t1, 260($s1)
	sw $t1, 248($s1)
	sw $t1, 520($s1)
	sw $t1, 504($s1)
	sw $t1, -264($s1)
	sw $t1, -248($s1)
	sw $t1, -512($s1)
	sw $t1, -516($s1)
	sw $t1, -520($s1)
	sw $t1, -508($s1)
	sw $t1, -504($s1)
	
	jr $ra
end:
	lw $t8, 0($t9)
	bne $t8, 1, end
	lw $t2, 4($t9)
	beq $t2, 0x70, p_key
	j end
