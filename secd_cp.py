#! /usr/bin/python
#  -*- coding: utf-8  -*-
#
CP_VER = '1707202047:linked-List'
#print "\tCompiler       :",CP_VER
#
# beginを構文として定義した
# call, callg, tcall, tcallg命令追加
# let-macroに対応
#
from fractions import Fraction, gcd
isa = isinstance
from secd_common import GL, tolist, tolist_, no_cycle, no_cycle_, search_circl, Llen, Llist, toLlist, Symbol, Vector
from secd_vm import vm
from secd_read import to_string

Nil = -9999

###
### primitive function
###

def car(x): return x[0]             # 1'st
def cdr(x): return x[1]
def caar(x): return x[0][0]
def cadr(x): return x[1][0]         # 2'nd
def cdar(x): return x[0][1]
def cddr(x): return x[1][1]
def caaar(x): return x[0][0][0]
#def caadr(x): return x[1][0][0]
def cadar(x): return x[0][1][0]
def caddr(x): return x[1][1][0]     # 3'd
#def cdaar(x): return x[0][0][1]
def cdadr(x): return x[1][0][1]
def cddar(x): return x[0][1][1]
def cdddr(x): return x[1][1][1]
def cadddr(x): return x[1][1][1][0] # 4'th
#def cddddr(x): return x[1][1][1][1]


def cons(x, y):
    return [x, y]


def ispair(x):
    return (type(x) == list or type(x) == tuple)


def cons_star(*args):
    a = args[:: - 1]
    S = a[0]
    for s in a[1:]:
        S = [s, S]
    return S



import sys                      #search-circlでstr関数を用いて
sys.setrecursionlimit(10000)    #list->strにしているが深いと失敗するので


# parts

def isSymbol(x):
    return type(x) == Symbol


def position_var(sym, ls):
    """ 変数の位置を求める
    """
    i = 0
    while True:
        if ls == None:
            return Nil
        if isSymbol(ls):
            if sym == ls:
                return -i - 1
            return Nil
        elif sym == ls[0]:
            return i
        i += 1
        ls = ls[1]


def location(sym, ls):
    """ フレームと変数の位置を求める """
    i = 0
    while True:
        if ls is None:return Nil
        j = position_var(sym, car(ls))
        if j != Nil:
            return [i, j]
        i += 1
        ls = cdr(ls)
    pass


def is_self_eval(expr):
    """ それ自身が値を持つか否かを判定する
     　 ペアでもシンボルでもなければ良い
     　 具体的には、数値(整数、実数、分数)、文字列、ブーリアン
    """
    return isa(expr, Vector) or ((not ispair(expr)) and (not isSymbol(expr)))


def ismacro(expr):
    """ グローバルマクロかどうか判別する
    """
    # serch global macro
    try:
        val = GL[expr]
    except:
        return False
    return ispair(val) and car(val) ==  'macro'

#def ismacro_closue(exp):
#    """ マクロクロージャかどうか判別する
#    """
#    # serch global macro
#    try:
#        val = GL[expr]
#    except:
#        return False
#    return ispair(val) and (Llen(val) >= 2) and (car(val) == 'macro')　and (cadr(val)  == 'closue')
#
#def ismacro_values(exp):
#    return ismacro(expr) and not ismacro_closue(expr)



def islocalmacro(expr, env):
    # serch local macro
    #print expr,env
    for LL in reversed(env):
        try:
            val = LL[expr]
        except:continue
        return ispair(val) and car(val) == 'macro'
    return False

def get_macro_code(expr):
    return caddr(GL[expr])

def get_localmacro_code(expr, env):
    # serch local macro
    for LL in reversed(env):
        try:
            val = LL[expr]
        except:continue
        return caddr(val)
    raise UnknownError

# vm命令(op-code)の定義
# ※strを使わずに小さな整数で定義すると多少早くなる
#
#    Symbolに変換しているのはdebug命令でop-codeが"～"に囲まれて見にくくなるのを防ぐため
#    実質は不要

LDC, LDG, LD, RTN, SEL, SELR, JOIN, DEF_, DEFM, POP = \
        map(Symbol, ['ldc', 'ldg', 'ld', 'rtn', 'sel', 'selr', 'join', 'def', 'defm', 'pop'])
        #1,2,3,4,5,6,7,8,9,10
LDF, LSET, GSET, STOP, LDCT, APP, TAPP, ARGS, ARGSAP, CALL = \
        map(Symbol, ['ldf', 'lset', 'gset', 'stop', 'ldct', 'app', 'tapp', 'args', 'args-ap', 'call'])
        #11,12,13,14,15,16,17,18,19,20
ADD, SUB, MUL, DIV, EQ, GEQ, SEQ, NEQ, ZEQ, ISPAIR, TCALL , CALLP = \
        map(Symbol, ['add', 'sub', 'mul', 'div', 'eq', 'geq', 'seq', 'neq', 'zeq', 'ispair', 'tcall', 'callp'])
        #21,22,23,24,25,26,27,28,29,30,31
GT, ST, _CAR, _CDR, _CONS, INC, DEC, NULL_ , CALLG, TCALLG, _2TIMES, CALLF, TCALLF,APPCC = \
        map(Symbol, ['gt', 'st', '_car', '_cdr', '_cons', 'inc', 'dec', 'null', 'callg', 'tcallg', '2times', 'callf', 'tcallf', 'appcc'])
        #32,33,34,35,36,37,38,39, 40, 41, 42, 43, 44


COUNT = 0   # compier loop counter for debug

def compile(expr):
    global COUNT
    dump = COUNT
    COUNT = 0
    #return comp(expr, None, [STOP, None], False,[])
    r = comp(expr, None, [STOP, None], False,[])
    opt(r)
    COUNT = dump
    return r
#
# compiler main body
#

def comp(expr, env, code, tail, LL):
    global COUNT    # for dbug

    if GL['%debug-cp']:
        print "\ncount", COUNT, 
        print "\nexp :", to_string(tolist(expr)), "\nenv :", to_string(tolist(env)), \
              "\ncod :", to_string(tolist(code))
    #
    COUNT += 1  #for debug
    if is_self_eval(expr):  # number, string, #t, #f, vector
        return cons_star(LDC, expr, code)
    elif isSymbol(expr):
        pos = location(expr,  env)
        if pos == Nil:
            #if ismacro_value(expr):
            #    return compile(cdr(GL[expr]))
            return cons_star(LDG, expr, code)
        return cons_star(LD, pos, code)
    #
    op = car(expr)
    if op == 'quote':
        require(expr, Llen(expr) == 2)
        return cons_star(LDC, cadr(expr), code)
    elif op == 'if':
        require(expr, Llen(expr) == 3 or Llen(expr) == 4)
        if tail:  # tail
            t_clause = comp(caddr(expr), env, [RTN, None], True, LL)
            if cdddr(expr) == None:
                f_clause = Llist(LDC, Symbol('*undef*'), RTN)
            else:
                f_clause = comp(cadddr(expr), env, [RTN, None], True, LL)
            return comp(cadr(expr), env, cons_star(SELR, t_clause, f_clause, cdr(code)), False, LL)
        t_clause = comp(caddr(expr), env, [JOIN, None], False,LL)
        if cdddr(expr) == None:
            f_clause = Llist(LDC, Symbol('*undef*'), JOIN)
        else:
            f_clause = comp(cadddr(expr), env, [JOIN, None], False,LL)
        return comp(cadr(expr), env, cons_star(SEL, t_clause, f_clause, code), False,LL)
    elif op == 'begin':
        if cdr(expr) is None:   # (begin)は'*undef*と展開する
            body=comp([Symbol('quote'),[Symbol('*undef*'),None]], env,code,False,LL)
        else:body = comp_body(cdr(expr), env, code, LL, True)
        return body
    elif op == '_lambda':
        body = comp_body(cddr(expr), cons(cadr(expr), env), [RTN, None],LL, False)
        return cons_star(LDF, body, code)
    elif op == '_define':
        require(expr, Llen(expr) == 3)
        require(expr,isa(cadr(expr), Symbol), "can define only a symbol")
        #return comp(caddr(expr), env, cons_star(DEF_, cadr(expr), code), False,LL)
        new_code = cons_star(DEF_, cadr(expr), code)
        new_code[1].append(expr)
        return comp(caddr(expr), env, new_code, False,LL)
    elif op == '_define-macro':
        require(expr, Llen(expr) == 3)
        require(expr,isa(cadr(expr), Symbol), "can define-macro only a symbol")
        return comp(caddr(expr), env, cons_star(DEFM, cadr(expr), code), False,LL)
    elif op == 'let-macro':
        #require(expr, Llen(expr) == 3)
        # local macroをLLに登録して
        L = {}
        defs, does = cadr(expr), cddr(expr)
        #print does
        while isa(defs,list):
            _def_ = car(defs)
            _name_, m_body = car(_def_), cadr(_def_)
            L[_name_]=Llist('macro','clouse',cadr(comp(m_body,env,code,False,LL)))
            defs = cdr(defs)
        # LLの環境内で式を評価する
        LL.append(L)
        new_expr =Llist(cons_star('lambda', None, does))
        return comp(new_expr, env, code, False, LL)
    elif op == 'set!' or op == '_set!':
        require(expr, Llen(expr) == 3)
        require(expr, isa(cadr(expr), Symbol), "can set! only a symbol")
        pos = location(cadr(expr), env)
        if pos != Nil:
            return comp(caddr(expr), env, cons_star(LSET, pos, code), False,LL)
        return comp(caddr(expr), env, cons_star(GSET, cadr(expr), code), False,LL)
    elif islocalmacro(op, LL):
        new_expr = vm(None, [cdr(expr), None], get_localmacro_code(
            car(expr), LL), [Llist(None, None, [STOP, None]), None])
        return comp(new_expr, env, code, False, LL)
    elif ismacro(op):
        #print op
        new_expr = vm(None, [cdr(expr), None], get_macro_code(
            car(expr)), [Llist(None, None, [STOP, None]), None])
        return comp(new_expr, env, code, False,LL)
    #elif (op == 'call/cc') or (op == 'call-with-current-continuation'):# TODO:第1引数が関数であることをチェックする
    elif op == '_call/cc':
        return cons_star(LDCT, code, ARGS, 1, comp(expr[1][0], env, cons(APP, code), False,LL))
    elif op == 'apply': # TODO:第1引数が関数であることをチェックする
        return complis(cddr(expr), env, cons_star(ARGSAP, Llen(expr[1][1]), comp(expr[1][0], env, [APP, code], False,LL)),LL)
    #elif op == 'applycc': # TODO:第1引数が関数であることをチェックする
    #    return complis(cddr(expr), env, cons_star(ARGSAP, Llen(expr[1][1]), comp(expr[1][0], env, [APPCC, code], False,LL)),LL)
    # optional VM OP-code
    #   高速化のためよく使う命令をVMのOP-codeに設定している
    #   通常は　args <n>, ldg <func name>, appと3命令かかるところ1命令で済む
    #   ただしVM OP-codeは高階関数の因数には使用できないので注意
    #   (同じ名前の関数をグローバル環境に登録しておくこと)
    elif (op == '+' and Llen(cdr(expr)) == 2) or op == ':+':     return complis(cdr(expr), env, [ADD     , code],LL)
    elif (op == '-' and Llen(cdr(expr)) == 2) or op == ':-':     return complis(cdr(expr), env, [SUB     , code],LL)
    elif (op == '=' and Llen(cdr(expr)) == 2) or op == ':=':     return complis(cdr(expr), env, [EQ      , code],LL)
    elif (op == '!=' and Llen(cdr(expr)) == 2) or op == ':!=':    return complis(cdr(expr), env, [NEQ     , code],LL)
    elif (op == '<=' and Llen(cdr(expr)) == 2) or op == ':<=':    return complis(cdr(expr), env, [SEQ     , code],LL)
    elif (op == '>=' and Llen(cdr(expr)) == 2) or op == ':>=':    return complis(cdr(expr), env, [GEQ     , code],LL)
    elif (op == '<' and Llen(cdr(expr)) == 2) or op == ':<':     return complis(cdr(expr), env, [ST      , code],LL)
    elif (op == '>' and Llen(cdr(expr)) == 2) or op == ':>':     return complis(cdr(expr), env, [GT      , code],LL)
    elif (op == '*' and Llen(cdr(expr)) == 2) or op == ':*':     return complis(cdr(expr), env, [MUL     , code],LL)
    elif (op == '/' and Llen(cdr(expr)) == 2) or op == ':/':     return complis(cdr(expr), env, [DIV     , code],LL)
    elif op == '1+':    return complis(cdr(expr), env, [INC     , code],LL)
    elif op == '1-':    return complis(cdr(expr), env, [DEC     , code],LL)
    elif op == '2*':    return complis(cdr(expr), env, [_2TIMES , code],LL)
    elif op == 'zero?': return complis(cdr(expr), env, [ZEQ     , code],LL)
    elif op == 'car':   return complis(cdr(expr), env, [_CAR    , code],LL)
    elif op == 'cdr':   return complis(cdr(expr), env, [_CDR    , code],LL)
    elif op == 'cons':  return complis(cdr(expr), env, [_CONS   , code],LL)
    elif op == 'pair?': return complis(cdr(expr), env, [ISPAIR  , code],LL)
    elif op == 'null?': return complis(cdr(expr), env, [NULL_   , code],LL)
    elif tail:
        c_ = cons_star(ARGS, Llen(cdr(expr)),
                       comp(car(expr), env,  cons(TAPP, code), False,LL))
        #print p_, c_
        if c_[1][1][0] == LDG and c_[1][1][1][1][0]==TAPP:
            if c_[1][1][1][0] in GL and isa(GL[c_[1][1][1][0]],list) and  GL[c_[1][1][1][0]][0] == 'primitive':
                return complis(cdr(expr), env, [CALLP, [c_[1][0], [GL[c_[1][1][1][0]][1][0], code]]], LL)
            else:
                return complis(cdr(expr), env, [TCALLG, [c_[1][0], [c_[1][1][1][0], code]]], LL)
        elif c_[1][1][0] == LD and c_[1][1][1][1][0]==TAPP:
            return complis(cdr(expr), env, [TCALL, [c_[1][0], [c_[1][1][1][0], code]]], LL)
        elif c_[1][1][0] == LDF and c_[1][1][1][1][0]==TAPP:
            return complis(cdr(expr), env, [TCALLF, [c_[1][0], [c_[1][1][1][0], code]]], LL)
        else:
            return complis(cdr(expr), env, c_, LL)
        #return complis(cdr(expr), env, c_, LL)
    else:
        c_ = cons_star(ARGS, Llen(cdr(expr)),
                       comp(car(expr), env,  cons(APP, code), False,LL))
        #print p_, c_
        if c_[1][1][0] == LDG and c_[1][1][1][1][0]==APP:
            if c_[1][1][1][0] in GL and isa(GL[c_[1][1][1][0]],list) and GL[c_[1][1][1][0]][0] == 'primitive':
                #print GL[c_[1][1][1][0]],c_[1][1][1][0]
                return complis(cdr(expr), env, [CALLP, [c_[1][0], [GL[c_[1][1][1][0]][1][0], code]]], LL)
            else:
                return complis(cdr(expr), env, [CALLG, [c_[1][0], [c_[1][1][1][0], code]]], LL)
            #return complis(cdr(expr), env, [CALLG, [c_[1][0], [c_[1][1][1][0], code]]], LL)
        elif c_[1][1][0] == LD and c_[1][1][1][1][0]==APP:
            return complis(cdr(expr), env, [CALL, [c_[1][0], [c_[1][1][1][0], code]]], LL)
        elif c_[1][1][0] == LDF and c_[1][1][1][1][0]==APP:
            return complis(cdr(expr), env, [CALLF, [c_[1][0], [c_[1][1][1][0], code]]], LL)
        else:
            return complis(cdr(expr), env, c_, LL)
        #return complis(cdr(expr), env, c_, LL)

