#!/usr/bin/env python
#   -*- coding: utf-8 -*-
#
OP_VER='1711072216:oprator/math/cmath/random/mathlab/os/array '
#
#   listdir/getcwdのバグfix
#   floor-quotient,floor-remainder,truncate-quotient,truncate-remainderに対応
#
from secd_common import toLlist, tolist, tolist_, Symbol, Vector, String
from secd_basefunction import make_vector,  vector_set,  vcopy, vector_append
from secd_read import atom,to_string
option_op={}
import operator
isa=isinstance
option_op.update({
 'abs'      : ['primitive', [lambda x, y: operator.abs(x)               , None]],
 'add'      : ['primitive', [lambda x, y: operator.add(x,y[0])          , None]],
 'and_'     : ['primitive', [lambda x, y: operator.and_(x, y[0])        , None]],
 'concat'   : ['primitive', [lambda x, y: operator.concat(x,y[0])   if isa(x,str)and isa(y[0],str)else(Vector(operator.concat(x,y[0]))if isa(x,Vector)and isa(y[0],Vector) else toLlist(operator.concat(tolist_(x),tolist_(y[0]))))   , None]],
 'contains' : ['primitive', [lambda x, y: operator.contains(x,y[0]) if isa(x,Vector)or isa(x,str) else operator.contains(tolist_(x), y[0])    , None]],#y in x? for list
 'countOf'  : ['primitive', [lambda x, y: operator.countOf(x,y[0])  if isa(x,Vector) or isa(x,str) else operator.countOf (tolist_(x), y[0])   , None]],#number of times b occurs in a for list
 'delitem'  : ['primitive', [lambda x, y: operator.delitem (x, y[0])if isa(x,Vector) or isa(x,str) else operator.delitem(tolist_(x), y[0])    , None]],#delete y[0]'th item
 'delslice' : ['primitive', [lambda x, y: operator.delslice(x, y[0])   , None]],
 'div'      : ['primitive', [lambda x, y: operator.div(x, y[0])	, None]],
 'eq'       : ['primitive', [lambda x, y: operator.eq(x, y[0])	        , None]],
 'floordiv' : ['primitive', [lambda x, y: operator.floordiv(x, y[0])    , None]],
 'ge'       : ['primitive', [lambda x, y: operator.ge(x, y[0])	        , None]],
 'getitem'  : ['primitive', [lambda x, y: operator.getitem(x, y[0])	, None]],
 'getslice' : ['primitive', [lambda x, y: operator.getslice(x, y[0])	, None]],
 'gt'       : ['primitive', [lambda x, y: operator.gt(x, y[0])	        , None]],
 'iadd'     : ['primitive', [lambda x, y: operator.iadd(x, y[0])	, None]],
 'iand'     : ['primitive', [lambda x, y: operator.iand(x, y[0])	, None]],
 'iconcat'  : ['primitive', [lambda x, y: operator.iconcat(x, y[0])	, None]],
 'idiv'     : ['primitive', [lambda x, y: operator.idiv(x, y[0])	, None]],
 'ifloordiv': ['primitive', [lambda x, y: operator.ifloordiv(x, y[0])	, None]],
 'ilshift'  : ['primitive', [lambda x, y: operator.ilshift(x, y[0])	, None]],
 'imod'     : ['primitive', [lambda x, y: operator.imod(x, y[0])	, None]],
 'imul'     : ['primitive', [lambda x, y: operator.imul(x, y[0])	, None]],
 'index'    : ['primitive', [lambda x, y: operator.index(x, y[0])	, None]],
 'indexOf'  : ['primitive', [lambda x, y: operator.indexOf(x, y[0])	, None]],
 'inv'      : ['primitive', [lambda x, y: operator.inv(x)	        , None]],
 'invert'   : ['primitive', [lambda x, y: operator.invert(x)	        , None]],
 'ior'      : ['primitive', [lambda x, y: operator.ior(x, y[0])	        , None]],
 'ipow'     : ['primitive', [lambda x, y: operator.ipow(x, y[0])	, None]],
 'irepeat'  : ['primitive', [lambda x, y: operator.irepeat(x, y[0])	, None]],
 'irshift'  : ['primitive', [lambda x, y: operator.irshift(x, y[0])	, None]],
 'isCallable': ['primitive', [lambda x, y: operator.isCallable(x)       , None]],
 'isMappingType'    : ['primitive', [lambda x, y: operator.isMappingType(x)	, None]],
 'isNumberType'     : ['primitive', [lambda x, y: operator.isNumberType(x)	, None]],
 'isSequenceType'   : ['primitive', [lambda x, y: operator.isSequenceType(x)	, None]],
 'is_'      : ['primitive', [lambda x, y: operator.is_(x, y[0])	        , None]],
 'is_not'   : ['primitive', [lambda x, y: operator.is_not(x, y[0])	, None]],
 'isub'     : ['primitive', [lambda x, y: operator.isub(x, y[0])	, None]],
 'itemgetter'       : ['primitive', [lambda x, y: operator.itemgetter(x, y[0])  , None]],
 'itruediv' : ['primitive', [lambda x, y: operator.itruediv(x, y[0])	, None]],
 'ixor'     : ['primitive', [lambda x, y: operator.ixor(x, y[0])	, None]],
 'le'       : ['primitive', [lambda x, y: operator.le(x, y[0])	        , None]],
 'lshift'   : ['primitive', [lambda x, y: operator.lshift(x, y[0])	, None]],
 'lt'       : ['primitive', [lambda x, y: operator.lt(x, y[0])	        , None]],
 'methodcaller'     : ['primitive', [lambda x, y: operator.methodcaller(x, y[0]), None]],
 'mod'      : ['primitive', [lambda x, y: operator.mod(x, y[0])	        , None]],
 'mul'      : ['primitive', [lambda x, y: operator.mul(x, y[0])	        , None]],
 'ne'       : ['primitive', [lambda x, y: operator.ne(x, y[0])	        , None]],
 'neg'      : ['primitive', [lambda x, y: operator.neg(x)	        , None]],
 #'not'      : ['primitive', [lambda x, y: operator.not_(x)	        , None]],
 #'not'      : ['primitive', [lambda x, y: operator.is_not(x, False)	        , None]],
 'or_'      : ['primitive', [lambda x, y: operator.or_(x, y[0])	        , None]],
 'pos'      : ['primitive', [lambda x, y: operator.pos(x, y[0])	        , None]],
 'pow'      : ['primitive', [lambda x, y: operator.pow(x, y[0])	        , None]],
 'expt'     : ['primitive', [lambda x, y: operator.pow(x, y[0])	        , None]],
 'repeat'   : ['primitive', [lambda x, y: operator.repeat(x, y[0])if isa(x,str) else(Vector(operator.repeat(x,y[0])) if isa(x,Vector)else toLlist(operator.repeat(tolist_(x),y[0])))	, None]],
 'rshift'   : ['primitive', [lambda x, y: operator.rshift(x, y[0])	, None]],
 'sequenceIncludes': ['primitive', [lambda x, y: operator.sequenceIncludes(x, y[0])if isa(x,Vector)or isa(x,str)else operator.sequenceIncludes(tolist_(x),y[0])	        , None]],
 'setitem'  : ['primitive', [lambda x, y: operator.setitem(x, y[0],y[1][0])if isa(x,Vector)or isa(x,str) else toLlist(operator.setitem(tolist_(x),y[0],y[1][0]))	, None]],
 'setslice' : ['primitive', [lambda x, y: operator.setslice(x, y[0],y[1][0],y[1][1][0]) , None]],
 'sub'      : ['primitive', [lambda x, y: operator.sub(x, y[0])	        , None]],
 'truediv'  : ['primitive', [lambda x, y: operator.truediv(x, y[0])	, None]],
 'truth'    : ['primitive', [lambda x, y: operator.truth(x)    	        , None]],
 'xor'      : ['primitive', [lambda x, y: operator.xor(x, y[0])	        , None]]
 })

