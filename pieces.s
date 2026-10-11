# pieces.s - formele pieselor Tetris
# Tipuri: 0=I, 1=O, 2=T, 3=S, 4=Z, 5=J, 6=L
# Acelasi set ca in board.py (PIECES), doar tabla e 10x15.
# Stil simplu: comparatii cmp/je, fara macrouri complicate.

.text

# num_rots: %rdi = tip piesa -> %rax = numar rotatii
.global num_rots
num_rots:
    cmpq $0, %rdi
    je nr_2
    cmpq $1, %rdi
    je nr_1
    cmpq $3, %rdi
    je nr_2
    cmpq $4, %rdi
    je nr_2
    movq $4, %rax       # T, J, L au 4 rotatii
    ret
nr_2:
    movq $2, %rax       # I, S, Z au 2 rotatii
    ret
nr_1:
    movq $1, %rax       # O are o singura rotatie
    ret

# piece_w: %rdi = tip, %rsi = rotatie -> %rax = latime
.global piece_w
piece_w:
    # piesa I
    cmpq $0, %rdi
    jne pw_not_i
    cmpq $0, %rsi
    je pw_4
    movq $1, %rax
    ret
pw_not_i:
    # piesa O
    cmpq $1, %rdi
    jne pw_not_o
    movq $2, %rax
    ret
pw_not_o:
    # piesa T
    cmpq $2, %rdi
    jne pw_not_t
    cmpq $0, %rsi
    je pw_3
    cmpq $2, %rsi
    je pw_3
    movq $2, %rax
    ret
pw_not_t:
    # piesa S
    cmpq $3, %rdi
    jne pw_not_s
    cmpq $0, %rsi
    je pw_3
    movq $2, %rax
    ret
pw_not_s:
    # piesa Z
    cmpq $4, %rdi
    jne pw_not_z
    cmpq $0, %rsi
    je pw_3
    movq $2, %rax
    ret
pw_not_z:
    # piesa J
    cmpq $5, %rdi
    jne pw_not_j
    cmpq $0, %rsi
    je pw_3
    cmpq $2, %rsi
    je pw_3
    movq $2, %rax
    ret
pw_not_j:
    # piesa L (ce a ramas)
    cmpq $0, %rsi
    je pw_3
    cmpq $2, %rsi
    je pw_3
    movq $2, %rax
    ret
pw_4:
    movq $4, %rax
    ret
pw_3:
    movq $3, %rax
    ret

# piece_h: %rdi = tip, %rsi = rotatie -> %rax = inaltime
.global piece_h
piece_h:
    # piesa I
    cmpq $0, %rdi
    jne ph_not_i
    cmpq $0, %rsi
    je ph_1
    movq $4, %rax
    ret
ph_not_i:
    # piesa O
    cmpq $1, %rdi
    jne ph_not_o
    movq $2, %rax
    ret
ph_not_o:
    # piesele T, S, Z, J, L: rotatiile 0 si 2 sunt late (h=2),
    # rotatiile 1 si 3 sunt inguste (h=3)
    cmpq $0, %rsi
    je ph_2
    cmpq $2, %rsi
    je ph_2
    movq $3, %rax
    ret
ph_1:
    movq $1, %rax
    ret
ph_2:
    movq $2, %rax
    ret

# piece_cell: %rdi = tip, %rsi = rot, %rdx = rand, %rcx = col -> %rax = 1/0
# Spune daca patratelul (rand, col) din piesa este plin.
.global piece_cell
piece_cell:
    cmpq $0, %rdi
    je pc_i
    cmpq $1, %rdi
    je pc_o
    cmpq $2, %rdi
    je pc_t
    cmpq $3, %rdi
    je pc_s
    cmpq $4, %rdi
    je pc_z
    cmpq $5, %rdi
    je pc_j
    jmp pc_l

# I: r0 = linie orizontala, r1 = linie verticala
pc_i:
    cmpq $0, %rsi
    je pc_i_h
    # vertical: col 0, rand 0-3
    cmpq $0, %rcx
    jne pc_zero
    cmpq $0, %rdx
    jl pc_zero
    cmpq $3, %rdx
    jg pc_zero
    movq $1, %rax
    ret
pc_i_h:
    # orizontal: rand 0, col 0-3
    cmpq $0, %rdx
    jne pc_zero
    cmpq $0, %rcx
    jl pc_zero
    cmpq $3, %rcx
    jg pc_zero
    movq $1, %rax
    ret

