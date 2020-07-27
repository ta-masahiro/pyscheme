#! /usr/bin/python
#  -*- coding: utf-8  -*-
#
# cython: boundscheck = False, wraparound = False
VM_VER = '1707091648:VM linked-List & OP-CODE in dict'
#print "\tVirtualmachine :",VM_VER
#
# vmで直接実行するcode群がスタックを壊していた(call/cc系命令で不具合あり)ので修正
# call系命令の最適化
# 元verは17051748
#  op codeをif～elifループで回して判定せずにop codeごとに関数にして
#  辞書でアクセスできるようにしたversion
#  さらにargs n, ldx yyy, (t)appを (t)callx n yyy命令にまとめた
#
from fractions import Fraction
from secd_common import GL,tolist, tolist_, Llen, Symbol,list_copy, Vector
from secd_read import to_string
#from secd_sysfuncs import _f_type
import sys                      #search-circlでstr関数を用いて
sys.setrecursionlimit(10000)    #list->strにしているが深いと失敗するので
isa = isinstance
# vm命令(op-code)の定義
# ※strを使わずに小さな整数で定義すると多少早くなる
#
#    Symbolに変換しているのはdebug命令でop-codeが"～"に囲まれて見にくくなるのを防ぐため
#    実質は不要

LDC, LDG, LD, RTN, SEL, SELR, JOIN, DEF_, DEFM, POP = \
        map(Symbol, ['ldc', 'ldg', 'ld', 'rtn', 'sel', 'selr', 'join', 'def', 'defm', 'pop'])
        # 1,2,3,4,5,6,7,8,9,10
LDF, LSET, GSET, STOP, LDCT, APP, TAPP, ARGS, ARGSAP, CALL ,CALLP = \
        map(Symbol, ['ldf', 'lset', 'gset', 'stop', 'ldct', 'app', 'tapp', 'args', 'args-ap', 'call', 'callp'])
        # 11,12,13,14,15,16,17,18,19,20
ADD, SUB, MUL, DIV, EQ, GEQ, SEQ, NEQ, ZEQ, ISPAIR, TCALL = \
        map(Symbol, ['add', 'sub', 'mul', 'div', 'eq', 'geq', 'seq', 'neq', 'zeq', 'ispair', 'tcall'])
        # 21,22,23,24,25,26,27,28,29,30,31
GT, ST, _CAR, _CDR, _CONS, INC, DEC, NULL_, CALLG, TCALLG, _2TIMES, CALLF, TCALLF, APPCC = \
        map(Symbol, ['gt', 'st', '_car', '_cdr', '_cons', 'inc', 'dec', 'null', 'callg', 'tcallg', '2times', 'callf', 'tcallf', 'appcc'])
        # 32,33,34,35,36,37,38,39, 40, 41, 42, 43

cdef list s, e, c, d

#
# 以下op codeの定義
#
cdef _LD_():
    global s, e, c, d
    cdef list c_0
    c_0 = c[0]
    s, c = [get_lvar(e, c_0[0], c_0[1]), s], c[1]

cdef _LDC_():
    global s, e, c, d
    s, c = [c[0], s], c[1]

cdef _LDG_():
    global s, e, c, d
    #s, c = [get_gvar(c[0]), s], c[1]
    s, c = [GL[c[0]], s], c[1]

cdef _CALLP_():
    # args n, ldg func, appのfuncがprimitiveの場合を1命令にまとめた
    global s, e, c, d
    cdef int N, i
    cdef list lvar, c1
    #cdef str hd
    #print s, e, c, d
    lvar, N ,c1 = None, c[0], c[1]
    for i in range(N):
        lvar, s = [s[0], lvar], s[1]
    #hd, (clo_0, clo_1) = GL[c1[0]]
    #if hd == 'primitive':
    s, c = [c1[0]( * lvar), s] if lvar is not None else [c1[0](), s], c1[1]
    #s, c = [c1[0]( * lvar), s] if lvar is not None else [c1[0](None,None), s], c1[1]

