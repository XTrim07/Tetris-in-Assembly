# Leaderboard — implementare si gandire

Documentul explica cum am implementat functionalitatea de leaderboard in
Tetris (assembly x86-64, GAS), ce am modificat in fiecare fisier si de ce
am ales solutia asta (cat mai simpla, in stilul restului proiectului).

## 1. Ce a cerut functionalitatea

1. La pornire, jucatorul isi scrie numele (login).
2. Daca numele exista deja in leaderboard, jucatorul isi continua contul:
   in partea de sus a jocului i se afiseaza scorul maxim (recordul) lui.
3. Daca numele nu exista, se creeaza un cont nou care porneste de la
   scor 0 si jucatorul e adaugat in leaderboard.
4. In timpul jocului, sub linia de comenzi, se afiseaza in timp real
   leaderboard-ul (lista jucatorilor cu scorurile lor, actualizata
   la fiecare tasta).
5. Limba jocului (mesaje + comenzi) e in engleza; saluturile la login:
   `Good to see you again:` pentru jucator vechi si `Nice to meet you:`
   pentru cont nou.

## 2. Cum am gandit solutia

Am pornit de la doua intrebari:

**Unde tin datele jucatorilor?** Varianta complicata ar fi fost un fisier
binar sau structuri alocate dinamic. Am ales ceva simplu, in stilul
proiectului:

- un fisier text, `leaderboard.txt`, cu o linie per jucator:
  `nume scor` (ex: `andrew 500`). E usor de citit si modificat manual,
  si se poate scrie superb cu `fprintf` (tehnica identica cu
  `bitmap/bitmap_format.s` din repo).

- in memorie, doua tablouri fixe in `.bss`:
  - `lb_names`   — 512 bytes = 16 jucatori x 32 bytes per nume
  - `lb_scores`  — 128 bytes = 16 scoruri x 8 bytes (`.quad`)
- de ce 16? E suficient pentru un joc la care joaca putini oameni si
  codul ramane banal (nu trebuie sa stilizez alocari/realocari). Daca e
  plin, conturile noi nu mai sunt adaugate (jocul nu crapa, doar ca
  recordul nu se salveaza pentru cel care nu are cont).

**Ce e un "cont"?** Pentru fiecare jucator tin trei variabile globale:
- `player_name` — numele introdus la login (max 31 caractere + `\0`)
- `player_idx`  — pozitia lui in tablouri (`-1` daca nu are cont, adica
  leaderboard-ul era plin)
- `player_high` — recordul personal (copie a `lb_scores[player_idx]`,
  tinuta separat ca sa o pot afisa direct in header-ul jocului)

**De ce nu am sortat leaderboard-ul?** Ca sa nu complic: lista ramane in
ordinea in care s-au creat conturile. Sortarea ar fi stricat `player_idx`
(shifteaza pozitiile la fiecare salvare) si ar fi trebuit re-cautat numele
dupa fiecare sortare — prea mult pentru ce a cerut functionalitatea.

**Cand salvez?** De fiecare data cand scorul curent trece peste record
(`lb_update`), plus o data la creare contului (sa apara imediat in fisier).
`lb_update` e chemat:
- in bucla principala, dupa fiecare tasta (`main.s`, in `game_loop`) —
  asa recordul se salveaza chiar daca jucatorul da `Q` din joc;
- o data in plus la `game_exit` (ca sa nu ratac scorul final daca
  jucatorul iese exact dupa ce face record).

## 3. Fisierele

