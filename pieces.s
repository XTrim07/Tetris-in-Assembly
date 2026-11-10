# pieces.s - the Tetris piece shapes
# Types: 0=I, 1=O, 2=T, 3=S, 4=Z, 5=J, 6=L
# Same set as in board.py (PIECES), only the board is 10x15.
# Simple style: cmp/je comparisons, no complicated macros.

.text

# num_rots: %rdi = piece type -> %rax = number of rotations
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
    movq $4, %rax       # T, J, L have 4 rotations
    ret
nr_2:
    movq $2, %rax       # I, S, Z have 2 rotations
    ret
nr_1:
    movq $1, %rax       # O has a single rotation
    ret

# piece_w: %rdi = type, %rsi = rotation -> %rax = width
.global piece_w
piece_w:
    # piece I
    cmpq $0, %rdi
    jne pw_not_i
    cmpq $0, %rsi
    je pw_4
    movq $1, %rax
    ret
pw_not_i:
    # piece O
    cmpq $1, %rdi
    jne pw_not_o
    movq $2, %rax
    ret
pw_not_o:
    # piece T
    cmpq $2, %rdi
    jne pw_not_t
    cmpq $0, %rsi
    je pw_3
    cmpq $2, %rsi
    je pw_3
    movq $2, %rax
    ret
pw_not_t:
    # piece S
    cmpq $3, %rdi
    jne pw_not_s
    cmpq $0, %rsi
    je pw_3
    movq $2, %rax
    ret
pw_not_s:
    # piece Z
    cmpq $4, %rdi
    jne pw_not_z
    cmpq $0, %rsi
    je pw_3
    movq $2, %rax
    ret
pw_not_z:
    # piece J
    cmpq $5, %rdi
    jne pw_not_j
    cmpq $0, %rsi
    je pw_3
    cmpq $2, %rsi
    je pw_3
    movq $2, %rax
    ret
pw_not_j:
    # piece L (what is left)
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

# piece_h: %rdi = type, %rsi = rotation -> %rax = height
.global piece_h
piece_h:
    # piece I
    cmpq $0, %rdi
    jne ph_not_i
    cmpq $0, %rsi
    je ph_1
    movq $4, %rax
    ret
ph_not_i:
    # piece O
    cmpq $1, %rdi
    jne ph_not_o
    movq $2, %rax
    ret
ph_not_o:
    # the pieces T, S, Z, J, L: rotations 0 and 2 are wide (h=2),
    # rotations 1 and 3 are narrow (h=3)
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

# piece_cell: %rdi = type, %rsi = rot, %rdx = row, %rcx = col -> %rax = 1/0
# Tells whether the cell (row, col) in the piece is filled.
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

# I: r0 = horizontal line, r1 = vertical line
pc_i:
    cmpq $0, %rsi
    je pc_i_h
    # vertical: col 0, row 0-3
    cmpq $0, %rcx
    jne pc_zero
    cmpq $0, %rdx
    jl pc_zero
    cmpq $3, %rdx
    jg pc_zero
    movq $1, %rax
    ret
pc_i_h:
    # horizontal: row 0, col 0-3
    cmpq $0, %rdx
    jne pc_zero
    cmpq $0, %rcx
    jl pc_zero
    cmpq $3, %rcx
    jg pc_zero
    movq $1, %rax
    ret

# O: 2x2 square, always filled
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

# T: 4 rotations
pc_t:
    cmpq $0, %rsi
    je pc_t0
    cmpq $1, %rsi
    je pc_t1
    cmpq $2, %rsi
    je pc_t2
    # r3: [[0,1],[1,1],[0,1]]
    cmpq $1, %rcx
    je pc_t_col1_ok      # column 1 is filled on all rows
    cmpq $0, %rcx
    jne pc_zero
    cmpq $1, %rdx        # column 0 only in the middle
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
    cmpq $0, %rcx        # row 1 is fully filled
    jl pc_zero
    cmpq $2, %rcx
    jg pc_zero
    movq $1, %rax
    ret
pc_t0_top:
    cmpq $1, %rcx        # row 0 only the middle
    jne pc_zero
    movq $1, %rax
    ret
pc_t1:
    # [[1,0],[1,1],[1,0]]
    cmpq $0, %rcx
    je pc_t_col0_ok      # column 0 is filled on all rows
    cmpq $1, %rcx
    jne pc_zero
    cmpq $1, %rdx        # column 1 only in the middle
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
    cmpq $1, %rcx        # row 1 only the middle
    jne pc_zero
    movq $1, %rax
    ret
pc_t2_top:
    cmpq $0, %rcx        # row 0 is fully filled
    jl pc_zero
    cmpq $2, %rcx
    jg pc_zero
    movq $1, %rax
    ret

# S: 2 rotations
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

# Z: 2 rotations
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

# J: 4 rotations
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

# L: 4 rotations
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
