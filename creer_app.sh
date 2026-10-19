#!/bin/bash
# Construit l'application « IP Pilot » dans le dossier Applications du Mac (/Applications).
#
# Usage :  bash creer_app.sh
#
# Les fichiers suivants doivent se trouver dans le même dossier que ce script :
#   ip_pilot.dat, IPPilot_icone_dock.png, et le dossier assets/ (images et polices de l'interface)
# À relancer chaque fois que tu changes de version.

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$DIR/ip_pilot.py"
DAT="$DIR/ip_pilot.dat"
ICONE="$DIR/IPPilot_icone_dock.png"
ASSETS="$DIR/assets"

# Les images, polices et sons sont fournis dans assets.zip (plus simple à télécharger depuis GitHub) :
# on le décompresse à côté du script s'il n'y a pas encore de dossier assets/.
if [ ! -d "$ASSETS" ] && [ -f "$DIR/assets.zip" ]; then
  echo "Décompression de assets.zip…"
  unzip -q -o "$DIR/assets.zip" -d "$DIR" || { echo "Erreur : impossible de décompresser assets.zip"; exit 1; }
fi

if [ ! -f "$SRC" ] && [ ! -f "$DAT" ]; then
  echo "Erreur : fichier introuvable : $DAT"
  exit 1
fi
for f in "$ICONE" "$ASSETS/fond.png" "$ASSETS/tete_170.png" "$ASSETS/tete_vide_170.png" "$ASSETS/fond_nuit.png" "$ASSETS/fond_tuile.png" "$ASSETS/fond_nuit_tuile.png" "$ASSETS/tete_170@150.png" "$ASSETS/sons/pop.wav" "$ASSETS/tete_48.png" "$ASSETS/tete_info.json" "$ASSETS/polices/GochiHand-Regular.ttf"; do
  if [ ! -f "$f" ]; then
    echo "Erreur : fichier introuvable : $f"
    exit 1
  fi
done

PYTHON="$(command -v python3)"
if [ -z "$PYTHON" ]; then
  echo "Erreur : python3 est introuvable."
  exit 1
fi

# Installation dans /Applications ; si le dossier n'est pas modifiable par cet utilisateur, on se rabat sur ~/Applications.
APPS="/Applications"
if [ ! -w "$APPS" ]; then
  echo "Note : /Applications n'est pas modifiable sans droits administrateur : installation dans ~/Applications à la place."
  echo "       (Pour l'installer dans /Applications : relance avec  sudo bash creer_app.sh )"
  APPS="$HOME/Applications"
  mkdir -p "$APPS"
fi
APP="$APPS/IP Pilot.app"
ANCIEN_DOSSIER="$HOME/Applications"

# On ferme IP Pilot (et ses anciennes versions) s'ils tournent, pour pouvoir les remplacer
pkill -f "IP Pilot.app/Contents/Resources/ip_pilot" 2>/dev/null || true
pkill -f "IPipi.app/Contents/Resources/ipipi.py" 2>/dev/null || true
pkill -f "IP Pilot.app/Contents/MacOS/IPPilot" 2>/dev/null || true
sleep 1

# Les anciennes applications sont remplacées par IP Pilot
for ancienne in "$APPS/IPipi.app" "$APPS/IP Switcher.app" "$ANCIEN_DOSSIER/IPipi.app" "$ANCIEN_DOSSIER/IP Switcher.app"; do
  if [ -d "$ancienne" ]; then
    rm -rf "$ancienne"
    echo "L'ancienne application « $(basename "$ancienne" .app) » a été remplacée par IP Pilot."
  fi
done

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# Le programme est installé sous forme compilée (ip_pilot.pyc), pas sous forme de texte lisible.
TMPSRC="$(mktemp -d)"
if [ -f "$SRC" ] && [ ! -f "$DAT" ]; then
  cp "$SRC" "$TMPSRC/ip_pilot.py"
else
  "$PYTHON" - "$DAT" "$TMPSRC/ip_pilot.py" <<'PYEOF'
