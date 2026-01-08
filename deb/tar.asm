%if 0
set -ue
: "${OUT:=control.tar}"
rm -f "$OUT"
touch $OUT
for FILE
do
	printf -v SIZE "%o" "$(stat -c '%s' "$FILE")"
	nasm "$0" -o tmp -DFILE="$FILE" -DSIZE="$SIZE" -DMODE="${MODE-0}"
	./tarify -b tmp
	cat "$FILE" >> tmp
	truncate -s '%512' tmp
	cat tmp >> $OUT
done

tar tvf $OUT
exit

%endif

%macro setpos 1
 times $$-$+%1 db 0
%endmacro

setpos 0	; name
db %str(FILE)

setpos 100	; mode
%if MODE
	db %str(MODE)
%else
	db 0
%endif

setpos 108	; uid
db 0

setpos 116	; gid
db 0

setpos 124	; size
db %str(SIZE)

setpos 136	; mtime
db 0

setpos 148	; cksum
db 0

setpos 156	; typeflag
db 0

setpos 512


