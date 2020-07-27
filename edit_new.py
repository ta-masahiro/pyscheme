#! /usr/bin/python
#  -*- coding: utf-8  -*-
#
import curses
import curses.textpad
import locale
locale.setlocale(locale.LC_ALL, '')
code = locale.getpreferredencoding()

TEXT, TESXT_TOP, YANK_BUF = [], 0, ['']   # テキストバッファ、画面TOPのテキスト行番号、ヤンクバッファ
SIZE_X, SIZE_Y, NUM_AREA = 0, 0, 6      # 画面横サイズ、画面縦サイズ
L_NUM_FLG = True                        # 行番号表示 / 非表示のフラグ
TAB_STOP, FILE_NAME = 2, ''             # TAB幅、編集中のファイルネーム
RES = None                              # スクリプトの実行結果
HELP                     = \
"                                          \n" + \
"  ^A          : ファイル挿入(未実装)      \n" + \
"  ^B          : 画面を半ページ戻す        \n" + \
"  ^D          : 1行削除                   \n" + \
"  ^F          : 画面を半ページ進める      \n" + \
"  ^G          : 対応する括弧にジャンプ    \n" + \
"  ^H          : ヘルプ(このページを表示)  \n" + \
"  ^I or TAB   : TABの数だけ空白を挿入     \n" + \
"  ^J or ENTER : 改行                      \n" + \
"  ^P          : ペースト                  \n" + \
"  ^R          : 読み込み                  \n" + \
"  ^W          : 書き出し                  \n" + \
"  ^X          : 終了して実行              \n" + \
"  ^Y          : コピー                    \n" + \
"  ESC         : 編集を破棄して終了        \n" + \
"                                          \n" + \
"  Press any key and return                \n" + \
"                                          "


def textdisp_pos(line, chr):
    """ 行番号、カラムから画面位置を算出する
    """
    y = line - TEXT_TOP     # 暫定2行にまたがる行については修正が必要
    x = chr + NUM_AREA  # 暫定；多バイト文字は修正必要
    return y, x


def disptext_pos(y, x):
    """ 画面位置から行番号とカラムを算出する
    """
    line = TEXT_TOP + y     # 暫定2行にまたがる行については修正が必要
    chr = x - NUM_AREA      # 暫定；多バイト文字は修正必要
    return line, chr


def l_num_str(n):
    """ 表示する行番号を文字列で返す
    """
    if L_NUM_FLG: return '{:4}: '.format(n)
    else: return ''


def norm_yx(win):
    """ カーソル位置に文字がない場合、直前の文字位置までカーソルを移動する
    """
    cur_y, cur_x = win.getyx()  # 現在のカーソル位置を入手
    cur_line, cur_chr = disptext_pos(cur_y, cur_x)
    if cur_line > len(TEXT) - 1:
        cur_line = len(TEXT) - 1
    if cur_chr > len(TEXT[cur_line]) - 1:
        cur_chr = len(TEXT[cur_line]) - 1
    y, x = textdisp_pos(cur_line, cur_chr)
    win.move(y, x)
    return y, x


def cursor_move_down(win):
    y, x = win.getyx()
    l, c = disptext_pos(y, x)
    if l >= len(TEXT) - 1: return
    if y >= SIZE_Y - 1:                                 # 最下行にいる場合
        #win.addstr(y, SIZE_X - 1, '\n')                 # 改行して上スクロール
        win.scroll()
        display_line(win, SIZE_Y - 1, 1, TEXT_TOP + 1)  # 最終行を再描画
        win.move(y, x)                                  # カーソルを戻す
    else: win.move(y + 1, x)


def cursor_move_up(win):
    y, x = win.getyx()
    if y <= 0:                                          # 最上部にいる場合
        l, c = disptext_pos(y, x)
        if l <=  0: return
        win.insertln()                                  # 画面の次の行に1行インサート
        display_line(win, 0, 2, TEXT_TOP - 1)           # 上の2行を再描画
        win.move(y, x)                                  # カーソルを戻す
    else: win.move(y - 1, x)


def cursor_move_left(win):
    y, x = norm_yx(win)
    l, c = disptext_pos(y, x)
    if l == 0 and c == 0: return                        # 最先端より前には行けない
    if x <= NUM_AREA:                                   # 最左端にいるときは
        win.move(y, len(TEXT[l - 1]) + NUM_AREA - 1)    # 最右端に移動して
        cursor_move_up(win)                             # カーソルup
    else: win.move(y, x - 1)


def cursor_move_right(win):
    y, x = norm_yx(win)
    l, c = disptext_pos(y, x)
    if l == len(TEXT) - 1 and c == len(TEXT[l]) - 1:return  # 最後端より後ろにはいかない
    if x >= len(TEXT[l]) + NUM_AREA - 1:                # 最右端にいるときは
        win.move(y, NUM_AREA)                           # 最左端に移動して
        cursor_move_down(win)                           # カーソルdown(次の行の行頭に行く)
    else: win.move(y, x + 1)


