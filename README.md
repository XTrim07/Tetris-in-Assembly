# Tetris Human in Assembly (x86-64, GAS)

Joc Tetris simplu, pentru un jucator uman, fara nicio parte de AI.
Urmeaza proiectul Python `Tetris-Research-RL-Framework`, doar modul
`human` (`human_player.py` + `board.py` + afisarea din `gui.py`).

Locatie: `~/assembly_project/Tetris in Assembly/`

## Compilare si rulare (Ubuntu, ca la celelalte proiecte)

```bash
cd ~/assembly_project/tetris_human
gcc -no-pie -o tetris main.s
./tetris
```

## Controale

| Tasta | Efect |
|---|---|
| `A` / `D` | muta coloana selectata la stanga / dreapta |
| `R` (sau `W`) | roteste piesa |
| `S` (sau `SPACE`) | pune piesa pe tabla (cade instant) |
| `1`-`9`, `0` | sari direct la coloana (ca tastele `1-9,0` din Python) |
| `Q` | iesire |
| `N` | joc nou (doar dupa game over) |

Sageata `^` de sub tabla arata coloana selectata, iar patratelele
`::` gri arata preview-ul (fantoma): unde va cadea piesa.

## Fisiere

- **`main.s`** — punctul de intrare (`.global main`). Face `srand(time(0))`,
  goleste tabla, trage primele piese, apoi bucla jocului:
  `clear -> deseneaza -> citeste tasta -> executa`. Include celelalte
  fisiere cu `.include`, ca `bitmap/main.s`.
- **`pieces.s`** — formele celor 7 piese (`I,O,T,S,Z,J,L`) cu toate
  rotatiile, exact ca `PIECES` din `board.py`. Functii: `num_rots`,
  `piece_w`, `piece_h`, `piece_cell` (spune daca un patratel e plin).
- **`board.s`** — starea jocului si regulile. Tabla e un vector de
  150 bytes (`15 randuri x 10 coloane`, `0 = gol`, `1-7 = piesa`).
  Functii: `collides`, `landing_row` (unde cade piesa), `place_piece`,
  `clear_lines`, `add_score`, `has_valid`, `rand7`, `init_board`.
- **`display.s`** — desenarea in terminal cu `printf` si culori ANSI
  (fiecare piesa are culoarea ei). Arata preview-ul piesei curente
  (forma exacta cu rotatia aleasa, se actualizeaza la `R`) si piesa
  urmatoare deasupra tablei, apoi tabla, preview-ul pozitiei de cadere
  (fantoma `::`), scorul, liniile, piesa curenta/urmatoare si controalele.
- **`input.s`** — citirea tastelor cu `scanf(" %c")` si aplicarea lor
  pe coloana/rotatia selectata (`handle_key`), plus `clear_screen`
  prin `system("clear")`.
- **`leaderboard.s`** — leaderboard-ul cu nume si scoruri (vezi sectiunea
  de jos). Cea mai mare parte a logicii sta aici, ca sa nu incurc
  restul jocului.
- **`IMPLEMENTARE.md`** — explicatia detaliata a implementarii
  leaderboard-ului (in romana): cum am gandit, ce fisier face ce,
  fluxul complet si restrictiile luate intentionat.

## Leaderboard

La pornire jocul cere un nume de jucator (`Player name:`):

- **Nume nou** — se creeaza un cont cu scor 0, e adaugat in
  `leaderboard.txt` si apare mesajul `Nice to meet you: <nume>`.
- **Nume existent** — se incarca contul (mesaj
  `Good to see you again: <nume>`) si in partea de sus a jocului
  apare mereu recordul personal: `Player: <nume> | High score: <scor>`.
- In timpul jocului, sub linia de comenzi, se afiseaza in timp real
  leaderboard-ul (jucatorul curent e marcat cu `>`). Se actualizeaza
  la fiecare tasta: daca bati recordul, scorul din lista creste pe loc.
- Recordul se salveaza automat in `leaderboard.txt` (format text,
  `nume scor` pe linie) imediat cand e batut, deci nu se pierde nici
  daca iesi cu `Q` din mijlocul jocului.

Detalii (format fisier, limite, de ce nu e sortata lista) in
`IMPLEMENTARE.md`.