# O: patrat 2x2, mereu plin
pc_o:
    cmpq $0, %rdx
    jl pc_zero
    cmpq $1, %rdx
    jg pc_zero
    cmpq $0, %rcx
    jl pc_zero
    cmpq $1, %rcx
    jg pc_zero
    movq $1, %rax
    ret

# T: 4 rotatii
pc_t:
    cmpq $0, %rsi
    je pc_t0
    cmpq $1, %rsi
    je pc_t1
    cmpq $2, %rsi
    je pc_t2
    # r3: [[0,1],[1,1],[0,1]]
    cmpq $1, %rcx
    je pc_t_col1_ok      # coloana 1 e plina pe toate randurile
    cmpq $0, %rcx
    jne pc_zero
    cmpq $1, %rdx        # coloana 0 doar la mijloc
    jne pc_zero
    movq $1, %rax
    ret
pc_t_col1_ok:
    cmpq $0, %rdx
    jl pc_zero
    cmpq $2, %rdx
    jg pc_zero
    movq $1, %rax
    ret
pc_t0:
    # [[0,1,0],[1,1,1]]
    cmpq $0, %rdx
    je pc_t0_top
    cmpq $1, %rdx
    jne pc_zero
    cmpq $0, %rcx        # randul 1 e plin tot
    jl pc_zero
    cmpq $2, %rcx
    jg pc_zero
    movq $1, %rax
    ret
pc_t0_top:
    cmpq $1, %rcx        # randul 0 doar mijlocul
    jne pc_zero
    movq $1, %rax
    ret
pc_t1:
    # [[1,0],[1,1],[1,0]]
    cmpq $0, %rcx
    je pc_t_col0_ok      # coloana 0 e plina pe toate randurile
    cmpq $1, %rcx
    jne pc_zero
    cmpq $1, %rdx        # coloana 1 doar la mijloc
    jne pc_zero
    movq $1, %rax
    ret
pc_t_col0_ok:
    cmpq $0, %rdx
    jl pc_zero
    cmpq $2, %rdx
    jg pc_zero
    movq $1, %rax
    ret
pc_t2:
    # [[1,1,1],[0,1,0]]
    cmpq $0, %rdx
    je pc_t2_top
    cmpq $1, %rdx
    jne pc_zero
    cmpq $1, %rcx        # randul 1 doar mijlocul
    jne pc_zero
    movq $1, %rax
    ret
pc_t2_top:
    cmpq $0, %rcx        # randul 0 e plin tot
    jl pc_zero
    cmpq $2, %rcx
    jg pc_zero
    movq $1, %rax
    ret

# S: 2 rotatii
pc_s:
    cmpq $0, %rsi
    je pc_s0
    # r1: [[1,0],[1,1],[0,1]]
    cmpq $0, %rdx
    je pc_s1_r0
    cmpq $1, %rdx
    je pc_s1_r1
    cmpq $2, %rdx
    jne pc_zero
    cmpq $1, %rcx
    jne pc_zero
    movq $1, %rax
    ret
pc_s1_r0:
    cmpq $0, %rcx
    jne pc_zero
    movq $1, %rax
    ret
pc_s1_r1:
    cmpq $0, %rcx
    jl pc_zero
    cmpq $1, %rcx
    jg pc_zero
    movq $1, %rax
    ret
pc_s0:
    # [[0,1,1],[1,1,0]]
    cmpq $0, %rdx
    je pc_s0_top
    cmpq $1, %rdx
    jne pc_zero
    cmpq $0, %rcx
    jl pc_zero
    cmpq $1, %rcx
    jg pc_zero
    movq $1, %rax
    ret
pc_s0_top:
    cmpq $1, %rcx
    jl pc_zero
    cmpq $2, %rcx
    jg pc_zero
    movq $1, %rax
    ret

# Z: 2 rotatii
pc_z:
    cmpq $0, %rsi
    je pc_z0
    # r1: [[0,1],[1,1],[1,0]]
    cmpq $0, %rdx
    je pc_z1_r0
    cmpq $1, %rdx
    je pc_z1_r1
    cmpq $2, %rdx
    jne pc_zero
    cmpq $0, %rcx
    jne pc_zero
    movq $1, %rax
    ret
pc_z1_r0:
    cmpq $1, %rcx
    jne pc_zero
    movq $1, %rax
    ret
pc_z1_r1:
    cmpq $0, %rcx
    jl pc_zero
    cmpq $1, %rcx
    jg pc_zero
    movq $1, %rax
    ret
