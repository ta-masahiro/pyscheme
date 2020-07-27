#! /usr/bin/python
#  -*- coding: utf-8  -*-
#
BASICFUNCTION_VER = '1801271336:VM Linked-list'
#print "\tBasic Function :",BASICFUNCTION_VER
#
# vector=対応
# partition!のバグ修正
# map!、any、everyにfast passを用意
# pair-for-each、filter-map対応
# 比較関数のtolist_をtolist_lightに変更(特に = でlistの比較ができない)
# string / vector関数の微調整
# string-replace
# someとeveryは評価値を返すように変更(True/Falseのみを返していた)
# python formatを暫定導入(srfi-48より表現力高い)
# appendにNULLリストを与えた場合でも正常に動くようにした
# write-charのバグ修正　str()でなく.tostring()してからwriteすること
# peek-chr / input-file? / output-file? に対応した
# fappend-nにヌルリストが渡ってもうまく動くようにした
# get-closue-bodyをdレジスタを参照できるように変更(call/cc対応)
# values,call-with-valuesにprimitive対応してみた->NG
#
from secd_common import GL, tolist_, tolist, tolist_light, toLlist, toLlist_, eq_, eqv_, equal_st,  \
        Symbol, Vector ,String, Values, nth, Llen, list_copy, circular_list, no_cycle, Llist
from secd_read import to_string,read
from secd_vm import vm,local_vm
from secd_cp import compile, STOP
isa=isinstance
UNDEF = Symbol('*undef*')

cdef inline str_base(num, int base):
    """ 数値->文字列のための補助ルーチン
        基数baseの下で数値を文字列に変換する
    """
    if base == 2:return (bin(num))[2:]
    elif base == 8:return (oct(num))[1:]
    elif base == 10:return str(num)
    elif base == 16:return (hex(num))[2:]
    else :  # 実用的には上記のみで十分、コード的には下記のみで事足りる
        def int2str(i, int base):
            int2str_table = '0123456789abcdefghijklmnopqrstuvwxyz'
            if not 2 <= base <= 36:
                raise ValueError('base must be 2 <= base < 36')
            result = []
            temp = abs(i)
            if temp == 0:
                result.append('0')
            else:
                while temp > 0:
                    result.append(int2str_table[temp % base])
                    temp /= base
            if i < 0:
                result.append('-')

            return ''.join(reversed(result))
        return int2str(num, base)


cdef inline s_EQ(x,y):
    for z in y:
        if x != z:return False
        #x=z    # 多引数 = の比較順序が規定されないならこの行は不要
    return True


cdef inline s_GT(x,y):
    for z in y:
        if not x<z:return False
        x=z
    return True


cdef inline s_GE(x,y):
    for z in y:
        if not x<=z:return False
        x=z
    return True


cdef inline s_LT(x,y):
    for z in y:
        if not x>z:return False
        x=z
    return True


cdef inline s_LE(x,y):
    for z in y:
        if not x>=z:return False
        x=z
    return True

#cdef s_comp(x,y,cmp):
#    for z in y:
#        if not cmp(x,z):return False
#    return True

cdef inline tolist_n(L, int s = 0, int e = 100000000, bint rev = False):
    """ Linked list Lをsからeまでpython listに変換する
        rev==Trueであれば結果を反転して返す
    """
    d = []
    cdef count = 0
    while isa(L, list):
        if count >= e: break
        if count >= s:  
            d.append(L[0])
        L = L[1]
        count += 1
    if rev:d.reverse()
    return d

cdef inline split_(lis, int n):
    """ lisをn番目で分割し、先頭をcar部に残りをcdr部に入れた新しいlistで返す
    """
    cdef int i
    s = lis
    t = [None, None]
    w = t
    for i in range(n):
        t[1] = [s[0], None]
        s, t = s[1], t[1]
    return [w[1], s]


cdef inline nth_cdr(lis, int n):
    """ nth_cdr = list-ref = drop
    """
    return split_(lis, n)[1]


cdef but_nth_cdr(lis, int n):
    """ but_nth_cdr  =  take
    """
    return split_(lis, n)[0]


cdef inline fsplit(lis, int n):
    """ splitと同じだが 
    """
    cdef int i
    s = lis
    for i in range(n-1):
        s = s[1]
    _cdr_ = s[1]
    s[1] = None
    return [lis, _cdr_]


cdef fnth_cdr(lis, int n):
    return fsplit(lis, n)[1]


cdef fbut_nth_cdr(lis, int n):
    return fsplit(lis, n)[0]


cdef inline set_car(Llis, val):
    """ set-car!に対応 
    """
    Llis[0] = val
    return UNDEF 


cdef inline set_cdr(Llis, val):
    """ set-cdr!に対応 
    """
    Llis[1] = val
    return UNDEF 


def last_pair(L):
    if type(L) != list:return L
    while True:
        if type(L[1]) != list: return L # miss!
        L = L[1]                        #
        #if type(L[1]) != list: return L#
    pass


cdef last(L):
    """ car(last-pair(L))
    """
    if type(L) != list:return L
    while True:
        L = L[1]
        if type(L[1]) != list: return L[0]
    pass


cdef inline append_1(lis1, lis2):
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


cdef append_n(list1, lists):
    """ 再帰で回しているのでappendするlistが多いと(10000以上)コアダンプする 
    """
    if lists is None: return list1
    if list1 is None:return append_n(lists[0], lists[1])
    return append_1(list1, append_n(lists[0], lists[1]))


cdef inline fappend_1(lis1, lis2):
    """ 引数が2個のappend!に対応
    """
    last_pair(lis1)[1] = lis2
    return lis1


cdef fappend_n(lis1, lists):
    """ append!に対応 
    """
    if lis1 is None:
        if lists is None: return None
        else:return fappend_n(lists[0],lists[1])

    L=lis1
    while isa(lists,list):
        lis2=lists[0]
        #set_cdr(last_pair(lis1), lis2)
        last_pair(lis1)[1]=lis2
        lis1=lis2
        lists=lists[1]
    return L 


cdef inline reverse_(lis):
    """ schemeで実装するより15倍ほど早い 
    """
    S = None
    while isa(lis,list):
        S,lis = [lis[0],S], lis[1]
    return S


cdef inline reverse_n(lis, int n):
    """ n個のみreverseする 
    """
    S, i = None, 0
    while isa(lis,list):
        if i >= n: break
        S,lis = [lis[0],S], lis[1]
        i += 1
    return S


# revese!の再帰版
# srfi-1の参考実装をそのままpythonに移植
# ※pythonは再帰回数に制限があるので長いリストはcore dumpする
#cdef freverse_test(ls, ans):
#    if ls is None:return ans
#    tail = ls[1]
#    ls[1] = ans
#    return freverse_test(tail, ls)


cdef freverse_(ls):
    """ reverse!の実装(非再帰版)
        ptrの入れ替えのみなので高速、さらにメモリも食わない
        元のlistは、先頭pairを残して逆転したリストに使われる
    """
    S = None        # Sに逆転したリストを格納する
    while isa(ls,list):
        T = ls[1]     # lsの2次以降をTに一時保存 
        ls[1] = S     # そこに(旧)逆転したリストを連結(ls[0]を逆転リストに追加)
        S = ls        # それを(新)逆転リストとする
        ls = T        # しまっておいたlsを戻す
    return S


cdef freverse_n(ls, int n):
    """ n個のみreverse!する 
    """
    S, i = None, 0          # Sに逆転したリストを格納する
    while isa(ls,list):
        if i >= n:break
        T=ls[1]     # lsの2番目以降をTにしまっておき 
        ls[1]=S     # lsの先頭pairに(旧)逆転したリストを連結し
        S=ls        # それを(新)逆転リストとする
        ls=T        # しまっておいたlsを戻す
        i += 1
    return S


cdef reverse_append_1(lis,lis2):
    S = lis2
    while isa(lis,list):
        S = [lis[0],S]
        lis = lis[1]
    return S


cdef freverse_append_1(lis,lis2):
    d=reverse_append_1(lis,lis2)
    lis[0],lis[1]=d[0],d[1]
    return lis


