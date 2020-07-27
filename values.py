#!/usr/bin/env python
#   -*- coding: utf-8 -*-
#
VL_VER='1802022022:'
#print "\tvalues         :",VL_VER
#
# __eq__に対応
# 新規作成
#

from secd_common import tolist, Symbol
from secd_read import to_string

isa = isinstance

class Values(object):
    def __init__(self, args):
        self.data = args
    def __eq__(self, other):
        if isa(other, Values) and self.data  ==  other.data:return True
        return False
    def __repr__(self):
        #return Symbol('#<values> ') + to_string(tolist(self.data))
        s = Symbol('#<values:')
        L=self.data
        while isa(L,list):
            s=s+' ' + to_string(tolist(L[0]))
            L=L[1]
        return s+Symbol('>')

def call_with_values(producer, consumer):
    m_vals = producer(None, None)
    #print m_vals
    if isa(m_vals, Values): return consumer(m_vals.data[0], m_vals.data[1])
    return consumer(m_vals, None)

option_op = {
        ':call-with-values' :['primitive', [lambda x, y:call_with_values(x, y[0])   , None]], 
        #':values'           :['primitive', [lambda x = None, y = None:Symbol('*undef*') if x is None else x if y is None else Values([x, y]), None]], 
        ':values'           :['primitive', [lambda *x:Symbol('*undef*') if x is () else x[0] if x[1] is None else Values([x[0],x[1]]), None]], 
        ':values?'          :['primitive', [lambda x, y:isa(x, Values)              , None]], 
        ':values->list'     :['primitive', [lambda x = None, y = None:x.data if isa(x, Values) else x     , None]]
        }