import math

option_op.update({\
 #'acos'     : ['primitive', [lambda x, y: math.acos(x)	        , None]],
 #'acosh'    : ['primitive', [lambda x, y: math.acosh(x)	        , None]],
 #'asin'     : ['primitive', [lambda x, y: math.asin(x)	        , None]],
 #'asinh'    : ['primitive', [lambda x, y: math.asinh(x)	        , None]],
 #'atan'     : ['primitive', [lambda x, y: math.atan(x)	        , None]],
 #'atan2'    : ['primitive', [lambda x, y: math.atan2(x, y[0])	, None]],
 #'atanh'    : ['primitive', [lambda x, y: math.atanh(x)	        , None]],
 'ceiling'  : ['primitive', [lambda x, y: math.ceil(x)	        , None]], # x以上の最小整数
 'copysign' : ['primitive', [lambda x, y: math.copysign(x, y[0]), None]], # return x with the sign of y
 #'cos'      : ['primitive', [lambda x, y: math.cos(x)	        , None]],
 #'cosh'     : ['primitive', [lambda x, y: math.cosh(x)	        , None]],
 'degrees'  : ['primitive', [lambda x, y: math.degrees(x)	, None]],
 'e'        : 2.718281828459045,
 'erf'      : ['primitive', [lambda x, y: math.erf(x)	        , None]],
 'erfc'     : ['primitive', [lambda x, y: math.erfc(x)	        , None]],
 #'exp'      : ['primitive', [lambda x, y: math.exp(x)	        , None]],
 'expm1'    : ['primitive', [lambda x, y: math.expm1(x, y[0])	, None]], # exp(x)-1
 'fabs'     : ['primitive', [lambda x, y: math.fabs(x)	        , None]],
 'factorial': ['primitive', [lambda x, y: math.factorial(x)	, None]],
 'floor'    : ['primitive', [lambda x, y: int(math.floor(x))	        , None]],
 'fmod'     : ['primitive', [lambda x, y: math.fmod(x, y[0])	, None]], # differ of x%y
 'frexp'    : ['primitive', [lambda x, y: toLlist(math.frexp(x)), None]], # as m*2**e
 'fsum'     : ['primitive', [lambda x, y: math.fsum(tolist(x))	, None]],
 'gamma'    : ['primitive', [lambda x, y: math.gamma(x)	        , None]],
 'hypot'    : ['primitive', [lambda x, y: math.hypot(x, y[0])	, None]], # sqrt(x*x+y*y)
 'isinf'    : ['primitive', [lambda x, y: math.isinf(x)	        , None]],
 'isnan'    : ['primitive', [lambda x, y: math.isnan(x)	        , None]],
 'ldexp'    : ['primitive', [lambda x, y: math.ldexp(x, y[0])	, None]], # x*(2**y)
 'lgamma'   : ['primitive', [lambda x, y: math.lgamma(x)	, None]],
 #'log'      : ['primitive', [lambda x, y: math.log(x)	        , None]],
 #'log10'    : ['primitive', [lambda x, y: math.log10(x)	        , None]],
 'log1p'    : ['primitive', [lambda x, y: math.log1p(x)	        , None]], # log(1+x)
 'modf'     : ['primitive', [lambda x, y: math.modf(x)	        , None]], #fractional part of x
 'pi'       : 3.141592653589793,
# 'pow'     : ['primitive', [lambda x, y: math.pow(x, y[0])     , None]],
 'radians'  : ['primitive', [lambda x, y: math.radians(x)       , None]],
 #'sin'      : ['primitive', [lambda x, y: math.sin(x)	        , None]],
 #'sinh'     : ['primitive', [lambda x, y: math.sinh(x)	        , None]],
 #'sqrt'     : ['primitive', [lambda x, y: math.sqrt(x)	        , None]],
 #'tan'      : ['primitive', [lambda x, y: math.tan(x)	        , None]],
 #'tanh'     : ['primitive', [lambda x, y: math.tanh(x)	        , None]],
 'truncate' : ['primitive', [lambda x, y: math.trunc(x) 	, None]],
 'floor-quotient'   :['primitive'   , [ lambda x,y: x // y[0]   , None]],
 'floor-remainder'  :['primitive'   , [ lambda x,y: x % y[0]    , None]],
 'truncate-quotient'    :['primitive'   , [ lambda x,y:math.trunc(operator.truediv(x,y[0]))          , None]],
 'truncate-remainder'   :['primitive'   , [ lambda x,y:x-(math.trunc(operator.truediv(x,y[0])))*y[0] , None]],


 })

import cmath

option_op.update({\
 'acos'     : ['primitive'	,[lambda x, y:cmath.acos(x)  if type(x)==complex else math.acos(x)	 , None]],
 'acosh'    : ['primitive'	,[lambda x, y:cmath.acosh(x) if type(x)==complex else math.acosh(x)      , None]],
 'asin'     : ['primitive'	,[lambda x, y:cmath.asin(x)  if type(x)==complex else math.asin(x)       , None]],
 'asinh'    : ['primitive'	,[lambda x, y:cmath.asinh(x) if type(x)==complex else math.asinh(x)      , None]],
 'atan'     : ['primitive'	,[lambda x, y:cmath.atan(x)  if type(x)==complex else math.atan(x)       , None]],
 'atanh'    : ['primitive'	,[lambda x, y:cmath.atanh(x) if type(x)==complex else math.atanh(x)      , None]],
 'cos'      : ['primitive'	,[lambda x, y:cmath.cos(x)   if type(x)==complex else math.cos(x)        , None]],
 'cosh'     : ['primitive'	,[lambda x, y:cmath.cosh(x)  if type(x)==complex else math.cosh(x)       , None]],
 'e'        : 2.718281828459045235360,
 'exp'      : ['primitive'	,[lambda x, y:cmath.exp(x)   if type(x)==complex else math.exp(x)        , None]],
 'isinf'    : ['primitive'	,[lambda x, y:cmath.isinf(x)             , None]],
 'isnan'    : ['primitive'	,[lambda x, y:cmath.isnan(x)             , None]],
 'log'      : ['primitive'	,[lambda x, y:(cmath.log(x)  if type(x)==complex else math.log(x)) if y is None else (cmath.log(x,y[0])  if (type(x)==complex or type(y[0])==complex) else math.log(x,y[0]))        , None]],
 'log10'    : ['primitive'	,[lambda x, y:cmath.log10(x) if type(x)==complex else math.log10(x)      , None]],
 'phase'    : ['primitive'	,[lambda x, y:cmath.phase(x)             , None]],                                   # angle of x
 'pi'       : 3.141592653589793238462,
 'polar'    : ['primitive'	,[lambda x, y:toLlist(cmath.polar(x))    , None]],
 'rect'     : ['primitive'	,[lambda x, y:cmath.rect(x, y[0])        , None]],
 'sin'      : ['primitive'	,[lambda x, y:cmath.sin(x)   if type(x)==complex else math.sin(x)        , None]],
 'sinh'     : ['primitive'	,[lambda x, y:cmath.sinh(x)  if type(x)==complex else math.sinh(x)       , None]],
 'sqrt'     : ['primitive'	,[lambda x, y:cmath.sqrt(x)  if (type(x)==complex)or(x<0) else math.sqrt(x)        , None]],
 'tan'      : ['primitive'	,[lambda x, y:cmath.tan(x)   if type(x)==complex else math.tan(x)        , None]],
 'tanh'     : ['primitive'	,[lambda x, y:cmath.tanh(x)  if type(x)==complex else math.tanh(x)   , None]],
 'real'     : ['primitive'      ,[lambda x, y:x.real                    , None]],
 'imag'     : ['primitive'      ,[lambda x, y:x.imag                    , None]],
 'conjugate': ['primitive'      ,[lambda x, y:x.conjugate()             , None]]\
 })

# import othes
from random import randint, random, seed
option_op.update({\
 'random-integer'   :['primitive'   ,[lambda x,y:randint(0, x - 1)      , None]],
 'random-real'      :['primitive'   ,[lambda:random()                   , None]],
 'random-seed'      :['primitive'   ,[seed                              , None]],
 'random-list'      :['primitive'   ,[lambda x,y:toLlist([randint(0,x-1) for i in range(y[0])]) , None]],
 'random-vector'    :['primitive'   ,[lambda x,y:Vector([randint(0,x-1) for i in range(y[0])])  , None]],
 })

# import mathlab
import mathlab
option_op.update({
 'floorsqrt'        :['primitive'   , [lambda x, y: mathlab.floorsqrt(x)            , None]],
 'floorpowerroot'   :['primitive'   , [lambda x, y:mathlab.floorpowerroot(x, y[0])  , None]],
 'ilog'             :['primitive'   , [lambda x, y:mathlab.log(x) if y is None else mathlab.log(x, y[0]), None]],
 'bigrand'          :['primitive'   , [lambda x, y:mathlab.bigrand(x)               , None]],
 'factorlist'       :['primitive'   , [lambda x, y:toLlist(mathlab.factorlist(x))   , None]],
 'primes'           :['primitive'   , [lambda x, y:toLlist(mathlab.primes(x))       , None]],
 'prime?'           :['primitive'   , [lambda x, y:mathlab.isprime(x)               , None]],
 'nextprime'        :['primitive'   , [lambda x, y:mathlab.nextprime(x)             , None]]
    })

import os, sys
from fractions import Fraction

cdef change_input_port(port):
    sys.stdin = port

cdef change_output_port(port):
    sys.stdout = port

cdef change_error_port(port):
    sys.stderr = port

option_op.update({
    'listdir'   :['primitive'   , [lambda x=None, y=None:toLlist(os.listdir(os.getcwd()) if x is None else os.listdir(x.tostring()))   , None]],
    'chdir'     :['primitive'   , [lambda x, y:os.chdir(x.tostring())                   , None]],
    'getcwd'    :['primitive'   , [lambda: String(os.getcwd())                                   , None]],
    'file-exists?'  :['primitive'  , [lambda x, y:os.path.exists(x.tostring())           , None]],
    'delete-file'   :['primitive'  , [lambda x,y:os.remove(x.tostring())                , None]],
    ':change-current-input-port'   :['primitive',  [lambda x, y : change_input_port(x)  , None]],
    ':change-current-output-port'  :['primitive',  [lambda x, y : change_output_port(x) , None]],
    ':change-current-error-port'   :['primitive',  [lambda x, y : change_error_port(x)  , None]],
    'current-output-port'   :['primitive'   ,[lambda: sys.stdout        ,None]],
    'current-input-port'    :['primitive'   ,[lambda: sys.stdin         ,None]],
    'current-error-port'    :['primitive'   ,[lambda: sys.stderr        ,None]],
    'standard-output-port'  :['primitive'   ,[lambda: sys.__stdout__    ,None]],
    'standard-input-port'   :['primitive'   ,[lambda: sys.__stdin__     ,None]],
    'standard-error-port'   :['primitive'   ,[lambda: sys.__stderr__    ,None]]
    })

option_op.update({
    'symbol->string'    :['primitive'   , [lambda x, y: String(x)          , None]],
    'string->symbol'    :['primitive'   , [lambda x, y: Symbol(x.tostring())       , None]],
    'string->number'    :['primitive'   , [lambda x, y: int(x.tostring(),y[0]) if (not y is None) else  atom(x.tostring()) if type(atom(x.tostring()))==int or (type(atom(x.tostring()))==long) or (type(atom(x.tostring()))==float) or (type(atom(x.tostring()))==complex) or (type(atom(x.tostring()))==Fraction) else False   , None]], # 暫定
    })

import array

option_op.update({
    'bytevector'        :['primitive'   ,[lambda x=None,y=None: array.array('B',[]) if x is None else array.array('B',[x]+tolist_(y))   ,None]],
    'bytevector?'       :['primitive'   ,[lambda x,y: isa(x,array.array)                ,None]],
    'make-bytevector'   :['primitive'   ,[lambda x,y: array.array('B',make_vector(x) if y is None else make_vector(x,y[0])) ,None]],
    'bytevector-length' :['primitive'   ,[lambda x,y: len(x)                            ,None]],
    'bytevector-u8-ref' :['primitive'   ,[lambda x,y: x[y[0]]                           ,None]],
    'bytevector-u8-set!':['primitive'   ,[lambda x,y: vector_set(x,y[0],y[1][0])                   ,None]],
    'bytevector-copy'   :['primitive'   ,[lambda x, y: x[:] if y is None else (x[y[0]:] if y[1] is None else x[y[0]:y[1][0]]), None]],
    'bytevector-copy!'  :['primitive'   ,[lambda x, y: vcopy(x,*tolist_(y)), None]],
    'bytevector-append' :['primitive'   ,[lambda x, y: vector_append(x,y)               ,None]],
    'utf8->string'      :['primitive'   ,[lambda x, y: String(x.tostring().encode('utf-8'))     ,None]],
    'string->utf8'      :['primitive'   ,[lambda x, y: array.array('B', x)     ,None]],
    'string->bytevector':['primitive'  , [lambda x, y: array.array('B', x.tostring())        , None]],
})
expt = pow
#print "\tGeneralOperator:",OP_VER