cdef reverse_append_n(list1, lists):
    """ 
       再帰で回しているのでappendするlistが多いとコアダンプする :
    """
    if lists is None: return reverse_(list1)
    def _reverse_append_n(LS):
        if LS[1] is None:return LS[0]
        if LS[1][1] is None:return reverse_append_1(LS[0], LS[1][0])
        return reverse_append_1(LS[0], _reverse_append_n(LS[1]))
    return reverse_append_1(list1, _reverse_append_n(lists ))


cdef inline range_(int start, int stop, int step = 1):
    cdef int i
    S = [start, None]
    T = S
    for i in range(start + step, stop, step):
        S[1] = [i, None]
        S = S[1]
    return T

    
cdef list_tabulate(int n, proc):
    """ for srfi-1:list-tabulate """
    cdef int i
    S = [None, None]
    T = S
    for i in range(n):
        S[1] = [proc(i, None), None]
        S = S[1]
    return T[1]

cdef inline map_car(ls):
    if not isa(ls,list): return None
    S = [ls[0][0], None]
    T, l = S, ls[1]
    while isa(l, list):
        S[1] = [l[0][0], None]
        S , l = S[1], l[1]
    return T


cdef inline map_cdr(ls):
    if not isa(ls,list):return None
    S = [ls[0][1], None]
    T, l = S, ls[1]
    while isa(l, list):
        S[1] = [l[0][1], None]
        S, l = S[1], l[1]
    return T


cdef inline map_cadr(ls):
    if not isa(ls,list):return None
    S = [ls[0][1], None]
    T, l = S, ls[1]
    while isa(l, list):
        S[1] = [l[0][1][0], None]
        S, l = S[1], l[1]
    return T


cdef inline map_reverse(l):
    if not isa(l,list):return l
    S = [None,None]
    T = S
    while isa(l,list):
        S[1] = [reverse_(l[0]),None]
        S, l = S[1], l[1]
    return T[1]


cdef inline map_cons(ls1, ls2):
    """ (map cons ls1 ls2) と同じ動作 """
    if not(isa(ls1,list) and isa(ls2,list)): return None
    S = [[ls1[0], ls2[0]], None]
    T = S
    ls1, ls2 = ls1[1], ls2[1]
    while isa(ls1,list) or isa(ls2,list):
        S[1] = [[ls1[0], ls2[0]], None]
        S, ls1, ls2 = S[1], ls1[1], ls2[1]
    return T

cdef map_1(f,ls):
    if not isa(ls, list):return None
    S=[f(ls[0],None),None]
    T=S
    ls=ls[1]
    while isa(ls,list):
        S[1]=[f(ls[0],None),None]
        S, ls=S[1],ls[1]
    return T

cdef map_2(f, ls1, ls2):
    if not(isa(ls1,list) and isa(ls2,list)): return None
    S = [f(ls1[0], [ls2[0],None]), None]
    T = S
    ls1, ls2 = ls1[1], ls2[1]
    while isa(ls1,list) and isa(ls2,list):
        S[1] = [f(ls1[0], [ls2[0],None]), None]
        S, ls1, ls2 = S[1], ls1[1], ls2[1]
    return T

cdef map_(f,lists):
    #if memq_(None,lists): return None
    #S=[f(*map_car(lists)), None]
    S = [None, None]
    T = S
    #lists = map_cdr(lists)
    while not memq_(None,lists) :
        S[1]=[f(*map_car(lists)), None]
        S, lists = S[1], map_cdr(lists)
    #return T
    return T[1]


cdef inline fmap_1(f,ls):
    S = ls
    while isa(ls,list):
        ls[0]=f(ls[0],None)
        ls = ls[1]
    return S


cdef inline fmap_2(f, ls1, ls2):
    S = ls1
    while isa(ls1,list) and isa(ls2,list):
        ls1[0] = f(ls1[0], [ls2[0],None])
        ls1, ls2 = ls1[1], ls2[1]
    return S


cdef fmap_(f,lists):
    cdef int n = Llen(lists)
    if n == 0: return None
    if n == 1: return fmap_1(f,lists[0])
    if n == 2: return fmap_2(f,lists[0],lists[1][0])
    #
    T = lists[0]
    while not lists[0] is None :
        lists[0][0]=f(*map_car(lists))
        lists = map_cdr(lists)
    return T

cdef inline filter_map_1(f, ls):
    S = [None, None]
    T = S
    while isa(ls, list) :
        r = f(ls[0], None)
        if r is not False:
            S[1] = [r, None]
            S = S[1]
        ls = ls[1]
    return T[1]


cdef inline filter_map_2(f, ls1, ls2):
    S = [None, None]
    T = S
    while isa(ls1, list) and isa(ls2, list) :
        r = f(ls1[0], [ls2[0], None])
        if r is not False:
            S[1] = [r, None]
            S = S[1]
        ls1, ls2 = ls1[1], ls2[1]
    return T[1]


cdef filter_map(f,lists):
    cdef int n = Llen(lists)
    if n == 0: return None
    if n == 1: return filter_map_1(f, lists[0])
    if n == 2: return filter_map_2(f, lists[0], lists[1][0])
    #
    S = [None, None]
    T = S
    while not memq_(None,lists) :
        r = f(*map_car(lists))
        if r is not False:
            S[1] = [r, None]
            S = S[1]
        lists = map_cdr(lists)
    return T[1]


cdef for_each(f,lists):
    while not memq_(None,lists):
        f(*map_car(lists))
        lists=map_cdr(lists)
    return UNDEF 


cdef pair_for_each(f,lists):
    while not memq_(None,lists):
        f(*lists)
        lists=map_cdr(lists)
    return UNDEF


cpdef get_primitive_body(clos):
    """ closがprimitive functionならその値(python関数本体)を返す
        そうでなければ#fを返す
    """
    if isa(clos, list) and clos[0]=='primitive':return clos[1][0]
    return False


#def get_closue_body(clos):
#    if clos[0]=='closue':
#        c, parm = clos[1][0], clos[1][1][0]
#        return lambda x,y:vm(None, [[x, y], parm] ,c, [[None, [None, [[STOP, None], None]]], None])
#    return False


def get_closue_body(clos):
    if isa(clos, list) and clos[0]=='closue':
        code, parm = clos[1][0], clos[1][1][0]
        #return lambda x,y:vm(None, [[x, y], parm] ,c, [[None, [None, [[STOP, None], None]]], None])
        return local_vm(code,parm) # dレジスタを参照できるようにsecd_vmで関数を定義する
    return False


cdef memq_(x, ls):
    if isa(x,Symbol):return memv_(x,ls)
    while isa(ls,list):
        if x is ls[0]:return ls     # eq?の定義はIDが等しいこと
        #if x is ls[0] or (isa(x,Symbol) and isa(ls[0],Symbol) and x==ls[0]):return ls   # Symbolの場合は値が等しいこと
        ls=ls[1]
    return False


cdef memv_(x,ls):
    while isa(ls,list):
        #if x == ls[0]:return ls
        #if type(x) == type(ls[0]) and x == ls[0]:return ls  # eqv?の定義には両方のtypeが等しいこと
        #if x==ls[0] and isa(x, (int,long)) and isa(ls[0], (int,long)) :return ls    # intとlongは同じとみなす
        #if eqv_(x, [ls[0], None]):return ls    #eqv?を呼ぶとoverheadあり
        if x == ls[0] and (type(x) is type(ls[0]) or (isa(x,(int,long)) and isa(ls[0], (int, long)))):return ls
        ls=ls[1]
    return False


cdef member_(x, ls):
    while isa(ls,list):
        if x == ls[0] :return ls    # memberは = で比較することにした
        ls=ls[1]
    return False


cdef member(x, ls, pred):
    while isa(ls, list):
        if pred(x,[ls[0],None]):return ls
        ls = ls [1]
    return False


cdef memp(pred,ls):
    while isa(ls,list):
        if pred(ls[0],None) != False:return ls
        ls=ls[1]
    return False