def delete_line(win):
    """ カーソル行を1行削除する
    """
    y, x = win.getyx()                                  # カーソル位置を保存
    win.deleteln()                                      # カーソル行を消して1行上スクロール
    display_line(win, SIZE_Y - 1, 1)                    # 空白になった最下行を表示
    win.move(y, x)                                      # 最下行に行ったカーソルを戻す
    l, c = disptext_pos(y, x)                           # 該当する行を求めて
    YANK_BUF[0] = TEXT[l]                               # yankバッファにいれて
    del TEXT[l]                                         # 実テキストを削除


def delete_ch(win):
    """ カーソル位置から1文字削除する
    """
    y, x = norm_yx(win)                                 # カーソル位置を正規化して
    l, c = disptext_pos(y, x)                           # 行とカラムに変換して
    if x == len(TEXT[l]) + NUM_AREA - 1:                # 左端にいる場合は
        TEXT[l] = TEXT[l][:-1] + TEXT[l + 1]            # 次の行をその行に連結して
        del TEXT[l + 1]                                 # 次の行を消す
        display_line(win, y, -1)                        # その行から画面全部を再描画
    else:                                               # 左端にいないなら
        win.delch(y, x)                                 # カーソルの文字を消して
        TEXT[l] = TEXT[l][:c] + TEXT[l][c + 1:]         # 該当行の該当文字を消す


def insert_line(win, str):
    """ カーソル下に空行を追加し、そこに文字列strを挿入する
    """
    y, x = win.getyx()                                  # カーソル位置を保存
    if y <  SIZE_Y - 1:                                 # カーソルが最下行でない場合
        win.insertln()                                  # カーソル行の下に1行インサートしてスクロール
        TEXT.insert(disptext_pos(y, x)[0] + 1, str)     # textに文字を挿入
        display_line(win, y, 2)                         # 挿入行を表示
        win.move(y + 1, NUM_AREA)                       # 行の先頭にカーソル移動
    else:                                               # カーソルが最下行だったら
        win.addstr(y, SIZE_X - 1, '\n')                 # 改行して上スクロール
        #win.scroll()
        TEXT.insert(disptext_pos(y, x)[0] + 1, str)
        display_line(win, SIZE_Y - 1, 1, TEXT_TOP - 1)  # 挿入行を表示
        win.move(SIZE_Y - 1, NUM_AREA)
    indent(win)                                         # オートインデント     

def insert_str(win, str):
    """ カーソル位置にstrを挿入する
    """
    y, x = norm_yx(win)                                 # カーソル位置を正規化
    for ch in str:                                      # 1文字ごとに
        l, c = disptext_pos(y, x)                       # 行とカラムを求めて
        win.insch(y, x, ch)                             # 画面に文字を挿入
        TEXT[l] = ch.join([TEXT[l][:c], TEXT[l][c:]])
        x += 1                                          # 次の文字に
        win.move(y, x)                                  # カーソルを移す


def display_line(win, start, n, t = None):
    """　TEXTのt行を画面の先頭としてstart行からn行まで再描画する
    """
    global TEXT_TOP, SIZE_X, SIZE_Y
    y, x = win.getyx()                                  # カーソル位置を保存しておいて
    if n < 0: n = SIZE_Y                                # 行数に負値を設定したら最大値とみなす
    if t is None: t = TEXT_TOP                          # tを設定時はTEXT_TOPを変更しない
    elif t < 0: t = 0 
    TEXT_TOP = t
    if TEXT_TOP >  len(TEXT) - 1:TEXT_TOP = len(TEXT) - 1   # 暫定
    l = t + start                                       # lは表示するTEXTの行位置
    for i in range(start, start + n):                   # 画面上startからn行について
        if l > len(TEXT) - 1:text = '~' + ' ' * (SIZE_X - NUM_AREA - 2) # テキストサイズを超えたら'~'表示
        elif i == SIZE_Y - 1: text = TEXT[l][: -1]      # 画面最下端表示時は改行コードを除く
        else: text = TEXT[l]

        # win.addstr(i, 0, l_num_str(t) + text)
        #if i == y: win.addstr(i, 0, l_num_str(t))
        #win.addstr(i, 0, l_num_str(t), curses.A_BLINK)
        win.addstr(i, NUM_AREA, text)                   # 行番号とTEXTを出力
        if i == SIZE_Y - 1: break                       # 画面最下端まで行ったら終了
        l += 1
    win.move(y, x)                                      # カーソルを戻す


