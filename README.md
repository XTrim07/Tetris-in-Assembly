# Tetris in Assembly (x86-64, GAS)

A complete single-player Tetris game written in x86-64 assembly for Ubuntu.
It runs entirely in the terminal using ANSI colors and offers turn-based,
instant-placement gameplay: you pick the column and rotation, and the piece
drops straight away. The game also keeps a persistent leaderboard with player
names and high scores.

Location: `~/assembly_project/Tetris in Assembly/`

## Build and run (Ubuntu)

```bash
cd ~/assembly_project/"Tetris in Assembly"
gcc -no-pie -o tetris main.s
./tetris
```

The file `leaderboard.txt` is created by itself the first time you enter a name.

## How to play

The game is turn-based, so there is no timer and pieces never fall by
themselves. On each turn you look at the current piece and the preview of
where it would land, move it to the column you want, optionally rotate it,
and then confirm the placement. The piece drops instantly to the lowest free
position in that column. If any rows become completely full, they are cleared
and the rows above fall down. You then receive the next piece.

The board is 10 columns wide and 15 rows tall. There are 7 classic shapes
(I, O, T, S, Z, J, L), each with its own color. You always see the current
piece and the next piece, so you can plan ahead.

## Controls

| Key | Effect |
|---|---|
| `A` / `D` | move the selected column left / right |
| `R` (or `W`) | rotate the piece |
| `S` (or `SPACE`) | place the piece on the board (drops instantly) |
| `1`-`9`, `0` | jump directly to a column (1 is leftmost, 0 is rightmost) |
| `Q` | quit |
| `N` | new game (only after game over) |

The `^` arrow below the board shows the selected column, and the gray
`::` squares show the preview (ghost): where the piece will fall. The preview
updates on every move and rotation, so you always know exactly where the
piece will go before placing it.

## Rules and scoring

- Board: 10 columns x 15 rows.
- A placed piece drops instantly; there is no real-time gravity.
- Full lines are cleared and the rows above move down.
- Scoring per placement: 1 line = 100, 2 lines = 300, 3 lines = 500,
  4 lines = 800.
- The game tracks your score, total cleared lines and total placed pieces.
- Game over when the stack reaches the top and the current piece can no longer
  be placed anywhere without going above the top of the board.
- If a piece only fails to fit sideways at the chosen column (for example a
  wide piece at the far right edge), it is NOT game over: the message
  "Not allowed here!" appears and you can try another column or rotation.

## Leaderboard

At startup the game asks for a player name (`Player name:`):

- **New name** — an account with score 0 is created, it is added to
  `leaderboard.txt` and the message `Nice to meet you: <name>` appears.
- **Existing name** — the account is loaded (message
  `Good to see you again: <name>`) and at the top of the game
  the personal record always appears: `Player: <name> | High score: <score>`.
- During the game, below the controls line, the leaderboard is displayed
  in real time (the current player is marked with `>`). It updates
  on every key: if you beat the record, the score in the list increases on the spot.
- The record is saved automatically in `leaderboard.txt` (text format,
  `name score` per line) immediately when it is beaten, so it is not lost even
  if you exit with `Q` in the middle of the game.

### Leaderboard implementation

The leaderboard is kept as simple as possible, in the style of the rest of the
project.

**Where the player data is stored.** A binary file or dynamically allocated
structures would have been more complicated. Instead:

- a text file, `leaderboard.txt`, with one line per player:
  `name score` (e.g. `andrew 500`). It is easy to read and edit by hand, and it
  can be written cleanly with `fprintf`.
- in memory, two fixed arrays in `.bss`:
  - `lb_names`  — 512 bytes = 16 players x 32 bytes per name
  - `lb_scores` — 128 bytes = 16 scores x 8 bytes (`.quad`)
- why 16? It is enough for a game played by few people and the code remains
  trivial (no need to handle allocations/reallocations). If it is full, new
  accounts are no longer added (the game does not crash, only the record is not
  saved for the player who has no account).

