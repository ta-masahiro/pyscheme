#!/usr/bin/env python
#   -*- coding: utf-8 -*-
#
from secd_common import Vector, toLlist, tolist_
from secd_sysfuncs import get_python_function
isa = isinstance

cdef inline self_(x, y):return x 
cdef inline lesseq_(x, y):return x <= y[0]

cdef vmerge_sort(arr, cmp_fn, key_fn):
    """ vector用のmergr sort
    """
    cdef int mid
    if len(arr) <= 1:
        return arr

    mid = len(arr) // 2
    # ここで分割を行う
    left = arr[:mid]
    right = arr[mid:]

    # 再帰的に分割を行う
    left = vmerge_sort(left, cmp_fn, key_fn)
    right = vmerge_sort(right, cmp_fn, key_fn)

    # returnが返ってきたら、結合を行い、結合したものを次に渡す
    return vmerge(left, right, cmp_fn, key_fn)

cdef vmerge(left, right, cmp_fn, key_fn):
    merged = []
    cdef int l_i = 0
    cdef int r_i = 0

    while l_i < len(left) and r_i < len(right):
        if cmp_fn(key_fn(left[l_i],None), [key_fn(right[r_i],None),None]):
            merged.append(left[l_i])
            l_i += 1
        else:
            merged.append(right[r_i])
            r_i += 1
    # 上のwhile文のどちらかがFalseになった場合終了するため、あまりをextendする
    if l_i < len(left):
        merged.extend(left[l_i:])
    if r_i < len(right):
        merged.extend(right[r_i:])
    return Vector(merged)


cdef inline map_list_1(ls):
    a = [None, None]
    b = a
    while isa(ls, list):
        a[1] = [[ls[0], None], None]
        ls, a = ls[1], a[1]
    return b[1]


cdef inline fmap_list_1(ls):
    r = ls
    while isa(ls, list):
        ls[0] = [ls[0], None]
        ls  =  ls[1]
    return r

#cpdef inline merge_sort_1(arr, cmp_fn, key_fn):
#    """ 1st step
#        偶数番目と基数番目を比較して並べ替えた2要素のリストのリストを作る
#    """
#    base = [None,None]
#    r = base
#    while isa(arr,  list) and isa(arr[1],list):
#        if cmp_fn(key_fn(arr[0], None), [key_fn(arr[1][0],None),None]):
#            base[1] = [[arr[0],[arr[1][0],None]],None]
#        else:
#            base[1] = [[arr[1][0],[arr[0],None]],None]
#        arr, base = arr[1][1], base[1]
#    if isa(arr, list):
#        base[1]  = [[arr[0],  None],None]
#    return r[1]

#cdef inline merge_sort_n(arr, cmp_fn, key_fn):
#    """ 
#        偶数番目と基数番目を比較して並べ替えた2要素のリストのリストを作る
#    """
#    base = [None,None]
#    r = base
#    while isa(arr, list) and isa(arr[1],list):
#        base[1] = [merge(arr[0],arr[1][0], cmp_fn, key_fn), None]
#        arr, base = arr[1][1], base[1]
#    if isa(arr,list):
#        base[1] = [arr[0], None]
#    return r[1]

cdef inline merge_sort_n(arr, cmp_fn, key_fn):
    """ ソート済の隣り合うlist同士をmergeする
        (l1 l2 l3 l4 ...)  -> ( merge(l1, l2),  merge(l3, l4),  ...)
        ※arrは破壊されるので注意
    """
    r = arr
    while isa(arr, list) and isa(arr[1],list):
        arr[0] = fmerge(arr[0],arr[1][0], cmp_fn, key_fn)
        arr[1] = arr[1][1]
        arr = arr[1]
    return r

cdef inline merge_sort_n_fast(arr):
    """ ソート済の隣り合うlistをmergeする
        (l1 l2 l3 l4 ...)  -> ( l12 l34 ...)
    """
    r = arr
    while isa(arr, list) and isa(arr[1],list):
    #while isa(arr[1],list):
        #print arr
        arr[0] = fmerge_fast(arr[0],arr[1][0])
        arr[1] = arr[1][1]
        arr = arr[1]
    return r