def br_search(l, c, br_nest, direct):
    """ TEXT[l][c]から現在と同じレベルの深さの括弧終端を探す
        nestは現在の深さ、directは探索方向で1は終端方向に閉じ括弧を
        -1は先頭方向に開き括弧を探す
    """
    c += direct
    while True:
        if 0 > c :
            c = - 1 
            l +=  - 1
        if 0 > l :return False
        if c < 0: c = len(TEXT[l]) - 1
        if TEXT[l][c] in (')', ']'):br_nest += 1
        if TEXT[l][c] in ('(', '['):
            br_nest -= 1
            if br_nest == 0: return l, c
        c -= 1
    return False

def br_bright(win, l, c):
    """ TEXT[l][c]位置に括弧があれば対になる括弧を目立たせる
        対になる括弧位置の画面位置を返す
    """
    old_y, old_x = norm_yx(win)
    new_l, new_c = disptext_pos(old_y, old_x)
    if new_c != c: return False     # カーソル位置にはデータがない
    if TEXT[l][c] in ('(', '['):    # 開き括弧の場合
        c_up, new_c = 1, 0
    elif TEXT[l][c] in (')', ']') :  # 閉じ括弧の場合
        c_up, new_c = -1, -1
    elif c != 0 and  TEXT[l][c - 1] in (')', ']'):
        c_up, new_c =  -1, -1
        c -= 1
    else: return False
    #
    br_nest = 1     # 一つ目の括弧
    c += c_up       # カーソルを次の文字まで進めておく
    while 0 <= textdisp_pos(l, c)[0] < SIZE_Y:
        if 0 > l or l >= len(TEXT): return False
        while 0 <=  c < len(TEXT[l]):
            y, x = textdisp_pos(l, c)
            if TEXT[l][c] in ('(', '['): br_nest += c_up 
            elif TEXT[l][c] in (')', ']'): br_nest -= c_up
            if br_nest == 0:
                win.chgat(y, x, 1, curses.A_BLINK)
                return y, x
            c += c_up
        c = new_c   # 次の行の先頭 / または前の行の終端
        l += c_up   # (今は一を決め打ちしているが行番号表示
                    #　非表示で変えられるように！)
        if c < 0: c = len(TEXT[l]) - 1
    #win.move(old_x, old_y)
    return False


def indent(win):
    """ オートインデント
        通常は開業時に呼ばれるが途中であっても機能する
        場合によってはバックスペースするので先頭の空白文字位置
        以外では使用しないのが望ましい
        (とりあえずscheme用である)
    """
    y, x = norm_yx(win)                         # 画面位置を正規化して
    l, c = disptext_pos(y, x)                   # テキスト位置を算出し
    res = br_search(l, c, 0,  - 1)              # 手前にある同一レベルの開き括弧を探す
    #win.addstr(0, 90, str(res))
    #win.move(y, x)
    if res:                                     # 括弧があれば
        c_y, c_x = textdisp_pos(res[0], res[1]) # その位置を画面位置に直して
        indent = c_x - x                        # 現在のx位置との差分をindent量とし
        if x >= 0 :                             # 値が正なら
            insert_str(win, ' ' * indent)            # その数だけスペースを挿入
        else :
            for i in range(indent): delete_ch(win) # 


