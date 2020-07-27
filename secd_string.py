#! /usr/bin/python
#  -*- coding: utf-8  -*-
#
ST_VER = '1703181648:'
#print "\tString Class   :",ST_VER

from array import array
class String(object):
    """ pythonのstringは変更不可なので変更可能な
        文字列クラスを作る
        arrayオブジェクトで実装
    """
    def __init__(self,x):
        if isinstance(x,String):self.body=x.body
        elif isinstance(x,str) :self.body=array('c',x)
        elif isinstance(x,array):self.body=x
        else :self.body=array('c',str(x))
    def __repr__(self):
        return '"'+self.body.tostring()+'"'
    def __add__(self,y):
        return String.append(self,y)
    def __radd__(self,y):
        return String.append(y,self)
    def __mul__(self,n):
        return String(self.tostring()*n)
    def ref(self,n):
        r= self.body[n]
        #if isinstance(r,array):return String(r)
        #else:return r
        return String(r)
    def set(self,n,val):
        r=self.body[n]
        if isinstance(r,array):
            self.body[n]=array('c',val)
        elif isinstance(val,array):self.body[n]=val.tostring()
        elif isinstance(val, String):self.body[n] = val.tostring()
        else :self.body[n]=val
    def copy(self,n,m):
        return String(self.body[n:m])
    def append(self,Str):
        return String(self.body+String(Str).body)
    def __concat__(self,y):
        return String.append(self,y)
    def __getitem__(self,i):
        return String.ref(self,i)
    def __setitem__(self,i,v):
        return String.set(self,i,v)
    def len(self):
        return len(self.body)
    def __len__(self):
        return len(self.body)
    def tostring(self):
        return self.body.tostring()
    def __eq__(self,y):
        if isinstance(y,String): return String.tostring(self)==y.tostring()
        elif isinstance(y,str):return String.tostring(self)==y
        else:return False 
    def __lt__(self,y):
        if isinstance(y,String): return String.tostring(self)<y.tostring()
        elif isinstance(y,str):return String.tostring(self)<y
        else:return False 
    def __le__(self,y):
        if isinstance(y,String): return String.tostring(self)<=y.tostring()
        elif isinstance(y,str):return String.tostring(self)<=y
        else:return False 
    def __gt__(self,y):
        if isinstance(y,String): return String.tostring(self)>y.tostring()
        elif isinstance(y,str):return String.tostring(self)>y
        else:return False 
    def __ge__(self,y):
        if isinstance(y,String): return String.tostring(self)>=y.tostring()
        elif isinstance(y,str):return String.tostring(self)>=y
        else:return False 
    def upper(self):
        return String(String.tostring(self).upper())
    def lower(self):
        return String(String.tostring(self).lower())
    def count(self,y):
        return String.tostring(self).count(y.tostring())
    def find(self,y):
        return String.tostring(self).find(y.tostring())
    def split(self,y):
        return map(String,String.tostring(self).split(y.tostring()))
    def pop(self,i=-1):
        return self.body.pop(i)
    def remove(self,x):
        self.body.remove(x.tostring())
    def reverse(self):
        self.body.reverse()
    def tolist(self):
        return self.body.tolist()
    def __list__():
        return self.body.tolist()
    def insert(self,pos,val):
        self.body.insert(pos,val.tostring())