import base64, sys, zlib
cle = b"GOONY-IP-Pilot"
brut = base64.b64decode(open(sys.argv[1], "rb").read())
clair = bytes(b ^ cle[i % len(cle)] for i, b in enumerate(brut))
open(sys.argv[2], "wb").write(zlib.decompress(clair))
PYEOF
fi
"$PYTHON" -c "import py_compile,sys; py_compile.compile(sys.argv[1], cfile=sys.argv[2], doraise=True, optimize=2)" \
  "$TMPSRC/ip_pilot.py" "$APP/Contents/Resources/ip_pilot.pyc"
CONTROLE="$(grep -c BONNET "$TMPSRC/ip_pilot.py")"
rm -rf "$TMPSRC"
cp "$DIR/LICENCE.txt" "$APP/Contents/Resources/LICENCE.txt" 2>/dev/null || true
cp "$DIR/lien_don.txt" "$APP/Contents/Resources/lien_don.txt" 2>/dev/null || true
cp "$DIR/lien_maj.txt" "$APP/Contents/Resources/lien_maj.txt" 2>/dev/null || true
cp "$ASSETS"/*.png "$ASSETS/tete_info.json" "$APP/Contents/Resources/"
cp -R "$ASSETS/polices" "$APP/Contents/Resources/polices"
cp -R "$ASSETS/sons" "$APP/Contents/Resources/sons"
cp "$ASSETS/tete_48.png" "$APP/Contents/Resources/barre_menu.png"

# ---------------------------------------------------------------- icône
faire_icone() {
  command -v sips >/dev/null && command -v iconutil >/dev/null || return 1
  local jeu
  jeu="$(mktemp -d)/AppIcon.iconset"
  mkdir -p "$jeu" || return 1
  local t
  for t in 16 32 128 256 512; do
    sips -z "$t" "$t" "$ICONE" --out "$jeu/icon_${t}x${t}.png" >/dev/null || return 1
    sips -z "$((t * 2))" "$((t * 2))" "$ICONE" --out "$jeu/icon_${t}x${t}@2x.png" >/dev/null || return 1
  done
  iconutil -c icns "$jeu" -o "$APP/Contents/Resources/AppIcon.icns" || return 1
  sips -z 256 256 "$ICONE" --out "$APP/Contents/Resources/icone_fenetre.png" >/dev/null || return 1
}

ICONE_OK=0
if faire_icone; then
  ICONE_OK=1
else
  echo "Avertissement : l'icône n'a pas pu être créée (l'application fonctionnera quand même)."
fi

# ---------------------------------------------------------------- barre de menu
# On installe le module « rumps » dans un environnement réservé à IP Pilot,
# pour ne rien toucher à ton Python habituel.
VENV="$APP/Contents/Resources/venv"
LOG="$(mktemp)"
BARRE=0
echo "Installation du module de barre de menu (connexion internet nécessaire)..."
if "$PYTHON" -m venv "$VENV" >"$LOG" 2>&1 \
   && "$VENV/bin/python" -m pip install --quiet --disable-pip-version-check rumps >>"$LOG" 2>&1 \
   && "$VENV/bin/python" -c "import rumps, tkinter" >>"$LOG" 2>&1; then
  BARRE=1
  # module MIDI (onglet Protocoles > MIDI) : facultatif, s'il manque seul l'écoute MIDI est indisponible
  "$VENV/bin/python" -m pip install --quiet --disable-pip-version-check python-rtmidi >>"$LOG" 2>&1 \
    || echo "Module MIDI non installé (l'écoute MIDI sera indisponible) : relance ce script avec internet."
else
  echo "Barre de menu indisponible : IP Pilot s'ouvrira avec sa fenêtre seule."
  echo "Détail du problème (à me copier si tu veux que je regarde) :"
  tail -n 6 "$LOG"
  rm -rf "$VENV"
  "$PYTHON" -m pip install --quiet --user --disable-pip-version-check python-rtmidi >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------- lanceur
if [ "$BARRE" = 1 ]; then
  PYBIN='"$DIR/Resources/venv/bin/python"'
  UIELEMENT="<true/>"
else
  PYBIN="\"$PYTHON\""
  UIELEMENT="<false/>"
fi

# Pour que Cmd+Tab et le Dock affichent « IP Pilot » (et pas « Python »), on place une copie du programme
# Python DANS l'application. Si ça ne marche pas sur ce Mac, on garde le lanceur simple.
NOMME=0
PYBASE="$("$PYTHON" -c 'import sys; print(sys.base_prefix)' 2>/dev/null || true)"
REELPY="$PYBASE/Resources/Python.app/Contents/MacOS/Python"
if [ -n "$PYBASE" ] && [ -x "$REELPY" ]; then
  SITE=""
  MODS="tkinter"
  if [ "$BARRE" = 1 ]; then
    SITE="$("$VENV/bin/python" -c 'import site; print(site.getsitepackages()[0])' 2>/dev/null || true)"
    MODS="tkinter, rumps"
  fi
  COPIE="$APP/Contents/MacOS/IPPilotPython"
  essai() { PYTHONHOME="$PYBASE" PYTHONPATH="$SITE" "$COPIE" -c "import $MODS" >>"$LOG" 2>&1; }
  if cp "$REELPY" "$COPIE" 2>/dev/null; then
    # macOS tue (« Killed: 9 ») un programme copié dont la signature n'est plus valide : on le re-signe sur place
    echo "(Si « Killed: 9 » s'affiche, c'est normal : je répare la signature du programme.)"
    if essai 2>/dev/null; then
      NOMME=1
    else
      xattr -cr "$COPIE" 2>/dev/null || true
      if codesign --force --sign - "$COPIE" >>"$LOG" 2>&1 && essai 2>/dev/null; then
        NOMME=1
      fi
    fi
  fi
  if [ "$NOMME" != 1 ]; then rm -f "$COPIE"; fi
fi

# Le chemin des modules est écrit RELATIF à l'application (et non en dur) : on peut ainsi la déplacer sans la casser.
SITE_REL=""
if [ -n "$SITE" ]; then
  SITE_REL="\$DIR/${SITE#"$APP/Contents/"}"
fi

if [ "$NOMME" = 1 ]; then
cat > "$APP/Contents/MacOS/IPPilot" <<EOT
#!/bin/bash
DIR="\$(cd "\$(dirname "\$0")/.." && pwd)"
export PYTHONHOME="$PYBASE"
export PYTHONPATH="$SITE_REL"
exec "\$DIR/MacOS/IPPilotPython" "\$DIR/Resources/ip_pilot.pyc" "\$@"
EOT
else
cat > "$APP/Contents/MacOS/IPPilot" <<EOT
#!/bin/bash
DIR="\$(cd "\$(dirname "\$0")/.." && pwd)"
exec $PYBIN "\$DIR/Resources/ip_pilot.pyc" "\$@"
EOT
fi
chmod +x "$APP/Contents/MacOS/IPPilot"

ICONE_LIGNE=""
if [ "$ICONE_OK" = 1 ]; then
  ICONE_LIGNE="<key>CFBundleIconFile</key><string>AppIcon</string>"
fi

cat > "$APP/Contents/Info.plist" <<EOT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>IP Pilot</string>
  <key>CFBundleDisplayName</key><string>IP Pilot</string>
  <key>CFBundleExecutable</key><string>IPPilot</string>
  <key>CFBundleIdentifier</key><string>local.ippilot</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>NSHumanReadableCopyright</key><string>© 2026 GOONY — tous droits réservés</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSUIElement</key>$UIELEMENT
  $ICONE_LIGNE
</dict>
</plist>
EOT

touch "$APP"

# Si une ancienne copie existe dans ~/Applications alors que la nouvelle est ailleurs, on la retire (une seule version).
if [ "$APPS" != "$ANCIEN_DOSSIER" ] && [ -d "$ANCIEN_DOSSIER/IP Pilot.app" ]; then
  rm -rf "$ANCIEN_DOSSIER/IP Pilot.app"
  echo "L'ancienne copie dans ~/Applications a été supprimée (IP Pilot est maintenant dans $APPS)."
fi

echo
echo "IP Pilot VERSION 1 est prête : $APP"
echo "Contrôle : $CONTROLE (doit être supérieur à 0)"
if [ "$BARRE" = 1 ]; then
  echo "Mode : icône dans la barre de menu + fenêtre."
else
  echo "Mode : fenêtre seule (pas de barre de menu)."
fi
echo "Python utilisé : $PYTHON"
if [ "$NOMME" = 1 ]; then echo "Nom dans Cmd+Tab : IP Pilot."; else echo "Nom dans Cmd+Tab : Python (la copie du programme n'a pas pu être faite sur ce Mac)."; fi
open -R "$APP" 2>/dev/null || true