def edit_main(win):
    global TRXT, YANK_BUF, SIZE_X, SIZE_Y
    win.clear()                         # 画面消去して
    win.scrollok(True)                  # スクロールOKに設定
    SIZE_Y, SIZE_X = win.getmaxyx()     # size_yは画面縦行数、size_xは横列数

    #SIZE_Y -= 1
    #win.addstr(SIZE_Y - 1, 0, ' ' * (SIZE_X - 1), curses.A_BLINK)
    display_line(win, 0, SIZE_Y, 0)     # 画面上端(0)から最大行をTop_Text_Line = 0で描画
    win.move(0, NUM_AREA)               # カーソルは最上端、最左端に

    while True:
        y, x = win.getyx()              # カーソル位置を入手
        l, c = disptext_pos(y, x)       # カーソル位置に相当するbuffer位置の入手
        res = br_bright(win, l, c)      # 対応する括弧があれば強調表示
        for i in range(SIZE_Y):
            win.addstr(i, 0, l_num_str(TEXT_TOP + i), curses.A_BLINK)
        win.addstr(y, 0, l_num_str(TEXT_TOP + y))
        #win.addstr(SIZE_Y - 1, 0, ' ' * (SIZE_X - 11) +  '({:4}:{:3})'.format(l, c), curses.A_BLINK)
        win.move(y, x)                  # カーソルを戻す
        c = win.getch()                 # キー入力待ち
        if res: win.chgat(res[0], res[1], 1, curses.A_NORMAL)   # 括弧協調を中止
        win.move(y, x)
        # 以下、キー値に従う動作をする
        if c == 2: display_line(win, 0, SIZE_Y, TEXT_TOP - SIZE_Y // 2)     # ^B:半ページ戻る
        elif c == 4: delete_line(win)                                       # ^F 1行delete
        elif c == 6:                                                        # ^F 半ページ進む
            if l <= len(TEXT):
                display_line(win, 0, SIZE_Y, TEXT_TOP + SIZE_Y // 2)
        elif c == 7:                    # ^G 対応する括弧があればそこにカーソルを移動する
            #res = br_bright(win, l, c)
            if res: win.move(res[0], res[1])
        elif c == 263:                    # ^H ヘルプ
            win.addstr(0, 0, HELP)
            curses.textpad.rectangle(win, 0, 0, 17, 42)
            win.refresh()
            win.move(16, 26)
            cc = win.getch()
            display_line(win, 0, 18)
            win.move(y, x)
        elif c == 9: insert_str(win, ' ' * TAB_STOP)   # TAB or ^I
        elif c == 10:                   # ENTER or ^J or ^M  カーソル位置で改行する
            l_pos, c_pos = disptext_pos(y, x)   # カーソル位置の行とカラムを求めて
            l_text, r_text = TEXT[l_pos][:c_pos] + '\n', TEXT[l_pos][c_pos:]
            TEXT[l_pos] = l_text
            # TEXT.insert(l_pos+1,r_text)
            display_line(win, y, 1)     # 現在行を表示して
            insert_line(win, r_text)    #
        #elif c == 13: continue          # ^M カーソル下の行にマージ
        elif c == 16:                   # ^P 行ペースト
            win.move(y, NUM_AREA)       # カーソルを先頭行に移して
            for buf in YANK_BUF:        # YANK_BUFにありったけを
                insert_line(win, buf)   # 行挿入する
        #elif c == 17:                   # ^Q 終了
        #    option_op[':TEXT'] = TEXT   # 編集内容は:TEXTで参照可能にしておく
        #    return
        elif c == 18: continue          # ^R 読み込み
        elif c == 19: continue          # ^S 検索、置換
        elif c == 22: continue          # ^V 選択モード
        elif c == 23:                   # ^W 書き込み
            if FILE_NAME == '': file_name = 'unknown.scm'
            else: file_name = FILE_NAME
            f = open(file_name, 'w')
            for text in TEXT:
                f.write(text)
            f.close()
        elif c == 24:                   # ^X 終了して編集したファイルを実行
            # for text in TEXT:
            #    RES = eval(read(TEXT))  # 実行結果はRESに保存
            #    break                   #
            return TEXT
        elif c == 25: YANK_BUF = [TEXT[disptext_pos(y, x)[0]]]  # ^Y yank(1行コピー)
        elif c <= 26: continue          # ^Z
        elif c == 27: return            # ESC 何もせずに終了
        elif c == 127:  # BS
            cursor_move_left(win)
            delete_ch(win)
        elif c == curses.KEY_DOWN: cursor_move_down(win)    # code:258
        elif c == curses.KEY_UP: cursor_move_up(win)        # code:259
        elif c == curses.KEY_LEFT: cursor_move_left(win)    # code 260
        elif c == curses.KEY_RIGHT: cursor_move_right(win)  # code:261
        elif c == curses.KEY_HOME:                          # code:262
            win.move(0, NUM_AREA)
            display_line(win, 0, SIZE_Y, 0)
        elif c == curses.KEY_DC: delete_ch(win)             # code:330 DELETE Key
        elif c == 331: display_line(win, 0, SIZE_Y, len(TEXT) - SIZE_Y)     # END Key
        elif c == 338: continue         # PgDn
        elif c == 339: continue         # PgUp
        elif c >= 256: continue         # ※多バイト文字への対応必要
        else:
            insert_str(win, chr(c))     # 単純に文字を挿入する
    pass


def read_file(file_name):
    
    try:
        f = open(file_name, 'r')
    except:
        print "file not exist!"
        return False
    else:                           # そうでない場合はTEXTに読み込む
        text = []
        while True:
            s = f.readline()
            s = s.replace('\t', ' ' * TAB_STOP)     # 暫定; タブはspaceに強制変換
            if s == '':break
            text.append(s)
        f.close()
        return text


def edit(file_name=''):
    global FILE_NAME, TEXT
    print file_name
    if file_name == '':
        TEXT = option_op[':TEXT']       # ファイル名を指定しない場合は以前の継続
    else:
        FILE_NAME=file_name
        t = read_file(file_name)
        if t:
            TEXT = t
        else:
            TEXT=["\n"]

    curses.wrapper(edit_main)
    return TEXT


from secd_common import Vector

option_op = {
            ':edit': ['primitive', [lambda x = None, y = None: Vector(edit()) if x is None else Vector(edit(x.tostring())), None]],
            ':TEXT': ['\n'],
            }