cdef _CALLG_():
    # args n, ldg func, appを1命令にまとめた
    global s, e, c, d
    cdef int N, i
    cdef str hd
    cdef list lvar, c1
    lvar, N ,c1 = None, c[0], c[1]
    for i in range(N):
        lvar, s = [s[0], lvar], s[1]
    #hd, (clo_0, clo_1), src = GL[c1[0]]
    hd, (clo_0, clo_1) = GL[c1[0]]
    if hd == 'primitive':
    #if isa(clo_0,_f_type):
        s, c = [clo_0( * lvar), s] if lvar is not None else [clo_0(), s], c1[1]
    elif hd == 'closue':
        s, e, c, d = None, [lvar, clo_1[0]], clo_0, [[s, [e, [c1[1], None]]], d]
    elif hd == 'continuation':
        s, e, c, d = [lvar[0], clo_0], clo_1[0], clo_1[1][0], clo_1[1][1][0]
    else:raise RuntimeError

cdef _TCALLG_():
    # args n, ldg func, tappを1命令にまとめた
    global s, e, c, d
    cdef int N, i
    cdef str hd
    cdef list lvar, c1
    lvar, N, c1 = None, c[0], c[1]
    for i in range(N):
        lvar, s = [s[0], lvar], s[1]
    #hd, clo = GL[c1[0]]
    #hd, (clo_0, clo_1), src = GL[c1[0]]
    hd, (clo_0, clo_1) = GL[c1[0]]
    if hd == 'primitive':
    #if isa(clo_0,_f_type):
        #s, c = [clo[0]( * lvar), s] if lvar is not None else [clo[0](), s], c1[1]
        s, c = [clo_0( * lvar), s] if lvar is not None else [clo_0(), s], c1[1]
    elif hd == 'closue':
        #e, c =  [lvar, clo[1][0]], clo[0]
        e, c =  [lvar, clo_1[0]], clo_0
    elif hd == 'continuation':
        #s, e, c, d = [lvar[0], clo[0]], clo[1][0], clo[1][1][0], clo[1][1][1][0]
        s, e, c, d = [lvar[0], clo_0], clo_1[0], clo_1[1][0], clo_1[1][1][0]
    else:
        #print hd, clo_0, clo_1,type(clo_0), isa(clo_0, _f_type), _f_type
        raise RuntimeError

cdef _CALL_():
    # args n, ld (i . j), appを1命令にまとめた
    global s, e, c, d
    cdef int N, i
    cdef str hd
    cdef list lvar, c1
    lvar, N, c1 = None, c[0], c[1]
    for i in range(N):
        lvar, s = [s[0],lvar], s[1]
    hd, (clo_0, clo_1) = get_lvar(e, c1[0][0], c1[0][1])
    if hd == 'primitive':
        s, c = [clo_0( * lvar), s] if lvar is not None else [clo_0(), s], c1[1]
    elif hd == 'continuation':
        s, e, c, d = [lvar[0], clo_0], clo_1[0], clo_1[1][0], clo_1[1][1][0]
    else:
        s, e, c, d = None, [lvar, clo_1[0]], clo_0, [[s, [e, [c1[1], None]]], d]

cdef _TCALL_():
    # args n, ld (i . j), tappを1命令にまとめた
    global s, e, c, d
    cdef int N, i
    cdef str hd
    cdef list lvar, c1
    lvar, N, c1 = None, c[0], c[1]
    for i in range(N):
        lvar, s = [s[0], lvar], s[1]
    hd, (clo_0, clo_1) = get_lvar(e, c1[0][0], c1[0][1])
    if hd == 'primitive':
        s, c = [clo_0( * lvar), s] if lvar is not None else [clo_0(), s], c1[1]
    elif hd == 'continuation':
        s, e, c, d = [lvar[0], clo_0], clo_1[0], clo_1[1][0], clo_1[1][1][0]
    else:
        e, c =  [lvar, clo_1[0]], clo_0