pc_z0:
    # [[1,1,0],[0,1,1]]
    cmpq $0, %rdx
    je pc_z0_top
    cmpq $1, %rdx
    jne pc_zero
    cmpq $1, %rcx
    jl pc_zero
    cmpq $2, %rcx
    jg pc_zero
    movq $1, %rax
    ret
pc_z0_top:
    cmpq $0, %rcx
    jl pc_zero
    cmpq $1, %rcx
    jg pc_zero
    movq $1, %rax
    ret

# J: 4 rotatii
pc_j:
    cmpq $0, %rsi
    je pc_j0
    cmpq $1, %rsi
    je pc_j1
    cmpq $2, %rsi
    je pc_j2
    # r3: [[0,1],[0,1],[1,1]]
    cmpq $1, %rcx
    je pc_j3_col1
    cmpq $0, %rcx
    jne pc_zero
    cmpq $2, %rdx
    jne pc_zero
    movq $1, %rax
    ret
pc_j3_col1:
    cmpq $0, %rdx
    jl pc_zero
    cmpq $2, %rdx
    jg pc_zero
    movq $1, %rax
    ret
pc_j0:
    # [[1,0,0],[1,1,1]]
    cmpq $0, %rdx
    je pc_j0_top
    cmpq $1, %rdx
    jne pc_zero
    cmpq $0, %rcx
    jl pc_zero
    cmpq $2, %rcx
    jg pc_zero
    movq $1, %rax
    ret
pc_j0_top:
    cmpq $0, %rcx
    jne pc_zero
    movq $1, %rax
    ret
pc_j1:
    # [[1,1],[1,0],[1,0]]
    cmpq $0, %rcx
    je pc_j1_col0
    cmpq $1, %rcx
    jne pc_zero
    cmpq $0, %rdx
    jne pc_zero
    movq $1, %rax
    ret
pc_j1_col0:
    cmpq $0, %rdx
    jl pc_zero
    cmpq $2, %rdx
    jg pc_zero
    movq $1, %rax
    ret
pc_j2:
    # [[1,1,1],[0,0,1]]
    cmpq $0, %rdx
    je pc_j2_top
    cmpq $1, %rdx
    jne pc_zero
    cmpq $2, %rcx
    jne pc_zero
    movq $1, %rax
    ret
pc_j2_top:
    cmpq $0, %rcx
    jl pc_zero
    cmpq $2, %rcx
    jg pc_zero
    movq $1, %rax
    ret

# L: 4 rotatii
pc_l:
    cmpq $0, %rsi
    je pc_l0
    cmpq $1, %rsi
    je pc_l1
    cmpq $2, %rsi
    je pc_l2
    # r3: [[1,1],[0,1],[0,1]]
    cmpq $1, %rcx
    je pc_l3_col1
    cmpq $0, %rcx
    jne pc_zero
    cmpq $0, %rdx
    jne pc_zero
    movq $1, %rax
    ret
pc_l3_col1:
    cmpq $0, %rdx
    jl pc_zero
    cmpq $2, %rdx
    jg pc_zero
    movq $1, %rax
    ret
pc_l0:
    # [[0,0,1],[1,1,1]]
    cmpq $0, %rdx
    je pc_l0_top
    cmpq $1, %rdx
    jne pc_zero
    cmpq $0, %rcx
    jl pc_zero
    cmpq $2, %rcx
    jg pc_zero
    movq $1, %rax
    ret
pc_l0_top:
    cmpq $2, %rcx
    jne pc_zero
    movq $1, %rax
    ret
pc_l1:
    # [[1,0],[1,0],[1,1]]
    cmpq $0, %rcx
    je pc_l1_col0
    cmpq $1, %rcx
    jne pc_zero
    cmpq $2, %rdx
    jne pc_zero
    movq $1, %rax
    ret
pc_l1_col0:
    cmpq $0, %rdx
    jl pc_zero
    cmpq $2, %rdx
    jg pc_zero
    movq $1, %rax
    ret
pc_l2:
    # [[1,1,1],[1,0,0]]
    cmpq $0, %rdx
    je pc_l2_top
    cmpq $1, %rdx
    jne pc_zero
    cmpq $0, %rcx
    jne pc_zero
    movq $1, %rax
    ret
pc_l2_top:
    cmpq $0, %rcx
    jl pc_zero
    cmpq $2, %rcx
    jg pc_zero
    movq $1, %rax
    ret

pc_zero:
    movq $0, %rax
    ret
