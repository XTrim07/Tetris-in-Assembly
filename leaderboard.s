# leaderboard.s - leaderboard simplu cu nume si scor maxim
# Fisierul "leaderboard.txt" are cate o linie pentru fiecare jucator:
#   nume scor
# La inceput jucatorul isi scrie numele:
#   - daca numele exista, incarca scorul maxim si joaca de acolo
#   - daca nu exista, creeaza un cont nou cu scor 0 si il adauga in lista
# Scorul maxim se actualizeaza automat cand jucatorul face un scor mai mare.

.bss
.global lb_names, lb_scores, lb_count, player_name, player_idx, player_high
lb_names:    .space 512        # 16 jucatori x 32 bytes (nume)
lb_scores:   .space 128        # 16 scoruri x 8 bytes
lb_count:    .space 8
player_name: .space 32         # numele jucatorului curent
player_idx:  .space 8          # pozitia in leaderboard (-1 = nu exista)
player_high: .space 8          # scorul maxim al jucatorului curent

.data
lb_file:    .asciz "leaderboard.txt"
lb_mode_r:  .asciz "r"
lb_mode_w:  .asciz "w"
lb_fmt:     .asciz "%s %ld\n"
lb_read:    .asciz "%31s %ld"
lb_scan:    .asciz "%31s"
lb_prompt:  .asciz "\nPlayer name: "
lb_welcome: .asciz "\nGood to see you again: %s (high score: %ld)\n"
lb_new:     .asciz "\nNice to meet you: %s (new account, score 0)\n"
lb_head:    .asciz "\n=== LEADERBOARD ===\n"
lb_row:     .asciz "%ld. %s - %ld\n"
lb_none:    .asciz "(gol)\n"
lb_buf:     .space 64          # o linie din fisier

.text

# lb_load: citeste leaderboard.txt in lb_names/lb_scores
.global lb_load
lb_load:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    subq $8, %rsp             # aliniere stiva pentru call
    movq $0, %r12             # numar jucatori
    movq $lb_file, %rdi
    movq $lb_mode_r, %rsi
    movq $0, %rax
    call fopen
    cmpq $0, %rax
    je ll_done                # fisierul nu exista = leaderboard gol
    movq %rax, %rbx           # FILE*
ll_loop:
    cmpq $16, %r12
    jge ll_close
    movq $lb_buf, %rdi
    movq $64, %rsi
    movq %rbx, %rdx
    movq $0, %rax
    call fgets
    cmpq $0, %rax
    je ll_close
    # sscanf(linie, "%31s %ld", &lb_names[i*32], &lb_scores[i])
    movq %r12, %rax
    imulq $32, %rax
    movq $lb_names, %rdx
    addq %rax, %rdx
    movq %r12, %rax
    imulq $8, %rax
    movq $lb_scores, %rcx
    addq %rax, %rcx
    movq $lb_buf, %rdi
    movq $lb_read, %rsi
    movq $0, %rax
    call sscanf
    cmpq $2, %rax
    jne ll_loop               # linie invalida, trecem mai departe
    incq %r12
    jmp ll_loop
ll_close:
    movq %rbx, %rdi
    movq $0, %rax
    call fclose
ll_done:
    movq %r12, lb_count
    addq $8, %rsp
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

# lb_save: scrie leaderboard-ul inapoi in leaderboard.txt
.global lb_save
lb_save:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    subq $8, %rsp             # aliniere stiva pentru call
    movq $lb_file, %rdi
    movq $lb_mode_w, %rsi
    movq $0, %rax
    call fopen
    cmpq $0, %rax
    je ls_done
    movq %rax, %rbx           # FILE*
    movq $0, %r12             # i
ls_loop:
    cmpq lb_count, %r12
    jge ls_close
    movq %r12, %rax
    imulq $32, %rax
    movq $lb_names, %r13
    addq %rax, %r13           # nume
    movq %r12, %rax
    imulq $8, %rax
    movq $lb_scores, %rcx
    addq %rax, %rcx           # &scor
    # fprintf(file, "%s %ld\n", nume, scor)
    movq %rbx, %rdi
    movq $lb_fmt, %rsi
    movq %r13, %rdx
    movq (%rcx), %rcx
    movq $0, %rax
    call fprintf
    incq %r12
    jmp ls_loop
ls_close:
    movq %rbx, %rdi
    movq $0, %rax
    call fclose
ls_done:
    addq $8, %rsp
    popq %r13
    popq %r12
    popq %rbx
    popq %rbp
    ret

# lb_find: %rdi = nume -> %rax = pozitia sau -1
.global lb_find
lb_find:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    movq %rdi, %r12           # nume
    movq $0, %rbx             # i