cdef _CALLF_():
    # args n, ld (i . j), appを1命令にまとめた
    global s, e, c, d
    cdef int N, i
    cdef list lvar, c1
    lvar, N, c1 = None, c[0], c[1]
    for i in range(N):
        lvar, s = [s[0], lvar], s[1]
    clo = [c1[0], [e, None]]
    s, e, c, d = None, [lvar, clo[1][0]], clo[0], [[s, [e, [c1[1], None]]], d]

cdef _TCALLF_():
    # args n, ld (i . j), tappを1命令にまとめた
    global s, e, c, d
    cdef int N, i
    cdef list l1, c1
    lvar, N,c1 = None, c[0], c[1]
    for i in range(N):
        lvar, s = [s[0], lvar], s[1]
    clo = [c1[0], [e, None]]
    e, c =  [lvar, clo[1][0]], clo[0]

cdef _APP_():
    global s, e, c, d
    cdef int N, i
    cdef str hd
    cdef list clo, lvar
    clo, lvar = s[0], s[1][0]
    hd, clo = clo
    if hd == 'primitive':
        s = [clo[0]( * lvar), s[1][1]] if lvar is not None else [clo[0](), s[1][1]]
    elif hd == 'continuation':
        s, e, c, d = [lvar[0], clo[0]], clo[1][0], clo[1][1][0], clo[1][1][1][0]
        #s, e, c, d = [lvar, clo[0]], clo[1][0], clo[1][1][0], clo[1][1][1][0]
    else:
        s, e, c, d = None, [lvar, clo[1][0]], clo[0], [[s[1][1], [e, [c, None]]], d]

cdef _TAPP_():
    global s, e, c, d
    cdef int N, i
    cdef str hd
    cdef list clo, lvar
    clo, lvar = s[0], s[1][0]
    hd, clo = clo
    if hd == 'primitive':
        s = [clo[0]( * lvar), s[1][1]] if lvar is not None else [clo[0](), s[1][1]]
    elif hd == 'continuation':
        s, e, c, d = [lvar[0], clo[0]], clo[1][0], clo[1][1][0], clo[1][1][1][0]
        #s, e, c, d = [lvar, clo[0]], clo[1][0], clo[1][1][0], clo[1][1][1][0]
    else:
        s, e, c = s[1][1], [lvar, clo[1][0]], clo[0]

#cdef _APPCC_():
#    global s, e, c, d
#    cdef int N, i
#    cdef str hd
#    clo, lvar = s[0], s[1][0]
#    hd, clo = clo
#    if hd == 'primitive':
#        s = [clo[0]( * lvar), s[1][1]] if lvar is not None else [clo[0](), s[1][1]]
#    elif hd == 'continuation':
#        #s, e, c, d = [lvar[0], clo[0]], clo[1][0], clo[1][1][0], clo[1][1][1][0]
#        s, e, c, d = [lvar, clo[0]], clo[1][0], clo[1][1][0], clo[1][1][1][0]
#    else:
#        s, e, c = s[1][1], [lvar, clo[1][0]], clo[0]

cdef _ARGS_():
    global s, e, c, d
    cdef int N, i
    a, N = None, c[0]
    for i in range(N):
        a, s = [s[0], a], s[1]
    s, c = [a, s], c[1]

cdef _ARGSAP_():
    global s, e, c, d
    cdef int i 
    a = list_copy(s[0])          # 浅いcopy
    s = s[1]
    for i in range(c[0] - 1):
        a, s = [s[0], a], s[1]
    s, c = [a, s], c[1]

cdef _RTN_():
    global s, e, c, d
    cdef list save_0, save_1
    save_0, save_1 = d[0]
    s, e, c, d = [s[0], save_0], save_1[0], save_1[1][0], d[1]
    #s, e, c, d = [s[0], d[0][0]], d[0][1][0], d[0][1][1][0], d[1]

cdef _SEL_():
    global s, e, c, d
    if not (s[0] is False):
        s, c, d = s[1], c[0], [c[1][1], d]
    else:
        s, c, d = s[1], c[1][0], [c[1][1], d]

