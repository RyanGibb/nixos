cd /storage/emulated/0/Documents/vault
git pull || exit 1
git add . || exit 1
git commit -m "phone $(date '+%Y-%m-%d %H.%M')" || exit 1
git push || exit 1