## Reguli (la fel ca in Python)

- Tabla: 10 coloane x 15 randuri.
- Piesa nu cade in timp real: alegi coloana + rotatia, piesa cade
  instant pe cel mai de jos rand liber (`landing_row`, ca `_get_landing_row`).
- Liniile pline se sterg, randurile de sus coboara.
- Scor: 1 linie = 100, 2 = 300, 3 = 500, 4 = 800 (ca `_update_score`).
- Game over cand piesa curenta nu mai poate fi pusa nicaieri
  (ca verificarea cu `get_valid_actions` din `place_piece`).
  ATENTIE: daca piesa doar nu incape lateral la coloana aleasa
  (ex. piesa lata la coloana 9), NU e game over — se afiseaza
  "Nu e voie aici!" si incerci alta coloana. Game over vine doar
  cand stiva ajunge sus si piesa ar trece de linia superioara.

## Decizii luate (si de ce)

1. **Doar modul human, fara AI.** Cerinta a fost joc simplu de jucat,
   fara agenti. Am scos toti agentii (`random`, `greedy`, `dqn`, ...)
   si buclele de antrenare (`RLTrainer`, `--no-gui`, `--games`).
2. **Gameplay ca in Python (plasare instant), nu Tetris clasic cu cadere.**
   Proiectul Python e simplificat intentionat (fara timing), ca sa se
   concentreze pe decizii. Varianta clasica ar fi cerut ceas, gravitatie
   si coliziuni laterale in timp real — mult mai complicat in assembly.
3. **Tabla 10x15 in loc de 10x20.** Incape mai bine intr-un terminal
   mic, iar codul e identic (doar constanta de inaltime difera).
4. **Terminal text cu culori ANSI in loc de `graphics.h`.**
   `graphics.h` e un header Borland vechi (DOS/Windows) si nu exista pe
   Ubuntu (`/usr/include/graphics.h` lipseste). In schimb am folosit
   `printf` cu secvente escape ANSI (`\x1b[...m`), aceeasi tehnica ca in
   `A3_MemoryInputs/decoder.s` din acest repo. Efectul vizual e acelasi
   (tabla colorata), fara librarii externe.
5. **Mai multe fisiere `.s` legate cu `.include`.** Ca in `bitmap/main.s`:
   fiecare fisier are rolul lui (piese / tabla / afisare / input),
   iar compilarea ramane o singura comanda (`gcc -no-pie -o tetris main.s`).
6. **Stil de programare simplu, ca in proiectele existente.**
   Doar instructiuni de baza (`cmp`, `je`, `jmp`, `call`, `push`/`pop`),
   functii C apelate (`printf`, `scanf`, `system`, `rand`, `srand`, `time`),
   fara macrouri sau structuri complicate. Registrele salvate de functie
   (`%rbx`, `%r12-%r15`) se pastreaza conform conventiei, iar stiva se
   tine aliniata la 16 bytes inainte de orice `call` (altfel `printf`
   crapa pe Ubuntu).
7. **Tasta `S` pentru plasare (in loc de `SPACE`).**
   Python foloseste `SPACE` prin evenimente pygame, dar `scanf(" %c")`
   sare peste spatii (whitespace), deci SPACE nu poate fi citit asa.
   Am pastrat si codul pentru SPACE, dar tasta principala e `S`.
8. **Leaderboard ca fisier text + tablouri fixe.**
   In loc de format binar sau liste alocate dinamic: `leaderboard.txt`
   (`nume scor` pe linie) si tablouri fixe pentru 16 jucatori. E usor de
   scris/citit cu `fprintf`/`sscanf` (ca in `bitmap_format.s`) si codul
   ramane in stilul simplu al proiectului. Lista nu e sortata dupa scor
   (ar fi stricat `player_idx` la fiecare salvare), iar numele e un
   singur cuvant (max 31 caractere, citit cu `scanf("%31s")`).
9. **Mesajele jocului sunt in engleza** (titlu, scoruri, comenzi,
   leaderboard, saluturile de la login), ca sa fie lizibil la corectare;
   comentariile din cod si documentatia (`IMPLEMENTARE.md`, acest
   README) raman in romana.
