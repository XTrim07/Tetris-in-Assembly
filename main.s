# main.s - Human Tetris game in assembly (x86-64, GAS syntax)
# Based on the Python project Tetris-Research-RL-Framework, only the
# human gameplay part (without AI): you choose column + rotation, the piece drops instantly.
# Board: 10 columns x 15 rows. Score: 100/300/500/800 as in board.py.
#
# Build (like the other projects in assembly_project):
#   gcc -no-pie -o tetris main.s
# Run:
#   ./tetris
#
# Registers: %rbx, %r12-%r15 are saved by functions (callee saved),
# the rest may be clobbered by a call (caller saved).

.global main

.include "pieces.s"
.include "board.s"
.include "leaderboard.s"
.include "display.s"
.include "input.s"

.text
main:
    # prolog
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    subq $8, %rsp             # align stack to 16 bytes

    # seed for rand(): srand(time(0)) initializes the rand to 0
    movq $0, %rdi
    movq $0, %rax
    call time
    movq %rax, %rdi
    movq $0, %rax
    call srand

    # empty board + first pieces
    call init_board
    call first_pieces

    # leaderboard: load the list, ask for the name, load the account
    call lb_load
    call lb_login

game_loop:
    call clear_screen
    call draw_board
    call read_key              # key in %rax
    movq %rax, %rdi
    call handle_key            # 0 = continue, 1 = placed, 2 = exit
    cmpq $2, %rax
    je game_exit
    call lb_update             # save the record if the score increased
    jmp game_loop

game_exit:
    call lb_update             # save the record on exit too
    # epilog
    addq $8, %rsp
    popq %rbx
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    ret
