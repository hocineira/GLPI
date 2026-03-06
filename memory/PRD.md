# PRD - Script GLPI install_glpi.sh

## Problem Statement
Le script `install_glpi.sh` avait la version GLPI 11.0.0 codée en dur. L'utilisateur souhaite que le script récupère automatiquement la dernière version via l'API GitHub, avec un fallback vers la version 11.0.6 en cas d'échec.

## What's Been Implemented (Jan 2026)
- Ajout de la détection automatique de la dernière version via l'API GitHub (`/repos/glpi-project/glpi/releases/latest`)
- Variable `FALLBACK_VERSION="11.0.6"` utilisée si l'API échoue ou retourne un format invalide
- Double fallback: si le téléchargement de la version détectée échoue, le script retente avec la version fallback
- Toutes les références à "11.0.0" remplacées par la variable dynamique `$GLPI_VERSION`
- Validation du format de version (regex `^[0-9]+\.[0-9]+\.[0-9]+$`)

## Backlog
- P2: Ajouter un paramètre CLI pour forcer une version spécifique (ex: `./install_glpi.sh --version 11.0.5`)