cpdef merge_sort(arr = None, opt = None):
#cdef merge_sort(arr, cmp_fn, key_fn):
    if not isa(arr,  list):return arr
    b = map_list_1(arr)
    if opt is None:                                 # fast pass
        #return toLlist_(sorted(tolist_light(x)))    #
        while isa(b[1], list):
            merge_sort_n_fast(b)
        return b[0]
    cmp_fn = get_python_function(opt[0])
    if opt[1] is None: key_fn = self_ 
    else: key_fn = opt[1][0]

    #b = merge_sort_1(arr, cmp_fn, key_fn)
    while isa(b[1],list):
        merge_sort_n(b, cmp_fn, key_fn)
    return b[0]


cdef fmerge_sort(arr, cmp_fn, key_fn):
    if not isa(arr, list):return arr
    fmap_list_1(arr)
    while isa(arr[1], list):
        merge_sort_n(arr, cmp_fn, key_fn)
    return arr[0]


cdef merge(left, right, cmp_fn, key_fn):
    """ ソート済のリストleft、rightをマージする
        left、rightは保持される
        ※left、rightは比較関数cmp_fn、key_fnの下でソート済のこと
    """
    merged = [None, None]
    r = merged
    while isa(left,list) and isa(right,list):
        if cmp_fn(key_fn(left[0],None), [key_fn(right[0],None),None]):
            merged[1] = [left[0], None]
            merged, left = merged[1], left[1]
        else:
            merged[1] = [right[0], None]
            merged, right = merged[1], right[1]
    if isa(left,list):
        merged[1] = left
    elif isa(right,list):
        merged[1] = right
    return r[1]


cdef fmerge(left, right, cmp_fn, key_fn):
    """ ソート済のリストleft、rightをマージする
        left、rightは破壊される
        ※left、rightは比較関数cmp_fn、key_fnの下でソート済のこと
    """
    merged = [None, None]
    r = merged
    while isa(left,list) and isa(right,list):
        if cmp_fn(key_fn(left[0],None), [key_fn(right[0],None),None]):
            merged[1] = left
            merged, left = merged[1], left[1]
        else:
            merged[1] = right
            merged, right = merged[1], right[1]
    if isa(left,list):
        merged[1] = left
    elif isa(right,list):
        merged[1] = right
    return r[1]

cdef fmerge_fast(left, right):
    """ ソート済のリストleft、rightを<=でマージする
        left、rightは破壊される
        ※left、rightは比較関数<=の下でソート済のこと
    """
    merged = [None, None]
    r = merged
    while isa(left,list) and isa(right,list):
        if left[0] <= right[0]:
            merged[1] = left
            merged, left = merged[1], left[1]
        else:
            merged[1] = right
            merged, right = merged[1], right[1]
    if isa(left,list):
        merged[1] = left
    elif isa(right,list):
        merged[1] = right
    return r[1]


option_op = {
    'merge-sort'    :['primitive'   , [merge_sort   , None]], 
    'merge-sort!'   :['primitive'   , [lambda x, y = None: fmerge_sort(x, lesseq_, self_) if y is None else fmerge_sort(x, y[0], self_) if y[1] is None else fmerge_sort(x, y[0], y[1][0])          , None]], 
    'merge'         :['primitive'   , [lambda x, y : merge(x, y[0], lesseq_, self_) if y[1] is None else merge(x, y[0], y[1][0], self_) if y[1][1] is None else merge(x, y[0], y[1][0], y[1][1][0])             , None]], 
    'merge!'        :['primitive'   , [lambda x, y : fmerge(x, y[0], lesseq_, self_) if y[1] is None else fmerge(x, y[0], y[1][0], self_) if y[1][1] is None else fmerge(x, y[0], y[1][0], y[1][1][0])          , None]], 
    'vector-merge-sort'    :['primitive'   , [lambda x, y = None: vmerge_sort(x, lesseq_, self_) if y is None else vmerge_sort(x, y[0], self_) if y[1] is None else vmerge_sort(x, y[0], y[1][0])               , None]], 
    'vector-merge'         :['primitive'   , [lambda x, y: vmerge(x, y[0], lesseq_, self_) if y[1] is None else vmerge(x, y[0], y[1][0], self_) if y[1][1] is None else vmerge(x, y[0], y[1][0], y[1][1][0])    , None]], 

    }
