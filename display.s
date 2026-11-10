# display.s - render the game in the terminal with ANSI colors
# Instead of graphics.h (not available on Ubuntu) we use printf
# with escape sequences, like in decoder.s from A3_MemoryInputs.

.data
fmt_player:  .asciz "Player: %s | High score: %ld\n"
fmt_title:   .asciz "\n=== TETRIS GAME ===\n"
fmt_top:     .asciz "+--------------------+\n"
fmt_bar:     .asciz "|"
fmt_bar_end: .asciz "|\n"
fmt_sel_l:   .asciz " "
fmt_arrow:   .asciz "^ "
fmt_arrow_sp:.asciz "  "
fmt_nl:      .asciz "\n"
fmt_nums:    .asciz "  1 2 3 4 5 6 7 8 9 0\n"
fmt_stats:   .asciz "Score: %ld | Lines: %ld | Pieces: %ld\n"
fmt_cur:     .asciz "Piece: %s | Next: %s | Col: %ld | Rot: %ld | lands on row %ld\n"
fmt_prev_cur:.asciz "Current piece (rot %ld) - like this:\n"
fmt_prev_nxt:.asciz "Next:\n"
fmt_ctrl:    .asciz "Controls: A/D = left/right, R = rotate, S = place, Q = quit\n"
fmt_invalid: .asciz "\x1b[31mNot allowed here! The piece doesn't fit at this column.\x1b[0m\n"
fmt_lb:      .asciz "  %s - %ld\n"
fmt_lb_me:   .asciz "> %s - %ld\n"
fmt_lb_head: .asciz "=== LEADERBOARD ===\n"
fmt_over:    .asciz "\n*** GAME OVER *** Final score: %ld\nPress N for a new game or Q to quit.\n"
# colored squares (colored background + reset)
cell_e: .asciz "  "
cell_1: .asciz "\x1b[106m[]\x1b[0m"       # I - cyan
cell_2: .asciz "\x1b[43m[]\x1b[0m"        # O - yellow
cell_3: .asciz "\x1b[45m[]\x1b[0m"        # T - purple
cell_4: .asciz "\x1b[42m[]\x1b[0m"        # S - green
cell_5: .asciz "\x1b[41m[]\x1b[0m"        # Z - red
cell_6: .asciz "\x1b[44m[]\x1b[0m"        # J - blue
cell_7: .asciz "\x1b[48;5;208m[]\x1b[0m"  # L - orange
cell_g: .asciz "\x1b[90m::\x1b[0m"        # ghost (preview)
# piece names
nm_i: .asciz "I"
nm_o: .asciz "O"
nm_t: .asciz "T"
nm_s: .asciz "S"
nm_z: .asciz "Z"
nm_j: .asciz "J"
nm_l: .asciz "L"
piece_names: .quad nm_i, nm_o, nm_t, nm_s, nm_z, nm_j, nm_l

.text

# piece_name: %rdi = type -> %rax = pointer to name
.global piece_name
piece_name:
    movq $piece_names, %rax
    movq (%rax, %rdi, 8), %rax
    ret

# print_cell_val: %rdi = value 0-7 -> prints the colored square
.global print_cell_val
print_cell_val:
    pushq %rbp
    movq %rsp, %rbp
    cmpq $1, %rdi
    je pcv_1
    cmpq $2, %rdi
    je pcv_2
    cmpq $3, %rdi
    je pcv_3
    cmpq $4, %rdi
    je pcv_4
    cmpq $5, %rdi
    je pcv_5
    cmpq $6, %rdi
    je pcv_6
    cmpq $7, %rdi
    je pcv_7
    movq $cell_e, %rdi
    movq $0, %rax
    call printf
    jmp pcv_end
pcv_1:
    movq $cell_1, %rdi
    movq $0, %rax
    call printf
    jmp pcv_end
pcv_2:
    movq $cell_2, %rdi
    movq $0, %rax
    call printf
    jmp pcv_end
pcv_3:
    movq $cell_3, %rdi
    movq $0, %rax
    call printf
    jmp pcv_end
