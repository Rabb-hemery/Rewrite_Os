# Rewrite_OS

[English Version](#english) | [Version Française](#french)

---

## <a id="english"></a> 🇬🇧 English Version

A hobby operating system written from scratch for x86, following the *Building an OS* series by nanobyte. Goal: one small step per day, over about 3 months, with my own notes for each step.

![Day 1: Hello from the boot sector](docs/images/day01-hello.png)

### Tools

- `nasm`: assembler
- `make`: build system
- `qemu-system-i386`: virtual machine to test the OS
- Developed on Arch Linux

### Build and run

```bash
make run     # assembles the code, builds the floppy image, starts QEMU
make clean   # removes the build/ folder
```

### Progress

| Day | Topic | Notes |
|-----|-------|-------|
| 1 | Boot sector, "Hello World" with BIOS `int 0x10` | [docs/day01-tests.md](docs/day01-tests.md) |

---

### Day 1: what I learned

#### 1. What is assembly?
Assembly is machine code written in a human-readable way. An instruction is a mnemonic plus 0 to 2 operands (`mov ax, 5`). NASM turns it into bytes. Here we target x86.

#### 2. How a PC boots (legacy mode)
The BIOS reads the first sector (512 bytes) of the disk and checks that its last 2 bytes equal `0xAA55`. It then loads the sector at `0x7C00` and jumps to it. My OS starts there.

#### 3. Directives vs instructions
A directive guides NASM and is not turned into machine code:

- `org 0x7C00`: "compute addresses starting at 0x7C00". It does not force the BIOS to load there, it only informs NASM.
- `bits 16`: the CPU always starts in 16-bit mode, for backward compatibility with the 8086.
- `times 510-($-$$) db 0`: `$` is the current line, `$$` the start of the section, so `$-$$` is the code size so far. It pads with zeros up to 510 bytes.
- `dw 0AA55h`: the last 2 bytes (the boot signature).

#### 4. Registers and segments
Registers are tiny, very fast memories inside the CPU (`ax`, `si`, `sp`, `ds`, `ss`...). A real address is computed as **segment × 16 + offset**. Several pairs give the same address: `0x0000:0x7C00` and `0x07C0:0x0000` are both `0x7C00`. Another rule: a constant cannot be written directly into a segment register, so we go through `ax`:

```nasm
mov ax, 0
mov ds, ax
```

#### 5. The stack
It is last-in, first-out (`push`/`pop`) and is used by `call`/`ret`. It grows **downwards** in memory, so we set `sp = 0x7C00`: it grows away from our code and does not overwrite it.

#### 6. Printing text (`puts`)
- `lodsb`: loads the byte at `ds:si` into `al`, then `si++`.
- `or al, al`: leaves `al` unchanged but updates the zero flag. `jz .done` leaves the loop when the character is 0.
- `int 0x10` with `ah = 0x0E`: asks the BIOS to print the character in `al`. Also set `bh = 0` (page).
- A new line is `0x0D, 0x0A` (carriage return + line feed).

#### Note about the "Boot failed" message in QEMU
At startup SeaBIOS first tries the hard disk. QEMU has none, so it prints "Boot failed: could not read the boot disk", then falls back to the floppy, which is my image. This is normal and not a bug in my code.

---

## <a id="french"></a> 🇫🇷 Version Française

Un système d'exploitation de loisir (hobby OS) écrit à partir de zéro pour l'architecture x86, en suivant la série *Building an OS* de nanobyte. Objectif : faire un petit pas par jour sur environ 3 mois, avec mes propres notes pour chaque étape.

![Jour 1 : Hello depuis le secteur d'amorçage](docs/images/day01-hello.png)

### Outils

- `nasm` : l'assembleur
- `make` : le système de build
- `qemu-system-i386` : la machine virtuelle pour tester l'OS
- Développé sous Arch Linux

### Compilation et exécution

```bash
make run     # assemble le code, génère l'image de la disquette et lance QEMU
make clean   # supprime le dossier de build (build/)
```

### Progression

| Jour | Sujet | Notes |
|------|-------|-------|
| 1 | Secteur d'amorçage, "Hello World" avec l'interruption BIOS `int 0x10` | [docs/day01-tests.md](docs/day01-tests.md) |

---

### Jour 1 : ce que j'ai appris

#### 1. Qu'est-ce que l'assembleur ?
L'assembleur est du code machine écrit d'une manière lisible par l'humain. Une instruction est composée d'un mnémonique et de 0 à 2 opérandes (`mov ax, 5`). NASM transforme cela en octets. Ici, nous ciblons l'architecture x86.

#### 2. Comment un PC démarre (mode legacy)
Le BIOS lit le premier secteur (512 octets) du disque et vérifie que ses 2 derniers octets sont égaux à `0xAA55`. Il charge ensuite ce secteur à l'adresse mémoire `0x7C00` et saute (jump) dessus. C'est là que mon OS commence.

#### 3. Directives vs instructions
Une directive guide NASM et n'est pas transformée en code machine :

- `org 0x7C00` : "calcule les adresses en commençant à 0x7C00". Cela ne force pas le BIOS à charger le code à cet endroit, cela informe simplement NASM.
- `bits 16` : le processeur démarre toujours en mode 16 bits, pour des raisons de rétrocompatibilité avec le 8086.
- `times 510-($-$$) db 0` : `$` représente la ligne actuelle, `$$` le début de la section, donc `$-$$` donne la taille du code écrit jusqu'ici. Cette commande remplit le reste avec des zéros jusqu'à atteindre 510 octets.
- `dw 0AA55h` : les 2 derniers octets (la signature d'amorçage ou *boot signature*).

#### 4. Registres et segments
Les registres sont de toutes petites mémoires très rapides situées directement dans le processeur (`ax`, `si`, `sp`, `ds`, `ss`...). Une adresse réelle se calcule ainsi : **segment × 16 + offset**. Plusieurs paires de valeurs peuvent donner la même adresse physique : `0x0000:0x7C00` et `0x07C0:0x0000` pointent toutes les deux vers `0x7C00`. Autre règle : on ne peut pas écrire une constante directement dans un registre de segment, il faut obligatoirement passer par `ax` :

```nasm
mov ax, 0
mov ds, ax
```

#### 5. La pile (The stack)
Elle fonctionne selon le principe du "dernier entré, premier sorti" (`push`/`pop`) et est utilisée par `call`/`ret`. Elle grandit **vers le bas** de la mémoire, c'est pourquoi nous définissons `sp = 0x7C00` : elle s'éloigne ainsi de notre code et ne risque pas de l'écraser.

#### 6. Afficher du texte (`puts`)
- `lodsb` : charge l'octet situé à l'adresse `ds:si` dans `al`, puis incrémente `si` (`si++`).
- `or al, al` : laisse `al` inchangé mais met à jour le drapeau zéro (*zero flag*). `jz .done` permet de quitter la boucle lorsque le caractère lu est égal à 0.
- `int 0x10` avec `ah = 0x0E` : demande au BIOS d'afficher le caractère contenu dans `al`. On définit également `bh = 0` (la page d'affichage).
- Un saut de ligne est représenté par `0x0D, 0x0A` (retour chariot + saut de ligne).

#### Note concernant le message "Boot failed" dans QEMU
Au démarrage, SeaBIOS cherche d'abord à démarrer sur le disque dur. QEMU n'en ayant pas, il affiche "Boot failed: could not read the boot disk", puis bascule sur la disquette, qui contient mon image. C'est un comportement tout à fait normal et ce n'est pas un bug dans mon code.
