# Day 11: building the `i686-elf` cross-compiler

[English](#english) | [Français](#french)

---

## <a id="english"></a> 🇬🇧 English

### Goal

No OS code today. I build the tool that will compile my kernel in C (part 7 of the nanobyte series): a GCC **cross-compiler** that runs on my PC (Arch Linux, x86_64) but produces 32-bit code for a bare machine (`i686-elf`).

### Why a cross-compiler?

My system `gcc` builds programs for **my** Linux: it assumes the host C library, host headers and a 64-bit Linux ELF format. My kernel has no libc, no OS underneath, and will run in 32-bit mode. A cross-compiler (`i686-elf-gcc`) makes no assumption about the target OS.

`i686-elf` means: **i686** = 32-bit x86 CPU, **elf** = output format, and no vendor or OS in the name (bare metal).

### Versions that worked

| Item | Version |
|------|---------|
| Host system | Arch Linux (rolling) |
| Host gcc | 16.2.1 |
| binutils | **2.46.1** |
| gcc | **15.2.0** |
| Install prefix | `$HOME/opt/cross` |
| Target | `i686-elf` |

I installed in `$HOME/opt/cross`, not `/usr/local`: no `sudo`, nothing touches the system, and I can delete the folder to start over. `$PREFIX/bin` is added at the **start** of `PATH` so `i686-elf-*` tools are found first.

### Steps

#### 0. Environment (`tools/env.sh`, to `source` in every new terminal)

```bash
export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"
```

Always check with `echo $TARGET`. If it is empty, `configure` silently builds a compiler for the host.

#### 1. Dependencies (Arch)

```bash
sudo pacman -S --needed base-devel gmp libmpc mpfr texinfo bison flex nasm mtools qemu-system-x86
```

#### 2. Sources (outside the Git repo, in `~/src/cross`)

```bash
mkdir -p ~/src/cross && cd ~/src/cross
curl -LO https://ftp.gnu.org/gnu/binutils/binutils-2.46.1.tar.xz
curl -LO https://ftp.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz
ls -lh *.tar.xz            # check the sizes BEFORE extracting
tar xf binutils-2.46.1.tar.xz
tar xf gcc-15.2.0.tar.xz
```

#### 3. binutils (linker `ld`, `as`, `objdump`...)

```bash
mkdir build-binutils && cd build-binutils
../binutils-2.46.1/configure --target=$TARGET --prefix=$PREFIX \
  --with-sysroot --disable-nls --disable-werror
make
make install
```

- `--target`: build tools for `i686-elf`, named `i686-elf-ld`, `i686-elf-as`...
- `--prefix`: where to install.
- `--with-sysroot`: lets the linker support a sysroot later (for user-land programs).
- `--disable-nls`: messages in English only, easier to search online.
- `--disable-werror`: warnings do not stop the build (my host gcc 16 is stricter than binutils 2.46.1 expects).

A separate build folder keeps the sources clean, and I can start over by deleting it.

#### 4. gcc (and `libgcc`)

```bash
mkdir build-gcc && cd build-gcc
../gcc-15.2.0/configure --target=${TARGET:?} --prefix=${PREFIX:?} \
  --disable-nls --enable-languages=c,c++ --without-headers \
  CXXFLAGS="-g -O2 -fno-char8_t"
make -j$(nproc) all-gcc
make -j$(nproc) all-target-libgcc
make install-gcc
make install-target-libgcc
```

- `--enable-languages=c,c++`: only the languages I need (faster, smaller).
- `--without-headers`: do not rely on the host C library.
- `all-gcc`: the compiler alone. `all-target-libgcc`: a small library the compiler needs for operations the CPU cannot do directly (for example some 64-bit divisions in 32-bit code).
- `CXXFLAGS=-fno-char8_t`: see the pitfall below.

I ran each `make` as a separate command and checked the end of the log before starting the next one.

### Testing

```bash
i686-elf-gcc --version | head -1
echo 'void kmain(void) { for(;;); }' > /tmp/test.c
i686-elf-gcc -ffreestanding -c /tmp/test.c -o /tmp/test.o
i686-elf-objdump -f /tmp/test.o
```

Expected: the last command shows `file format elf32-i386`. That proves the compiler produces 32-bit code for my future kernel.

### What I learned about debugging a build

- A new terminal loses the variables (`PREFIX`, `TARGET`, `PATH`): `source tools/env.sh` every time.
- `command | tee log && next` does **not** stop if `command` fails (the exit code is the one of `tee`). Run steps separately and read the end of the log.
- A recent host compiler (gcc 16) can break older sources (gcc 15.2.0). I went for a recent but not the latest version, and wrote down the working combination.
- Always read the **first** `error:` in the log: the following lines are usually consequences.

The bugs I hit are listed in [PITFALLS.md](PITFALLS.md).

---

## <a id="french"></a> 🇫🇷 Français

### Objectif

Pas de code d'OS aujourd'hui. Je construis l'outil qui compilera mon noyau en C (partie 7 de la série nanobyte) : un **cross-compilateur** GCC qui tourne sur mon PC (Arch Linux, x86_64) mais produit du code 32 bits pour une machine « nue » (`i686-elf`).

### Pourquoi un cross-compilateur ?

Le `gcc` de mon système construit des programmes pour **mon** Linux : il suppose la libc de l'hôte, les en-têtes de l'hôte et un format ELF 64 bits pour Linux. Mon noyau n'aura ni libc, ni système en dessous, et tournera en 32 bits. Un cross-compilateur (`i686-elf-gcc`) ne fait aucune hypothèse sur le système cible.

`i686-elf` veut dire : **i686** = processeur x86 32 bits, **elf** = format de sortie, et ni fabricant ni système dans le nom (machine nue).

### Versions qui ont marché

| Élément | Version |
|---------|---------|
| Système hôte | Arch Linux (rolling) |
| gcc de l'hôte | 16.2.1 |
| binutils | **2.46.1** |
| gcc | **15.2.0** |
| Dossier d'installation | `$HOME/opt/cross` |
| Cible | `i686-elf` |

J'installe dans `$HOME/opt/cross` et non dans `/usr/local` : pas de `sudo`, rien ne touche au système, et je peux supprimer le dossier pour recommencer. `$PREFIX/bin` est ajouté **au début** du `PATH` pour que les outils `i686-elf-*` soient trouvés en premier.

### Étapes

#### 0. Environnement (`tools/env.sh`, à `source` dans chaque nouveau terminal)

```bash
export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"
```

Toujours vérifier avec `echo $TARGET`. S'il est vide, `configure` construit sans erreur un compilateur pour l'hôte.

#### 1. Dépendances (Arch)

```bash
sudo pacman -S --needed base-devel gmp libmpc mpfr texinfo bison flex nasm mtools qemu-system-x86
```

#### 2. Sources (hors du dépôt Git, dans `~/src/cross`)

```bash
mkdir -p ~/src/cross && cd ~/src/cross
curl -LO https://ftp.gnu.org/gnu/binutils/binutils-2.46.1.tar.xz
curl -LO https://ftp.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz
ls -lh *.tar.xz            # vérifier les tailles AVANT d'extraire
tar xf binutils-2.46.1.tar.xz
tar xf gcc-15.2.0.tar.xz
```

#### 3. binutils (éditeur de liens `ld`, `as`, `objdump`...)

```bash
mkdir build-binutils && cd build-binutils
../binutils-2.46.1/configure --target=$TARGET --prefix=$PREFIX \
  --with-sysroot --disable-nls --disable-werror
make
make install
```

- `--target` : construire des outils pour `i686-elf`, nommés `i686-elf-ld`, `i686-elf-as`...
- `--prefix` : où installer.
- `--with-sysroot` : permet à l'éditeur de liens de gérer un sysroot plus tard (programmes utilisateur).
- `--disable-nls` : messages en anglais uniquement, plus faciles à chercher sur Internet.
- `--disable-werror` : les avertissements n'arrêtent pas la compilation (mon gcc 16 est plus strict que ce que binutils 2.46.1 attend).

Un dossier de build séparé garde les sources propres, et je peux tout recommencer en le supprimant.

#### 4. gcc (et `libgcc`)

```bash
mkdir build-gcc && cd build-gcc
../gcc-15.2.0/configure --target=${TARGET:?} --prefix=${PREFIX:?} \
  --disable-nls --enable-languages=c,c++ --without-headers \
  CXXFLAGS="-g -O2 -fno-char8_t"
make -j$(nproc) all-gcc
make -j$(nproc) all-target-libgcc
make install-gcc
make install-target-libgcc
```

- `--enable-languages=c,c++` : seulement les langages utiles (plus rapide, plus léger).
- `--without-headers` : ne pas dépendre de la libc de l'hôte.
- `all-gcc` : le compilateur seul. `all-target-libgcc` : une petite bibliothèque dont le compilateur a besoin pour les opérations que le processeur ne fait pas directement (par exemple certaines divisions 64 bits en code 32 bits).
- `CXXFLAGS=-fno-char8_t` : voir le piège plus bas.

J'ai lancé chaque `make` séparément et vérifié la fin du log avant de passer au suivant.

### Tester

```bash
i686-elf-gcc --version | head -1
echo 'void kmain(void) { for(;;); }' > /tmp/test.c
i686-elf-gcc -ffreestanding -c /tmp/test.c -o /tmp/test.o
i686-elf-objdump -f /tmp/test.o
```

Attendu : la dernière commande affiche `file format elf32-i386`. Cela prouve que le compilateur produit du code 32 bits pour mon futur noyau.

### Ce que j'ai appris sur le débogage d'un build

- Un nouveau terminal perd les variables (`PREFIX`, `TARGET`, `PATH`) : `source tools/env.sh` à chaque fois.
- `commande | tee log && suite` ne s'arrête **pas** si `commande` échoue (le code de retour est celui de `tee`). Lancer les étapes séparément et lire la fin du log.
- Un compilateur hôte récent (gcc 16) peut casser des sources plus anciennes (gcc 15.2.0). J'ai pris une version récente mais pas la dernière, et noté la combinaison qui marche.
- Toujours lire la **première** ligne `error:` du log : les suivantes sont en général des conséquences.

Les bugs rencontrés sont listés dans [PITFALLS.md](PITFALLS.md).