- **`leaderboard.s`** (nou) — toata logica de leaderboard:
  - `lb_load`  — citeste `leaderboard.txt` cu `fopen`/`fgets`, iar
    `sscanf("%31s %ld")` despica linia in nume + scor si li le scrie
    direct in `lb_names`/`lb_scores` (fara copie intermediara;
    daca fisierul nu exista, leaderboard-ul pleaca gol).
  - `lb_save`  — deschide fisierul cu mod `"w"` si scrie fiecare
    jucator cu `fprintf(file, "%s %ld\n", nume, scor)`.
  - `lb_find`  — cauta un nume cu `strcmp`, returneaza pozitia sau `-1`.
  - `lb_add`   — adauga un cont nou (nume + scor 0) la final si mareste
    `lb_count`.
  - `lb_draw`  — afiseaza leaderboard-ul numerotat (folosit la login).
  - `lb_login` — cere numele (`scanf("%31s", player_name)`), il cauta:
    - daca exista: `Good to see you again: %s (high score: %ld)` si
      incarca `player_high` din `lb_scores`.
    - daca nu exista: `Nice to meet you: %s (new account, score 0)`,
      `lb_add` + `lb_save`.
  - `lb_update` — daca `score > player_high`, updateaza recordul
    (`player_high` si `lb_scores[player_idx]`) si salveaza fisierul.
- **`main.s`** — am adaugat `.include "leaderboard.s"` (inainte de
  `display.s`, ca simbolurile `player_name`/`player_high` sa fie
  vizibile) si apelurile `lb_load` + `lb_login` inainte de bucla jocului
  si `lb_update` in bucla si la iesire.
- **`display.s`** — am adaugat:
  - header-ul `Player: %s | High score: %ld` sus de tot (cu `player_name`
    si `player_high`), exact ce s-a cerut ("scorul maxim in partea de sus").
  - leaderboard-ul in timp real sub linia `Controls:` (functia `dr_lb`
    si bucla `dlb_loop` din `draw_board`): liniile sunt
    `  nume - scor`, iar jucatorul curent are in fata `>` (comparatia cu
    `player_idx`).
- **`input.s`** — doar traducerea promptului (`Move (a/d/r/s, 1-9/0,
  q=quit): `); logica nu s-a schimbat.

## 4. Fluxul complet

```
start -> lb_load (citeste fisierul) -> lb_login:
             scriu numele -> lb_find:
             |- gasit    -> player_idx = pozitia, player_high = lb_scores[idx]
             |              "Good to see you again: ..."
             |- negasit  -> lb_add (scor 0) + lb_save
                            "Nice to meet you: ..."
       -> bucla jocului:
             clear_screen -> draw_board (header cu |Scor maxim| +
             leaderboard live jos) -> read_key -> handle_key
             -> lb_update (salveaza doar daca scor > record)
       -> Q -> game_exit -> lb_update (ultima salvare)
```

## 5. Bug pe care l-am prins intre timp

La prima varianta a listei live din `display.s` (`dlb_loop`), la `printf`
pusem scorul in `%rcx`, dar la printf variadic al doilea argument e
`%rdx` (ordinea: 1=%rsi, 2=%rdx, 3=%rcx, 4=%r8, 5=%r9). Rezultat: lista
live arata mereu 0 desi recordul se salva corect in memorie si in fisier
(de-aia header-ul "High score" dadea valoarea buna dupa re-login).
Am mutat scorul in `%rdx` si a mers. Lectie: la printf din assembly,
argumentele variadic merg STRIC pe ordinea registrelor `%rsi, %rdx,
%rcx, %r8, %r9`.

## 6. Restrictii (si de ce sunt ok)

- Numele NU poate avea spatii (`scanf("%31s")` citeste doar primul cuvant).
  Pentru un leaderboard e suficient si pastreaza fisierul usor de parsat
  (numele nu poate contine "spatiu + scor").
- Maxim 16 jucatori (tablourile fixe). Daca e plin, conturile noi nu se mai
  adauga, dar jocul ruleaza normal.
- Lista nu e sortata dupa scor (vezi sect. 2).
- Fisierul e `nume - scor` in folderul curent de rulare; daca
  rulezi `./tetris` din alt folder, iti va face alt `leaderboard.txt`
  acolo (comportare standard pentru fisiere relative).

## 7. Compilare si rulare

```bash
cd ~/assembly_project/"Tetris in Assembly"
gcc -no-pie -o tetris main.s
./tetris
```

Fisierul `leaderboard.txt` se creeaza singur prima data cand introduci
un nume.
</content>