cdef member_st(x,ls):
    """ memberのcar方向に再帰するVersion
        比較は=決め打ち
    """
    while isa(ls,list):
        if isa(ls[0],list):
            r=member_st(x,ls[0])
            if r is not False: return r
        elif x == ls[0]: return ls
        ls=ls[1]
    return False


#cdef list_position(x,ls): # => list-indexに統合
#    cdef int count=0
#    while isa(ls,list):
#        if x==ls[0]:return count
#        ls = ls[1]
#        count += 1
#    return False


#cdef filter_(fn, ls):  # => partitionのcarを返す
#    if not isa(ls,list):return ls
#    S = [None, None]
#    T = S
#    while isa(ls,list):
#        if not fn(ls[0],None) == False:
#            S[1] = [ls[0], None]
#            S=S[1]
#        ls = ls[1]
#    return T[1]


cdef some_(pred, lists): 
    """ srfi-1:any
        r6rs:exists
    """
    cdef n = Llen(lists)
    p = False
    if n == 0: return False
    if n == 1:
        ls = lists[0]
        while isa(ls, list):
            p = pred(ls[0], None)
            if p is not False: return p
            ls = ls[1]
        return False
    while not memq_(None, lists):
        #if pred(lists[0][0], map_car(lists[1])):return True
        p = pred(lists[0][0], map_car(lists[1]))
        if p is not False: return p
        lists = map_cdr(lists)
    return False 


cdef every_(pred, lists):
    """ srfi-1:every
        r6rs:for-all
    """
    cdef n = Llen(lists) 
    p = True
    if n == 0: return True
    if n == 1:
        ls = lists[0]
        while isa(ls, list):
            p = pred(ls[0], None)
            if p is False:return False
            ls = ls[1]
        return p
    #
    while not memq_(None, lists):
        p = pred(lists[0][0], map_car(lists[1]))
        if p is False: return False
        lists = map_cdr(lists)
    return p


cdef find_(f, ls):
    """ srfi-1:find
        lsの要素のうち、述語fを満たす最初の要素を返す。
        満たす要素がなければ偽を返す。
    """
    while isa(ls, list):
        if f(ls[0], None): return ls[0]
        ls = ls[1]
    return False 


cdef find_tail(f, ls):
    while isa(ls, list):
        if f(ls[0], None): return ls
        ls = ls[1]
    return False


cdef list_index(pred, lists):
    """ srfi-1:list-index
        pred を満たす最左の要素のインデックスを返す。
    """
    cdef int c = 0
    if Llen(lists) == 1:
        # simple case
        ls = lists[0]
        while isa(ls,list):
            if pred(ls[0], None):return c
            c += 1
            ls = ls[1]
        return False
    # 
    while not memq_(None, lists):
        if pred(*map_car(lists)) is not False:return c
        c += 1
        lists = map_cdr(lists)
    return False

cdef bint list_eq_2(pred, l1, l2):
    """ 2要素のlist=の実装
        predは任意の2引数関数でよい
        predにかかわらずl1とl2が同値ならTrueを返す
        cdr方向をループで回し、car方向は再帰しない
        ※car方向の再帰が必要ならpredにequal?を用いる
        ※ただしequal?はeqv?での再帰なので注意
    """
    #if (not isa(l1, list)) or (not isa(l2, list)):return pred(l1, [l2, None])  # 再帰する場合必要
    if l1 is l2: return True
    while True:
        if l1 is None:
            if l2 is None:return True
            return False
        elif l2 is None:return False
        #elif not list_eq_2(pred, l1[0], l2[0]): return False   #再帰する場合(srfi-1では要求されない)
        elif not pred(l1[0], [l2[0], None]): return False       #再帰しない場合
        l1, l2 = l1[1], l2[1]


cdef bint list_eq_n(pred ,lists):
    """ 多因数のlist=
        因数分のlist=2を呼び出して結果をandしている
    """
    cdef bint T = True
    if not isa(lists, list): return True
    while isa(lists[1],list):
        T = T and list_eq_2(pred,lists[0],lists[1][0])      #list_eq_2は再帰しない
        #T = T and equal_st(pred,[lists[0],lists[1]])       #equal_stは再帰で比較する
        if not T:return False
        lists=lists[1]
    return True


cdef partition_(fn, ls):
    """ ls の要素を述語 fn で分割する
        car部に述語を満たす要素のリストを、cdr部に満たさない要素のリスト値を返す
        srfi-1準拠にするにはcar、cdrをvaluesで括って返すように変更必要
    """
    #if not isa(ls,list):return ls
    S1, S2 = [None, None], [None, None]
    T1, T2 = S1, S2
    while isa(ls,list):
        if fn(ls[0],None) == False:
            S1[1] = [ls[0], None]
            S1 = S1[1]
        else:
            S2[1] = [ls[0], None]
            S2 = S2[1]
        ls = ls[1]
    return [T2[1], T1[1]]

 
cdef remove_(fn, ls):
    """ is の要素のうち、fn を満たさない要素だけを返す """
    return partition_(fn, ls)[1]


cdef filter_(fn, ls):
    """ list の要素のうち、pred を満たすものを返す"""
    return partition_(fn, ls)[0]


cdef int count_(fn, lists):
    """ srfi-1:countに相当 """
    cdef int c = 0
    cdef int n = Llen(lists)
    if n == 1 :
        ls = lists[0]
        while isa(ls,list):
            if fn(ls[0], None):c += 1
            ls = ls[1]
        return c
    while not memq_(None,lists):
        if fn(lists[0][0], map_car(lists[1])):
            c += 1
        lists = map_cdr(lists)
    return c


#cdef remove_(fn, ls):
#    if not isa(ls,list):return ls
#    S = [None, None]
#    T = S
#    while isa(ls,list):
#        if fn(ls[0],None) == False:
#            S[1] = [ls[0], None]
#            S = S[1]
#        ls = ls[1]
#    return T[1]


cdef fpartition_(fn,ls):
    """ carにfn:Trueをcdrにfn:Falseを返す
    """
    p_ptr, n_ptr = [None, ls],[None, ls]
    P, N = p_ptr, n_ptr
    while isa(ls, list):
        if fn(ls[0], None) is not False:
            n_ptr[1] = ls[1]
            p_ptr = ls
        else:
            p_ptr[1] =ls[1]
            n_ptr = ls
        ls = ls[1]
    return [P[1],N[1]]

cdef fremove_(fn, ls):
    return fpartition_(fn, ls)[1]


cdef ffilter_(fn, ls):
    return fpartition_(fn, ls)[0]


cpdef reduce_init(fn, a, ls):   #  comlist original function
    if not isa(ls, list):return a
    #a, ls = ls[0], ls[1]
    while isa(ls, list):
        #a = fn(a, [ls[0], None])
        a = fn(ls[0], [a, None])
        ls = ls[1]
    return a


cpdef reduce_(fn, ls):
    if isa(ls, list):return reduce_init(fn, ls[0], ls[1])
    else:return ls


cdef inline fold_left_1(fn, a, ls):
    while isa(ls, list):
        a, ls = fn(ls[0], [a, None]), ls[1]
    return a


#cdef fold_right_1(fn, a, ls):
#    if not isa(ls, list):return a
#    return fn(ls[0],[fold_right_1(fn,a,ls[1]),None])

cdef inline fold_right_1(fn, a, ls):
    """ 1引数のfold-right """
    return fold_left_1(fn, a, reverse_(ls))


cdef fold_left_n(fn, a, lists):
    while not memq_(None, lists):
        arg= fappend_1(map_car(lists), [a, None])
        a, lists = fn(arg[0], arg[1]), map_cdr(lists)
    return a


#cdef fold_right_n(fn, a, lists):
#    if memq_(None, lists):return a
#    arg=fappend_1(map_car(lists),[fold_right_n(fn,a,map_cdr(lists)),None])
#    return fn(arg[0],arg[1])


cdef fold_right_n(fn, a, lists):
    """ ！バグ！リストの長さが違うときの動作が定義と異なる """
    return fold_left_n(fn, a, map_reverse(lists))


def unfold(cond, func, iter_up, seed):
    """ 逆畳み込み関数
        cond    : 終了条件を示す#t/#fを返す関数
        func    : 適用する関数
        iter_up : カウンターを更新する関数
        seed    : 初期値
    """
    # きちんと動くが無駄あり;修正すべし
    l = [None, None]
    L = l
    if cond(seed, None): return None
    while True:
        l[0], seed = func(seed, None), iter_up(seed, None)
        if cond(seed, None): break
        l[1] = [None, None]
        l = l[1]
    return L


def unfold_right(cond, func, iter_up, seed):
    """ 与えられた種に関数を適用し、リストに右側詰めで入れる
        種に更新条件を適用し、その結果が終了条件に合致したら終了
        そうでないなら上記を繰り返す

        usage:(unfold-right 終了条件 適用関数 更新条件 初期値)
        ex:   (unfold-right zero? square 1-  5) =>
              (1 4 9 16 25)
    """
    l = [None, None]
    while not cond(seed, None):
        l[0], seed = func(seed, None), iter_up(seed, None)
        l = [None, l]
    return l[1]


cdef cons_s(first, rest):
    if rest is None:return first
    S = [first,None]
    T = S
    while isa(rest[1],list):
        S[1]=[rest[0],None]
        S, rest = S[1], rest[1]
    S[1]=rest[0]
    return T

#
# hash functon
#
cdef is_hash(table, key):
    if type(key) == list:key = tuple(tolist_light(key))
    return key in table


cdef get_hash(table, key):
    if type(key) == list:key = tuple(tolist_light(key))
    return table[key]


cdef set_hash(table,key,value):
    if type(key) == list:table[tuple(key)]=value
    else:table[key]=value
    return UNDEF


# string function
cdef string_set(st,int pos, ch):
    """ stの位置posの文字をchにする
    """
    st[pos]=ch
    return UNDEF


cpdef fstring_copy(a, int k, b, int i = 0, int j =- 1):
    """vector-copy"""
    if j <  0:j = len(b) + j + 1
    a.body[k:k + (j - i)] = b.body[i:j]
    return UNDEF


cdef fstring_reverse(str,op):
    if op is None:
        str.reverse()
        return UNDEF
    if op[1] is None:
        st, en = op[0], -1
    else:
        st, en = op[0], op[1][0]
    ss=str[st:en][::-1]
    str[st:en]=ss
    return UNDEF


cdef string_replace(s1, op):
    cdef int c
    args = tolist_light(op)
    c = len(args)
    if c == 3:
        s2, start1, end1 = args
        start2, end2 = 0, len(s2) 
    elif c == 4:
        s2, start1, end1, start2 = args
        end2  = len(s2)
    elif c == 5:
        s2, start1, end1, start2, end2 = args
    return s1[:start1] + s2[start2:end2]+ s1[end1:]


# vector function
#cpdef vector_ref(v, int pos):
#    a = v[pos]
#    #if isa(a, list):return Vector(a)
#    return a

cdef bint vector_eq_2(f, v1, v2):
    """ 2要素の vector= 
        ※通常は(= v1 v2)で良い
        　比較をeq?またはeqv?で行いたいときに有効
    """
    cdef int i, l1, l2
    if v1 is v2: return True    # 同じものならTrue
    l1, l2 = len(v1), len(v2)
    if l1 != l2: return False    # 長さが違えばFalse
    for i in range(l1):
        if not f(v1[i],[v2[i], None]): return False
    #for vv1, vv2 in zip(v1, v2):               # きれいだが早くない(zip関数が遅い)
    #    if not f(vv1,[vv2, None]):return False #
    return True
    # 下は途中でfalseになるときでも最後まで比較するので平均的に早くない
    #return reduce(lambda x, y: x is y, map(lambda x, y: f(x, [y, None]), v1, v2))


cdef bint vector_eq_n(f,vects):
    cdef bint T = True
    if vects is None:return True
    # if len(vects) == 1:return True
    while isa(vects[1], list):
        T = T and vector_eq_2(f, vects[0], vects[1][0])
        if not T :return False
        vects = vects[1]
    return True


cpdef vector_set(v, int pos, val):
    v[pos] = val
    return UNDEF


cdef vector_fill(v, val, int st = 0, int ed = 0):
    cdef int n
    if ed == 0:ed = len(v)
    n = min(len(v), ed) - st
    v[st:ed] = [val] * n
    return UNDEF


cpdef make_vector(int k, val = True):
    return Vector([val] * k)


cpdef make_list(int k, val = True):
    return Llist( * ([val] * k))

cdef vector_reverse(v, op = None):
    if op is None: v.reverse()
    elif op[1] is None: v[op[0]:] = v[op[0]:][::-1]
    else: v[op[0]:op[1][0]] = v[op[0]:op[1][0]][::-1] 
    return UNDEF

cpdef vector_append(vt, vs):
    v=vt[:]
    for vv in vs:
        v += vv
    return Vector(v)

cpdef fvector_append(v, vs):
    for vv in vs:
        v.extend(vv)
    return UNDEF

cpdef vcopy(a, int k, b, int i = 0, int j =- 1):
    """vector-copy"""
    if j <  0:j = len(b) + j + 1
    a[k:k + (j - i)] = b[i:j]
    return UNDEF


#cdef vector_for_each(proc,vects):
#    cdef int i = 0
#    for p in zip(*tolist_light(vects)):
#        proc(i, Llist(*p))
#        i += 1
#    return Symbol('*undef*')


cdef vector_for_each(proc,vects):
    for p in zip(*tolist_light(vects)):
        p=toLlist_(p)
        #if isa(p,list):
        proc(p[0],p[1])
        #else:proc([p,None],None)
    return UNDEF


#cdef int vector_count(proc, vects):
#    cdef int i = 0
#    cdef int count = 0
#    for p in zip( * tolist_light(vects)):
#        if proc(i, Llist( * p)) != False:count += 1
#        i += 1
#    return count


cdef int vector_count(proc, vects):
    cdef int count = 0
    for p in zip( * tolist_light(vects)):
        p=toLlist_(p)
        if proc(p[0],p[1]) != False:count += 1
    return count


#cdef vector_map_1(fn, vect):
#    cdef int i
#    S = []
#    for i in range(len(vect)):
#        S.append(fn(i, [vect[i], None]))
#    return Vector(S)


cdef vector_map_1(fn, vect):
    #S = []
    #for p in vect:
    #    S.append(fn(p, None))
    #return Vector(S)
    return Vector(map(lambda x:fn(x,None),vect))

#cdef vector_map_2(fn, vect1, vect2):
#    cdef int i
#    S = []
#    for i in range(min(len(vect1), len(vect2))):
#        S.append(fn(i, [vect1[i], [vect2[i], None]]))
#    return Vector(S)


cdef vector_map_2(fn, vect1, vect2):
    #cdef int i
    #S = []
    #for i in range(min(len(vect1), len(vect2))):
    #    S.append(fn(vect1[i], [vect2[i], None]))
    #return Vector(S)
    return Vector(map(lambda x,y: fn(x,[y,None]),vect1,vect2))


#cdef vector_map_n(fn, vects):
#    cdef int i = 0
#    S = []
#    for p in zip( * tolist_light(vects)):
#        S.append(fn(i, Llist( * p)))
#        i += 1
#    return Vector(S)


cdef vector_map_n(fn, vects):
    S = []
    for p in zip( * tolist_light(vects)):
        p=toLlist_(p)
        S.append(fn(p[0],p[1]))
    return Vector(S)
    #return Vector(map(lambda *x:fn(*toLlist_(x)),*tolist_light(vects)))    # bug

#cdef vector_fold_1(fn, a, vect):
#    for i in range(len(vect)):
#        a = fn(i, [a, [vect[i], None]])
#    return a


cdef vector_fold_1(fn, a, vect):
    #for x in vect:
    #    a = fn(a, [x, None])
    #return a
    return reduce(lambda a,x:fn(a,[x,None]),vect,a)


