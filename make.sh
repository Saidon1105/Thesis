#!/bin/bash
EXT=("bbl" "aux" "blg" "dvi" "lof" "log" "toc" "lot")
SDIR=$(cd $(dirname $0); pwd)
tmptxt=`mktemp`

# texファイル読み込み
ls $SDIR/*.tex | sed -e "s/^.\///g" > $tmptxt 2>/dev/null
option=() ; while read line; do
  option+=(${line##*/})
done < $tmptxt

# ファイルの削除
function rm_tmp {
  [[ -f "$tmptxt"  ]] && rm -f "$tmptxt"
  for i in `seq $((${#EXT[@]}-1))`; do
    rm -f $SDIR/*.${EXT[$i]}
  done
}
trap rm_tmp EXIT
trap 'trap - EXIT; rm_tmp; exit -1' INT PIPE TERM

# ファイルのコンパイル
function compile() {
  case $j in
    "1" ) platex $SDIR/${1} ;;
    "*" ) platex $SDIR/${1} >/dev/null 2>&1 ;;
  esac
}

# 形式変換(DVI -> PDF)
function dvipdf(){
  dvipdfmx $SDIR/${1}
}

# 選択肢
function select_menu {
  current_line=0 ;
  while clear && main_menu && IFS= read -r -n1 -s SELECTION && [[ -n "$SELECTION" ]]; do
    [[ $SELECTION == $'\x1b' ]] && read -r -n2 -s rest && SELECTION+="$rest" ; clear
    case $SELECTION in
      $'\x1b\x5b\x41' ) [[ $current_line -ne 0 ]]                      && current_line=$(( current_line - 1 )) || current_line=$(( ${#option[@]}-1 )) ;;
      $'\x1b\x5b\x42' ) [[ $current_line -ne $(( ${#option[@]}-1 )) ]] && current_line=$(( current_line + 1 )) || current_line=0                      ;;
      $'\x20'         ) [[ "${choices[current_line]}" == "+"  ]]       && choices[current_line]=""             || choices[current_line]="+"           ;;
    esac
  done
}

# メニュー画面
function main_menu {
  echo "移動:[↑]or[↓], 選択:[SPACE], 決定:[ENTER]"
  for n in ${!option[@]}; do
    [ $n -eq $current_line ] && echo -n ">" || echo -n " "
    echo "[${choices[$n]:- }]: ${option[$n]}"
  done
}

# メインプログラム
# sudo mktexlsr
if [ ${#option[@]} -gt 1 ]; then
  select_menu
fi
for i in `seq 0 1 $((${#option[@]}-1))` ; do
  if [ ${choices[$i]} ] || [ ${#option[@]} -le 1 ] ; then
    for j in `seq 3`; do
      compile ${option[$i]} $j
    done
    dvipdf ${option[$i]%.*}.dvi >/dev/null 2>&1
    open   ${option[$i]%.*}.pdf >/dev/null 2>&1
  fi
done

# 不要なファイルを削除
rm_tmp
