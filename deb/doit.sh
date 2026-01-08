#!/bin/sh
set -eu
#rm -f debian-binary control preinst control.tar control.tar.gz control.tar.zst data.tar data.tar.gz data.tar.zst foo.deb
#rm -f debian-binary control preinst control.tar.gz control.tar.zst data.tar data.tar.gz data.tar.zst foo.deb

# versions to potentially submit:
# 0: smallest deb that outputs 6: ~~172~~ ~~72~~ 58 bytes
# 2: smallest that executes curl: ~~244~~ 135 bytes
# 3: smallest clean install, curl on remove/purge: ~~324~~ 153 bytes
# 4: clean inst, /bin/6: ~~376~~ 205 bytes

# empty for gnu tar, 1 for custom tar w/nasm
CUSTOMTAR=1
VERSION="2.6"

script="postrm"

case ${1:-2} in
0)
	echo "smallest new deb"
	VERSION="6.0"
	FILES="control"
	FILES2="debian-binary"
	control="control1"
	;;
1)
	echo "smallest old deb"
	control="control3"
	FILES="control"
	FILES2="debian-binary control.tar.zst"
	;;
2)
	echo "smallest BGGP5"
	control="control2"
	script="preinst"
	FILES="control $script"
	FILES2="debian-binary control.tar.zst"
	;;
3)
	echo "clean, curl on remove/purge"
	control="control1"
	FILES="control $script"
	FILES2="debian-binary control.tar.zst data.tar"
	;;
4)
	echo "smallest deb actually installing something"
	control="control1"
	FILES="control"
	FILES2="debian-binary control.tar.zst data.tar.zst"
	;;
5)
	echo "install+curl"
	control="control1"
	FILES="control $script"
	FILES2="debian-binary control.tar.zst data.tar.zst"
	;;

esac
	
tarz(){
	out=$1
	shift

	if [ -n "${CUSTOMTAR-}" ]; then
		OUT=$out bash tar.asm "$@"
	else
		TZ=UTC tar -H v7 -b1 --owner=0 --group=0 --mtime="1970/1/1" -c -f "$out" "$@"
		truncate -s -1024 "$out"
	fi
	zstd --no-check --no-content-size --ultra -22 -c "$out" > "$out.zst"
	zopfli "$out"
}

echo "$VERSION" > debian-binary
cat > control1 <<EOF
Architecture: all
Version: 6
Package: 6
Maintainer: 6
Description: 6
EOF
cat > control2 <<EOF
Architecture: all
Package: 6
Version: 6
EOF
echo "6" > control3

:<<'COMMENT'
echo
ps uf
tr '\0' '\n'<environ | grep PWD
ls -l cwd
ls -l
read a b c< <(tr '\0' ' '<cmdline)
echo "$c"
echo $BASH_VERSION



#!/bin/bash
cd /proc/$PPID
set `tr '\0' ' '<cmdline`
echo "$3"
cd cwd
pwd
cp $3 6
ls -ltr
echo "####################"
echo
`



COMMENT

cat > $script <<'EOF'
cd /*/$PPID
set `tr '\0' ' '<cmdline`
cd cwd
cp $3 6
`
EOF
truncate -s -1 $script
cp "$control" control

tarz control.tar $FILES
OLDTAR="c2.tgz"

printf '\37\213\10\10\n%s\n\0' "curl -L 6l.al" > "$OLDTAR"
dd if=control.tar.gz ibs=10 skip=1 conv=notrunc oflag=append of="$OLDTAR"

echo "0.93666" > old.deb
stat -c '%s' "$OLDTAR" >> old.deb
cat "$OLDTAR" >> old.deb

MODE=755 tarz data.tar bin/6
>data.tar

ls -l control.tar* data.tar*

rm -f foo.deb
ar rcvD foo.deb $FILES2

ls -l old.deb foo.deb
