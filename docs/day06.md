# Jour 6 : la stage 2 du bootloader en C / Day 6: Writing Stage 2 of the Bootloader in C

[Version Française](#french) | [English Version](#english)

---

## <a id="french"></a> 🇫🇷 Version Française

### Objectif

Séparer le bootloader en deux étapes (stage 1 en assembleur, stage 2 en C), installer le compilateur Open Watcom, et afficher un message depuis du code C.

### Résultat

_ajouter ici ta capture de QEMU avec `Hello world from C!` (par exemple `images/day06-hello-c.png`)_

### Ce que j'ai compris

#### Pourquoi deux étapes ?
Le boot sector ne fait que 512 octets : il ne reste que 46 octets libres. La **stage 1** (dans le boot sector) ne fait qu'une chose : chercher `stage2.bin` dans le répertoire racine FAT12 et le charger. La **stage 2** n'a plus la limite des 512 octets : on peut y écrire en C, et plus tard y faire passer le processeur en mode 32 bits.

#### Pourquoi le C, et pourquoi Open Watcom ?
Le C n'a pas besoin de support à l'exécution (pas de bibliothèque obligatoire), il est utilisé par la plupart des systèmes d'exploitation et il donne le contrôle de la mémoire. Mais on est encore en **mode réel 16 bits**, et GCC et Clang ne savent pas produire ce code. Open Watcom sait le faire, et il tourne sous Linux.

#### Les options de compilation (`wcc`)
* `-4` : code compatible avec un processeur 486 ou plus récent.
* `-d3` : beaucoup d'informations de débogage.
* `-s` : désactive la vérification de débordement de pile (on n'a pas de runtime pour la faire).
* `-wx` : tous les avertissements.
* `-ms` : modèle mémoire « small ».
* `-zl` : ne pas référencer les bibliothèques standard (on n'y a pas accès).
* `-zq` : silencieux, n'affiche que les avertissements et erreurs.

#### Les modèles mémoire
En mode réel, une adresse est `segment:offset`. Un pointeur « near » ne contient que l'offset (16 bits), un pointeur « far » contient les deux (32 bits). Le modèle **small** utilise deux segments (un pour le code, un pour les données et la pile) avec des pointeurs near par défaut : c'est le plus simple, et le bootloader n'est pas gros. Les autres (tiny, medium, compact, large, huge) mélangent near et far pour gérer plus de code ou plus de données, au prix de la vitesse et de la complexité.

#### Le script d'édition de liens (`linker.lnk`)
On veut que le premier octet de `stage2.bin` soit directement le point d'entrée, sans en-tête. D'où `FORMAT RAW BIN`, `OPTION START=entry`, `OPTION OFFSET=0` (l'équivalent de `org`, car le fichier est chargé à l'offset 0 du segment `0x2000`) et `ORDER` qui place d'abord le segment `_ENTRY`, puis `_TEXT`, puis les données. Dans le fichier `.map`, l'adresse du point d'entrée doit être **0**, sinon quelque chose ne va pas.

#### La convention d'appel cdecl
* Les paramètres sont empilés **de droite à gauche**.
* Un entier ou une adresse est retourné dans `ax`.
* L'appelant retire les paramètres de la pile après l'appel.
* Les registres `eax`, `ecx`, `edx` sont sauvegardés par l'appelant, les autres par la fonction appelée.
* Le nom des fonctions commence par un `_` (d'où `_cstart_` en assembleur pour la fonction C `cstart_`).

Dans une fonction (modèle small, appel near) : `[bp]` est l'ancien `bp`, `[bp+2]` l'adresse de retour, `[bp+4]` le 1er argument, `[bp+6]` le 2e.

#### Mélanger C et assembleur
Le C ne peut pas appeler une interruption BIOS. J'écris donc en assembleur `x86_Video_WriteCharTeletype` (qui fait `int 10h` avec `ah = 0Eh`), et `putc` et `puts` en C l'appellent.

### Mini-exos

#### Exo 1 : installer Open Watcom
- **Commandes utilisées :** _à compléter_
- **Vérification (`wcc` affiche sa bannière) :** _à compléter_

#### Exo 2 : lancer le tout
- **Commande :** `make run`
- **Observé :** _à compléter_

#### Exo 3 : lire le fichier `.map`
- **Commande :** `grep -n -i entry build/stage2.map`
- **Adresse du point d'entrée :** _à compléter_
- **Taille de `stage2.bin` :** _à compléter_

#### Exo 4 : modifier le message
- **Modification :** changer le texte de `puts` dans `main.c` et ajouter une deuxième ligne
- **Observé :** _à compléter_

#### Exo 5 : l'erreur de la vidéo
- **Modification :** dans `x86.asm`, remplacer `[bp + 4]` par `[bp + 2]`, puis `make run`
- **Observé :** _à compléter_
- **Pourquoi :** _à compléter (que contient `[bp + 2]` ?)_

### Erreurs rencontrées

| Erreur / symptôme | Cause | Solution |
|-------------------|-------|----------|
| `Warning! W1014: stack segment not found` | l'éditeur de liens ne trouve pas de segment de pile explicite | sans gravité ici, la vidéo le signale aussi |
| _à compléter_ | | |

---

## <a id="english"></a> 🇬🇧 English Version

### Goal

Split the bootloader into two stages (stage 1 in assembly, stage 2 in C), install the Open Watcom compiler, and print a message from C code.

### Result

_add your QEMU screenshot showing `Hello world from C!` here (for example `images/day06-hello-c.png`)_

### What I understood

#### Why two stages?
The boot sector is only 512 bytes: just 46 free bytes remain. **Stage 1** (in the boot sector) does only one thing: find `stage2.bin` in the FAT12 root directory and load it. **Stage 2** is no longer limited to 512 bytes: it can be written in C, and later it will switch the processor to 32-bit mode.

#### Why C, and why Open Watcom?
C needs no runtime support (no mandatory library), it is used by most operating systems and it gives control over memory. But we are still in **16-bit real mode**, and GCC and Clang cannot produce that code. Open Watcom can, and it runs on Linux.

#### The compile options (`wcc`)
* `-4`: code compatible with a 486 or newer processor.
* `-d3`: lots of debugging information.
* `-s`: disables stack overflow checks (there is no runtime to do them).
* `-wx`: all warnings.
* `-ms`: "small" memory model.
* `-zl`: do not reference the standard libraries (we have no access to them).
* `-zq`: quiet, prints only warnings and errors.

#### Memory models
In real mode, an address is `segment:offset`. A "near" pointer holds only the offset (16 bits), a "far" pointer holds both (32 bits). The **small** model uses two segments (one for code, one for data and stack) with near pointers by default: it is the simplest, and the bootloader is not big. The others (tiny, medium, compact, large, huge) mix near and far to handle more code or more data, at the cost of speed and complexity.

#### The linker script (`linker.lnk`)
I want the first byte of `stage2.bin` to be the entry point itself, with no header. Hence `FORMAT RAW BIN`, `OPTION START=entry`, `OPTION OFFSET=0` (the equivalent of `org`, since the file is loaded at offset 0 of segment `0x2000`) and `ORDER`, which places the `_ENTRY` segment first, then `_TEXT`, then the data. In the `.map` file, the entry point address must be **0**, otherwise something is wrong.

#### The cdecl calling convention
* Parameters are pushed **from right to left**.
* An integer or an address is returned in `ax`.
* The caller removes the parameters from the stack after the call.
* Registers `eax`, `ecx`, `edx` are saved by the caller, the others by the called function.
* Function names start with `_` (hence `_cstart_` in assembly for the C function `cstart_`).

Inside a function (small model, near call): `[bp]` is the old `bp`, `[bp+2]` the return address, `[bp+4]` the 1st argument, `[bp+6]` the 2nd.

#### Mixing C and assembly
C cannot call a BIOS interrupt. So I wrote `x86_Video_WriteCharTeletype` in assembly (it does `int 10h` with `ah = 0Eh`), and `putc` and `puts` in C call it.

### Mini-exercises

#### Exercise 1: installing Open Watcom
- **Commands used:** _to be completed_
- **Check (`wcc` prints its banner):** _to be completed_

#### Exercise 2: running it
- **Command:** `make run`
- **Observed:** _to be completed_

#### Exercise 3: reading the `.map` file
- **Command:** `grep -n -i entry build/stage2.map`
- **Entry point address:** _to be completed_
- **Size of `stage2.bin`:** _to be completed_

#### Exercise 4: changing the message
- **Change:** edit the text passed to `puts` in `main.c` and add a second line
- **Observed:** _to be completed_

#### Exercise 5: the video's bug
- **Change:** in `x86.asm`, replace `[bp + 4]` with `[bp + 2]`, then `make run`
- **Observed:** _to be completed_
- **Why:** _to be completed (what does `[bp + 2]` contain?)_

### Errors encountered

| Error / symptom | Cause | Solution |
|-----------------|-------|----------|
| `Warning! W1014: stack segment not found` | the linker finds no explicit stack segment | harmless here, the video mentions it too |
| _to be completed_ | | |
