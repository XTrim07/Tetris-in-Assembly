# display.s - afisare joc in terminal cu culori ANSI
# In loc de graphics.h (nu exista pe Ubuntu) folosim printf
# cu secvente escape, ca in decoder.s din A3_MemoryInputs.

.data
fmt_title:   .asciz "\n=== TETRIS GAME ===\n"
fmt_top:     .asciz "+--------------------+\n"
fmt_bar:     .asciz "|"
fmt_bar_end: .asciz "|\n"
fmt_sel_l:   .asciz " "
fmt_arrow:   .asciz "^ "
fmt_arrow_sp:.asciz "  "
fmt_nl:      .asciz "\n"
fmt_nums:    .asciz "  1 2 3 4 5 6 7 8 9 0\n"
fmt_stats:   .asciz "Scor: %ld | Linii: %ld | Piese: %ld\n"
fmt_cur:     .asciz "Piesa: %s | Urm: %s | Col: %ld | Rot: %ld | cade pe randul %ld\n"
fmt_prev_cur:.asciz "Piesa curenta (rot %ld) - asa va fi pusa:\n"
fmt_prev_nxt:.asciz "Urmatoarea:\n"
fmt_ctrl:    .asciz "Comenzi: A/D = stanga/dreapta, R = rotire, S = pune, Q = iesire\n"
fmt_invalid: .asciz "\x1b[31mNu e voie aici! Piesa nu incape la coloana asta.\x1b[0m\n"
fmt_over:    .asciz "\n*** GAME OVER *** Scor final: %ld\nApasa N pentru joc nou sau Q pentru iesire.\n"
# patratele colorate (fundal colorat + reset)
cell_e: .asciz "  "
cell_1: .asciz "\x1b[106m[]\x1b[0m"       # I - cyan
cell_2: .asciz "\x1b[43m[]\x1b[0m"        # O - galben
cell_3: .asciz "\x1b[45m[]\x1b[0m"        # T - mov
cell_4: .asciz "\x1b[42m[]\x1b[0m"        # S - verde
cell_5: .asciz "\x1b[41m[]\x1b[0m"        # Z - rosu
cell_6: .asciz "\x1b[44m[]\x1b[0m"        # J - albastru
cell_7: .asciz "\x1b[48;5;208m[]\x1b[0m"  # L - portocaliu
cell_g: .asciz "\x1b[90m::\x1b[0m"        # fantoma (preview)
# nume piese
nm_i: .asciz "I"
nm_o: .asciz "O"
nm_t: .asciz "T"
nm_s: .asciz "S"
nm_z: .asciz "Z"
nm_j: .asciz "J"
nm_l: .asciz "L"
piece_names: .quad nm_i, nm_o, nm_t, nm_s, nm_z, nm_j, nm_l

.text

# piece_name: %rdi = tip -> %rax = pointer la nume
.global piece_name
piece_name:
    movq $piece_names, %rax
    movq (%rax, %rdi, 8), %rax
    ret

# print_cell_val: %rdi = valoare 0-7 -> afiseaza patratul colorat
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

# is_ghost: %rdi = rand, %rsi = col -> %rax = 1 daca e parte din preview
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
    jl igh_no                 # rand negativ = plasare invalida
    movq %rdi, %r12           # rand
    movq %rsi, %r13           # col
    subq %rax, %r12           # rand relativ in piesa
    jl igh_no
    movq sel_col, %rax
    subq %rax, %r13           # col relativ in piesa
    jl igh_no
    movq cur_piece, %rdi
    movq sel_rot, %rsi
    movq %r12, %rdx
    movq %r13, %rcx
    call piece_cell           # 1 daca patratul apartine piesei
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

# draw_one_piece: %rdi = tip, %rsi = rot -> deseneaza forma piesei
# (se vede exact cum va arata la plasare)
.global draw_one_piece
draw_one_piece:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp            # aliniere stiva pentru printf
    movq %rdi, %r14          # tip (ramane aici, registre salvat)
    movq %rsi, %rbx          # rot (ramane aici, registru salvat)
    movq $0, %r12            # rand = 0
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
    incq %rdi                # culoare = tip + 1
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

# draw_preview: arata piesa curenta (cu rotatia aleasa) + urmatoarea,
# deasupra tablei. Se redeseneaza la fiecare tasta, deci la R vezi
# imediat noua pozitie a piesei.
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

# draw_board: deseneaza tot ecranul
.global draw_board
draw_board:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    subq $8, %rsp            # aliniere stiva pentru printf
    # titlu
    movq $fmt_title, %rdi
    movq $0, %rax
    call printf
    # actualizam randul fantoma
    call update_ghost
    # preview piesa curenta + urmatoarea, deasupra tablei
    call draw_preview
    # margine sus
    movq $fmt_top, %rdi
    movq $0, %rax
    call printf
    movq $0, %r12             # rand = 0
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
    call board_get            # valoare tabla in %rax
    movq %rax, %r14
    cmpq $0, %r14
    jne dr_real
    # gol: verificam fantoma
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
    # margine jos
    movq $fmt_top, %rdi
    movq $0, %rax
    call printf
    # numere coloane
    movq $fmt_nums, %rdi
    movq $0, %rax
    call printf
    # sageata sub coloana selectata
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
    # statistici
    movq $fmt_stats, %rdi
    movq score, %rsi
    movq lines_cleared, %rdx
    movq pieces_placed, %rcx
    movq $0, %rax
    call printf
    # piesa curenta + urmatoare + selectie
    movq cur_piece, %rdi
    call piece_name
    movq %rax, %rbx           # nume curenta
    movq next_piece, %rdi
    call piece_name
    movq %rax, %r15           # nume urmatoare
    movq $fmt_cur, %rdi
    movq %rbx, %rsi
    movq %r15, %rdx
    movq sel_col, %rcx
    movq sel_rot, %r8
    movq ghost_row, %r9
    movq $0, %rax
    call printf
    # controale sau game over
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
    # daca ultima plasare a fost respinsa (nu incape lateral),
    # afisam mesajul, fara game over
    movq msg_invalid, %rax
    cmpq $1, %rax
    jne dr_end
    movq $fmt_invalid, %rdi
    movq $0, %rax
    call printf
    jmp dr_end
dr_end:
    addq $8, %rsp
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret
