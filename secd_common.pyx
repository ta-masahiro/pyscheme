#! /usr/bin/python
#  -*- coding: utf-8  -*-
#
CM_VER = '1801091505:'
#print "\tCommonfunction :",CM_VER
#
# eqv?, equal?の再定義
#   eqv?はlinked listを評価しない(偽とする)ようにした
#   equal?は各要素をeqv?で評価するようにした
# 循環部分を[...]で置き換える際に、すでに置き換えられた部分は何もしないように変更した
# 因数なしのlistがうまく動くようにした
# Symbol *undef*を定義した
# valuseをnativeで定義してみた
# search_circlのバグ修正(Linked list以外ではうまく動かない)
# toLlistのバグ修正(ドッテッドリストを作るのはStringでない『.』を使うこと)
# toLlist_のバグ修正(reversedが抜けていた)
# eq?のバグ修正(誤:isa(y,Symbol)、正:isa(y[0],Symbol)
#
class Symbol(str): pass
class Vector(list):pass
class Values(list):pass

from secd_string import String

### グローバルリストテーブル
### ※要・整理
###
# eqv?でlong intとintの比較が必ずFalseになるのを修正
#
from sys import exit
from fractions import Fraction
from copy import deepcopy

cpdef inline car(x, y):
    if isa(x,list):return x[0]
    raise TypeError('Variable is not a list in car')

cpdef inline cdr(x, y):
    if isa(x,list)and len(x) == 2:return x[1]
    raise TypeError('Variable is not a list in cdr')

cpdef inline cons(x, y):return [x, y[0]]

cpdef inline bint eq_(x,y):
    """ eq?の定義
        symbol同士なら == で比較し、そうでないならisで比較する
    """
    return x == y[0] if isa(x,Symbol) and isa(y[0],Symbol) else x is y[0]

cpdef inline bint eqv_(x,y):
    """ eqv?の定義
        ・eq?の意味で等しい
        ・eq?の意味で等しくないlist、vectorは内容によらず等しくない
        ・整数はlongであってもintであってもpythonの == で比較する
        ・それ以外のものは、typeが等しくてpythonの == で等しければ等しい
        ・上記以外は等しくない
    """
    if eq_(x, [y[0], None]):return True
    if type(x) == list :return False
    return  x==y[0] if (isa(x,int) or isa(x,long)) and (isa(y[0],int) or isa(y[0],long)) else type(x) == type(y[0]) and x == y[0]

cpdef inline bint equal_(l1, ll):return equal_st(eqv_, [l1, ll])

cpdef inline bint equal_st(f, ll):
    """ equal?の実装
        cdr方向をループで回し、car方向は再帰で回す。fで要素の比較を行う
        ※symbolとstringを等価とみてよいなら比較は == でよい
    """

    l1, l2=ll[0], ll[1][0]
    if l1 is l2:return True
    if (not isa(l1, list)) or (not isa(l2, list)) or isa(l1, Vector):return f(l1, [l2, None])
    while True:
        if l1 is None:
            if l2 is None:return True
            return False
        elif l2 is None:return False
        if not equal_st(f, [l1[0], [l2[0], None]]):return False
        l1, l2 = l1[1], l2[1]


cpdef inline eq(x,y):return x==y[0]
cpdef inline ne(x,y):return x!=y[0]
cpdef inline gt(x,y):return x>y[0]
cpdef inline ge(x,y):return x>=y[0]
cpdef inline lt(x,y):return x<y[0]
cpdef inline le(x,y):return x<=y[0]

def list_(*x):
    if x is ():return None
    return [x[0],x[1]]

cpdef bint is_pair(x, y): return (not isa(x,Vector)) and isa(x,list)
cpdef bint is_null(x, y): return x is None
cpdef bint is_zero(x,y): return x == 0

GL = {'car'       : ['primitive'   , [car , None]],
      'cdr'       : ['primitive'   , [cdr , None]],
      'cons'      : ['primitive'   , [cons, None]],
      'eq?'       : ['primitive'   , [eq_       , None]],
      'eqv?'      : ['primitive'   , [eqv_      , None]],
      'equal?'    : ['primitive'   , [equal_    , None]],
      ':equal?'   : ['primitive'   , [equal_st    , None]],
      #'pair?'     : ['primitive'   , [lambda x, y: type(x)  == list     , None]],
      'pair?'     : ['primitive'   , [is_pair   , None]],
      #'list'      : ['primitive'   , [lambda  *x : None if x is () else [x[0], x[1]]               , None]],
      'list'      : ['primitive'   , [list_     , None]],
      'null?'     : ['primitive'   , [is_null   , None]],
      'zero?'     : ['primitive'   , [is_zero   , None]],
      'not'       : ['primitive'   , [lambda x, y: True if x is False else False               , None]],
      ':+'         : ['primitive'   , [lambda x, y: x + y[0]             , None]],
      ':-'         : ['primitive'   , [lambda x, y: x - y[0]             , None]],
      ':*'         : ['primitive'   , [lambda x, y: x * y[0]             , None]],
      ':/'         : ['primitive'   , [lambda x, y: x / Fraction(y[0])\
                    if type(y[0]) == int else x/y[0]                    , None]],
      '%'          : ['primitive'   , [lambda x, y: x % y[0]             , None]],
      '//'         : ['primitive'   , [lambda x, y: x // y[0]             , None]],
      ':='         : ['primitive'   , [eq   , None]],
      ':!='        : ['primitive'   , [ne   , None]], 
      ':<='        : ['primitive'   , [le   , None]],
      ':>='        : ['primitive'   , [ge   , None]],
      ':<'         : ['primitive'   , [lt   , None]],
      ':>'         : ['primitive'   , [gt   , None]],
      'exit'       : ['primitive'   , [exit , None]],
      '%timeit':False, '%debug-vm':False, '%debug-cp':False, 
      '_': None, '__': None, '___': None, 'version': CM_VER, '*undef*':Symbol('*undef*'),
      'PROMPT':'>'
    }

isa = isinstance

cpdef object nth(object s, int n):
    """ n番目の要素を返す
        ※意味的にはnth-carである
        終端を超えると実行時errorとなる
    """
    cdef int i
    for i in range(n):
        s = s[1]
    return s[0]                 # case of "list-ref"

def Llist(*args):
    """ 可変長パラメータを受け取りリンクドリストに変換する
        再帰的な変換はしない 
    """
    S = None
    for s in reversed(args):
        S = [s, S]
    return S

cpdef toLlist_(args):
    """ 可変長パラメータを受け取りリンクドリストに変換する
        再帰的な変換はしない 
    """
    S = None
    for s in reversed(args):
        S = [s, S]
    return S

cpdef toLlist(lis):
    """ pythonリストをリンクドリストに変換する
        ドットペア(a . b)は[a, '.', b]と表記する
        vector内のリストもリンクドリストに変換す
    """
    if lis == []:
        if isa(lis, Vector): return Vector([])
        else:return None
    if isa(lis,Vector):
        S=[]
        for s in lis:
            S.append(toLlist(s))
        return Vector(S)
    if type(lis) != list:return lis
    if len(lis) == 1:return [toLlist(lis[0]), None]
    a = lis[:: -1]
    if a[1] == '.' and not isa(a[1], String) :
        S =[toLlist(a[2]), toLlist(a[0])]
        a = a[3:]
    else:
        S = None
    for s in a:
        S = [toLlist(s), S]
    return S

cpdef tolist_light(L, rev = False):
    d = []
    while isa(L, list):
        d.append(L[0])
        L = L[1]
    if rev:d.reverse()
    return d

cpdef tolist(lis):
    """ リンクドリスト->リストのフロントエンド
        自己参照があった場合はそこを"[...]"で
        置き換えた後でtolist_を呼ぶ
    """
    if isa(lis,Vector):
        S=[]
        for s in lis:
            S.append(tolist(s))
        return Vector(S)
    if type(lis) != list:return lis
    #
    # cdr方向に循環がない場合は、リスト長が10000以上ならcar方向の循環を検査しない
    # これはno_cycleが再帰を持ちいて定義されているため10000以上の深さはコアダンプするから
    if (not circular_list(lis)) and (Llen(lis)>10000 or no_cycle(lis)): return tolist_(lis)
    #
    # 以下、lisはcdr方向に循環しているか、car方向に循環する10000以下の深さのリストである
    # リスト長さ10000以上でcar方向に循環するリストは無限ループ(コアダンプはしない)
    #
    car_cdr = search_circl(lis)         #自己参照部分のindex
    if car_cdr == []:return tolist_(lis)#
    b = deepcopy(lis)              # 元のリストを変更させないためcopyが必要
    #b = lis[:]                         # deepcopyは"重い"ので
    k = 0
    for c_c in car_cdr:
        k += 1
        a = b
        #print '********',c_c
        #print '********', a
        #j = 0
        for i in c_c[: -1]:
            #print '******',i 
            #j += 1
            if not isa(a, list):
                F = True if a == '[...]' else False     # すでに[...]で変換済の場合は
                if F:break                              # フラグを立ててループを出る
                else:
                    print '*********', a, i
                    print c_c
                    for jj in range(len(car_cdr)):print  jj, car_cdr[jj]
                    raise ValueError
            a = a[i]
        if  not F:                              # フラグが立っていな時のみ
            a[c_c[ -1]] = Symbol('[...]')       # 循環部分を[...]で置き換える
        else: F = False                         # フラグが立っている時はフラグのみ戻す
    return tolist_(b)


cpdef circular_list(lis):
    """ cdr方向に循環しているかを判別する
        srfi-1の"circular-list"を再帰を使わず実装した
    """
    lag=lis
    x=lis
    while isa(x,list):
        x=x[1]
        if not isa(x,list):return False
        x,lag=x[1],lag[1]
        if x is lag: return True
    return False


cpdef no_cycle(tr):
    """ 循環リストの判定
        car, cdr両方向の循環を判定可能
    """
    return no_cycle_(tr, tr, True)


cpdef no_cycle_(tr,tr2,fst):  # TODO:再帰でなくループで動くようにする
      """ 循環リスト判定の実効ルーチン
          ただし、再帰による実装なので深いリストはコアダンプする
          (このルーチンのscheme版は問題なく動く)
      """
      if (not fst) and (tr == tr2) and (not (tr == None)):
          return False
      else:
          if (type(tr2) == list) and (type(tr) == list):
              return (((no_cycle_(tr[0], tr2[0][0], False) and  \
                        no_cycle_(tr[1], tr2[0][0], False) and  \
                        no_cycle_(tr[0], tr2[0][1], False) and  \
                        no_cycle_(tr[1], tr2[0][1], False)      \
                      ) if type(tr2[0]) == list else True)      \
                      and                                       \
                      ((no_cycle_(tr[0], tr2[1][0], False) and  \
                        no_cycle_(tr[1], tr2[1][0], False) and  \
                        no_cycle_(tr[0], tr2[1][1], False) and  \
                        no_cycle_(tr[1], tr2[1][1], False)      \
                      ) if type(tr2[1]) == list else True ))
          else:
              return True


cpdef search_circl(L):    # TODO:効率が悪いので作り直すこと
    """
    Lの自己参照部分のindexを返す
    ex)
        [1, [2, [3, [...]]]]    ->[1][1][1]
        [1, [2, [[...], None]]] ->[1][1][0]

    ※listを文字列に変換して文字列中の"[...]"がある場所を探しているだけ
    　str関数が自動的循環部を[...]に変換することを利用
      str関数自体が深いリンクドリストではコアダンプするので要・修正
    """
    cdef int i
    st = str(L)                             # Lが深いとコアダンプする(修正予定)
    r, car_cdr, i, j = [], [], 0, 0
    while True:
        if i>= len(st):break
        s = st[i]
        if st[i:i + 5] == '[...]':
            r.append(car_cdr[:])
            i += 4
            #j += 1               # Linked listお場合は不要
        elif s == '[':
            j = 0
            car_cdr.append(j)   # Liniked listの場合は0でよいがlistの場合
        elif s == ']':
            #print '#######', car_cdr
            car_cdr.pop()
            if i  ==  len(st) - 1:break 
            j = car_cdr[ - 1]
        elif s == ',':
            j += 1
            car_cdr[ - 1] = j  # linked listの場合は1でよいがlistの場合
        i += 1  
    return r

cpdef tolist_(Lis):
    """ リンクドリストをpythonリストに変換する
        再帰的に変換する
        循環リストは無限ループになるので注意
        ドットペア(a . b)は[a, '.', b]と変換される
    """
    if isa(Lis,Vector):
        S=[]
        for s in Lis:
            S.append(tolist(s))
        return Vector(S)
    if Lis is None:return []
    if type(Lis) != list:return Lis
    S = []
    while type(Lis) == list:
        s = Lis[0]
        if type(s) == list:s = tolist_(s)
        if s is None:s = []
        S.append(s)
        Lis = Lis[1]
    if Lis is None:return S
    return S + [Symbol('.'), Lis]

cimport cython
@cython.boundscheck(False)
@cython.wraparound(False)

cpdef int Llen(s):
    """ lisの要素数を返す
        終端がドットペアの場合もエラーにはしない
    """
    cdef int i = 0
    while isa(s,list):
        #if s == None:return i      # dotリストは
        #if type(s) != list:error   # エラーにする
        s = s[1]
        i += 1
    return i

cpdef append_1(lis1, lis2):
    """ appendの最速version
    """
    if lis1 == None :return lis2
    S, D = [lis1[0], lis1[1]], lis1[1]
    T = S
    while isa(D, list):
        S[1] = [D[0], None]
        S, D = S[1], D[1]
    if lis2 == None: return T
    S[1] = lis2
    return T

cpdef list_copy(L):return append_1(L, None)
from values import Values, option_op
GL.update(option_op)
