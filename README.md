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
- `dosfstools` (`mkfs.fat`) and `mtools` (`mcopy`, `mdir`): build and inspect the FAT12 floppy image
- Developed on Arch Linux

### Build and run

```bash
make run     # assembles the bootloader and kernel, builds the FAT12 floppy image, starts QEMU
make clean   # removes the build/ folder
```

### Progress

| Day | Topic | Notes |
|-----|-------|-------|
| 1 | Boot sector, "Hello World" with BIOS `int 0x10` | [docs/day01-tests.md](docs/day01-tests.md) |
| 2 | Bootloader / kernel split, FAT12 floppy image | [docs/day02.md](docs/day02.md) |

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

### Day 2: what I learned

![Day 2: Hello from the bootloader](docs/images/day02-bootloader-hello.png)

#### 1. Why split into bootloader and kernel?
The boot sector is only 512 bytes, too small for a real OS. The bootloader (in the boot sector) loads the kernel, a separate file, from the rest of the disk and hands over control. The code now lives in `src/bootloader/boot.asm` and `src/kernel/main.asm`.

#### 2. Why a FAT12 floppy image?
Every BIOS and virtual machine supports floppies, images are easy to create, and FAT12 is simple. The kernel becomes a real file (`kernel.bin`) instead of raw sectors.

#### 3. Building the image
`dd` creates an empty 1.44 MB file (2880 × 512 bytes), `mkfs.fat -F 12` formats it, `dd ... conv=notrunc` writes the bootloader into the first sector, and `mcopy` copies `kernel.bin` into the image without mounting it (no `sudo`).

#### 4. The FAT12 header
Writing the bootloader over the first sector erases the headers that describe the disk, so `mcopy` fails with `non DOS media`. The bootloader must therefore start with `jmp short start`, a `nop`, then the BPB and the EBR fields:

| Field | Value |
|-------|-------|
| Bytes per sector | 512 |
| Sectors per cluster | 1 |
| Reserved sectors | 1 |
| Number of FATs | 2 |
| Root directory entries | `0E0h` (224) |
| Total sectors | 2880 |
| Media descriptor | `0F0h` (3.5" floppy) |
| Sectors per FAT | 9 |
| Sectors per track | 18 |
| Heads | 2 |

#### 5. Little-endian
Multi-byte numbers are stored low byte first: 512 = `0x0200` is stored as `00 02`, and the serial number bytes `12 34 56 78` form the value `0x78563412`, which `mdir` shows as `7856-3412`.

---

## <a id="french"></a> 🇫🇷 Version Française

Un système d'exploitation de loisir (hobby OS) écrit à partir de zéro pour l'architecture x86, en suivant la série *Building an OS* de nanobyte. Objectif : faire un petit pas par jour sur environ 3 mois, avec mes propres notes pour chaque étape.

![Jour 1 : Hello depuis le secteur d'amorçage](docs/images/day01-hello.png)

### Outils

- `nasm` : l'assembleur
- `make` : le système de build
- `qemu-system-i386` : la machine virtuelle pour tester l'OS
- `dosfstools` (`mkfs.fat`) et `mtools` (`mcopy`, `mdir`) : pour créer et inspecter l'image disquette FAT12
- Développé sous Arch Linux

### Compilation et exécution

```bash
make run     # assemble le bootloader et le kernel, génère l'image disquette FAT12 et lance QEMU
make clean   # supprime le dossier de build (build/)
```

### Progression

| Jour | Sujet | Notes |
|------|-------|-------|
| 1 | Secteur d'amorçage, "Hello World" avec l'interruption BIOS `int 0x10` | [docs/day01-tests.md](docs/day01-tests.md) |
| 2 | Séparation bootloader / kernel, image disquette FAT12 | [docs/day02.md](docs/day02.md) |

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

---

### Jour 2 : ce que j'ai appris

![Jour 2 : Hello depuis le bootloader](docs/images/day02-bootloader-hello.png)

#### 1. Pourquoi séparer bootloader et kernel ?
Le boot sector ne fait que 512 octets, trop peu pour un vrai OS. Le bootloader (dans le boot sector) charge le kernel, un fichier à part, depuis le reste du disque, puis lui laisse la main. Le code est maintenant dans `src/bootloader/boot.asm` et `src/kernel/main.asm`.

#### 2. Pourquoi une image disquette FAT12 ?
Tous les BIOS et toutes les machines virtuelles gèrent les disquettes, les images se créent facilement, et FAT12 est simple. Le kernel devient un vrai fichier (`kernel.bin`) au lieu de secteurs bruts.

#### 3. Construire l'image
`dd` crée un fichier vide de 1,44 Mo (2880 × 512 octets), `mkfs.fat -F 12` le formate, `dd ... conv=notrunc` écrit le bootloader dans le premier secteur, et `mcopy` copie `kernel.bin` dans l'image sans la monter (pas de `sudo`).

#### 4. L'en-tête FAT12
Écrire le bootloader sur le premier secteur efface les en-têtes qui décrivent le disque, donc `mcopy` échoue avec `non DOS media`. Le bootloader doit donc commencer par `jmp short start`, un `nop`, puis les champs du BPB et de l'EBR :

| Champ | Valeur |
|-------|--------|
| Octets par secteur | 512 |
| Secteurs par cluster | 1 |
| Secteurs réservés | 1 |
| Nombre de FAT | 2 |
| Entrées du répertoire racine | `0E0h` (224) |
| Nombre total de secteurs | 2880 |
| Type de média | `0F0h` (disquette 3,5") |
| Secteurs par FAT | 9 |
| Secteurs par piste | 18 |
| Têtes | 2 |

#### 5. Little-endian
Les nombres sur plusieurs octets sont stockés en commençant par l'octet de poids faible : 512 = `0x0200` s'écrit `00 02`, et les octets `12 34 56 78` du numéro de série forment la valeur `0x78563412`, que `mdir` affiche `7856-3412`.
