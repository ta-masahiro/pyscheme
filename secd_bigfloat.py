#!/usr/bin/env python
#   -*- coding: utf-8 -*-
#
MP_VER='1703111832:'
print "\tMPmath Operatorversion:",MP_VER
#
from secd_common import toLlist, tolist, tolist_, Symbol, Vector
#from secd_basefunction import make_vector,  vector_set,  vcopy, vector_append
#from secd_read import atom,to_string
isa = isinstance

import mpmath as mp

#prec = 16
#mp.mp.dps = prec

def set_prec(n):
    mp.mp.dps = n
    return n

def is_prec():
    return mp.mp.dps

def matrix_set(x, i, j, val):
    x[i, j] = val
    return Symbol('*undef*')

option_op = {
    'prec'  : ['primitive', [lambda x, y: set_prec(x),  None]],
    'prec?' : ['primitive', [lambda : is_prec(),   None]], 
    'real'  : ['primitive', [lambda x, y: x.real    , None]], 
    'imag'  : ['primitive', [lambda x, y: x.imag    , None]], 
    'pi'    : mp.pi,
    'degree': mp.degree,  #pi / 180
    'e'     : mp.e, 
    'phi'   : mp.phi, #golden ratio = 1.61803...
    'euler' : mp.euler,   #euler's constance   =  0.577216...
    'mpf'   : ['primitive', [lambda x, y: mp.mpf(str(x)) ,     None]], 
    'mpc'   : ['primitive', [lambda x, y: mp.mpc(x, y[0]),    None]],
    #
    'sqrt'  : ['primitive', [lambda x, y: mp.sqrt(x)     ,     None]], 
    'cbrt'  : ['primitive', [lambda x, y: mp.cbrt(x)     ,     None]], 
    'root'  : ['primitive', [lambda x, y: mp.root(x, y[0])     ,     None]],# y's root 
    'unitroots'  : ['primitive', [lambda x, y: Vector(mp.unitroots(x))     ,     None]],#  
    'hypot'  : ['primitive', [lambda x, y: mp.hypot(x, y[0]),    None]],   # sqrt(x**2+y**2) 
    #
    'sin'   : ['primitive', [lambda x, y: mp.sin(x)     ,     None]], 
    'cos'   : ['primitive', [lambda x, y: mp.cos(x)     ,     None]], 
    'tan'   : ['primitive', [lambda x, y: mp.tan(x)     ,     None]], 
    'sinpi' : ['primitive', [lambda x, y: mp.sinpi(x)     ,     None]],   #sin(x * pi) 
    'cospi' : ['primitive', [lambda x, y: mp.cospi(x)     ,     None]], 
    'sec'   : ['primitive', [lambda x, y: mp.sec(x)     ,     None]], 
    'csc'   : ['primitive', [lambda x, y: mp.csc(x)     ,     None]], 
    'cot'   : ['primitive', [lambda x, y: mp.cot(x)     ,     None]], 
    'asin'  : ['primitive', [lambda x, y: mp.asin(x)     ,     None]], 
    'acos'  : ['primitive', [lambda x, y: mp.acos(x)     ,     None]], 
    'atan'  : ['primitive', [lambda x, y: mp.atan(x)     ,     None]], 
    'atan2' : ['primitive', [lambda x, y: mp.atan2(y[0], x)     ,     None]], 
    'asec'  : ['primitive', [lambda x, y: mp.asec(x)     ,     None]], 
    'acsc'  : ['primitive', [lambda x, y: mp.acsc(x)     ,     None]], 
    'acot'  : ['primitive', [lambda x, y: mp.acot(x)     ,     None]], 
    'sinc'  : ['primitive', [lambda x, y: mp.sinc(x)     ,     None]], 
    'sincpi': ['primitive', [lambda x, y: mp.sincpi(x)     ,     None]], 
    'degrees'   : ['primitive', [lambda x, y: mp.degrees(x)     ,     None]],#radian - >degree 
    'radians'   : ['primitive', [lambda x, y: mp.radians(x)     ,     None]],#degree - >radian 
    #
    'exp'   : ['primitive', [lambda x, y: mp.exp(x)     ,     None]], 
    'expj'   : ['primitive', [lambda x, y: mp.expj(x)     ,     None]], #exp(x*i) 
    'expjpi'   : ['primitive', [lambda x, y: mp.expjpi(x)     ,     None]], #exp(x*i*pi)
    'expm1'   : ['primitive', [lambda x, y: mp.expm1(x)     ,     None]], #exp(x)-1
    'power'   : ['primitive', [lambda x, y: mp.power(x, y[0])     ,     None]], 
    'powm1'   : ['primitive', [lambda x, y: mp.powm1(x, y[0])     ,     None]], #pow(x, y) - 1 
    'log'   : ['primitive', [lambda x, y: mp.log(x) if y is None else mp.log(x, y[0])     ,     None]],
    'ln'   : ['primitive', [lambda x, y: mp.ln(x)  ,     None]],
    'log10'   : ['primitive', [lambda x, y: mp.log10(x)  ,     None]],
    #
    'lambertw': ['primitive', [lambda x, y:mp.lambertw(x) if y is None else mp.lambertw(x, y[0]), None]], 
    'agm'   : ['primitive', [lambda x, y: mp.agm(x) if y is None else mp.agm(x, y[0]), None]], 
    #
    'matrix'    :['primitive'   , [lambda x, y:mp.matrix(x) if isa(x, Vector) else mp.matrix(x) if y is None else mp.matrix(x, y[0]), None]], 
    'matrix-ref':['primitive'   , [lambda x, y:x[y[0], y[1], [0]], None]], 
    'matrix-set':['primitive'   , [lambda x, y:matrix_set(x, y[0], y[1][0], y[1][1][0]), None]],
    'zeros'     :['primitive'   , [lambda x, y:mp.zeros(x), None]], 
    'ones'      :['primitive'   , [lambda x, y:mp.ones(x), None]], 
    'eye'       :['primitive'   , [lambda x, y:mp.eye(x), None]],
    'diag'      :['primitive'   , [lambda x, y:mp.diag(x), None]], 
    'randmatrix':['primitive'   , [lambda x, y:mp.randmatrix(x), None]],
    'matrix-inv':['primitive'   , [lambda x, y:x**(-1), None]], 
    'norm'      :['primitive'   , [lambda x, y:mp.norm(x) if y is None else mp.norm(x, y[0]), None]], 
    'mnorm'     :['primitive'   , [lambda x, y:mp.mnorm(x, y[0]), None]], 

}

