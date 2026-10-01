# Jour 1 : tests et erreurs / Day 1: Tests and Errors

[Version Française](#french) | [English Version](#english)

---

## <a id="french"></a> 🇫🇷 Version Française

Journal des expériences faites sur `main.asm`. Pour chaque test : ce que je prévois, ce que j'observe, et pourquoi.

### Résultat de référence

![QEMU affichant Hello RewriteOS!](images/day01-hello.png)

Le message `Hello RewriteOS!` s'affiche : le boot sector fonctionne.

### Message « Boot failed: could not read the boot disk »

* **Observé :** juste avant mon message, QEMU affiche `Booting from Hard Disk... Boot failed: could not read the boot disk`, puis `Booting from Floppy...`.
* **Explication :** le BIOS (SeaBIOS) essaie d'abord le disque dur, qui n'existe pas dans QEMU, puis passe à la disquette. Ce n'est pas une erreur de mon code.
* **Option :** ajouter `-boot a` dans la règle `run` du Makefile pour démarrer directement sur la disquette.

### Test 1 : calcul d'adresse (papier)

* **Question :** quelle adresse réelle donne `0x1234:0x0010` ?
* **Mon calcul :** _à compléter_
* **Vérification :** segment × 16 + offset

### Test 2 : enlever le `jmp .loop` dans `puts`

* **Prévu :** _à compléter_
* **Observé :** _à compléter (capture possible dans `images/`)_
* **Pourquoi :** _à compléter_

### Test 3 : macro `ENDL`

* **Modification :** `%define ENDL 0x0D, 0x0A` puis `msg: db 'Salut', ENDL, 0`
* **Observé :** _à compléter_

### Test 4 : `sp = 0x7E00` au lieu de `0x7C00`

* **Prévu :** _à compléter_
* **Observé :** _à compléter_
* **Pourquoi :** _à compléter (vers où descend la pile ?)_

### Erreurs rencontrées

| Erreur / symptôme | Cause | Solution |
|-------------------|-------|----------|
| `fatal: not a git repository` | `git init` pas encore fait | `git init` à la racine du projet |
| _à compléter_ | | |

---

## <a id="english"></a> 🇬🇧 English Version

Log of experiments performed on `main.asm`. For each test: what I expect, what I observe, and why.

### Reference result

![QEMU displaying Hello RewriteOS!](images/day01-hello.png)

The message `Hello RewriteOS!` is displayed: the boot sector works.

### "Boot failed: could not read the boot disk" message

* **Observed:** just before my message, QEMU prints `Booting from Hard Disk... Boot failed: could not read the boot disk`, then `Booting from Floppy...`.
* **Explanation:** the BIOS (SeaBIOS) tries the hard disk first, which does not exist in QEMU, then falls back to the floppy. This is not a bug in my code.
* **Option:** add `-boot a` to the `run` rule in the Makefile to boot directly from the floppy.

### Test 1: address calculation (paper)

* **Question:** what real address does `0x1234:0x0010` yield?
* **My calculation:** _to be completed_
* **Verification:** segment × 16 + offset

### Test 2: removing `jmp .loop` in `puts`

* **Expected:** _to be completed_
* **Observed:** _to be completed (screenshot possible in `images/`)_
* **Why:** _to be completed_

### Test 3: `ENDL` macro

* **Modification:** `%define ENDL 0x0D, 0x0A` then `msg: db 'Hi', ENDL, 0`
* **Observed:** _to be completed_

### Test 4: `sp = 0x7E00` instead of `0x7C00`

* **Expected:** _to be completed_
* **Observed:** _to be completed_
* **Why:** _to be completed (which way does the stack grow?)_

### Errors encountered

| Error / symptom | Cause | Solution |
|-----------------|-------|----------|
| `fatal: not a git repository` | `git init` not done yet | `git init` at the project root |
| _to be completed_ | | |