pcv_4:
    movq $cell_4, %rdi
    movq $0, %rax
    call printf
    jmp pcv_end
pcv_5:
    movq $cell_5, %rdi
    movq $0, %rax
    call printf
    jmp pcv_end
pcv_6:
    movq $cell_6, %rdi
    movq $0, %rax
    call printf
    jmp pcv_end
pcv_7:
    movq $cell_7, %rdi
    movq $0, %rax
    call printf
pcv_end:
    popq %rbp
    ret

# is_ghost: %rdi = row, %rsi = col -> %rax = 1 if it is part of the preview
.global is_ghost
is_ghost:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    subq $8, %rsp
    movq ghost_row, %rax
    cmpq $0, %rax
    jl igh_no                 # negative row = invalid placement
    movq %rdi, %r12           # row
    movq %rsi, %r13           # col
    subq %rax, %r12           # relative row in piece
    jl igh_no
    movq sel_col, %rax
    subq %rax, %r13           # relative col in piece
    jl igh_no
    movq cur_piece, %rdi
    movq sel_rot, %rsi
    movq %r12, %rdx
    movq %r13, %rcx
    call piece_cell           # 1 if the cell belongs to the piece
    jmp igh_end
igh_no:
    movq $0, %rax
igh_end:
    movq %rax, %rbx
    addq $8, %rsp
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    movq %rbx, %rax
    ret

# draw_one_piece: %rdi = type, %rsi = rot -> draws the piece shape
# (shows exactly how it will look when placed)
.global draw_one_piece
draw_one_piece:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp            # align stack for printf
    movq %rdi, %r14          # type (stays here, saved register)
    movq %rsi, %rbx          # rot (stays here, saved register)
    movq $0, %r12            # row = 0
dop_row:
    movq %r14, %rdi
    movq %rbx, %rsi
    call piece_h
    cmpq %rax, %r12
    jge dop_done
    movq $0, %r13            # col = 0
dop_col:
    movq %r14, %rdi
    movq %rbx, %rsi
    call piece_w
    cmpq %rax, %r13
    jge dop_next_row
    movq %r14, %rdi
    movq %rbx, %rsi
    movq %r12, %rdx
    movq %r13, %rcx
    call piece_cell
    cmpq $0, %rax
    je dop_empty
    movq %r14, %rdi
    incq %rdi                # color = type + 1
    call print_cell_val
    jmp dop_next_col
dop_empty:
    movq $cell_e, %rdi
    movq $0, %rax
    call printf
dop_next_col:
    incq %r13
    jmp dop_col
dop_next_row:
    movq $fmt_nl, %rdi
    movq $0, %rax
    call printf
    incq %r12
    jmp dop_row
dop_done:
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

# draw_preview: shows the current piece (with the chosen rotation) + the next one,
# above the board. It is redrawn on every key, so on R you see
# the new piece position immediately.
.global draw_preview
draw_preview:
    pushq %rbp
    movq %rsp, %rbp
    movq $fmt_prev_cur, %rdi
    movq sel_rot, %rsi
    movq $0, %rax
    call printf
    movq cur_piece, %rdi
    movq sel_rot, %rsi
    call draw_one_piece
    movq $fmt_prev_nxt, %rdi
    movq $0, %rax
    call printf
    movq next_piece, %rdi
    movq $0, %rsi
    call draw_one_piece
    popq %rbp
    ret

# draw_board: draws the whole screen
.global draw_board
draw_board:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp            # align stack for printf
    # title
    movq $fmt_title, %rdi
    movq $0, %rax
    call printf
    # player name + high score, at the very top
    movq $fmt_player, %rdi
    movq $player_name, %rsi
    movq player_high, %rdx
    movq $0, %rax
    call printf
    # update the ghost row
    call update_ghost
    # preview current piece + next one, above the board
    call draw_preview
    # top border
    movq $fmt_top, %rdi
    movq $0, %rax
    call printf
    movq $0, %r12             # row = 0