**What an "account" is.** For each player three global variables are kept:

- `player_name` — the name entered at login (max 31 characters + `\0`)
- `player_idx`  — their position in the arrays (`-1` if they have no account,
  i.e. the leaderboard was full)
- `player_high` — the personal record (copy of `lb_scores[player_idx]`, kept
  separately so it can be displayed directly in the game header)

**Why the leaderboard is not sorted.** The list stays in the order in which the
accounts were created. Sorting would break `player_idx` (it shifts the
positions on every save) and the name would have to be re-searched after every
sort — too much for what the feature needs.

**When it is saved.** Every time the current score passes the record
(`lb_update`), plus once at account creation (so it appears in the file
immediately). `lb_update` is called:

- in the main loop, after every key (`main.s`, in `game_loop`) — this way the
  record is saved even if the player presses `Q` from the game;
- once more at `game_exit` (so the final score is not missed if the player
  exits right after setting a record).

**Functions in `leaderboard.s`:**

- `lb_load` — reads `leaderboard.txt` with `fopen`/`fgets`, and
  `sscanf("%31s %ld")` splits the line into name + score and writes them
  directly into `lb_names`/`lb_scores` (no intermediate copy; if the file does
  not exist, the leaderboard starts empty).
- `lb_save` — opens the file in mode `"w"` and writes each player with
  `fprintf(file, "%s %ld\n", name, score)`.
- `lb_find` — searches for a name with `strcmp`, returns the position or `-1`.
- `lb_add` — adds a new account (name + score 0) at the end and increments
  `lb_count`.
- `lb_draw` — displays the numbered leaderboard (used at login).
- `lb_login` — asks for the name (`scanf("%31s", player_name)`), searches for
  it:
  - if it exists: `Good to see you again: %s (high score: %ld)` and loads
    `player_high` from `lb_scores`.
  - if it does not exist: `Nice to meet you: %s (new account, score 0)`,
    `lb_add` + `lb_save`.
- `lb_update` — if `score > player_high`, updates the record (`player_high` and
  `lb_scores[player_idx]`) and saves the file.

**Integration:**

- `main.s` — includes `leaderboard.s` (before `display.s`, so the symbols
  `player_name`/`player_high` are visible) and calls `lb_load` + `lb_login`
  before the game loop and `lb_update` in the loop and on exit.
- `display.s` — shows the header `Player: %s | High score: %ld` at the very top
  (with `player_name` and `player_high`), and the real-time leaderboard below
  the `Controls:` line (the function `dr_lb` and the loop `dlb_loop` from
  `draw_board`): the lines are `  name - score`, and the current player has a
  `>` in front (comparison with `player_idx`).
- `input.s` — only the prompt text (`Move (a/d/r/s, 1-9/0, q=quit): `); the
  logic did not change.

**Complete flow:**

```
start -> lb_load (reads the file) -> lb_login:
             type the name -> lb_find:
             |- found    -> player_idx = position, player_high = lb_scores[idx]
             |              "Good to see you again: ..."
             |- not found -> lb_add (score 0) + lb_save
                             "Nice to meet you: ..."
       -> game loop:
             clear_screen -> draw_board (header with |High score| +
             live leaderboard below) -> read_key -> handle_key
             -> lb_update (saves only if score > record)
       -> Q -> game_exit -> lb_update (last save)
```

**A bug caught along the way.** In the first version of the live list in
`display.s` (`dlb_loop`), the score was placed in `%rcx` for `printf`, but for
variadic printf the second argument is `%rdx` (order: 1=%rsi, 2=%rdx, 3=%rcx,
4=%r8, 5=%r9). As a result the live list always showed 0 even though the record
was saved correctly in memory and in the file (that is why the "High score"
header gave the right value after re-login). Moving the score to `%rdx` fixed
it. Lesson: with printf in assembly, the variadic arguments go STRICTLY in the
register order `%rsi, %rdx, %rcx, %r8, %r9`.

