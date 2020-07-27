#! /usr/bin/python
#  -*- coding: utf-8  -*-
#
SYS_FUNC_VER = '1801091834:VM linked-List'
#print "\tSystemFunction :",SYS_FUNC_VER
#
#   Stringに対応
#   %python-import
#   eoorで第2因数以降が文字列なら""を外すようにした
#   errorのバグFix
#
import importlib
import time
from secd_common import toLlist, tolist,GL,Symbol, Vector,String
from secd_read import to_string
#from secd_cp import ismacro, get_macro_code
from secd_vm import vm,local_vm

isa = isinstance

cdef debug_vm(n=None,m=None):
    if n is None and m is None:
        if isa(GL['%debug-vm'], tuple):GL['%debug-vm'] = False 
        else: GL['%debug-vm'] = not GL['%debug-vm']
    else:
        GL['%debug-vm'] = (n, m)
    return Symbol('*undef*')

cdef debug_cp():
    GL['%debug-cp'] = not GL['%debug-cp']
    return Symbol('*undef*')

cdef timeit():
    GL['%timeit'] = not GL['%timeit']
    return Symbol('*undef*')

cdef error(reason, args):
    if isa(reason,list):reason=tolist(reason)
    msg = to_string(reason) + ":"
    if not args is None:
        for arg in args:
            if isa(arg,str)or isa(args,String):msg=msg+str(arg)+' '
            else: msg = msg + to_string(arg)+" "
    raise RuntimeError(msg)

#PD=dict()

cpdef get_python_function(fn):
    if isinstance(fn,list):
        if fn[0]=='primitive':
            return fn[1][0]
        if fn[0]=='closue'  :
            return local_vm(fn[1][0],fn[1][1][0])
    raise RuntimeError('Function required in get-python-function') 


cdef python_exec(exp,opt=None):
    #global PD
    #exec(exp,globals(),PD)
    exec(exp.tostring(),globals())
    return Symbol('*undef*')

cdef make_primitive(lmd, body = None):
    if not body is None:python_exec(body)
    return ['primitive', [toLlist(eval(lmd.tostring())), None]]

cdef python_import(module):
    global GL
    m = importlib.import_module(module.tostring())
    GL.update(m.option_op)
    return Symbol('*undef*')

cdef GL_update(dict):
    global GL
    GL.update(dict)

from subprocess import check_call
cdef edit(f):
    file_name = f.tostring()
    check_call(['vim', file_name])


### グローバルリストテーブル
###
import sys
_f_type=type(GL_update),type(len)
GL.update({\
      'debug-vm'    :['primitive'   , [lambda x = None,y = None: debug_vm() if x is None else debug_vm(x, y[0])         , None]],
      'debug-cp'    :['primitive'   , [debug_cp         , None]],
      'timeit'      :['primitive'   , [timeit           , None]],
      'display'     :['primitive'   , [lambda x, y: sys.stdout.write\
                    (x if isa(x, str) else x.tostring() if isa(x,String) else to_string(tolist(x)))\
                    if y is None else (y[0].write(x.tostring() if isa(x,String) \
                    else x if isa(x, str) else to_string(tolist(x))))                      , None]],
      'display-raw' :['primitive'   , [lambda x, y: sys.stdout.write(x if isa(x, str) else to_string(x)), None]],
      'write'       :['primitive'   , [lambda x, y: sys.stdout.write(to_string(tolist(x))) if y is None \
                    else y[0].write(to_string(tolist(x)))                       , None]],
      'error'       :['primitive'   , [lambda x, y: error(x,None) if y is None else error(x,tolist(y))  , None]],
      '%function-list'  :['primitive'   , [lambda :toLlist(map(Symbol, GL.keys()))                      , None]],
      '%python-ev'  :['primitive'   , [lambda x, y: toLlist(eval(x.tostring())) , None]],
      '%python-ex'  :['primitive'   , [lambda x, y: python_exec(x,y), None]],
      '%make-primitive' :['primitive'   , [lambda x, y = None: make_primitive(x) if y is None \
                    else make_primitive(x, y[0])        , None]], 
      '%python-import'  :['primitive'   , [lambda x, y: python_import(x)        , None]], 
      '%GL-update'      :['primitive'   , [lambda x, y:GL_update(x)             , None]], 
      'current-seconds'         :['primitive'   , [lambda: int(round(time.time()       )), None]], 
      'current-milliseconds'    :['primitive'   , [lambda: int(round(time.time() * 1000)), None]],
      ':primitive?'     :['primitive'   , [lambda x, y: isa(x,_f_type)    ,None]], 
      'edit'        :['primitive'   , [lambda x, y: edit(x) , None]],
      'primitive?'  :['primitive'   , [lambda x, y: isa(x,_f_type)          ,None]],
      'get-python-function'     :['primitive'   , [lambda x, y: get_python_function(x)          ,None]],
      })

