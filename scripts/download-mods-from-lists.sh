#!/bin/bash
set -euo pipefail

# =========================
# CONFIGURAÇÃO
# =========================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODS_DIR="mods"

CLIENT_LIST="$SCRIPT_DIR/client-mods.txt"
BOTH_LIST="$SCRIPT_DIR/both-mods.txt"
SERVER_LIST="$SCRIPT_DIR/server-mods.txt"

# =========================
# ESTADO GLOBAL
# =========================

declare -a ALLOWED_LIST

# =========================
# CARREGAR LISTAS
# =========================

load_mod_list() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  while IFS= read -r mod || [[ -n "$mod" ]]; do
    [[ -z "$mod" || "$mod" == \#* ]] && continue

    ALLOWED_LIST+=("$mod")
  done < "$file"
}

# =========================
# LIMPAR PASTA DE MODS
# =========================

clean_mods_folder() {
  echo "[INFO] Removendo todos os mods..."
  local file mod

  for file in "$MODS_DIR"/*.pw.toml; do
    [[ -e "$file" ]] || continue

    mod="$(basename "$file" .pw.toml)"
    packwiz remove "$mod" -y >/dev/null 2>&1 || true
  done
  
  rm -f "$MODS_DIR"/*.jar >/dev/null 2>&1 || true
}

# =========================
# GARANTIR MODS EXISTENTES
# =========================

ensure_mods_present() {
  local line mod_name mod_version res

  echo "[INFO] Baixando/Atualizando mods das listas..."
  for line in "${ALLOWED_LIST[@]}"; do
    if [[ "$line" == https://* ]]; then
      packwiz cf add "$line" -y >/dev/null 2>&1 || packwiz mr add "$line" -y >/dev/null 2>&1 || true
      continue
    fi

    if [[ "$line" == --addon-id* ]]; then
      packwiz curseforge add $line -y >/dev/null 2>&1 || true
      continue
    fi

    # Separa por espaço: primeiro token é o nome, o resto é a versão (se existir)
    mod_name="${line%% *}"
    mod_version="${line#* }"

    if [[ "$mod_name" == "$mod_version" ]]; then
      # Nenhuma versão especificada
      if ! packwiz update "$mod_name" -y >/dev/null 2>&1; then
        if packwiz curseforge add "$mod_name" -y >/dev/null 2>&1; then
          packwiz update "$mod_name" -y >/dev/null 2>&1 || true
        elif packwiz modrinth add "$mod_name" -y >/dev/null 2>&1; then
          packwiz update "$mod_name" -y >/dev/null 2>&1 || true
        else
          echo "[WARN] Não foi possível adicionar: $mod_name"
        fi
      fi
    else
      # Versão específica solicitada
      echo "[INFO] Resolvendo versão específica para $mod_name ($mod_version)..."
      res=$(python3 "$SCRIPT_DIR/resolve_version.py" "$mod_name" "$mod_version" 2>/dev/null || true)
      
      if [[ "$res" == MR* ]]; then
        local pid vid
        read -r _ pid vid <<< "$res"
        packwiz remove "$mod_name" -y >/dev/null 2>&1 || true
        packwiz mr add --project-id "$pid" --version-id "$vid" -y >/dev/null 2>&1 || echo "[WARN] Falha MR $mod_name (v $mod_version)"
      elif [[ "$res" == CF* ]]; then
        local pid fid
        read -r _ pid fid <<< "$res"
        packwiz remove "$mod_name" -y >/dev/null 2>&1 || true
        packwiz cf add --addon-id "$pid" --file-id "$fid" -y >/dev/null 2>&1 || echo "[WARN] Falha CF $mod_name (v $mod_version)"
      else
        echo "[WARN] Não encontrou versão na API. Tentando versão genérica para $mod_name..."
        if ! packwiz update "$mod_name" -y >/dev/null 2>&1; then
          packwiz curseforge add "$mod_name" -y >/dev/null 2>&1 || packwiz modrinth add "$mod_name" -y >/dev/null 2>&1 || true
        fi
      fi
    fi
  done
}

# =========================
# EXECUÇÃO
# =========================

load_mod_list "$CLIENT_LIST"
load_mod_list "$BOTH_LIST"
load_mod_list "$SERVER_LIST"

clean_mods_folder
ensure_mods_present

packwiz refresh

# correção final de side (se existir)
if [[ -f "$SCRIPT_DIR/fix-mods-to-client-or-server.sh" ]]; then
  "$SCRIPT_DIR/fix-mods-to-client-or-server.sh"
fi