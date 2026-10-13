# Jour 10 : apprendre à déboguer (le laboratoire de bugs) / Day 10: Learning to Debug (the Bug Lab)

[Version Française](#french) | [English Version](#english)

---

## <a id="french"></a> 🇫🇷 Version Française

### Objectif

Apprendre à trouver un bug dans du code de système d'exploitation : on casse le pilote FAT exprès, un bug à la fois, on observe le symptôme, on cherche la cause avec les bons outils, puis on corrige.

### Résultat

_ajouter ici ta capture de QEMU avec les 5 lignes `OK` du programme de test (par exemple `images/day10-tests-ok.png`)_

### Ce que j'ai compris

#### Pourquoi apprendre à déboguer
Dans la vidéo, l'auteur a passé environ 3 heures à trouver les bugs du pilote FAT. Quand on écrit un système d'exploitation, rien ne se passe comme prévu, et on ne dispose ni d'un débogueur intégré ni de messages d'erreur clairs. La méthode compte donc autant que le code.

#### Les trois techniques de la vidéo
1. **Afficher des valeurs avec `printf`** pendant que l'OS tourne.
2. **Le pas à pas** avec un débogueur (Bochs, ou QEMU avec `gdb`).
3. **Sortir le code sur le PC** et le déboguer avec les outils habituels.

#### Mon pilote FAT sur le PC (`fathost`)
`make` compile aussi `build/tools/fathost`. C'est **le même fichier `fat.c`** que celui de la stage 2, mais compilé par `gcc` sur mon PC. Pour cela : des en-têtes de remplacement (`tools/fathost/shim/`) fournissent `disk.h` (lecture dans un fichier image au lieu d'un vrai disque) et `memdefs.h` (un tableau au lieu d'une adresse mémoire), et deux options de compilation suppriment les mots-clés propres à Open Watcom : `-Dfar=` et `-D_cdecl=`. Usage : `./build/tools/fathost build/main_floppy.img test.txt mydir bigfile.txt`. Sur le PC, je peux utiliser `gdb`, afficher ce que je veux et comparer avec l'OS.

#### Sa limite
Le PC ne reproduit pas les bugs propres au mode 16 bits (par exemple, mélanger pointeurs near et far). Un bug qui **réussit sur le PC mais échoue dans l'OS** est un indice : il vient de la différence entre les deux (taille des types, segments).

#### Ma méthode
1. **Reproduire** le bug avec un test précis (les tests affichent `OK` ou `ECHEC`).
2. **Réduire** : trouver le plus petit cas qui échoue (quel fichier, quelle taille de morceau).
3. **Comparer** l'OS et le PC : même résultat ou pas ?
4. **Localiser** : `printf` ou `gdb` pour voir les valeurs, `hexdump`, `mshowfat` et `xp` dans le moniteur QEMU pour voir les vraies données.
5. **Corriger**, puis **relancer tous les tests**, pas seulement celui qui échouait.

#### Les tests avec valeurs attendues
`main.c` lit des fichiers par morceaux de tailles différentes et compare la longueur et la **somme des octets** avec des valeurs calculées à l'avance sur le PC. Un résultat `OK` prouve que le fichier est lu en entier et sans erreur.

### Le laboratoire de bugs

Avant de commencer : `git add . && git commit` (pour pouvoir revenir en arrière). Commandes : `tools/bug.sh list` (liste les bugs), `tools/bug.sh N` (introduit le bug N), `tools/bug.sh restore` (remet le fichier d'origine). Après chaque bug : `make`, puis `make run` (OS) et `./build/tools/fathost build/main_floppy.img ...` (PC).

#### Bug 1 : l'extension n'est pas en majuscules
- **Symptôme dans l'OS :** _à compléter_
- **Symptôme sur le PC :** _à compléter_
- **Comment je l'ai trouvé :** _à compléter_
- **Cause :** _à compléter_
- **Correction :** _à compléter_

#### Bug 2 : le tampon n'est pas rechargé quand il est vidé pile
- **Symptôme dans l'OS (quels morceaux échouent, lesquels réussissent ?) :** _à compléter_
- **Symptôme sur le PC :** _à compléter_
- **Comment je l'ai trouvé :** _à compléter_
- **Cause :** _à compléter_
- **Correction :** _à compléter_

#### Bug 3 : on interdit la lecture d'un sous-dossier
- **Symptôme dans l'OS :** _à compléter_
- **Symptôme sur le PC :** _à compléter_
- **Comment je l'ai trouvé :** _à compléter_
- **Cause (indice : quelle est la taille d'un sous-dossier dans sa propre entrée ?) :** _à compléter_
- **Correction :** _à compléter_

#### Bug 4 : la table FAT est lue avec un pointeur near au lieu de far
- **Symptôme dans l'OS :** _à compléter_
- **Symptôme sur le PC :** _à compléter_
- **Pourquoi la différence entre l'OS et le PC :** _à compléter_
- **Cause :** _à compléter_
- **Correction :** _à compléter_

#### Bug 5 : la racine n'est pas rechargée à chaque ouverture (plus de 16 fichiers)
- **Préparation :** ajouter 40 fichiers à l'image après `make` : `for i in $(seq 1 40); do echo "fichier $i" > /tmp/f$i.txt; mcopy -i build/main_floppy.img /tmp/f$i.txt ::f$i.txt; done`
- **Test sur le PC :** `./build/tools/fathost build/main_floppy.img f40.txt test.txt`
- **Symptôme :** _à compléter_
- **Cause :** _à compléter_
- **Correction :** _à compléter_

### Erreurs rencontrées

| Erreur / symptôme | Cause | Solution |
|-------------------|-------|----------|
| _à compléter_ | | |

---

## <a id="english"></a> 🇬🇧 English Version

### Goal

Learn how to find a bug in operating system code: we break the FAT driver on purpose, one bug at a time, observe the symptom, look for the cause with the right tools, then fix it.

### Result

_add your QEMU screenshot showing the 5 `OK` lines of the test program here (for example `images/day10-tests-ok.png`)_

### What I understood

#### Why learn to debug
In the video, the author spent about 3 hours finding the FAT driver's bugs. When writing an operating system, nothing goes as planned, and there is no built-in debugger or clear error message. So the method matters as much as the code.

#### The three techniques from the video
1. **Print values with `printf`** while the OS runs.
2. **Step-by-step** with a debugger (Bochs, or QEMU with `gdb`).
3. **Take the code out to the PC** and debug it with the usual tools.

#### My FAT driver on the PC (`fathost`)
`make` also builds `build/tools/fathost`. It is **the same `fat.c` file** as in stage 2, but compiled by `gcc` on my PC. To do that: replacement headers (`tools/fathost/shim/`) provide `disk.h` (reading from an image file instead of a real disk) and `memdefs.h` (an array instead of a memory address), and two compile options remove Open Watcom-specific keywords: `-Dfar=` and `-D_cdecl=`. Usage: `./build/tools/fathost build/main_floppy.img test.txt mydir bigfile.txt`. On the PC, I can use `gdb`, print whatever I want and compare with the OS.

#### Its limit
The PC does not reproduce bugs specific to 16-bit mode (for example, mixing near and far pointers). A bug that **succeeds on the PC but fails in the OS** is a clue: it comes from the difference between the two (type sizes, segments).

#### My method
1. **Reproduce** the bug with a precise test (the tests print `OK` or `ECHEC`).
2. **Reduce**: find the smallest case that fails (which file, which chunk size).
3. **Compare** the OS and the PC: same result or not?
4. **Locate**: `printf` or `gdb` to see the values, `hexdump`, `mshowfat` and `xp` in the QEMU monitor to see the real data.
5. **Fix**, then **rerun all the tests**, not only the one that failed.

#### Tests with expected values
`main.c` reads files in chunks of different sizes and compares the length and the **sum of the bytes** with values computed beforehand on the PC. An `OK` result proves the file is read completely and without error.

### The bug lab

Before starting: `git add . && git commit` (so I can go back). Commands: `tools/bug.sh list` (lists the bugs), `tools/bug.sh N` (introduces bug N), `tools/bug.sh restore` (puts the original file back). After each bug: `make`, then `make run` (OS) and `./build/tools/fathost build/main_floppy.img ...` (PC).

#### Bug 1: the extension is not uppercased
- **Symptom in the OS:** _to be completed_
- **Symptom on the PC:** _to be completed_
- **How I found it:** _to be completed_
- **Cause:** _to be completed_
- **Fix:** _to be completed_

#### Bug 2: the buffer is not reloaded when it is emptied exactly
- **Symptom in the OS (which chunk sizes fail, which succeed?):** _to be completed_
- **Symptom on the PC:** _to be completed_
- **How I found it:** _to be completed_
- **Cause:** _to be completed_
- **Fix:** _to be completed_

#### Bug 3: reading a subdirectory is forbidden
- **Symptom in the OS:** _to be completed_
- **Symptom on the PC:** _to be completed_
- **How I found it:** _to be completed_
- **Cause (hint: what is the size of a subdirectory in its own entry?):** _to be completed_
- **Fix:** _to be completed_

#### Bug 4: the FAT table is read with a near pointer instead of a far one
- **Symptom in the OS:** _to be completed_
- **Symptom on the PC:** _to be completed_
- **Why the OS and the PC differ:** _to be completed_
- **Cause:** _to be completed_
- **Fix:** _to be completed_

#### Bug 5: the root directory is not reloaded on each open (more than 16 files)
- **Setup:** add 40 files to the image after `make`: `for i in $(seq 1 40); do echo "file $i" > /tmp/f$i.txt; mcopy -i build/main_floppy.img /tmp/f$i.txt ::f$i.txt; done`
- **Test on the PC:** `./build/tools/fathost build/main_floppy.img f40.txt test.txt`
- **Symptom:** _to be completed_
- **Cause:** _to be completed_
- **Fix:** _to be completed_

### Errors encountered

| Error / symptom | Cause | Solution |
|-----------------|-------|----------|
| _to be completed_ | | |
