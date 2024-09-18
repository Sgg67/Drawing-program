# Sage Yanoff
# sey39

.include "display_2244_0203.asm"
.include "lab4_graphics.asm"

.eqv MODE_NOTHING 0
.eqv MODE_BRUSH   1
.eqv MODE_COLOR   2

.eqv PALETTE_X  32
.eqv PALETTE_Y  56
.eqv PALETTE_X2 96
.eqv PALETTE_Y2 72

.data
	drawmode: .word MODE_NOTHING
	last_x:   .word -1
	last_y:   .word -1
	color:    .word 0b111111 # 3,3,3 (white)
	
	
.text

.global main
main:
	li a0, 15
	li a1, 1
	li a2, 0
	
	jal display_init
	
	jal load_graphics
	
	# infinite loop
	_loop:
		jal check_input
		
		jal draw_cursor
		
		jal display_finish_frame
		
		# infinite loop
		j _loop
		
	# -----------------------------
	load_graphics:
		push ra
		
		la a0, cursor_gfx
		li a1, CURSOR_TILE
		li a2, N_CURSOR_TILES
		
		# call display sprite 1
		jal display_load_sprite_gfx
		
		la a0, palette_sprite_gfx
		li a1, PALETTE_TILE
		li a2, N_PALETTE_TILES
		
		# call display sprite 2
		jal display_load_sprite_gfx
		
		pop ra
		jr ra

	# -----------------------------
	check_input:
		push ra
	
	lw t0, drawmode
	beq t0, MODE_NOTHING, _nothing
	beq t0, MODE_BRUSH, _brush
	beq t0, MODE_COLOR, _color
	j _default
	_nothing:
    	jal drawmode_nothing
	    j _break
	_brush:
    	jal drawmode_brush
   		j _break
	_color:
   		jal drawmode_color
    	j _break

	_default:
	
		print_str "invalid option!\n"
    	li v0, 10
    
    # j _break not needed
	_break:
		pop ra
		jr ra
		
	# -----------------------------
	draw_cursor:
		
		push ra
		
		# load adress of display table into t1
		la t1, display_spr_table
		
		# load cursor x into t0
		lw t0, display_mouse_x
		
		sub t0, t0, 3
		
		
		# store cursor_x * 8 into 0 + t1
		sb t0, 0(t1)
		
		
		# load cursor y into t0
		lw t0, display_mouse_y
		
		sub t0, t0, 3
		
		
		sb t0, 1(t1)

		li t0, CURSOR_TILE
		# store 0 into 2 + t1
		sb t0, 2(t1)
		
		# load constant into t0
		li t0, 0x41
		
		# store constant into 3 + t1
		sb t0, 3(t1)
		
		pop ra
		jr ra
		
	# -----------------------------
	drawmode_brush:
		push ra
		
		# if the button is released
		lw t0, display_mouse_released
		and t0, t0, MOUSE_LBUTTON
		bne t0, 0, _brk_valid
		
		# load mouse_x into t0 and check if it is within  bounds
		lw t0, display_mouse_x
		blt t0, 0, _brk_valid
		lw t0, display_mouse_x
		bgt t0, 127, _brk_valid
		
		
		# lod mouse_y into t0
		lw t0, display_mouse_y
		blt t0, 0, _brk_valid
		lw t0, display_mouse_y
		bgt t0, 127, _brk_valid
		
		j _else_if
		
		_brk_valid:
		
			li t0, MODE_NOTHING
			sw t0, drawmode
			j _end_if
			
			_else_if:
			
			# if curr mouse_x != last_x
			lw t0, display_mouse_x
			lw t1, last_x
			bne t0, t1, _inner_if_brk
			
			# if curr mouse_y  != last_y
			lw t0, display_mouse_y
			lw t1, last_y
			bne t0, t1, _inner_if_brk
			
			j _end_if
			
			_inner_if_brk:
			
			# call draw line
			lw a0, display_mouse_x
			lw a1, display_mouse_y
			lw a2, last_x
			lw a3, last_y
			lw v1, color
			
			# call draw line
			jal display_draw_line 
			
			# store last_x into display_mouse_x
			lw t0, display_mouse_x
			sw t0, last_x
			
			# store last_y into display_mouse_y
			lw t0, display_mouse_y
			sw t0, last_y
			
			_end_if:
						
		pop ra
		jr ra
	
	
	# -----------------------------
	start_brush:
	
		push ra
	
			#if user is holding shift
		display_is_key_held t0, KEY_SHIFT
			
		beq t0, 0, _shift_else
		
		lw a0, last_x
		lw a1, last_y
		
		j _exit
		
		_shift_else:
		
			lw a0, display_mouse_x
			lw a1, display_mouse_y
			
			_exit:
			
			lw a2, display_mouse_x
			lw a3, display_mouse_y
			lw v1, color
		
		jal display_draw_line
		
		# set last_x to mouse_x
		lw t0, display_mouse_x
		sw t0, last_x
		
		# set last_y to mouse_y
		lw t0, display_mouse_y
		sw t0, last_y
		
		
		pop ra
		jr ra
		
	# -----------------------------
	drawmode_nothing:
		push ra
		push s0
		push s1
		
		
		# get state of all the buttons
		lw t0, display_mouse_pressed
		
		# look at left button
		and t0, t0, MOUSE_LBUTTON 
		
		# if button is pressed do something, else jump out of if statement
		beq t0, 0, _endif_lbutton
		
		# check if alt is being held
		display_is_key_held t0, KEY_ALT
			
		beq t0, 0, _end_alt_else
			
		# load display mouse x into a0
		lw a0, display_mouse_x
			
		# load display mouse y into a1
		lw a1, display_mouse_y
			
		jal display_get_pixel
			
		sw v0, color
		
		j _end_alt
		
		_end_alt_else:
			# load brush into t0
			li t0, MODE_BRUSH
			# set drawmode = brush
			sw  t0, drawmode
		jal start_brush
		
		_end_alt:
		
		_endif_lbutton:
			
		display_is_key_held t0, KEY_F
		
		beq t0, 0, _end_F_if
		
		jal flood_fill
		
		j _key_c_end_if
		
		_end_F_if:
		
			li t0, KEY_C
			
			# store t0 into display key pressed
			sw t0, display_key_pressed	
			
			lw t0, display_key_pressed
			
			beq t0, 0, _key_c_end_if
						
			# store color into drawmode
			li t0, MODE_COLOR
			sw t0, drawmode
		
		
		la t9, display_spr_table
		add t9, t9, 4
		
		# tile counter
		li s2, 0
		
		# row counter
		li s0, 0

		# outer loop
		_outer:
			
			# column counter
			li s1, 0
			
			# inner loop
			_inner:
			
				# add t0 into palette_x
				mul t0, s1, 8
				add t0, t0, PALETTE_X
				sb t0, 0(t9)
				
				# add t0 into palette_x
				mul t0, s0, 8
				add t0, t0, PALETTE_Y
				sb t0, 1(t9)
				
				# t0 into palette_tile
				add t0, s2, PALETTE_TILE
				sb t0, 2(t9)		
				
				# set flags to 1
				li t0, 1
				sb t0, 3(t9)		
				
				# palette_tile++
				add s2, s2, 1
				
				add t9, t9, 4
				
				
				# column++
				add s1, s1, 1
				
				# inner loop condition
				blt s1, 8, _inner
	
			# row++
			add s0, s0, 1
				
			# outer loop condition
			blt s0, 2, _outer
			
			_key_c_end_if:
			
		pop s1
		pop s0
		pop ra
		jr ra
	
	# -----------------------------
	drawmode_color:
		push ra
		push s0
		push s1
		
		# laod left mouse into t0
		lw t0, display_mouse_pressed
		and t0, t0, MOUSE_LBUTTON
		bne t0, 1, _brk_and
		
		lw t0, display_mouse_x
		blt t0, PALETTE_X, _brk_and
		
		lw t0, display_mouse_x
		bge t0, PALETTE_X2, _brk_and
		
		lw t0, display_mouse_y
		blt t0, PALETTE_Y, _brk_and
		
		lw t0, display_mouse_y
		bge t0, PALETTE_Y2, _brk_and
		
			lw  s0, display_mouse_x
			sub s0, s0, PALETTE_X
			div s0, s0, 4 # s0 = (display_mouse_x -  PALETTE_X) / 4
			
			lw  s1, display_mouse_y
			sub s1, s1, PALETTE_Y
			div s1, s1, 4 # s1 = (display_mouse_1 -  PALETTE_Y) / 4
			mul s1, s1, 16
			
			add s0, s0, s1
			sw  s0, color
			
		# load table into t9
		la t9, display_spr_table
		add t9, t9, 4		
		
		# row counter
		li s0, 0

		# outer loop
		_outer:
			
			# column counter
			li s1, 0
			
			# inner loop
			_inner:
			
				# set flags to 0
				li t0, 0
				sb t0, 3(t9)
				
				add t9, t9, 4
				
				add s1, s1, 1
				
				# inner loop condition
				blt s1, 8, _inner
	
			# row++
			add s0, s0, 1
				
			# outer loop condition
			blt s0, 2, _outer
		
		
		li t0, MODE_NOTHING
		sw t0, drawmode
		
		
		
		_brk_and:
			pop s1
			pop s0
			pop ra
			jr ra
		
	# -----------------------------
	flood_fill:
		push ra
		
		# put display_x into a0
		lw a0, display_mouse_x
		
		# put display_y into a1
		lw a1, display_mouse_y
		
		jal display_get_pixel
		
		# put display_x into a0
		lw a0, display_mouse_x
		
		# put display_y into a1
		lw a1, display_mouse_y
		
		# move v0 into a2
		move a2, v0
		
		# load color into a3
		lw a3, color
		
		# call flood fill rec
		jal floodfill_rec
		
		pop ra
		jr ra
		
	
	# -----------------------------
	floodfill_rec:
		push ra
		push s0
		push s1
		push s2
		push s3
		
		# x
		move s0, a0
		
		# y 
		move s1, a1
		
		# target
		move s2, a2
		
		# repl
		move s3, a3
		
		# move s0, into a0
		move a0, s0
		
		# move s1, into a1
		move a1, s1
	
		jal display_get_pixel
		
			# v0 == repl
		beq v0, s3, _return
		
		# v0 != target
		bne v0, s2, _return
		
		
		# move s0, into a0
		move a0, s0
		
		# move s1, into a1
		move a1, s1
		
		
		# move s3, into a2
		move a2, s3
		
		jal display_set_pixel
		
		
		# if x--
		sub a0, s0, 1
		
		# if x > 0
		blt a0, 0, _x_greater_brk
		
		move a1, s1
		move a2, s2
		move a3, s3
		
		jal floodfill_rec
		
		
		# return the result of the recursion
		_x_greater_brk:
		
		add a0, s0, 1
		
		bge a0, 127, _x_less_brk
		
		move a1, s1
		move a2, s2
		move a3, s3
		
		jal floodfill_rec
		
		_x_less_brk:
		
			sub a1, s1, 1
			
			blt a1, 0, _y_greater_brk
			
			move a0, s0
			move a2, s2
			move a3, s3
			
			jal floodfill_rec
			
		_y_greater_brk:
			
			add a1, s1, 1
			
			
			bge a1, 127, _y_less_brk
			
			move a0, s0
			move a2, s2
			move a3, s3
			
			jal floodfill_rec
			
		_y_less_brk:
		
				
		_return:
		
		pop s3
		pop s2
		pop s1
		pop s0
		pop ra 
		jr ra
	# -----------------------------
	display_get_pixel:
		push ra
		
		sll t0, a1, DISPLAY_W_SHIFT
		add t0, t0, a0
		 lb v0, display_fb_ram(t0)
		
		pop ra
		jr ra
		
		
