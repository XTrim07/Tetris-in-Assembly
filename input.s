# input.s - read keys from the player
# Controls (like in human_player.py, adapted to the terminal):
# A/D = column left/right, R = rotate, SPACE = place piece,
# 1-9,0 = jump to column, Q = quit, N = new game after game over.

.bss
keybuf: .space 8

.data
fmt_prompt: .asciz "Move (a/d/r/s, 1-9/0, q=quit): "
fmt_scan:   .asciz " %c"
clear_cmd:  .asciz "clear"

.text

# clear_screen: clears the terminal (system("clear"))
.global clear_screen
clear_screen:
    pushq %rbp
    movq %rsp, %rbp
    movq $clear_cmd, %rdi
    movq $0, %rax
    call system
    popq %rbp
    ret

# read_key: -> %rax = the pressed character
.global read_key
read_key:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    subq $8, %rsp            # align stack for printf/scanf
    movq $fmt_prompt, %rdi
    movq $0, %rax
    call printf
    movq $fmt_scan, %rdi
    movq $keybuf, %rsi
    movq $0, %rax
    call scanf
    movzbq keybuf, %rax
    addq $8, %rsp
    popq %rbx
    popq %rbp
    ret

# handle_key: %rdi = key -> %rax = 0 continue, 1 place, 2 exit
.global handle_key
handle_key:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    subq $16, %rsp           # align stack for call
    movq %rdi, %rbx           # key
    # if the game is over, only N or Q matter
    movq game_over, %rax
    cmpq $1, %rax
    je hk_over
    # clear the "not allowed" message on any new key;
    # hk_place puts it back if the placement is rejected
    movq $0, %rax
    movq %rax, msg_invalid
    # Q = quit
    cmpq $113, %rbx           # 'q'
    je hk_quit
    cmpq $81, %rbx            # 'Q'
    je hk_quit
    # A = left
    cmpq $97, %rbx            # 'a'
    je hk_left
    cmpq $65, %rbx            # 'A'
    je hk_left
    # D = right
    cmpq $100, %rbx           # 'd'
    je hk_right
    cmpq $68, %rbx            # 'D'
    je hk_right
    # R or W = rotate
    cmpq $114, %rbx           # 'r'
    je hk_rot
    cmpq $82, %rbx            # 'R'
    je hk_rot
    cmpq $119, %rbx           # 'w'
    je hk_rot
    cmpq $87, %rbx            # 'W'
    je hk_rot
    # SPACE = place piece (works only if scanf does not skip it; that is why
    # we also accept S as the main placement key)
    cmpq $32, %rbx
    je hk_place
    cmpq $115, %rbx           # 's'
    je hk_place
    cmpq $83, %rbx            # 'S'
    je hk_place
    # digits: '0' = column 9, '1'-'9' = columns 0-8
    # ('0' is checked first, because 48 < 49)
    cmpq $48, %rbx            # '0'
    je hk_zero
    cmpq $49, %rbx            # '1'
    jl hk_done
    cmpq $57, %rbx            # '9'
    jg hk_done
    jmp hk_digit
hk_digit:
    subq $49, %rbx            # '1' -> 0
    movq %rbx, sel_col
    # do not leave the board
    movq sel_col, %rax
    cmpq $9, %rax
    jle hk_done
    movq $9, %rax
    movq %rax, sel_col
    jmp hk_done
hk_zero:
    movq $9, %rax
    movq %rax, sel_col
    jmp hk_done
hk_left:
    movq sel_col, %rax
    cmpq $0, %rax
    jle hk_done
    decq %rax
    movq %rax, sel_col
    jmp hk_done
hk_right:
    movq sel_col, %rax
    cmpq $9, %rax
    jge hk_done
    incq %rax
    movq %rax, sel_col
    jmp hk_done
hk_rot:
    # rot = (rot + 1) % number_of_rotations
    movq cur_piece, %rdi
    call num_rots
    movq %rax, %r12           # number of rotations
    movq sel_rot, %rax
    incq %rax
    xorq %rdx, %rdx
    divq %r12                 # remainder in %rdx
    movq %rdx, sel_rot
    jmp hk_done
hk_place:
    # check if the piece fits horizontally at the chosen column;
    # if not, it is NOT game over, we just reject the move
    movq cur_piece, %rdi
    movq sel_rot, %rsi
    call piece_w              # width in %rax
    addq sel_col, %rax
    cmpq $10, %rax
    jg hk_reject
    movq sel_col, %rdi
    movq sel_rot, %rsi
    call place_piece
    movq $1, %rax
    jmp hk_end
hk_reject:
    # not allowed here: the piece would leave the board sideways
    movq $1, %rax
    movq %rax, msg_invalid
    movq $0, %rax
    jmp hk_end
hk_over:
    # after game over: N = new game, Q = quit
    cmpq $110, %rbx           # 'n'
    je hk_new
    cmpq $78, %rbx            # 'N'
    je hk_new
    cmpq $113, %rbx
    je hk_quit
    cmpq $81, %rbx
    je hk_quit
    jmp hk_done
hk_new:
    call init_board
    call first_pieces
    jmp hk_done
hk_quit:
    movq $2, %rax
    jmp hk_end
hk_done:
    movq $0, %rax
hk_end:
    addq $16, %rsp
    popq %r12
    popq %rbx
    popq %rbp
    ret