**Restrictions (and why they are ok):**

- The name can NOT contain spaces (`scanf("%31s")` reads only the first word).
  For a leaderboard that is enough and it keeps the file easy to parse (the name
  cannot contain "space + score").
- Maximum 16 players (the fixed arrays). If it is full, new accounts are no
  longer added, but the game runs normally.
- The list is not sorted by score (see above).
- The file is `name - score` in the current working folder; if `./tetris` is
  run from another folder, another `leaderboard.txt` is created there (standard
  behavior for relative files).

## Files

- **`main.s`** — entry point (`.global main`). Seeds the random number
  generator, clears the board, draws the first pieces, then runs the game loop:
  `clear -> draw -> read key -> execute`. Includes the other
  files with `.include`.
- **`pieces.s`** — the shapes of the 7 pieces (`I,O,T,S,Z,J,L`) with all
  rotations. Functions: `num_rots`, `piece_w`, `piece_h`, `piece_cell`
  (tells whether a cell is filled).
- **`board.s`** — the game state and rules. The board is a vector of
  150 bytes (`15 rows x 10 columns`, `0 = empty`, `1-7 = piece`).
  Functions: `collides`, `landing_row` (where the piece falls), `place_piece`,
  `clear_lines`, `add_score`, `has_valid`, `rand7`, `init_board`.
- **`display.s`** — drawing in the terminal with `printf` and ANSI colors
  (each piece has its own color). Shows the preview of the current piece
  (the exact shape with the chosen rotation, updated on `R`) and the next
  piece above the board, then the board, the landing-position preview
  (ghost `::`), the score, the lines, the current/next piece and the controls.
- **`input.s`** — reading keys with `scanf(" %c")` and applying them
  to the selected column/rotation (`handle_key`), plus `clear_screen`
  via `system("clear")`.
- **`leaderboard.s`** — the leaderboard with names and scores (see the section
  above). Most of the logic lives here, so as not to clutter
  the rest of the game.

## Design notes

1. **Turn-based, instant placement.** There is no clock or gravity, so the
   game focuses purely on placement decisions and stays simple to reason about
   in assembly.
2. **Board 10x15 instead of 10x20.** Fits comfortably in a small terminal
   window; only the height constant differs.
3. **Text terminal with ANSI colors.** Instead of an external graphics
   library, the game uses `printf` with ANSI escape sequences (`\x1b[...m`),
   which keeps everything dependency-free and works out of the box on Ubuntu.
4. **Several `.s` files linked with `.include`.** Each file has its role
   (pieces / board / display / input / leaderboard), and compilation remains a
   single command (`gcc -no-pie -o tetris main.s`).
5. **Simple programming style.** Only basic instructions (`cmp`, `je`, `jmp`,
   `call`, `push`/`pop`) and standard C functions (`printf`, `scanf`, `system`,
   `rand`, `srand`, `time`). The callee-saved registers (`%rbx`, `%r12-%r15`)
   are preserved, and the stack is kept aligned to 16 bytes before every
   `call` (otherwise `printf` crashes on Ubuntu).
6. **Key `S` for placement.** `scanf(" %c")` skips whitespace, so the space
   bar is unreliable as a key; `S` is therefore the main placement key, while
   the code for `SPACE` is kept as an alternative.
7. **Leaderboard as a text file + fixed arrays.** `leaderboard.txt`
   (`name score` per line) plus fixed arrays for 16 players keeps persistence
   simple and easy to write/read with `fprintf`/`sscanf`. The list is not
   sorted by score (it would break `player_idx` on every save), and the name is
   a single word (max 31 characters, read with `scanf("%31s")`).
8. **English in-game text.** Titles, scores, controls, leaderboard and login
   greetings are all in English, and so are the code comments and this README.
