#!/data/data/com.termux/files/usr/bin/bash
# Скачивает иконки Material Symbols (npm-пакет @material-symbols/svg-400) для галереи иконок Vexel.
#
# Запуск в Termux:
#   pkg install curl tar
#   termux-setup-storage            # один раз, даст доступ к памяти телефона
#   bash get_icons.sh               # все три стиля, с залитыми вариантами
#   bash get_icons.sh -s outlined   # только Outlined
#   bash get_icons.sh -s outlined,rounded -n   # два стиля, без залитых (-n = no fill, файлов вдвое меньше)
#   bash get_icons.sh -o /путь/к/app/src/main/assets/icons   # своя папка назначения
#
# По умолчанию иконки кладутся в ~/storage/shared/Download/vexel-icons: Android не даёт Termux писать
# в Android/data других приложений, поэтому потом скопируйте папки outlined, rounded, sharp
# в app/src/main/assets/icons проекта обычным файловым менеджером.

set -e
STYLES="outlined,rounded,sharp"
NOFILL=0
OUT="$HOME/storage/shared/Download/vexel-icons"
PKG="@material-symbols/svg-400"

while getopts "s:o:nh" opt; do
  case "$opt" in
    s) STYLES="$OPTARG" ;;
    o) OUT="$OPTARG" ;;
    n) NOFILL=1 ;;
    *) sed -n '2,14p' "$0"; exit 0 ;;
  esac
done

for tool in curl tar; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Нет $tool. Выполните: pkg install curl tar"; exit 1; }
done

echo "Ищу последнюю версию $PKG ..."
META=$(curl -fsSL "https://registry.npmjs.org/$PKG/latest") || { echo "Не удалось получить данные с npm. Проверьте интернет."; exit 1; }
URL=$(printf '%s' "$META" | grep -o '"tarball":"[^"]*"' | head -1 | cut -d'"' -f4)
VER=$(printf '%s' "$META" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)
[ -n "$URL" ] || { echo "В ответе npm нет ссылки на архив."; exit 1; }
echo "Версия $VER"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
echo "Скачиваю архив (десятки мегабайт, это может занять минуту) ..."
curl -fL --progress-bar -o "$TMP/pkg.tgz" "$URL"

# в архиве всё лежит в папке package/
INCLUDE=""
for s in $(printf '%s' "$STYLES" | tr ',' ' '); do INCLUDE="$INCLUDE package/$s"; done
EXCL=""
[ "$NOFILL" = 1 ] && EXCL="--wildcards --exclude=*-fill.svg"

mkdir -p "$OUT"
echo "Распаковываю: $STYLES ..."
# shellcheck disable=SC2086
tar -xzf "$TMP/pkg.tgz" -C "$TMP" $EXCL $INCLUDE 2>/dev/null || tar -xzf "$TMP/pkg.tgz" -C "$TMP" $INCLUDE

TOTAL=0
for s in $(printf '%s' "$STYLES" | tr ',' ' '); do
  if [ -d "$TMP/package/$s" ]; then
    rm -rf "$OUT/$s"
    mv "$TMP/package/$s" "$OUT/$s"
    N=$(ls "$OUT/$s" | wc -l)
    echo "  $s: $N файлов"
    TOTAL=$((TOTAL + N))
  else
    echo "  $s: папки нет в пакете, пропускаю"
  fi
done

[ "$TOTAL" -gt 0 ] || { echo "Ничего не нашёл. Структура пакета могла измениться."; exit 1; }
echo
echo "Готово: $OUT"
echo "Скопируйте папки (outlined, rounded, sharp) в app/src/main/assets/icons проекта и пересоберите приложение."
