# board.s - tabla de joc 10 latime x 15 inaltime
# Logica e ca in board.py: piesa cade instant pe landing_row,
# liniile pline se sterg, scor 100/300/500/800.

.bss
.global board
board: .space 150          # 15 randuri x 10 coloane, 0 = gol, 1-7 = piesa

.data
.global score, lines_cleared, pieces_placed, game_over
.global cur_piece, next_piece, sel_col, sel_rot, ghost_row, msg_invalid
score:          .quad 0
lines_cleared:  .quad 0
pieces_placed:  .quad 0
game_over:      .quad 0
cur_piece:      .quad 0
next_piece:     .quad 1
sel_col:        .quad 0
sel_rot:        .quad 0
ghost_row:      .quad 0
msg_invalid:    .quad 0     # 1 = ultima plasare respinsa (nu incape lateral)

.text

# rand7: -> %rax numar 0-6 (folosim rand din C)
.global rand7
rand7:
    pushq %rbp
    movq %rsp, %rbp
    call rand                # rezultat in %eax
    movl %eax, %ecx
    xorl %edx, %edx
    movl $7, %esi
    movl %ecx, %eax
    divl %esi                # restul in %edx
    movq %rdx, %rax
    popq %rbp
    ret

# init_board: goleste tabla si scorurile
.global init_board
init_board:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    movq $board, %rbx
    movq $0, %rcx
ib_loop:
    cmpq $150, %rcx
    jge ib_done
    movb $0, (%rbx, %rcx, 1)
    incq %rcx
    jmp ib_loop
ib_done:
    movq $0, %rax
    movq %rax, score
    movq %rax, lines_cleared
    movq %rax, pieces_placed
    movq %rax, game_over
    movq %rax, sel_col
    movq %rax, sel_rot
    movq %rax, ghost_row
    movq %rax, msg_invalid
    popq %rbx
    popq %rbp
    ret

# first_pieces: trage piesa curenta si urmatoarea
.global first_pieces
first_pieces:
    pushq %rbp
    movq %rsp, %rbp
    call rand7
    movq %rax, cur_piece
    call rand7
    movq %rax, next_piece
    popq %rbp
    ret

# board_get: %rdi = rand, %rsi = col -> %rax = valoare
.global board_get
board_get:
    movq %rdi, %rax
    imulq $10, %rax          # rand * 10
    addq %rsi, %rax          # + col
    movq $board, %rdx
    movzbq (%rdx, %rax, 1), %rax
    ret

# board_set: %rdi = rand, %rsi = col, %rdx = valoare
.global board_set
board_set:
    movq %rdi, %rax
    imulq $10, %rax
    addq %rsi, %rax
    movq $board, %rcx
    movb %dl, (%rcx, %rax, 1)
    ret

# collides: %rdi = rand, %rsi = col, %rdx = tip, %rcx = rot -> %rax = 1/0
.global collides
collides:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp            # aliniere stiva pentru call
    movq %rdi, %r12          # rand
    movq %rsi, %r13          # col
    movq %rdx, %r14          # tip
    movq %rcx, %r15          # rot
    # latime si inaltime piesa
    movq %r14, %rdi
    movq %r15, %rsi
    call piece_w
    movq %rax, %rbx          # latime in %rbx
    movq %r14, %rdi
    movq %r15, %rsi
    call piece_h             # inaltime in %rax
    # verificare margini
    cmpq $0, %r12
    jl col_yes
    cmpq $0, %r13
    jl col_yes
    movq %r12, %rcx
    addq %rax, %rcx
    cmpq $15, %rcx
    jg col_yes
    movq %r13, %rcx
    addq %rbx, %rcx
    cmpq $10, %rcx
    jg col_yes
    # verificare suprapunere cu piese vechi
    movq $0, %r10            # i = rand in piesa
col_i:
    cmpq %rax, %r10
    jge col_no               # am terminat, nu e coliziune
    movq $0, %r11            # j = col in piesa
col_j:
    cmpq %rbx, %r11
    jge col_next_i
    movq %r14, %rdi
    movq %r15, %rsi
    movq %r10, %rdx
    movq %r11, %rcx
    call piece_cell
    cmpq $0, %rax
    je col_next_j            # patrat gol in piesa, trecem mai departe
    # patrat plin: verificam tabla
    movq %r12, %rdi
    addq %r10, %rdi
    movq %r13, %rsi
    addq %r11, %rsi
    call board_get
    cmpq $0, %rax
    jne col_yes              # tabla ocupata = coliziune