#
# code of eval parameter
#

def complis(expr, env, code,LL):
    if expr == None:
        return code
    return comp(car(expr), env, complis(cdr(expr), env, code,LL), False,LL)

#
# compiling body of lambda expr
#

def comp_body(body, env, code, LL ,is_begin = False):
    if cdr(body) == None:
        if is_begin: return comp(car(body), env, code, False, LL)   # 末尾であってもbeginから呼ばれた時は
        return comp(car(body), env, code, True,LL)                  # 末尾再帰にはしない！
    else:
        return comp(car(body), env, cons_star(POP, comp_body(cdr(body), env, code,LL,is_begin)), False,LL)


def require(x, predicate, msg="wrong length"):
    "Signal a syntax error if predicate is false."
    if not predicate: raise SyntaxError(to_string(tolist(x))+': '+msg)


def macroexpand(x, count = 1):
    global MACRO_FLG
    if count ==  -1:count = 100000000
    z = []
    while count > 0 :
        MACRO_FLG = False
        x = macroexpand_(x)
        count -= 1
        if not MACRO_FLG :return x
    return x

MACRO_FLG = False
#STOP = Symbol('stop')
#STOP =14 

def macroexpand_(x):
    """ S式中にあるmacroすべてを1回のみ展開する
    """
    global MACRO_FLG
    if isa(x, Vector) or (not isa(x, list)):# macroでないatomの場合
        return x
    if ismacro(x[0]):# macroの場合
        #
        MACRO_FLG = True
        new_expr = vm(None, [x[1], None], get_macro_code(
            x[0]), [Llist(None, None, [STOP, None]), None])
        return  new_expr
        #return comp(new_expr, env, code, False)
        #
    else:   # listであってvectorでない場合
        return map(macroexpand_,x)
        #return map_1(lambda x,y:macroexpand_(x), x)

            
GL.update({
      '%macroexpand'     :['primitive'   ,  [lambda x, y:macroexpand(x) if y is None else macroexpand(x, y[0]) ,  None]]
    })

WCD = '***'
def members(l1, l2):
    """ l2にl1が含まれた場合にはそれ以下のリストを返す
        l1にはワイルドカード *** を含んでよい
    """
    while isa(l2, list):
        res = True
        l = l1
        ll = l2
        while isa(l, list):
            if l[0] != ll[0] and l[0] != WCD:
                res = False
                break
            ll, l = ll[1], l[1]
        if res:return l2, ll
        l2 = l2[1]
    return False 

def opt(code):
    while True:
        # inc 
        r = members(code, ['ldc', [1, ['add', None]]])
        if r:
            s, e = r
            rep_code = ['inc', e]
            s[0] = rep_code[0]
            s[1] = rep_code[1]
            continue
        # dec
        r = members(code, ['ldc', [1, ['sub', None]]])
        if r:
            s, e = r
            rep_code = ['dec', e]
            s[0] = rep_code[0]
            s[1] = rep_code[1]
            continue
        break