cdef _SELR_():
    global s, e, c, d
    if not (s[0] is False):
        s, c = s[1], c[0]
    else:
        s, c = s[1], c[1][0]

cdef _JOIN_():
    global s, e, c, d
    #c, d = d[0], d[1]
    c, d = d

cdef _LSET_():
    global s, e, c, d
    cdef list pos
    pos = c[0]
    set_lvar(e, pos[0], pos[1], s[0])
    c = c[1]

cdef _GSET_():
    global s, e, c, d
    #set_gvar(c[0], s[0])
    GL[c[0]] = s[0]
    c = c[1]

cdef _DEF_():
    global s, e, c, d
    sym = c[0]
    #if len(c)>= 3:              # option
    #    val = s[0]              # option
    #    if not isa(val, Vector) and isa(val, list) and val[0] == 'closue':
    #        val.append(c[2])        # optional source code attatch
    #        GL[sym] = val
    #else:GL[sym] = s[0]
    GL[sym] = s[0]
    s, c = [sym, s[1]], c[1]

cdef _DEFM_():
    global s, e, c, d
    sym = c[0]
    GL[sym] = ['macro', s[0]]
    s, c = [sym, s[1]], c[1]

cdef _LDF_():
    global s, e, c, d
    s, c = [['closue', [c[0], [e, None]]], s], c[1]

cdef _LDCT_():
    global s, e, c, d
    s, c = [['continuation', [s, [e, [c[0], [d, None]]]]], s], c[1]

cdef _POP_():
    global s, e, c, d
    s = s[1]
#
# _ADD_以下_DEC_まではなくてもよい
# op codeを直接実行することで高速化を図っている
# コンパイル時に命令が確定してる必要があるので
# 変数として高階関数等に渡される場合には適用されない
# ※pythonのdictionaryは高速なのでprimitive関数に書いた場合
#   との速度差はたいして大きくない
#
cdef _ADD_():
    global s, e, c, d
    ##s[1][0] = s[1][0] + s[0]   # call/cc等でsレジスタの値をwatchしている場合
    ##s = s[1]                   # 左記実装では値が更新されない
    #s[0] += s[1][0]             # この実装では順序が逆
    #s[1]=s[1][1]
    s[0] = s[1][0]+s[0]
    s[1]=s[1][1]
cdef _SUB_():
    global s, e, c, d
    #s[1][0] = s[1][0] - s[0]
    #s = s[1]
    s[0]=s[1][0]-s[0]
    s[1]=s[1][1]
cdef _MUL_():
    global s, e, c, d
    #s[1][0] = s[1][0] * s[0]
    #s = s[1]
    s[0]=s[1][0]*s[0]
    s[1]=s[1][1]
cdef _EQ_():
    global s, e, c, d
    #s[1][0] = (s[1][0] == s[0])
    #s = s[1]
    #if isa(s[0], (int, long, float, complex, Fraction)) and isa(s[1][0], (int, long, float, complex, Fraction)):
    s[0] = <bint>(s[1][0] == s[0])
    s[1] = s[1][1]
    #else:
    #    print s[0], s[1][0]
    #    raise ValueError()
cdef _DIV_():
    global s, e, c, d
    #s[1][0] = s[1][0] / Fraction(s[0]) if type(s[0]) == int else s[1][0]/s[0]
    #s = s[1]
    s[0] = s[1][0] / Fraction(s[0]) if type(s[0]) == int else s[1][0]/s[0]
    s[1] = s[1][1]
cdef _SEQ_():
    global s, e, c, d
    #s[1][0] = <bint>(s[1][0] <= s[0])
    #s = s[1]
    s[0] = <bint>(s[1][0] <= s[0])
    s[1] = s[1][1]
cdef _GEQ_():
    global s, e, c, d
    #s[1][0] = <bint>(s[1][0] >= s[0])
    #s = s[1]
    s[0] = <bint>(s[1][0] >= s[0])
    s[1] = s[1][1]
