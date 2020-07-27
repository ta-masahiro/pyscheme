#!/usr/bin/env python
#   -*- coding: utf-8 -*-
#
UV_VER='17008080756:'
#print "\tuniform vector  :",UV_VER
#
# 新規作成
#
import array
from secd_common import tolist_, Vector
from secd_basefunction import vcopy, vector_append, vector_set, make_vector
isa = isinstance

def make_Nvector(prt, dim, ini = 0):
    if isa(prt, Vector):return make_vector(dim, ini)
    elif isa(prt, array.array):
        t = prt.typecode
        if t == 'b':return array.array('b', make_vector(dim, ini))
        if t == 'B':return array.array('B', make_vector(dim, ini))
        if t == 'h':return array.array('h', make_vector(dim, ini))
        if t == 'H':return array.array('H', make_vector(dim, ini))
        if t == 'l':return array.array('l', make_vector(dim, ini))
        if t == 'L':return array.array('L', make_vector(dim, ini))
        if t == 'f':return array.array('f', make_vector(dim, ini))
        if t == 'd':return array.array('d', make_vector(dim, ini))
    else:raise ValueError

option_op = {

    # make-vector       :usage (make-vector vec_type, size, init_value)
    #                   init_valuesがsize個あるvec_typeのbytevectorを作る
    ':make-vector'      : ['primitive'      , [lambda x, y:make_Nvector(x, y[0]) if y[1] is None else make_Nvector(x, y[0], y[1][0]), None]], 
    #
    's8vector'          : ['primitive'      , [lambda x=None,y=None: array.array('b',[]) if x is None else array.array('b',[x]+tolist_(y))   ,None]],
    's8vector?'         : ['primitive'      , [lambda x,y: isa(x,array.array) and x.typecode == 'b'      ,None]],
    'make-s8vector'     : ['primitive'      , [lambda x,y: array.array('b',make_vector(x) if y is None else make_vector(x,y[0])) ,None]],
    's8vector-copy'     : ['primitive'      , [lambda x, y: x[:] if y is None else (x[y[0]:] if y[1] is None else x[y[0]:y[1][0]]), None]],
    's8vector->list'    : ['primitive'      , [lambda x, y: toLlist_(x.tolist())    , None]], 
    'u8vector?'         : ['primitive'      , [lambda x=None,y=None: array.array('B',[]) if x is None else isa(x,array.array) and x.typecode == 'B'      ,None]],
    'make-u8vector'     : ['primitive'      , [lambda x,y: array.array('B',make_vector(x) if y is None else make_vector(x,y[0])) ,None]],
    's16vector'          : ['primitive'      , [lambda x=None,y=None: array.array('h',[]) if x is None else array.array('h',[x]+tolist_(y))   ,None]],
    's16vector?'         : ['primitive'      , [lambda x,y: isa(x,array.array) and x.typecode == 'h'      ,None]],
    'make-s16vector'     : ['primitive'      , [lambda x,y: array.array('h',make_vector(x) if y is None else make_vector(x,y[0])) ,None]],
    'u16vector'          : ['primitive'      , [lambda x=None,y=None: array.array('H',[]) if x is None else array.array('H',[x]+tolist_(y))   ,None]],
    'u16vector?'         : ['primitive'      , [lambda x,y: isa(x,array.array) and x.typecode == 'H'      ,None]],
    'make-u16vector'     : ['primitive'      , [lambda x,y: array.array('H',make_vector(x) if y is None else make_vector(x,y[0])) ,None]],
    's32vector'          : ['primitive'      , [lambda x = None,y = None: array.array('l', []) if x is None else array.array('l',[x]+tolist_(y))   ,None]],
    's32vector?'         : ['primitive'      , [lambda x,y: isa(x,array.array) and x.typecode == 'l'      ,None]],
    'make-s32vector'     : ['primitive'      , [lambda x,y: array.array('l',make_vector(x) if y is None else make_vector(x,y[0])) ,None]],
    'u32vector'          : ['primitive'      , [lambda x = None,y = None: array.array('L', []) if x is None else array.array('L',[x]+tolist_(y))   ,None]],
    'u32vector?'         : ['primitive'      , [lambda x,y: isa(x,array.array) and x.typecode == 'L'      ,None]],
    'make-u32vector'     : ['primitive'      , [lambda x,y: array.array('L',make_vector(x) if y is None else make_vector(x,y[0])) ,None]],
    'f32vector'          : ['primitive'      , [lambda x = None,y = None: array.array('f', []) if x is None else array.array('f',[x]+tolist_(y))   ,None]],
    'f32vector?'         : ['primitive'      , [lambda x,y: isa(x,array.array) and x.typecode == 'f'      ,None]],
    'make-f32vector'     : ['primitive'      , [lambda x,y: array.array('f',make_vector(x) if y is None else make_vector(x,y[0])) ,None]],
    'f64vector'          : ['primitive'      , [lambda x = None,y = None: array.array('d', []) if x is None else array.array('d',[x]+tolist_(y))   ,None]],
    'f64vector?'         : ['primitive'      , [lambda x,y: isa(x,array.array) and x.typecode == 'd'      ,None]],
    'make-f64vector'     : ['primitive'      , [lambda x,y: array.array('d',make_vector(x) if y is None else make_vector(x,y[0])) ,None]],
}