#cdef vector_fold_2(fn, a, v1, v2):
#    for i in range(min(len(v1), len(v2))):
#        a = fn(i, [a, [v1[i], [v2[i], None]]])
#    return a


cdef vector_fold_2(fn, a, v1, v2):
    for i in range(min(len(v1), len(v2))):
        a = fn(a, [v1[i], [v2[i], None]])
    return a


#cdef vector_fold(fn,a, vects):
#    """ SRFI-43 vector-fold
#    """
#    cdef int i = 0
#    for p in zip( *tolist_light(vects)):
#        a = fn(i, [a, Llist(*p)])
#        i += 1
#    return a


cdef vector_fold(fn,a, vects):
    for p in zip( *tolist_light(vects)):
        a = fn(a, toLlist_(p))
        i += 1
    return a


#cdef vector_fold_right(fn, a, vects):
#    cdef int i = 0
#    for p in reversed(zip( *tolist_light(vects))):
#        a = fn(i, [a, Llist( * p)])
#        i += 1
#    return a


cdef vector_fold_right(fn, a, vects):
    for p in reversed(zip( *tolist_light(vects))):
        a = fn(a, toLlist_(p))
    return a


def vector_unfold(f, l, s):
    """ うまく動いていない
    """
    def vector_unfold_0(f,l):
        S=[]
        for i in range(l):
            S.append(f(i,None))
        return Vector(S)

    def vector_unfold_1(f,l,s):
        S = []
        for i in range(l):
            e = f(i, [s, None])
            if isa(e,Values):
                S.append(e.data[0])
                s = e.data[1][0]
            else:raise ValueError
        return Vector(S)

    def vector_unfold_2(f,l,s):
        S=[]
        for i in range(l):
            e=f(i,s)
            if isa (e, Values):
                S.append(e.data[0])
                s=e.data[1]
            else:raise ValueError
        return Vector(S)

    if s is None:return vector_unfold_0(f,l)
    elif isa(s, list):return vector_unfold_2(f,l,s) # この時うまく動いていない
    else :return vector_unfold_1(f,l,s)


def vector_unfold_right(f, l, s):
    """ うまく動いていない
    """
    def vector_unfold_0(f,l):
        S=[]
        for i in reversed(range(l)):
            S.append(f(i,None))
        return Vector(S)

    def vector_unfold_1(f,l,s):
        S = []
        for i in reversed(range(l)):
            e = f(i, [s, None])
            if isa(e,Values):
                S.append(e.data[0])
                s = e.data[1][0]
            else:raise ValueError
        return Vector(S)

    def vector_unfold_2(f,l,s):
        S=[]
        for i in reversed(range(l)):
            e=f(i,s)
            if isa (e, Values):
                S.append(e.data[0])
                s=e.data[1]
            else:raise ValueError
        return Vector(S)

    if s is None:return vector_unfold_0(f,l)
    elif isa(s, list):return vector_unfold_2(f,l,s) # この時うまく動いていない
    else :return vector_unfold_1(f,l,s)

cdef is_sorted(ls, cmp_fn):
    while isa(ls[1], list):
        if cmp_fn(ls[0], [ls[1][0], None]) is False:return False
        ls = ls[1]
    return True


cdef peek_(port = None):
    if port is None:port = sys.stdin
    ch = port.read(1)
    port.seek( - 1, 1)
    return ch

cpdef plus(x=None, y=None):
    if x is None:return 0
    if y is None:return x
    while isa(y, list):
        x += y[0]
        y = y[1]
    return x