col_next_j:
    incq %r11
    jmp col_j
col_next_i:
    incq %r10
    # trebuie sa re-citim inaltimea (rax s-a stricat)
    movq %r14, %rdi
    movq %r15, %rsi
    call piece_h
    jmp col_i
col_no:
    movq $0, %rax
    jmp col_end
col_yes:
    movq $1, %rax
col_end:
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

# landing_row: %rdi = col, %rsi = tip, %rdx = rot -> %rax = rand sau -1
.global landing_row
landing_row:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    subq $16, %rsp
    movq %rdi, %r12          # col
    movq %rsi, %r13          # tip
    movq %rdx, %r14          # rot
    movq $0, %rbx            # rand curent
lr_loop:
    cmpq $15, %rbx
    jge lr_bottom
    movq %rbx, %rdi
    movq %r12, %rsi
    movq %r13, %rdx
    movq %r14, %rcx
    call collides
    cmpq $1, %rax
    je lr_found              # am lovit ceva, stam pe randul anterior
    incq %rbx
    jmp lr_loop
lr_found:
    movq %rbx, %rax
    decq %rax                # rand - 1 (poate fi -1 = invalid)
    jmp lr_end
lr_bottom:
    # ajunge jos: ultimul rand valid
    movq %r13, %rdi
    movq %r14, %rsi
    call piece_h
    movq $15, %rcx
    subq %rax, %rcx
    movq %rcx, %rax
lr_end:
    addq $16, %rsp
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

# has_valid: -> %rax = 1 daca piesa curenta mai poate fi pusa undeva
.global has_valid
has_valid:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp
    movq cur_piece, %r12     # tip
    movq %r12, %rdi
    call num_rots
    movq %rax, %r13          # numar rotatii
    movq $0, %rbx            # rot = 0
hv_rot:
    cmpq %r13, %rbx
    jge hv_no
    # latime pentru rotatia asta
    movq %r12, %rdi
    movq %rbx, %rsi
    call piece_w             # latime in %rax
    movq $10, %r14
    subq %rax, %r14          # ultima coloana incercata (in %r14, registru salvat)
    movq $0, %r15            # col = 0 (in %r15, salvat peste call-uri)
hv_col:
    cmpq %r14, %r15
    jg hv_next_rot
    movq %r15, %rdi
    movq %r12, %rsi
    movq %rbx, %rdx
    call landing_row
    cmpq $0, %rax
    jge hv_yes               # am gasit un loc bun
    incq %r15
    jmp hv_col
hv_next_rot:
    incq %rbx
    jmp hv_rot
hv_no:
    movq $0, %rax
    jmp hv_end
hv_yes:
    movq $1, %rax
hv_end:
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

# clear_lines: -> %rax = cate linii s-au sters acum
.global clear_lines
clear_lines:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp            # aliniere stiva pentru call
    movq $14, %r12           # pornim de jos in sus
    movq $0, %r15            # linii sterse
cl_row:
    cmpq $0, %r12
    jl cl_done
    # verificam daca randul e plin
    movq $0, %r13            # col
    movq $1, %r14            # presupunem ca e plin
cl_check:
    cmpq $10, %r13
    jge cl_full_check
    movq %r12, %rdi
    movq %r13, %rsi
    call board_get
    cmpq $0, %rax
    je cl_not_full
    incq %r13
    jmp cl_check
cl_not_full:
    movq $0, %r14
cl_full_check:
    cmpq $1, %r14
    jne cl_next
    # rand plin: mutam tot ce e deasupra cu o linie in jos
    movq %r12, %rbx          # rand destinatie
cl_shift:
    cmpq $0, %rbx
    jle cl_top
    movq $0, %r13
cl_copy:
    cmpq $10, %r13
    jge cl_shift_next
    movq %rbx, %rdi
    decq %rdi                # rand sursa = destinatie - 1
    movq %r13, %rsi
    call board_get           # valoare de sus
    movq %rax, %rdx
    movq %rbx, %rdi
    movq %r13, %rsi
    call board_set
    incq %r13
    jmp cl_copy
