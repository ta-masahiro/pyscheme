#!/usr/bin/env python
#   -*- coding: utf-8 -*-
#
RD_VER='1801260110:slib record'
#print "\tMake record type:",RD_VER
#
# __eq__メソッド追加
# record_modifireのバグ修正
# 出力時にfieldのすべてを出力するように__repr__を修正した
# slibに対応したrecord
#
from secd_common import Llen, Symbol, tolist
from secd_read import to_string

isa = isinstance
cdef class record_type(object):
    cdef public object name, fields
    def __init__(self, name_,fields_):
        self.name = name_
        self.fields = fields_
    def __eq__(self, r):
        if not isa(r, record_type):return False
        if self.name  ==  r.name and self.fields  == r.fields:return True
        return False
    def __repr__(self):
        #return '#<record-type:' + str(self.name) + '>'
        s =  '#<record-type:' + str(self.name) 
        L = self.fields
        while isa(L, list):
            s = s + ' '+Symbol(L[0])
            L = L[1]
        return s + '>'

cdef class record(object):
    cdef public object rtd, data
    def __init__(self, rtd_, data_):
        if not isa(rtd_, record_type):raise ValueError
        if Llen(rtd_.fields) == Llen(data_):
            self.rtd = rtd_
            self.data = data_
        elif data_ == None:
            rf = self.rtd.fields
            data = [None, None]
            while isa(rf, list):
                data[1] =[ None, None]
                data, rf = data[1], rf[1]
            self.data = data[1]
            self.rtd = rtd_
        else: raise ValueError
    def __eq__(self, rec):
        if not isa(rec, record):return False
        if self.rtd  == rec.rtd and self.data  ==  rec.data: return True
        return False
    def __repr__(self):
        #return '#<record:' + str(self.rtd.name) + '>'
        s = '#<' + str(self.rtd.name) 
        L, D = self.rtd.fields, self.data
        while isa(L, list):
            s = s + ' '+Symbol(L[0]) + ': ' + to_string(tolist(D[0]))
            L, D = L[1], D[1]
        return s + '>'

cdef make_record_type(name,fields):
    return record_type(name,fields)

def record_constructor(rtd, default_data = None):
    def rec_cons(data ):
        if data == [None,None]:data = default_data
        return record(rtd, data)
    return ['primitive', [lambda x=None, y=None:rec_cons([x, y]), None]]

def record_predicate(rtd_):
    def rec_pred(var):
        return isa(var,record) and var.rtd == rtd_
    return ['primitive',[lambda x,y:rec_pred(x),None]]

def record_accessor(rtd, field):
    def rec_acc(obj):
        rf =  rtd.fields
        oj = obj.data
        while isa(rf, list):
            if field == rf[0]:return oj[0]
            rf, oj = rf[1], oj[1]
        raise TypeError(' Unknown field '+field)
    return ['primitive', [lambda x, y:rec_acc(x), None]]
    
def record_modifier(rtd, field):
    def rec_modi(obj, val):
        rf = rtd.fields
        oj = obj.data
        while isa(rf, list):
            if field == rf[0]:
                oj[0] = val
                return Symbol('*undef*')
        raise TypeError('Unknown field '+field)
    return ['primitive', [lambda x, y:rec_modi(x, y[0]), None]]

option_op = {
        'make-record-type'  : ['primitive'  , [lambda x, y: make_record_type(x, y[0])   , None]], 
        'record-constructor': ['primitive'  , [lambda x, y = None: record_constructor(x) if y is None else record_constructor(x, y[0]) , None]], 
        'record-accessor'   : ['primitive'  , [lambda x, y: record_accessor(x, y[0])    , None]], 
        'record-modifier'   : ['primitive'  , [lambda x, y: record_modifier(x, y[0])    , None]],
        'record-predicate'  : ['primitive'  , [lambda x, y: record_predicate(x) , None]]
        }