cdef _ST_():
    global s, e, c, d
    #s[1][0] = <bint>(s[1][0] < s[0])
    #s = s[1]
    s[0] = <bint>(s[1][0] < s[0])
    s[1] = s[1][1]
cdef _GT_():
    global s, e, c, d
    #s[1][0] = <bint>(s[1][0] > s[0])
    #s = s[1]
    s[0] = <bint>(s[1][0] > s[0])
    s[1] = s[1][1]
cdef _NEQ_():
    global s, e, c, d
    #s[1][0] = <bint>(s[1][0] != s[0])
    #s = s[1]
    s[0] = <bint>(s[1][0] != s[0])
    s[1] = s[1][1]
cdef _ZEQ_():
    global s, e, c, d
    s[0] = <bint>(s[0] == 0)
cdef _NULL_():
    global s, e, c, d
    s[0] = <bint>(s[0] is None)
cdef _CAR_():
    global s, e, c, d
    s[0] = s[0][0]
cdef _CDR_():
    global s, e, c, d
    s[0] = s[0][1]
cdef _CONS_():
    global s, e, c, d
    #s[1][0] = [s[1][0], s[0]]
    #s = s[1]
    s[0] = [s[1][0], s[0]]
    s[1] = s[1][1]
cdef _ISPAIR_():
    global s, e, c, d
    s[0] = (type(s[0]) == list )
cdef _INC_():
    global s, e, c, d
    #s[0] += 1
    # incは整数演算のみに対応とした
    s[0] = <int>s[0] + 1
cdef _DEC_():
    global s, e, c, d
    #s[0] -= 1
    # decは整数演算のみに対応とした
    s[0] = <int>s[0]  - 1
cdef _2TIMES_():
    global s,e,c,d
    s[0] = <int>s[0] * 2
cdef _STOP_():
    global s, e, c, d
    #global GL
    #GL['___'] = GL['__']
    #GL['__'] = GL['_']
    #GL['_'] = s[0]          # 直前の結果が_で参照できる
    return s[0]

VM_CODE = {
LD:     _LD_,   LDC:   _LDC_,   LDG:    _LDG_,      CALL:   _CALL_, TCALL:  _TCALL_,    APP:    _APP_,  TAPP:   _TAPP_, 
ARGS:   _ARGS_, ARGSAP:_ARGSAP_,RTN:    _RTN_,      SEL:    _SEL_,  SELR:   _SELR_,     JOIN:   _JOIN_, LSET:   _LSET_,
GSET:   _GSET_, DEF_:  _DEF_,   DEFM:   _DEFM_,     LDF:    _LDF_,  LDCT:   _LDCT_,     POP:    _POP_,  STOP:   _STOP_, 
ADD:    _ADD_,  SUB:   _SUB_ ,  MUL:    _MUL_,      DIV:    _DIV_,  EQ:     _EQ_,       GEQ:    _GEQ_,  SEQ:    _SEQ_, 
NEQ:    _NEQ_,  ZEQ:    _ZEQ_,  ISPAIR: _ISPAIR_,   GT:     _GT_,   ST:     _ST_,       _CAR:   _CAR_,  _CDR:   _CDR_,  CALLP:  _CALLP_,  
_CONS:  _CONS_, INC:    _INC_,  DEC:    _DEC_,      NULL_:  _NULL_, CALLG:  _CALLG_,    TCALLG: _TCALLG_,   _2TIMES: _2TIMES_,  CALLF:  _CALLF_, TCALLF: _TCALLF_#, APPCC:   _APPCC_
}

###
### vm non-recursion
###

