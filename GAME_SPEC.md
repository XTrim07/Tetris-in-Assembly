# Tetris in Assembly — Game Specification

## 1. Overview
Tetris in Assembly is a simple, single-player Tetris game that runs in a terminal on Ubuntu.

We are going to implement a leader board in the game with players names.

You play alone, one piece at a time, until the board fills up.

## 2. Goal of the Game
Stack falling pieces to fill complete horizontal lines. When a line is full, it disappears and you earn points. The game ends when new pieces can no longer fit on the board.

Your goal is to get the highest score possible by clearing as many lines as possible, especially multiple lines at once.

## 3. The Board
The board has 10 columns and 15 rows. It starts empty.

Pieces fall from the top and stack at the bottom. Empty cells are free space. Filled cells are blocks from pieces you have already placed. The stack grows higher as you place more pieces.

The smaller height of 15 rows (instead of the classic 20) is chosen so the whole game fits comfortably in a small terminal window.

## 4. The Pieces
There are 7 classic Tetris shapes: I (straight line), O (square), T, S, Z, J, and L.

Each shape can be rotated. Some shapes have 2 rotation positions, others have 4. The square looks the same in every rotation.

You always see two pieces:
- Current piece: the one you are about to place.
- Next piece: the one that will come after. This helps you plan ahead.

Each piece type has its own color so the board is easy to read.

## 5. How a Turn Works
The game is turn-based. There is no timer and pieces do not fall by themselves.

One turn looks like this:
1. Look at your current piece and the preview of where it would land.
2. Move it left or right to choose a column.
3. Optionally rotate it.
4. Confirm placement. The piece then drops instantly to the lowest free position in that column.
5. If any rows become completely full, they are cleared and rows above fall down.
6. You receive a new current piece (the old next piece) and a new random next piece.

You can take as much time as you want before placing.

## 6. Controls
- A / D: move selected column left / right
- R (or W): rotate the current piece
- S: place the piece (drops instantly)
- 1 to 9, 0: jump directly to a column (1 is leftmost, 0 is rightmost)
- Q: quit the game
- N: start a new game, only after game over

After every key press the screen is redrawn so you immediately see the result.

## 7. Landing Preview and Selector
Under the board there is a selector marker that shows which column is currently selected.

Empty cells where the current piece would land are shown as a ghost preview. This preview updates every time you move or rotate, so you always know exactly where the piece will go before you place it.

Above the board you also see a preview of the current piece in its selected rotation and a preview of the next piece.

## 8. Scoring and Progress
Clearing lines gives points:
- 1 line at once: 100 points
- 2 lines at once: 300 points
- 3 lines at once: 500 points
- 4 lines at once: 800 points

The game also counts total cleared lines and total placed pieces. All three values (score, lines, pieces) are always visible below the board, together with the names of the current and next pieces, the selected column and rotation, and the landing row.

## 9. Invalid Move vs Game Over
Not every placement is possible:

- Invalid move: if the piece is too wide to fit at the chosen column (for example a long horizontal piece at the far right edge), the game shows a warning message and lets you try another column or rotation. This is not game over.
- Game over: when the stack is so high that the current piece cannot be placed anywhere without going above the top of the board. In that case the game ends and shows your final score.

After game over you can press N for a new empty board or Q to quit.

## 10. What the Final Game Looks Like
When playing, the terminal shows a title at the top, then the current-piece preview and next-piece preview, then a bordered board with colored blocks. Below the board are column numbers, the selector marker, the score line, the piece info line, and the controls line.

Everything is text with colors. There are no external graphics, windows, or mouse input. The screen clears and redraws after each move for a clean, flicker-free view.
