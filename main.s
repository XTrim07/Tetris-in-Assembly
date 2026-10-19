# main.s - Joc Tetris human in assembly (x86-64, sintaxa GAS)
# Urmeaza proiectul Python Tetris-Research-RL-Framework, doar partea
# de joc human (fara AI): alegi coloana + rotatia, piesa cade instant.
# Tabla: 10 coloane x 15 randuri. Scor: 100/300/500/800 ca in board.py.
#
# Compilare (ca la celelalte proiecte din assembly_project):
#   gcc -no-pie -o tetris main.s
# Rulare:
#   ./tetris
#
# Registre: %rbx, %r12-%r15 se salveaza de functii (callee saved),
# restul se pot pierde la call (caller saved).

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
    subq $8, %rsp             # aliniere stiva la 16 bytes

    # seed pentru rand(): srand(time(0))
    movq $0, %rdi
    movq $0, %rax
    call time
    movq %rax, %rdi
    movq $0, %rax
    call srand

    # tabla goala + primele piese
    call init_board
    call first_pieces

    # leaderboard: citim lista, cerem numele, incarcam contul
    call lb_load
    call lb_login

game_loop:
    call clear_screen
    call draw_board
    call read_key              # tasta in %rax
    movq %rax, %rdi
    call handle_key            # 0 = continua, 1 = a pus, 2 = iesi
    cmpq $2, %rax
    je game_exit
    call lb_update             # salveaza recordul daca scorul a crescut
    jmp game_loop

game_exit:
    call lb_update             # salveaza recordul si la iesire
    # epilog
    addq $8, %rsp
    popq %rbx
    movq $0, %rax
    movq %rbp, %rsp
    popq %rbp
    ret
