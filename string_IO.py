#! /usr/bin/python
#  -*- coding: utf-8  -*-
#
SIO_VER = '170i8152029:'
#print "\tString Class   :",SIO_VERA

# srfi-6をStringIOで実装した
# 使用法:(%python-import "string_IO")
#
from StringIO import StringIO
from secd_common import String
isa = isinstance

option_op = {
        'open-input-string' : ['primitive'  , [lambda x, y: StringIO(x.tostring()) if isa(x, String) else StringIO(x) , None]], 
        'open-output-string': ['primitive'  , [lambda x = None, y = None:StringIO()  , None]], 
        'get-output-string' : ['primitive'  , [lambda x, y: String(x.getvalue()), None]], 
        'output-port?'      : ['primitive'  , [lambda x, y: (isa(x, file) and x.mode == 'w') or isa(x,StringIO)   , None]], 
        'input-port?'       : ['primitive'  , [lambda x, y: (isa(x, file) and x.mode == 'r') or isa(x,StringIO)   , None]],
        }