cl_shift_next:
    decq %rbx
    jmp cl_shift
cl_top:
    # prima linie devine goala
    movq $0, %r13
cl_zero:
    cmpq $10, %r13
    jge cl_erased
    movq $0, %rdi
    movq %r13, %rsi
    movq $0, %rdx
    call board_set
    incq %r13
    jmp cl_zero
cl_erased:
    incq %r15
    # ramai pe acelasi rand (a cazut altul peste el)
    jmp cl_row
cl_next:
    decq %r12
    jmp cl_row
cl_done:
    # adunam la total si la scor
    movq lines_cleared, %rax
    addq %r15, %rax
    movq %rax, lines_cleared
    movq %r15, %rdi
    call add_score
    movq %r15, %rax
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

# add_score: %rdi = linii (0-4) -> aduna puncte ca in Python
.global add_score
add_score:
    cmpq $0, %rdi
    je as_end
    cmpq $1, %rdi
    je as_100
    cmpq $2, %rdi
    je as_300
    cmpq $3, %rdi
    je as_500
    # 4 sau mai multe linii
    movq score, %rax
    addq $800, %rax
    movq %rax, score
    ret
as_100:
    movq score, %rax
    addq $100, %rax
    movq %rax, score
    ret
as_300:
    movq score, %rax
    addq $300, %rax
    movq %rax, score
    ret
as_500:
    movq score, %rax
    addq $500, %rax
    movq %rax, score
as_end:
    ret

# place_piece: %rdi = col, %rsi = rot -> %rax = 1 ok, 0 esec
.global place_piece
place_piece:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp
    movq %rdi, %r12          # col
    movq %rsi, %r13          # rot
    movq cur_piece, %r14     # tip
    # unde cade piesa?
    movq %r12, %rdi
    movq %r14, %rsi
    movq %r13, %rdx
    call landing_row
    cmpq $0, %rax
    jl pp_fail               # sub tabla = game over
    movq %rax, %r15          # rand de plasare
    # scriem piesa pe tabla (valoare = tip + 1)
    movq %r14, %rdi
    movq %r13, %rsi
    call piece_w
    movq %rax, %rbx          # latime
    movq %r14, %rdi
    movq %r13, %rsi
    call piece_h
    # %rax = inaltime, o pastram pe stiva
    movq %rax, (%rsp)
    movq $0, %r10            # i
pp_i:
    movq (%rsp), %rcx
    cmpq %rcx, %r10
    jge pp_written
    movq $0, %r11            # j
pp_j:
    cmpq %rbx, %r11
    jge pp_next_i
    movq %r14, %rdi
    movq %r13, %rsi
    movq %r10, %rdx
    movq %r11, %rcx
    call piece_cell
    cmpq $0, %rax
    je pp_next_j
    movq %r15, %rdi
    addq %r10, %rdi
    movq %r12, %rsi
    addq %r11, %rsi
    movq %r14, %rdx
    incq %rdx                # valoare = tip + 1
    call board_set
pp_next_j:
    incq %r11
    jmp pp_j
pp_next_i:
    incq %r10
    jmp pp_i
pp_written:
    movq pieces_placed, %rax
    incq %rax
    movq %rax, pieces_placed
    call clear_lines         # sterge linii + scor
    # piesa urmatoare devine curenta
    movq next_piece, %rax
    movq %rax, cur_piece
    call rand7
    movq %rax, next_piece
    movq $0, %rax
    movq %rax, sel_col
    movq %rax, sel_rot
    # mai exista vreo mutare? daca nu, game over
    call has_valid
    cmpq $0, %rax
    jne pp_ok
    movq $1, %rax
    movq %rax, game_over
pp_ok:
    movq $1, %rax
    jmp pp_end
pp_fail:
    movq $1, %rax
    movq %rax, game_over
    movq $0, %rax
pp_end:
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

# update_ghost: calculeaza randul de cadere pentru selectia curenta
.global update_ghost
update_ghost:
    pushq %rbp
    movq %rsp, %rbp
    movq sel_col, %rdi
    movq cur_piece, %rsi
    movq sel_rot, %rdx
    call landing_row
    movq %rax, ghost_row
    popq %rbp
    ret