lf_loop:
    cmpq lb_count, %rbx
    jge lf_no
    movq %rbx, %rax
    imulq $32, %rax
    movq $lb_names, %rdi
    addq %rax, %rdi
    movq %r12, %rsi
    movq $0, %rax
    call strcmp
    cmpq $0, %rax
    je lf_yes
    incq %rbx
    jmp lf_loop
lf_no:
    movq $-1, %rax
    jmp lf_end
lf_yes:
    movq %rbx, %rax
lf_end:
    popq %r12
    popq %rbx
    popq %rbp
    ret

# lb_add: %rdi = nume -> %rax = pozitia noului cont (sau -1 daca e plin)
.global lb_add
lb_add:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    movq %rdi, %r12           # nume
    movq lb_count, %rbx       # pozitia noului cont
    cmpq $16, %rbx
    jge la_full
    # strcpy(&lb_names[i*32], nume)
    movq %rbx, %rax
    imulq $32, %rax
    movq $lb_names, %rdi
    addq %rax, %rdi
    movq %r12, %rsi
    movq $0, %rax
    call strcpy
    # lb_scores[i] = 0
    movq %rbx, %rax
    imulq $8, %rax
    movq $lb_scores, %rdx
    addq %rax, %rdx
    movq $0, (%rdx)
    incq %rbx
    movq %rbx, lb_count
    movq %rbx, %rax
    decq %rax
    jmp la_end
la_full:
    movq $-1, %rax
la_end:
    popq %r12
    popq %rbx
    popq %rbp
    ret

# lb_draw: afiseaza leaderboard-ul
.global lb_draw
lb_draw:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    subq $8, %rsp             # aliniere stiva pentru call
    movq $lb_head, %rdi
    movq $0, %rax
    call printf
    movq $0, %rbx
    cmpq $0, lb_count
    jne ld_loop
    movq $lb_none, %rdi
    movq $0, %rax
    call printf
    jmp ld_end
ld_loop:
    cmpq lb_count, %rbx
    jge ld_end
    # printf("%ld. %s - %ld\n", i+1, nume, scor)
    movq $lb_row, %rdi
    movq %rbx, %rsi
    incq %rsi
    movq %rbx, %rax
    imulq $32, %rax
    movq $lb_names, %rdx
    addq %rax, %rdx
    movq %rbx, %rax
    imulq $8, %rax
    movq $lb_scores, %rcx
    addq %rax, %rcx
    movq (%rcx), %rcx
    movq $0, %rax
    call printf
    incq %rbx
    jmp ld_loop
ld_end:
    addq $8, %rsp
    popq %rbx
    popq %rbp
    ret

# lb_login: citeste numele si incarca contul (sau creeaza unul nou)
.global lb_login
lb_login:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    movq $lb_prompt, %rdi
    movq $0, %rax
    call printf
    # scanf("%31s", player_name)
    movq $lb_scan, %rdi
    movq $player_name, %rsi
    movq $0, %rax
    call scanf
    # caut numele in leaderboard
    movq $player_name, %rdi
    call lb_find
    cmpq $0, %rax
    jl llg_new
    # numele exista: iau scorul maxim
    movq %rax, %rbx
    movq %rbx, player_idx
    movq %rbx, %rax
    imulq $8, %rax
    movq $lb_scores, %rdx
    addq %rax, %rdx
    movq (%rdx), %rax
    movq %rax, player_high
    movq $lb_welcome, %rdi
    movq $player_name, %rsi
    movq player_high, %rdx
    movq $0, %rax
    call printf
    jmp llg_draw
llg_new:
    # nume nou: cont cu scor 0, adaugat in leaderboard
    movq $player_name, %rdi
    call lb_add
    movq %rax, player_idx
    movq $0, %rax
    movq %rax, player_high
    movq $lb_new, %rdi
    movq $player_name, %rsi
    movq $0, %rax
    call printf
    call lb_save
llg_draw:
    call lb_draw
    popq %r12
    popq %rbx
    popq %rbp
    ret

# lb_update: daca scorul curent e mai mare decat recordul, il salveaza
.global lb_update
lb_update:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    subq $8, %rsp             # aliniere stiva pentru call
    movq player_idx, %rbx
    cmpq $0, %rbx
    jl lu_end                 # cont inexistent (leaderboard plin)
    movq score, %rax
    cmpq player_high, %rax
    jle lu_end                # nu e record nou
    movq %rax, player_high
    movq %rbx, %rax
    imulq $8, %rax
    movq $lb_scores, %rdx
    addq %rax, %rdx
    movq score, %rax
    movq %rax, (%rdx)
    call lb_save
lu_end:
    addq $8, %rsp
    popq %rbx
    popq %rbp
    ret