cpdef vm(list S, list E, list C, list D):
    """ s:スタックレジスタ
        e:環境レジスタ
        c:コードレジスタ
        d:ダンプダンプ多
    """
    global s, e, c, d
    dump = (s, e, c, d)
    s, e, c, d = S, E, C, D


    #cdef int op       # pyx
    cdef int n, m, count = 0  # pyx
    cdef bint DBG_VM_FLG #= GL['%debug-vm']
    v = GL['%debug-vm']
    if isa(v, tuple):
        n, m = v
        DBG_VM_FLG = True
    elif v is True:
        n, m = 0, 10000000
        DBG_VM_FLG = True
    elif v is False:
        DBG_VM_FLG = False
    while True:
        if DBG_VM_FLG and count >= n and count <= m:
            #print "\ncount :", count, "\ns :", (to_string(tolist(s)) + ' ' * 128)[:128],\
            #        "\ne :", (to_string(tolist(e)) + ' ' * 128)[:128], "\nc :", (to_string(tolist(c)) + ' ' * 128)[:128], "\nd :", (to_string(tolist(d)) + ' ' * 128)[:128]
            print "\ncount :", count, "\ns :", to_string(tolist(s)),\
                    "\ne :", to_string(tolist(e)), "\nc :", to_string(tolist(c)), "\nd :", to_string(tolist(d))
        count += 1
        op = c[0]
        c = c[1]
        #try:
        ret_code = VM_CODE[op]()
        #except Exception as e:
        #    print "VM count:", count, 
        #    print '%s: %s' % (type(e).__name__,  e)
        #    raise RuntimeError
        if op == STOP:
            s, e, c, d = dump
            return ret_code
    pass
#
# VM utility rootine
#
cdef inline object nth(list s, int n):
    """ n番目の要素を返す
        ※意味的にはnth-carである
        終端を超えると実行時errorとなる
    """
    cdef int i
    for i in range(n):
        s = s[1]
    return s[0]                 # case of "list-ref"

cdef inline object get_lvar(list e, int i, int j):
    # iフレームのj番目の局所変数の値を求める
    if j >= 0:
        # 通常の場合はi番目のリストのj番目の要素を返す
        return nth(nth(e, i), j)
    # jがマイナスの場合はjより後ろの要素をすべて返す
    # (j以前の要素をすべて捨てる)
    return drop(nth(e, i),  - j - 1)


cdef inline set_lvar(list e, int i, int j, object val):   
    # iフレームのj番目の局所変数にvalを代入する
    cdef int ii,jj 
    cdef list p
    if j >= 0:
        # 通常の場合はi番目のリストのj番目の要素にValを代入
        # TODO:もう少しまとめる
        for ii in range(i):
            e = e[1]
        p = e[0]
        for jj in range(j):
            p = p[1]
        p[0] = val
    elif j == -1:
        #
        for ii in range(i):
            e = e[1]
        e[0] = val
    else:
        #
        for ii in range(i):
            e = e[1]
        p = e[0]
        for jj in range( - j - 2):
            p = p[1]
        p[1] = val


#cpdef inline get_gvar(sym):
#    try:
#        return GL[sym]
#    except KeyError as e:
#        raise KeyError(to_string(sym)+": unbound variable")

#cdef inline get_gvar(sym):
#    return GL[sym]

#cdef set_gvar(sym, val):
#    try:
#        cell = GL[sym]
#    except KeyError as e:
#        raise KeyError(to_string(sym)+": unbound variable")
#    GL[sym] = val

#cdef inline set_gvar(sym, val):
#    GL[sym] = val

cdef inline drop(list Llis, int n):
    """ 先頭からn個のデータを取り除いたリストを返す
        元のリストは変更されないので注意
        ※引数を"list Llist"と型定義すると、末尾がnull、ドットリスト時に
        エラーになるので注意
    """
    cdef int i
    for i in range(n):
        Llis = Llis[1]
    return Llis

#def local_vm(c,parm):
def local_vm(code,parm):
    """ get-closue-bodyで呼ばれる
        各レジスタを参照したいためsecd_vmで定義する
        ※レジスタを参照できないとcall/ccでの戻り場所がわからない
    """
    #global d
    global s,e,c,d
    #return lambda x, y: vm(None, [[x, y], parm], c, [[None ,[None, [[STOP, None], None]]], d])
    return lambda x, y: vm(None, [[x, y], parm], code, [[None ,[None, [[STOP, None], None]]], None])
    #return lambda x, y: vm(None, [[x, y], parm], code, [[s, [e, [c, None]]], d])