dr_row:
    cmpq $15, %r12
    jge dr_rows_done
    movq $fmt_bar, %rdi
    movq $0, %rax
    call printf
    movq $0, %r13             # col = 0
dr_col:
    cmpq $10, %r13
    jge dr_row_end
    movq %r12, %rdi
    movq %r13, %rsi
    call board_get            # board value in %rax
    movq %rax, %r14
    cmpq $0, %r14
    jne dr_real
    # empty: check the ghost
    movq %r12, %rdi
    movq %r13, %rsi
    call is_ghost
    cmpq $1, %rax
    jne dr_empty
    movq $cell_g, %rdi
    movq $0, %rax
    call printf
    jmp dr_next
dr_empty:
    movq $cell_e, %rdi
    movq $0, %rax
    call printf
    jmp dr_next
dr_real:
    movq %r14, %rdi
    call print_cell_val
dr_next:
    incq %r13
    jmp dr_col
dr_row_end:
    movq $fmt_bar_end, %rdi
    movq $0, %rax
    call printf
    incq %r12
    jmp dr_row
dr_rows_done:
    # bottom border
    movq $fmt_top, %rdi
    movq $0, %rax
    call printf
    # column numbers
    movq $fmt_nums, %rdi
    movq $0, %rax
    call printf
    # arrow below the selected column
    movq $fmt_sel_l, %rdi
    movq $0, %rax
    call printf
    movq $0, %r13
dr_arr:
    cmpq $10, %r13
    jge dr_arr_end
    movq sel_col, %rax
    cmpq %rax, %r13
    je dr_is_sel
    movq $fmt_arrow_sp, %rdi
    movq $0, %rax
    call printf
    jmp dr_arr_next
dr_is_sel:
    movq $fmt_arrow, %rdi
    movq $0, %rax
    call printf
dr_arr_next:
    incq %r13
    jmp dr_arr
dr_arr_end:
    movq $fmt_nl, %rdi
    movq $0, %rax
    call printf
    # stats
    movq $fmt_stats, %rdi
    movq score, %rsi
    movq lines_cleared, %rdx
    movq pieces_placed, %rcx
    movq $0, %rax
    call printf
    # current piece + next one + selection
    movq cur_piece, %rdi
    call piece_name
    movq %rax, %rbx           # current name
    movq next_piece, %rdi
    call piece_name
    movq %rax, %r15           # next name
    movq $fmt_cur, %rdi
    movq %rbx, %rsi
    movq %r15, %rdx
    movq sel_col, %rcx
    movq sel_rot, %r8
    movq ghost_row, %r9
    movq $0, %rax
    call printf
    # controls or game over
    movq game_over, %rax
    cmpq $1, %rax
    je dr_over
    movq $fmt_ctrl, %rdi
    movq $0, %rax
    call printf
    jmp dr_msg
dr_over:
    movq $fmt_over, %rdi
    movq score, %rsi
    movq $0, %rax
    call printf
dr_msg:
    # if the last placement was rejected (does not fit sideways),
    # we show the message, without game over
    movq msg_invalid, %rax
    cmpq $1, %rax
    jne dr_lb
    movq $fmt_invalid, %rdi
    movq $0, %rax
    call printf
    jmp dr_lb
dr_lb:
    # real-time leaderboard, below the controls (> = current player)
    movq $fmt_lb_head, %rdi
    movq $0, %rax
    call printf
    movq $0, %rbx             # i
dlb_loop:
    cmpq lb_count, %rbx
    jge dr_end
    movq $fmt_lb, %rdi
    cmpq player_idx, %rbx
    jne dlb_show
    movq $fmt_lb_me, %rdi
dlb_show:
    # printf(fmt, name, score) - arg1 = %rsi, arg2 = %rdx
    movq %rbx, %rax
    imulq $32, %rax
    movq $lb_names, %rsi
    addq %rax, %rsi
    movq %rbx, %rax
    imulq $8, %rax
    movq $lb_scores, %rdx
    addq %rax, %rdx
    movq (%rdx), %rdx
    movq $0, %rax
    call printf
    incq %rbx
    jmp dlb_loop
dr_end:
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret
