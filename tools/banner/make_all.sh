#!/bin/bash
# Régénère tous les titres du dossier banners/ (versions sombre et claire).
# Usage, depuis le dossier RewriteOS :  bash tools/banner/make_all.sh
#
# ===== TES RÉGLAGES (les deux seules lignes à modifier) =====
COLOR="#B79BFF"     # couleur des briques : violet clair. Essaie #FF8A3D (orange), #5CC8FF (bleu), #7CE38B (vert)...
SIZE=16             # taille d'une brique en pixels : 12 = moyen, 16 = grand, 20 = très grand
# ============================================================

cd "$(dirname "$0")/../.." || exit 1
mkdir -p banners

# Les titres à produire (A-Z, 0-9, espace, _ - . :). Pour en ajouter un, écris-le dans cette liste.
for title in REWRITE_OS BOOTLOADER STAGE1 STAGE2 KERNEL TOOLS DOCS; do
    name=$(echo "$title" | tr 'A-Z ' 'a-z_')
    python3 tools/banner/make_banner.py "$title" --color "$COLOR" --px "$SIZE" --theme dark  > "banners/$name-dark.svg"
    python3 tools/banner/make_banner.py "$title" --color "$COLOR" --px "$SIZE" --theme light > "banners/$name-light.svg"
    echo "fait : banners/$name-dark.svg et banners/$name-light.svg"
done

# Image d'aperçu du dépôt (GitHub > Settings > Social preview) : 1280x640
python3 tools/banner/make_banner.py "REWRITE_OS" --color "$COLOR" --canvas 1280x640 > banners/rewrite_os-social.svg
echo "fait : banners/rewrite_os-social.svg"
echo
echo "Pour obtenir le PNG de l'aperçu (GitHub demande un PNG) :"
echo "  sudo pacman -S librsvg"
echo "  rsvg-convert banners/rewrite_os-social.svg -o banners/rewrite_os-social.png"