### グローバルリストテーブル
###
import sys
from fractions import Fraction,gcd
GL.update({\
      '+'     : ['primitive'   , [plus, None]],  
      #'+'        : ['primitive'   , [lambda x=None, y=None: 0 if (x is None and y is None) else x if y is None\
      #              else x + sum(tolist_light(y))                            , None]],
      '-'        : ['primitive'   , [lambda x=None, y=None: 0 if (x is None and y is None) else -x if y is None\
                    else  x - sum(tolist_light(y))                           , None]],
      '*'        : ['primitive'   , [lambda x=None, y=None: 1 if (x is None and y is None) else x if y is None \
                    else x * reduce(lambda x,y:x*y,tolist_light(y))          , None]],
      '/'        : ['primitive'   , [lambda x=None, y=None: 1 if (x is None and y is None) else Fraction(1, x)\
                    if y is None else Fraction(x, reduce(lambda x,y:x*y,\
                    tolist_light(y)))                                        , None]],
      #'='        : ['primitive'   , [lambda x=None, y=None: True if (x is None or  y is None) else reduce(lambda a, b:a and b, map(lambda z:x == z, tolist_light(y))), None]],   #yがlistの場合は使えない 
      '='        : ['primitive'   , [lambda x=None, y=None: True if y is None else s_EQ(x, tolist_light(y)), None]],  
      #':equal?'  : ['primitive' , [equal_st, None]], 
      '<'        : ['primitive'   , [lambda x=None, y=None: True if y is None else s_GT(x,tolist_light(y)), None]], 
      '<='       : ['primitive'   , [lambda x=None, y=None: True if y is None else s_GE(x,tolist_light(y)), None]], 
      '>'        : ['primitive'   , [lambda x=None, y=None: True if y is None else s_LT(x,tolist_light(y)), None]], 
      '>='       : ['primitive'   , [lambda x=None, y=None: True if y is None else s_LE(x,tolist_light(y)), None]], 
      'infinite?'  : ['primitive'   , [lambda x, y: x==float('inf') or x==float('-inf'), None]],
      'nan?'       : ['primitive'   , [lambda x, y: x != x, None]],
      #'::list='   : ['primitive'   , [lambda x, y: list_eq(x, y[0])     , None]],  
      ':list=2'   : ['primitive'   , [lambda x, y: list_eq_2(x, y[0],y[1][0])   , None]],  
      ':list=n'   : ['primitive'   , [lambda x, y: list_eq_n(x, y[0])   , None]],  
      ':list-tabulate'  : ['primitive'  , [lambda x, y: list_tabulate(x, y[0])  , None]], 
      ':append-1' : ['primitive'   , [lambda x, y: append_1(x, y[0])    , None]], 
      ':append-n' : ['primitive'   , [lambda x = None, y = None: None if x is None and y is None else append_n(x, y)       , None]], 
      ':append-1!': ['primitive'   , [lambda x, y: fappend_1(x, y[0])   , None]], 
      ':append-n!': ['primitive'   , [lambda x = None, y = None:None if x is None and y is None else fappend_n(x, y)      , None]], 
      ':reverse'  : ['primitive'   , [lambda x, y: reverse_(x)          , None]],
      ':reverse!' : ['primitive'   , [lambda x, y: freverse_(x)         , None]],
      'reverse-n' : ['primitive'   , [lambda x, y: reverse_n(x, y[0])   , None]],
      'reverse!-n' : ['primitive'   , [lambda x, y: freverse_n(x, y[0])   , None]],
      'append-reverse'  : ['primitive'   , [lambda x, y: reverse_append_1(x,y[0])     , None]],
      'append-reverse!' : ['primitive'   , [lambda x, y: freverse_append_1(x,y[0])    , None]],
      'append-reverse-n'  : ['primitive'   , [lambda x, y: reverse_append_n(x,y)        , None]],
      'map-car'   : ['primitive'   , [lambda x, y: map_car(x)           , None]], 
      'map-cdr'   : ['primitive'   , [lambda x, y: map_cdr(x)           , None]], 
      'map-cadr'   : ['primitive'   , [lambda x, y: map_cadr(x)           , None]], 
      'map-cons'  : ['primitive'   , [lambda x, y: map_cons(x, y[0])    , None]], 
      'map-reverse' : ['primitive' , [lambda x, y: map_reverse(x)       , None]], 
      ':map-1'    : ['primitive'   , [lambda x, y: map_1(x, y[0])       , None]],
      ':map-2'    : ['primitive'   , [lambda x, y: map_2(x, y[0], y[1][0])        , None]],
      ':map'      : ['primitive'   , [lambda x, y: map_(x, y[0])        , None]],
      ':map!'     : ['primitive'   , [lambda x, y: fmap_(x, y[0])       , None]],
      ':filter-map'     : ['primitive'   , [lambda x, y: filter_map(x, y[0])       , None]],
      ':for-each' : ['primitive'   , [lambda x, y: for_each(x, y[0])    , None]],
      ':pair-for-each' : ['primitive'   , [lambda x, y: pair_for_each(x, y[0])    , None]],
      ':memq'     : ['primitive'   , [lambda x, y: memq_(x, y[0])       , None]],
      ':memv'     : ['primitive'   , [lambda x, y: memv_(x, y[0])       , None]],
      ':memp'     : ['primitive'   , [lambda x, y: memp(x,y[0])         , None]],
      ':find'     : ['primitive'   , [lambda x, y: find_(x,y[0])         , None]],
      ':find-tail'     : ['primitive'   , [lambda x, y: find_tail(x,y[0])         , None]],
      ':member'   : ['primitive'   , [lambda x, y: member_(x, y[0])     , None]],
      '::member'  : ['primitive'   , [lambda x, y: member(x, y[0], y[1][0])     , None]],
      'member*'   : ['primitive'   , [lambda x, y: member_st(x, y[0])   , None]],
      #'list-position':['primitive' , [lambda x,y: list_position(x,y[0]) , None]],
      'list-index':['primitive' , [lambda x,y: list_index(x,y[0]) , None]],
      ':filter'   : ['primitive'   , [lambda x, y: filter_(x,y[0])      , None]],
      ':filter!'  : ['primitive'   , [lambda x, y: ffilter_(x,y[0])     , None]],
      ':partition': ['primitive'   , [lambda x, y: partition_(x,y[0])   , None]],
      ':partition!': ['primitive'   , [lambda x, y: fpartition_(x,y[0])   , None]],
      ':count'    : ['primitive'   , [lambda x, y: count_(x, y[0])      , None]],  
      ':remove'   : ['primitive'   , [lambda x, y: remove_(x,y[0])      , None]],
      ':remove!'  : ['primitive'   , [lambda x, y: fremove_(x,y[0])     , None]],
      ':reduce'   : ['primitive'   , [lambda x, y: reduce_(x, y[0])        , None]], 
      ':reduce-init'    : ['primitive'  , [lambda x, y: reduce_init(x, y[0], y[1][0])     , None]], 
      ':fold-right-1'   : ['primitive'  , [lambda x, y: fold_right_1(x, y[0], y[1][0])    , None]],
      ':fold-left-1'    : ['primitive'  , [lambda x, y: fold_left_1(x, y[0], y[1][0])     , None]],
      ':fold-right-n'   : ['primitive'  , [lambda x, y: fold_right_n(x, y[0], y[1][0])    , None]],
      ':fold-left-n'    : ['primitive'  , [lambda x, y: fold_left_n(x, y[0], y[1][0])     , None]],
      ':unfold'   : ['primitive'   , [lambda x, y: unfold(x, y[0], y[1][0], y[1][1][0])   , None]],
      ':unfold-right'   : ['primitive'  , [lambda x, y: unfold_right(x, y[0], y[1][0], y[1][1][0])    , None]],
      'caar'      : ['primitive'   , [lambda x, y: x[0][0]              , None]],
      'cadr'      : ['primitive'   , [lambda x, y: x[1][0]              , None]],
      'cdar'      : ['primitive'   , [lambda x, y: x[0][1]              , None]],
      'cddr'      : ['primitive'   , [lambda x, y: x[1][1]              , None]],
      'cadar'     : ['primitive'   , [lambda x, y: x[0][1][0]           , None]],
      'caddr'     : ['primitive'   , [lambda x, y: x[1][1][0]           , None]],
      'cadddr'    : ['primitive'   , [lambda x, y: x[1][1][1][0]        , None]],
      'caddddr'   : ['primitive'   , [lambda x, y: x[1][1][1][1][0]     , None]],
      'not-pair?' : ['primitive'   , [lambda x, y: not isa(x,list)      , None]],
      ':cons*'    : ['primitive'   , [lambda x, y: cons_s(x,y)          , None]],
      'no-cycle?' : ['primitive'   , [lambda x, y: no_cycle(x)          , None]], 
      'circular-list?'     : ['primitive', [lambda x, y: circular_list(x)         , None]], 
      ':get-primitive-body': ['primitive', [lambda x, y: get_primitive_body(x)    , None]],
      ':get-closure-body'  : ['primitive', [lambda x, y: get_closue_body(x)       , None]], 
      'quotient'  : ['primitive'   , [lambda x, y: x // y[0]      , None]],
      'range'     : ['primitive'   , [lambda x, y: range_(0, x) if y is None else (range_(x, y[0]) if y[1] is None else range_(x, y[0], y[1][0]))   , None]], 
      'iota'      : ['primitive'   , [lambda x, y: range_(0, x) if y is None else (range_(y[0], x + y[0]) if y[1] is None else range_(y[0], y[0] + x * y[1][0], y[1][0]))   , None]], 
      'sum'       : ['primitive'   , [lambda x, y: sum(tolist_light(x))      , None]],
      'range-v'   : ['primitive'   , [lambda x, y: Vector(range(x)) if y is None else (Vector(range(x, y[0])) if y[1] is None else Vector(range(x, y[0], y[1][0]))), None]],
      'sum-v'     : ['primitive'   , [lambda x, y: sum(x)               , None]],
      'make-hash-table'     : ['primitive'   , [lambda x, y : {}                        , None]],
      'hash-table-exists?'  : ['primitive'   , [lambda x, y : is_hash(x, y[0])          , None]],
      'hash-table-get'      : ['primitive'   , [lambda x, y : get_hash(x, y[0])         , None]],
      'hash-table-put!'     : ['primitive'   , [lambda x, y : set_hash(x, tolist_light(y[0]), y[1][0])   , None]],
      'read'      : ['primitive'   , [lambda x = "", y  = None : toLlist(read(x)) if y is None else toLlist(read(x,y[0]))       , None]],
      'set-car!'  : ['primitive'   , [lambda x, y : set_car(x, y[0])    , None]],
      'set-cdr!'  : ['primitive'   , [lambda x, y : set_cdr(x, y[0])    , None]],
      'last-pair' : ['primitive'   , [lambda x, y : last_pair(x)        , None]],
      'compile'   : ['primitive'   , [lambda x, y : compile(x)          , None]], 
      'eval'      : ['primitive'   , [lambda x, y : vm(None, None, compile(x), None)    , None]],
      'vm'        : ['primitive'   , [lambda x, y : vm(None, None, x, None)             , None]],
      'length'    : ['primitive'   , [lambda x, y : Llen(x)             , None]],
      'string-length'       : ['primitive'   , [lambda x, y : len(x)    , None]],
      'string='   : ['primitive'   , [lambda x, y : x == y[0]           , None]],
      'string-pop'          : ['primitive'   , [lambda x, y : x.pop() if y is None else x.pop(y[0]) , None]],
      'string-count'        : ['primitive'   , [lambda x, y : x.count(y[0])                         , None]],
      'string-remove'       : ['primitive'   , [lambda x, y : x.remove(y[0])                        , None]],
      'string-insert'       : ['primitive'   , [lambda x, y : x.insert(y[0], y[1][0])               , None]],
      'string-fill!'    : ['primitive'  , [lambda x, y: vector_fill(x, y[0].tostring()) if y[1] is None else (vector_fill(x, y[0].tostring(), y[1][0]) if y[1][1]==None else vector_fill(x, y[0].tostring(), y[1][0], y[1][1][0]))    , None]],
      'list-ref'  : ['primitive'   , [lambda x, y : nth(x, y[0])        , None]],
      'list-tail' : ['primitive'   , [lambda x, y : nth_cdr(x, y[0])    , None]],
      'drop'      : ['primitive'   , [lambda x, y : nth_cdr(x, y[0])    , None]],
      'take'      : ['primitive'   , [lambda x, y : but_nth_cdr(x, y[0]), None]],
      'drop!'     : ['primitive'   , [lambda x, y : fnth_cdr(x, y[0])   , None]],
      'take!'     : ['primitive'   , [lambda x, y : fbut_nth_cdr(x, y[0])   , None]],
      ':split'    : ['primitive'   , [lambda x, y : split_(x, y[0])     , None]],
      ':split!'   : ['primitive'   , [lambda x, y : fsplit(x, y[0])     , None]],
      ':some'     : ['primitive'   , [lambda x, y : some_(x, y[0])      , None]],
      ':every'    : ['primitive'   , [lambda x, y : every_(x, y[0])     , None]],
      'list-copy' : ['primitive'   , [lambda x, y : list_copy(x)        , None]],
      'last'      : ['primitive'   , [lambda x, y : last(x)             , None]],
      'upper'     : ['primitive'   , [lambda x, y : x.upper()           , None]],
      'lower'     : ['primitive'   , [lambda x, y : x.lower()           , None]],
      'string?'   : ['primitive'   , [lambda x, y : type(x) == String or type(x)==str   , None]],
      'string'    : ['primitive'   , [lambda x, y : String(x if y is None else x+reduce(lambda x, y:x + y, tolist_light(y)))      , None]],
      'symbol?'   : ['primitive'   , [lambda x, y : type(x) == Symbol   , None]],
      'boolean?'  : ['primitive'   , [lambda x, y : type(x) == bool     , None]],
      'char?'     : ['primitive'    ,[lambda x, y : type(x) == String and len(x)<=1     , None]],
      'integer->char'   : ['primitive'  , [lambda x,y :String(chr(x))   , None]],
      'char->integer'   : ['primitive'  , [lambda x,y :ord(x.tostring()), None]],
      'char-alphabetic?': ['primitive'  , [lambda x,y :(ord(x.tostring())>=65 and ord(x.tostring())<=90) or (ord(x.tostring())>=97 and ord(x.tostring())<=122), None]],
      'char-numeric?'   : ['primitive'  , [lambda x,y :x.tostring() in '1234567890', None]],
      'char-whitespace?': ['primitive'  , [lambda x,y :x == ' ' or x=='\t', None]],
      'char-upper-case?': ['primitive'  , [lambda x,y :(ord(x.tostring())>=65 and ord(x.tostring())<=90), None]],
      'char-lower-case?': ['primitive'  , [lambda x,y :(ord(x.tostring())>=97 and ord(x.tostring())<=122), None]],
      'string->list'    : ['primitive'  , [lambda x, y:toLlist(map(String,list(x.body) if y is None else list(x.body[y[0]:]) if y[1] is None else list(x.body[y[0]:y[1][0]]))), None]],
      'string->vector'    : ['primitive'  , [lambda x, y:Vector(list(x.tostring()))     , None]],
      #'string->bytevector'    : ['primitive'  , [lambda x, y: array.array('B', x.tostring()))        , None]],
      'tostring'        : ['primitive'  , [lambda x, y : to_string(x)   , None]],
      'number->string'  : ['primitive'  , [lambda x, y: String(str(x) if y is None else str_base(x, y[0]))          , None]],
      'list->string'    : ['primitive'  , [lambda x = None, y = None: String('' if x is None else reduce(lambda a, b:a + b, tolist_light(x)))               , None]],
      'make-string'     : ['primitive'  , [lambda x, y: String(" "*x if y is None else y[0]*x)          , None]],
      'string-ref'      : ['primitive'  , [lambda x, y: x[y[0]]                         , None]],
      'string-set!'     : ['primitive'  , [lambda x, y: string_set(x,y[0],y[1][0])      , None]],
      'substring'       : ['primitive'  , [lambda x, y: x[y[0]:] if y[1] is None else x[y[0]:y[1][0]]   , None]],
      'string-append-1' : ['primitive'  , [lambda x, y: String(x).append(y[0])          , None]],
      'string-append'   : ['primitive'  , [lambda x=None, y=None: String("") if x is None else x if y is None else String(x).append(String(reduce(lambda s,t:s+t,map(lambda c:c.tostring(),tolist_light(y)))))          , None]],
      'string-copy'     : ['primitive'  , [lambda x, y: x[:] if y is None else x[y[0]:] if y[1] is None else x[y[0]:y[1][0]], None]],
      'string-copy!'    : ['primitive'  , [lambda x, y: fstring_copy(x,  *tolist(y))    , None]],
      'string-scan'     : ['primitive'  , [lambda x, y: x.find(y[0])    , None]],
      'read-line'       : ['primitive'  , [lambda x = None, y = None: String(raw_input("") if x is None else x.readline())  , None]],
      'read-char'       : ['primitive'  , [lambda x = None, y = None: String(sys.stdin.read(1) if x is None else x.read(1)) , None]],
      'peek-char'       : ['primitive'  , [lambda x = None, y = None: String(peek_(x)) , None]],
      'output-port?'    : ['primitive'  , [lambda x, y: isa(x, file) and x.mode == 'w'   , None]], 
      'input-port?'     : ['primitive'  , [lambda x, y: isa(x, file) and x.mode == 'r'   , None]],
      'read-text'       : ['primitive'  , [lambda x=None, y=None: sys.stdin.read() if x is None else x.read(),None]],
      'write-char'      : ['primitive'  , [lambda x, y=None: sys.stdout.write(x.tostring()) if y is None else y[0].write(x.tostring())   , None]],
      'string-split'    : ['primitive'  , [lambda x, y: toLlist(x.split(y[0]))          , None]],
      ':string-replace' : ['primitive'  , [lambda x, y: string_replace(x, y)            , None]],
      'string-reverse'  : ['primitive'  , [lambda x, y: x[::-1] if y is None else x[y[0]:][::-1] if y[1] is None else x[y[0]:y[1][0]][::-1], None]],
      'string-reverse!' : ['primitive'  , [lambda x, y: fstring_reverse(x,y)    ,None]],
      ':string-map-1'   : ['primitive'  , [lambda x, y: String("".join(map(lambda a:x(a,None), y[0].tostring())))    , None]],
      ':string-map-2'   : ['primitive'  , [lambda x, y: String("".join(map(lambda a, b:x(a,[b,None]) ,y[0].tostring(),y[1][0].tostring()))),None]], 
      ':string-map-n'   : ['primitive'  , [lambda x, y: String("".join(map(lambda *a:x(*Llist(*a)),*map(lambda c:c.tostring(), tolist_light(y[0]))))),None]], 
      'integer?'        : ['primitive'  , [lambda x, y: isinstance(x,int) or isinstance(x,long) , None]],
      'complex?'        : ['primitive'  , [lambda x, y: isinstance(x,complex)                   , None]],
      'real?'           : ['primitive'  , [lambda x, y: isinstance(x,float)                     , None]],
      'rational?'       : ['primitive'  , [lambda x, y: isinstance(x,Fraction)                  , None]],
      'Fraction'        : ['primitive'  , [lambda x, y: Fraction(str(x))    , None]],
      'float'           : ['primitive'  , [lambda x, y: float(x)            , None]],
      'complex'         : ['primitive'  , [lambda x, y: complex(x, y[0])    , None]],
      'open-input-file' : ['primitive'  , [lambda x, y: open(x.tostring())  , None]],
      'open-output-file' : ['primitive'  , [lambda x, y: open(x.tostring(), 'w')         , None]],
      'close-input-file': ['primitive'  , [lambda x, y: x.close()           , None]],
      'eof-object?'     : ['primitive'  , [lambda x, y: x=="" or x==-1      , None]],
      'port?'           : ['primitive'  , [lambda x, y: isa(x, file)        , None]],
      'square'          : ['primitive'  , [lambda x, y: x*x                 , None]],
      ':sort-v!'        : ['primitive'  , [lambda x, y: x.sort() if y is None else x.sort(cmp = lambda a, b: -1 if y[0](a, [b, None]) else 1 )       , None]],
      ':sort-v'         : ['primitive'  , [lambda x, y: Vector(sorted(x)) if y is None else Vector(sorted(x, cmp = lambda a, b: -1 if y[0](a, [b, None]) else 1))                               , None]],
      #'sort!'           : ['primitive'  , [lambda x, y: toLlist((tolist_light(x)).sort()) if y is None else toLlist(tolist_light(x).sort(cmp = lambda a, b: -1 if y[0](a,[b,None]) else 1))     , None]],
      ':sort'           : ['primitive'  , [lambda x, y: toLlist_(sorted(tolist_light(x))) if y is None else toLlist_(sorted(tolist_light(x), cmp = lambda a, b: -1 if y[0](a,[b,None]) else 1)) if y[1] is None else toLlist_(sorted(tolist_light(x), cmp = lambda a, b: -1 if y[0](a,[b,None]) else 1, key = lambda a: y[1][0](a, None)))  , None]],
      ':sorted?'        : ['primitive'  , [lambda x, y: is_sorted(x, lambda x, y:x<=y[0] ) if y is None else is_sorted(x, y[0])   , None]],
      'vector?'         : ['primitive'  , [lambda x, y: isa(x, Vector)      , None]],
      'list->vector'    : ['primitive'  , [lambda x = None, y = None: Vector([]) if x is None else Vector(tolist_light(x)) if y is None else Vector(tolist_n(x, y[0])) if y[1] is None else Vector(tolist_n(x, y[0], y[1][0]))  , None]],
      'vector-reverse'  : ['primitive'  , [lambda x, y: Vector(x[:: -1] if y is None else x[:y[0]] + x[y[0]:][:: -1] if y[1] is None else x[:y[0]] + x[y[0]:y[1][0]][:: -1] + x[y[1][0]:])     , None]],
      'vector-reverse!' : ['primitive'  , [lambda x, y = None: vector_reverse(x, y)    , None]],
      'reverse-list->vector'    : ['primitive'  , [lambda x = None, y = None: Vector([]) if x is None else Vector(tolist_light(x, True)) if y is None else Vector(tolist_n(x, y[0], 10000000, True)) if y[1] is None else Vector(tolist_n(x, y[0], y[1][0], True))  , None]],
      'vector->list'    : ['primitive'  , [lambda x = None, y = None: None if x is None else toLlist_(list(x) if y is None else list(x[y[0]:]) if y[1] is None else list(x[y[0]:y[1][0]])), None]],
      'vector->string'  : ['primitive'  , [lambda x = None, y = None: '' if x  == [] or x is None else reduce(lambda a, b:a + b, x), None]],
      'vector-ref'      : ['primitive'  , [lambda x, y: x[y[0]] , None]],
      'vector-length'   : ['primitive'  , [lambda x, y: 0 if x is None else len(x)              , None]],
      'vector-copy'     : ['primitive'  , [lambda x, y: Vector(x[:] if y is None else x[y[0]:] if y[1] is None else x[y[0]:y[1][0]]), None]],
      'vector-copy!'    : ['primitive'  , [lambda x, y: vcopy(x,  *tolist_light(y)), None]],
      'vector-set!'     : ['primitive'  , [lambda x, y: vector_set(x, y[0], y[1][0])                , None]],
      'vector-append'   : ['primitive'  , [lambda x, y: vector_append(x, tolist(y))     , None]], 
      'vector-append!'  : ['primitive'  , [lambda x, y: fvector_append(x, tolist(y))    , None]], 
      'vector-concatenate'   : ['primitive'  , [lambda x, y: vector_append(x[0], tolist(x[1]))      , None]], 
      ':vector='        : ['primitive'  , [lambda x, y: vector_eq_n(x, y[0])      , None]], 
      #':vector-map-1'   : ['primitive'  , [lambda x, y: Vector(map(lambda a:x(a,None), y[0]))    , None]],
      ':vector-map-1'   : ['primitive'  , [lambda x, y: vector_map_1(x, y[0])   ,None]], 
      #':vector-map-2'   : ['primitive'  , [lambda x, y: Vector(map(lambda a, b:x(a,[b,None]) ,y[0],y[1][0])),None]], 
      ':vector-map-2'   : ['primitive'  , [lambda x, y: vector_map_2(x, y[0], y[1][0]),None]], 
      #':vector-map-n'   : ['primitive'  , [lambda x, y: Vector(map(lambda *a:x(*Llist(*a)),*tolist_light(y[0]))),None]], 
      ':vector-map-n'   : ['primitive'  , [lambda x, y: vector_map_n(x, y[0])   , None]], 
      ':vector-for-each': ['primitive'  , [lambda x, y: vector_for_each(x,y[0]) , None]],
      ':vector-count'   : ['primitive'  , [lambda x, y: vector_count(x, y[0])   , None]], 
      ':vector-fold-1'  : ['primitive'  , [lambda x, y: vector_fold_1(x,y[0], y[1][0]),None]], 
      ':vector-fold-2'  : ['primitive'  , [lambda x, y: vector_fold_2(x,y[0], y[1][0], y[1][1][0])  ,None]],
      ':vector-fold-n'  : ['primitive'  , [lambda x, y: vector_fold(x,y[0], y[1][0]),None]],
      ':vector-fold-right':['primitive' , [lambda x, y: vector_fold_right(x,y[0],y[1][0]),None]],
      ':vector-unfold'  : ['primitive'  , [lambda x, y: vector_unfold(x, y[0], y[1][0])  , None]], 
      ':vector-unfold-right'  : ['primitive'  , [lambda x, y: vector_unfold_right(x, y[0], y[1][0])  , None]], 
      'vector-fill!'    : ['primitive'  , [lambda x, y: vector_fill(x, y[0]) if y[1] is None else (vector_fill(x, y[0], y[1][0]) if y[1][1]==None else vector_fill(x, y[0], y[1][0], y[1][1][0]))    , None]],
      'make-vector'     : ['primitive'  , [lambda x, y: make_vector(x) if y is None else make_vector(x, y[0]), None]],
      'make-list'       : ['primitive'  , [lambda x, y: make_list(x) if y is None else make_list(x, y[0]), None]],
      'procedure?'      : ['primitive'  , [lambda x, y: type(x) == list and (x[0] == 'primitive' or x[0] == 'closue'), None]],
      '1+'              : ['primitive'  , [lambda x, y: <int>x + 1          , None]],
      '1-'              : ['primitive'  , [lambda x, y: <int>x - 1          , None]],
      '2*'              : ['primitive'  , [lambda x, y: <int>x * 2          , None]],  
      'gcd'             : ['primitive'  , [lambda x, y: gcd(x,y[0])         , None]],
      'numerator'       : ['primitive'  , [lambda x,y: x.numerator          , None]],
      'denominator'     : ['primitive'  , [lambda x,y: x.denominator        , None]],
      'rationalize'     : ['primitive'  , [lambda x,y:  Fraction(x).limit_denominator() if y is None else Fraction(x).limit_denominator(1/ Fraction(y[0])),None]],
      'round'           : ['primitive'  , [lambda x,y: int(round(x)) if ((isa(x, Fraction) or isa(x, int)) and y is None ) else round(x) if y is None else round(x,y[0]) , None]],
      'odd?'            : ['primitive'  , [lambda x,y: (x % 2)==1           , None]],
      'even?'           : ['primitive'  , [lambda x,y: (x % 2)==0           , None]],
      'positive?'       : ['primitive'  , [lambda x,y: x>0                  , None]],
      'negative?'       : ['primitive'  , [lambda x,y: x<0                  , None]],
      'max'             : ['primitive'  , [lambda x,y = None: x if y is None else max(x, *tolist_light(y))  , None]],
      'min'             : ['primitive'  , [lambda x,y = None: x if y is None else min(x, *tolist_light(y))  , None]],
      #':values'         : ['primitive'  , [lambda x = None, y = None: None if x is None else Values([x,y])        ,None]],
      #':call-with-values':['primitive'  , [lambda x,y: c_w_v(x,y[0])        ,None]], 
      ':format'          : ['primitive'  , [lambda x, y:(x.tostring()).format( *tolist_light(y)),   None]], 
      })

