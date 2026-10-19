# input.s - citire taste de la jucator
# Controale (ca in human_player.py, adaptat la terminal):
# A/D = coloana stanga/dreapta, R = rotire, SPACE = pune piesa,
# 1-9,0 = sar la coloana, Q = iesire, N = joc nou dupa game over.

.bss
keybuf: .space 8

.data
fmt_prompt: .asciz "Move (a/d/r/s, 1-9/0, q=quit): "
fmt_scan:   .asciz " %c"
clear_cmd:  .asciz "clear"

.text

# clear_screen: sterge terminalul (system("clear"))
.global clear_screen
clear_screen:
    pushq %rbp
    movq %rsp, %rbp
    movq $clear_cmd, %rdi
    movq $0, %rax
    call system
    popq %rbp
    ret

# read_key: -> %rax = caracterul apasat
.global read_key
read_key:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    subq $8, %rsp            # aliniere stiva pentru printf/scanf
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

# handle_key: %rdi = tasta -> %rax = 0 continua, 1 pune, 2 iesi
.global handle_key
handle_key:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    subq $16, %rsp           # aliniere stiva pentru call
    movq %rdi, %rbx           # tasta
    # daca jocul s-a terminat, doar N sau Q conteaza
    movq game_over, %rax
    cmpq $1, %rax
    je hk_over
    # stergem mesajul "nu e voie" la orice tasta noua;
    # hk_place il pune la loc daca plasarea e respinsa
    movq $0, %rax
    movq %rax, msg_invalid
    # Q = iesire
    cmpq $113, %rbx           # 'q'
    je hk_quit
    cmpq $81, %rbx            # 'Q'
    je hk_quit
    # A = stanga
    cmpq $97, %rbx            # 'a'
    je hk_left
    cmpq $65, %rbx            # 'A'
    je hk_left
    # D = dreapta
    cmpq $100, %rbx           # 'd'
    je hk_right
    cmpq $68, %rbx            # 'D'
    je hk_right
    # R sau W = rotire
    cmpq $114, %rbx           # 'r'
    je hk_rot
    cmpq $82, %rbx            # 'R'
    je hk_rot
    cmpq $119, %rbx           # 'w'
    je hk_rot
    cmpq $87, %rbx            # 'W'
    je hk_rot
    # SPACE = pune piesa (merge doar daca scanf nu-l sare; de aceea
    # acceptam si S ca tasta principala de plasare)
    cmpq $32, %rbx
    je hk_place
    cmpq $115, %rbx           # 's'
    je hk_place
    cmpq $83, %rbx            # 'S'
    je hk_place
    # cifre: '0' = coloana 9, '1'-'9' = coloanele 0-8
    # ('0' se verifica prima, ca 48 < 49)
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
    # nu iesim din tabla
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
    # rot = (rot + 1) % numar_rotatii
    movq cur_piece, %rdi
    call num_rots
    movq %rax, %r12           # numar rotatii
    movq sel_rot, %rax
    incq %rax
    xorq %rdx, %rdx
    divq %r12                 # restul in %rdx
    movq %rdx, sel_rot
    jmp hk_done
hk_place:
    # verifica daca piesa incape pe orizontala la coloana aleasa;
    # daca nu, NU e game over, doar respingem mutarea
    movq cur_piece, %rdi
    movq sel_rot, %rsi
    call piece_w              # latime in %rax
    addq sel_col, %rax
    cmpq $10, %rax
    jg hk_reject
    movq sel_col, %rdi
    movq sel_rot, %rsi
    call place_piece
    movq $1, %rax
    jmp hk_end
hk_reject:
    # nu e voie aici: piesa ar iesi din tabla lateral
    movq $1, %rax
    movq %rax, msg_invalid
    movq $0, %rax
    jmp hk_end
hk_over:
    # dupa game over: N = joc nou, Q = iesire
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
