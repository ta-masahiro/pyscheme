#! /usr/bin/python
#  -*- coding: utf-8  -*-
#
repl_VER = '1710212012:syntax-rules/syntax-case'
#print "\n\tRepl           :",repl_VER
# syntax-caseに対応した
# syntax-rulesに対応した
# record型の表示に対応
import sys


import time
from secd_common import GL, toLlist, tolist,String, Values, Vector
from secd_read import read, to_string, PP, Tokens, res
from secd_cp import compile
from secd_vm import vm
from secd_basefunction import get_closue_body

isa = isinstance
###
### read eval print loop
###

def repl(prompt='>'):
    global Tokens, res
    # print "\n"
    print 'Pyscheme REPL Ver:', repl_VER
    s_time = 0
    cc = 0
    GL['PROMPT'] = prompt
    while True:
        prompt = GL['PROMPT']
        if isa(prompt, String):prompt = prompt.tostring()
        cc += 1
        try:
            s = read("", 'In ['+str(cc)+']' if isa(prompt,int) else prompt )                    # S式を入手
            #s=expand(s,True)                           # 文法チェック＆前処理
            if GL['%timeit'] == True:
                s_time = time.time()
            #expr = compile(s)                          # コンパイル(case of python list)
            #expr = compile(toLlist(s))                 # コンパイル(case of Linked list)
            du = GL['%debug-vm']
            GL['%debug-vm'] = False
            if EXPAND_FLG:
                tt = expand(toLlist(s), None)           # expand syntax-rules
            else:
                tt = toLlist(s)                         # expand syntax-rules
            GL['%debug-vm'] = du
            expr = compile(tt)                          # コンパイル
            #GL['%debug-vm'] = du
            res = vm(None, None, expr, None)            # VM実行
            GL['_' + str(cc)] = res                     # _番号　で以前の値を参照可能
            GL['___'] = GL['__']
            GL['__'] = GL['_']
            GL['_'] = res                               # 直前の結果が_で参照できる
            # outputの処理
            if isa(prompt,int) :print 'Out[' + str(cc) + ']:',  # python like prompt
            # 以下VMの出力をデータタイプ別にわかりやすく表示
            # 本来ならデータタイプごとにclass化してそこで__repr__にて規定すべき
            if isa(res, Vector) and res == []:print(to_string(res))
            elif isa(res, Values):
                res = tolist_(res.data)
                for r in res:print to_string(r)
            elif res != [] and isa(res, list):
                if isa(s, list):s = ""
                if res[0] == "closue" :print '#<user-function> ' + s + ' '
                elif res[0] == "continuation" :print '#<continuation-function> ' + s + ' '
                elif res[0] == "macro":print '#<macro-function> ' + s + ' '
                elif res[0] == "primitive":print '#<primitive-function> ' + s + ' '
                else:print(to_string(tolist(res)))
            else:print(to_string(tolist(res)))
            if GL['%timeit'] == True:
                e_time = time.time() - s_time
                print("elapsed time:{0}".format(e_time))
        except KeyError as e:
            print 'KeyError: Unbound variable', e
            Tokens,res = [],""
        #except TypeError as e:
        #    print 'TypeError: variable is not a list or out of range '
        #    Tokens,res = [],""
        except Exception as e:
            print '%s: %s' % (type(e).__name__,  e)
            Tokens,res = [],""
        except KeyboardInterrupt:
            print " -- User break!!"
            Tokens, res = [],""
            continue
        pass

def repl_dbg(prompt = 'dbg>'):
    #print "\n"
    print 'Pyscheme REPL (debug version) Ver:', repl_VER
    s_time = 0
    cc = 0
    GL['PROMPT'] = prompt
    while True:
        prompt = GL['PROMPT']
        if isa(prompt, String):prompt = prompt.tostring()
        cc += 1
        s = read("", 'In ['+str(cc)+']' if isa(prompt,int) else prompt )                    # S式を入手
        #s=expand(s,True)                           # 文法チェック＆前処理
        if GL['%timeit'] == True:
            s_time = time.time()
        #expr = compile(s)                          # コンパイル(case of python list)
        #expr = compile(toLlist(s))                 # コンパイル(case of Linked list)
        if EXPAND_FLG:
            expr = compile(expand(toLlist(s), None))    # コンパイル(case of Linked list)
        else:
            expr = compile(toLlist(s))              # コンパイル(case of Linked list)
        res = vm(None, None, expr, None)            # VM実行
        GL['_' + str(cc)] = res
        GL['___'] = GL['__']
        GL['__'] = GL['_']
        GL['_'] = res                               # 直前の結果が_で参照できる
        # outputの処理
        if isa(prompt,int) :print 'Out[' + str(cc) + ']:',  # python like prompt
        print(to_string(tolist(res)))               # 結果を加工しないで出力
        print
        if GL['%timeit'] == True:
            e_time = time.time() - s_time
            print("elapsed time:{0}".format(e_time))
    pass
EXPAND_FLG = False
EOF = - 1 
DBG = False
def load(file_name, silent = True):
    """ schemeプログラムを読み込みコンパイル、実行する
    """
    global DBG
    if DBG is True :silent = False
    f = open(file_name)
    while True:
        s = read(f, '')
        if s == EOF:
            break   # EOFが返るのはファイルから読み込んだ場合のみ
        #s=expand(s) # 文法チェック＆構文拡張
        if EXPAND_FLG:expr = compile(expand(toLlist(s), None))
        else:expr = compile(toLlist(s))
        if silent:
            vm(None, None, expr, None)
        else:
            print(to_string(tolist(vm(None, None, expr, None))))
    f.close()
    return 

GL.update({
    'load'      :['primitive', [lambda x, y: load(x.tostring()) if y is None else load(x.tostring(),y[0]), None]], 
    'repl'      :['primitive', [lambda x = None, y = None: repl(x), None]], 
    'repl-debug':['primitive', [lambda x = None, y = None: repl_dbg(x), None]]
        })

if __name__ == '__main__':
    #print "\nSECD Scheme by Python\n"
    #print "\tcompiler & VM  version:", VM_VER
    #print "\tread / write   version:", READ_VER

    args=sys.argv

    from secd_sysfuncs import *
    from secd_basefunction import *
    from secd_optionalfunction import *
    GL.update(option_op)

    #from secd_bigfloat import  * 
    #GL.update(option_mp)

    load("lib_py.scm", True)                    # 基本libralyをロード
    load("secd.init", True)                     # slib initialize
    load("/usr/share/slib/require.scm", True)   # slib require

    #load("/usr/share/slib/macwork.scm", True)   # syntax-rulesを使う場合
    #load("alexpander.scm",True)                 # syntax-rulesの別な実装(高機能遅い)
    #load("/usr/share/slib/scainit.scm", True)   # synatax-caseを使う場合
    #load("syntax_pp.scm", True)                 # 別なsyntax-case;高機能だがtop levelが使えない
    #load("simple-macros.scm",True)              # 別なsyntax-caseの実装
    #load("macros-core.scm", True)               # また別なsyntax-case 遅いが機能豊富
    if 'macro:expand' in GL :
        expand = get_closue_body(GL['macro:expand'])
        EXPAND_FLG = True
    else:
        EXPAND_FLG = False
        load("define-syntax.scm", True)         # expanderを使わない簡易syntax-rules
    if len(args)>1 and args[1]=='dbg':
        DBG = True
        repl_dbg()
    else:repl()
