## Day 11: building the `i686-elf` cross-compiler

**1. `curl` downloads a tiny error page instead of the archive**
- Symptom: `tar: This does not look like a tar archive`; the file is only 196 or 286 bytes.
- Cause: wrong file name (a 404 page was saved), or a redirect not followed (no `-L`).
- Fix: use `curl -LO`, and check the size with `ls -lh` before `tar` (binutils is about 28 MB, gcc about 96 MB). `cat` the file to read the error.

**2. The archive is called `2.46.1`, not `2.46`**
- Symptom: 404 on `binutils-2.46.tar.xz`.
- Cause: recent releases carry a patch number.
- Fix: list the server folder first: `curl -sL https://ftp.gnu.org/gnu/binutils/ | grep -o 'binutils-2\.4[5-9][^"<]*\.tar\.xz' | sort -u`.

**3. `libcody` fails with `char8_t` errors (host g++ 16 + gcc 15.2.0)**
- Symptom: hundreds of lines `no matching function for call to 'S2C(const char8_t [2])'`, then `make: *** [all-libcody] Error`.
- Cause: g++ 16 compiles in C++20, where `u8"..."` has type `char8_t`. The code of gcc 15.2.0 expects plain `char`.
- Fix: `CXXFLAGS="-g -O2 -fno-char8_t"` at `configure`.
- Do not use `-std=gnu++17` in `CXXFLAGS`: gcc's `configure` then stops with `C++11 is required`.

**4. Empty `$TARGET` after opening a new terminal**
- Symptom: `configure` prints `target system type... x86_64-pc-linux-gnu` and builds a compiler for the host, with no error.
- Cause: the variables are lost when the terminal closes.
- Fix: `source tools/env.sh`, then `echo $TARGET`. Use `--target=${TARGET:?}` so the command fails if the variable is empty.

**5. `make ... | tee log && next` does not stop on failure**
- Symptom: `libgcc` started after `all-gcc` had failed, and printed unrelated errors (`xgcc: No such file`).
- Cause: the exit code of a pipe is the one of its last command (`tee`).
- Fix: run each `make` separately, then `tail -5` the log; or `set -o pipefail`.

**6. binutils warning `strnlen ... -Wstringop-overread` in `dwarf.c`**
- Symptom: one warning during `make`.
- Cause: gcc 16 is stricter than the code of binutils 2.46.1.
- Fix: none needed. `--disable-werror` keeps warnings from stopping the build.

**7. Messages `checking for i686-elf-gcc... no` during binutils `configure`**
- Normal: the cross-compiler does not exist yet.

**8. Noisy build output**
- Many `old-style function definition` (zlib) and `deprecated-enum-enum-conversion` warnings during the gcc build are harmless. Look for the first `error:`, not for the word `error` (it also matches `ferror_unlocked`).

---

## Jour 11 : construire le cross-compilateur `i686-elf`

**1. `curl` télécharge une petite page d'erreur au lieu de l'archive**
- Symptôme : `tar: This does not look like a tar archive` ; le fichier ne fait que 196 ou 286 octets.
- Cause : mauvais nom de fichier (une page 404 a été enregistrée), ou redirection non suivie (pas de `-L`).
- Correction : `curl -LO`, et vérifier la taille avec `ls -lh` avant `tar` (binutils environ 28 Mo, gcc environ 96 Mo). `cat` le fichier pour lire l'erreur.

**2. L'archive s'appelle `2.46.1`, pas `2.46`**
- Symptôme : 404 sur `binutils-2.46.tar.xz`.
- Cause : les versions récentes ont un numéro de correction.
- Correction : lister d'abord le dossier du serveur : `curl -sL https://ftp.gnu.org/gnu/binutils/ | grep -o 'binutils-2\.4[5-9][^"<]*\.tar\.xz' | sort -u`.

**3. `libcody` échoue avec des erreurs `char8_t` (g++ 16 de l'hôte + gcc 15.2.0)**
- Symptôme : des centaines de lignes `no matching function for call to 'S2C(const char8_t [2])'`, puis `make: *** [all-libcody] Error`.
- Cause : g++ 16 compile en C++20, où `u8"..."` a le type `char8_t`. Le code de gcc 15.2.0 attend des `char` normaux.
- Correction : `CXXFLAGS="-g -O2 -fno-char8_t"` au `configure`.
- Ne pas mettre `-std=gnu++17` dans `CXXFLAGS` : le `configure` de gcc s'arrête alors avec `C++11 is required`.

**4. `$TARGET` vide après l'ouverture d'un nouveau terminal**
- Symptôme : `configure` affiche `target system type... x86_64-pc-linux-gnu` et construit un compilateur pour l'hôte, sans erreur.
- Cause : les variables sont perdues à la fermeture du terminal.
- Correction : `source tools/env.sh`, puis `echo $TARGET`. Utiliser `--target=${TARGET:?}` pour que la commande échoue si la variable est vide.

**5. `make ... | tee log && suite` ne s'arrête pas en cas d'échec**
- Symptôme : `libgcc` a démarré après l'échec de `all-gcc` et a affiché des erreurs sans rapport (`xgcc: No such file`).
- Cause : le code de retour d'un tube est celui de sa dernière commande (`tee`).
- Correction : lancer chaque `make` séparément, puis `tail -5` du log ; ou `set -o pipefail`.

**6. Avertissement binutils `strnlen ... -Wstringop-overread` dans `dwarf.c`**
- Symptôme : un avertissement pendant `make`.
- Cause : gcc 16 est plus strict que le code de binutils 2.46.1.
- Correction : aucune. `--disable-werror` évite que les avertissements arrêtent la compilation.

**7. Messages `checking for i686-elf-gcc... no` pendant le `configure` de binutils**
- Normal : le cross-compilateur n'existe pas encore.

**8. Sortie très bavarde**
- Les nombreux avertissements `old-style function definition` (zlib) et `deprecated-enum-enum-conversion` pendant la compilation de gcc sont sans danger. Chercher la première ligne `error:`, pas le mot `error` (il apparaît aussi dans `ferror_unlocked`).
