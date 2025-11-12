#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# Config
# -------------------------------
BUILD_DIR="build"
SITE_TITLE="GameDevHub"
CSS_FILE="style.css"

# -------------------------------
# Reset build dir
# -------------------------------
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/contributions"

# -------------------------------
# 1) Pages statiques existantes
# -------------------------------
# home.html devient index.html pour l'accueil
cp "home.html" "$BUILD_DIR/index.html"

# Copie des autres pages statiques
cp "article.html" "experience.html" "ressources.html" "communauté.html" "$BUILD_DIR/" 2>/dev/null || true

# Copie du CSS
cp "$CSS_FILE" "$BUILD_DIR/"

# Copie des assets si présents
if [ -d "assets" ]; then
  cp -R "assets" "$BUILD_DIR/assets"
fi

# -------------------------------
# 2) Contributions Markdown → HTML
#    Chaque .md est converti en /contributions/<nom>.html
# -------------------------------
if [ -d "contributions" ]; then
  shopt -s nullglob
  for f in contributions/*.md; do
    base="$(basename "$f" .md)"
    out="$BUILD_DIR/contributions/${base}.html"

    # Pandoc produit un HTML complet (-s) avec un <head> propre
    # --css ../style.css car la page générée est dans /contributions/
    pandoc \
      --from=gfm \
      --to=html5 \
      --standalone \
      --metadata=lang:fr \
      --metadata=title:"$SITE_TITLE – ${base//-/ }" \
      --css ../style.css \
      --quiet \
      "$f" -o "$out"
  done
fi

# -------------------------------
# 3) Page d'index des contributions
# -------------------------------
INDEX_CONTRIB="$BUILD_DIR/contributions.html"

cat > "$INDEX_CONTRIB" <<'HTML'
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>GameDevHub – Contributions</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <div class="container">
    <header class="header">
      <div class="logo">🎮 <h2>GameDevHub</h2></div>
      <nav class="nav">
        <a href="index.html">Accueil</a>
        <a href="article.html">Articles</a>
        <a href="experience.html">Expériences</a>
        <a href="ressources.html">Ressources</a>
        <a href="communauté.html">Communauté</a>
      </nav>
    </header>

    <section class="hero">
      <h1>Contributions</h1>
      <h2>Les apports de la communauté (Markdown → HTML)</h2>
    </section>

    <section>
      <h2 class="section-title">Liste des contributions</h2>
      <ul class="list">
HTML

# Boucle pour lister les fichiers HTML générés
if compgen -G "$BUILD_DIR/contributions/*.html" > /dev/null; then
  for html in "$BUILD_DIR"/contributions/*.html; do
    name="$(basename "$html")"
    title="${name%.html}"
    # Affichage plus joli (remplacer - par espace)
    title_pretty="${title//-/ }"
    echo "        <li><a href=\"contributions/$name\">$title_pretty</a></li>" >> "$INDEX_CONTRIB"
  done
else
  echo "        <li>Aucune contribution publiée pour le moment.</li>" >> "$INDEX_CONTRIB"
fi

cat >> "$INDEX_CONTRIB" <<'HTML'
      </ul>
    </section>

    <footer class="footer">
      <p>© 2024 GameDevHub. Tous droits réservés.</p>
    </footer>
  </div>
</body>
</html>
HTML

echo "✅ Build terminé dans: $BUILD_DIR"
