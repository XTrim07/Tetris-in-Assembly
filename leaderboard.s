# leaderboard.s - simple leaderboard with names and high scores
# The file "leaderboard.txt" has one line for each player:
#   name score
# At the start the player types their name:
#   - if the name exists, load the high score and play from there
#   - if it does not exist, create a new account with score 0 and add it to the list
# The high score is updated automatically when the player gets a higher score.

.bss
.global lb_names, lb_scores, lb_count, player_name, player_idx, player_high
lb_names:    .space 512        # 16 players x 32 bytes (name)
lb_scores:   .space 128        # 16 scores x 8 bytes
lb_count:    .space 8
player_name: .space 32         # name of the current player
player_idx:  .space 8          # position in leaderboard (-1 = does not exist)
player_high: .space 8          # high score of the current player

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
lb_buf:     .space 64          # one line from the file

.text

# lb_load: reads leaderboard.txt into lb_names/lb_scores
.global lb_load
lb_load:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    subq $8, %rsp             # align stack for call
    movq $0, %r12             # number of players
    movq $lb_file, %rdi
    movq $lb_mode_r, %rsi
    movq $0, %rax
    call fopen
    cmpq $0, %rax
    je ll_done                # file does not exist = empty leaderboard
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
    # sscanf(line, "%31s %ld", &lb_names[i*32], &lb_scores[i])
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
    jne ll_loop               # invalid line, move on
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

# lb_save: writes the leaderboard back to leaderboard.txt
.global lb_save
lb_save:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    pushq %r13
    subq $8, %rsp             # align stack for call
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
    addq %rax, %r13           # name
    movq %r12, %rax
    imulq $8, %rax
    movq $lb_scores, %rcx
    addq %rax, %rcx           # &score
    # fprintf(file, "%s %ld\n", name, score)
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

# lb_find: %rdi = name -> %rax = position or -1
.global lb_find
lb_find:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    movq %rdi, %r12           # name
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

# lb_add: %rdi = name -> %rax = position of the new account (or -1 if full)
.global lb_add
lb_add:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    pushq %r12
    movq %rdi, %r12           # name
    movq lb_count, %rbx       # position of the new account
    cmpq $16, %rbx
    jge la_full
    # strcpy(&lb_names[i*32], name)
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

# lb_draw: displays the leaderboard
.global lb_draw
lb_draw:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    subq $8, %rsp             # align stack for call
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
    # printf("%ld. %s - %ld\n", i+1, name, score)
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

# lb_login: reads the name and loads the account (or creates a new one)
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
    # look for the name in the leaderboard
    movq $player_name, %rdi
    call lb_find
    cmpq $0, %rax
    jl llg_new
    # the name exists: take the high score
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
    # new name: account with score 0, added to the leaderboard
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

# lb_update: if the current score is higher than the record, save it
.global lb_update
lb_update:
    pushq %rbp
    movq %rsp, %rbp
    pushq %rbx
    subq $8, %rsp             # align stack for call
    movq player_idx, %rbx
    cmpq $0, %rbx
    jl lu_end                 # account does not exist (leaderboard full)
    movq score, %rax
    cmpq player_high, %rax
    jle lu_end                # not a new record
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
