# 途中！
# srfi-14関数をprimitiveで定義したい
#
def string_every(pred,strs):
    if memv_('', strs): return ???
    while not memv_('', strs):
        if not pred(strs[0][0],)

def string_any(pred, strs):

;述語 
string? 
      'string?'   : ['primitive'   , [lambda x, y : type(x) == String or type(x)==str   , None]],
string-null?
      'string-null?'   : ['primitive'   , [lambda x, y : x == ''   , None]],
string-every 
      'string-every':['primitive',[lambda x, y: string_every(x,y),None]],
string-any
      'string-any':['primitive',[lambda x, y: string_any(x,y),None]],

;構築子 
make-string 
      'make-string'     : ['primitive'  , [lambda x, y: String(" "*x if y is None else y[0]*x)          , None]],
string 
      'string'    : ['primitive'   , [lambda x, y : String(x if y is None else x+reduce(lambda x, y:x + y, tolist_(y)))      , None]],
string-tabulate

;リストと文字列の変換 
string->list 
      'string->list'    : ['primitive'  , [lambda x, y:toLlist(map(String,list(x.body) if y is None else list(x.body[y[0]:]) if y[1] is None else list(x.body[y[0]:y[1][0]]))), None]],
list->string
      'list->string'    : ['primitive'  , [lambda x = None, y = None: String('' if x is None else reduce(lambda a, b:a + b, tolist_(x)))               , None]],
reverse-list->string 
      'reverse-list->vector'    : ['primitive'  , [lambda x = None, y = None: Vector([]) if x is None else Vector(tolist_light(x, True)) if y is None else Vector(tolist_n(x, y[0], 10000000, True)) if y[1] is None else Vector(tolist_n(x, y[0], y[1][0], True))  , None]],
string-join

;選択 
string-length
      'string-length'       : ['primitive'   , [lambda x, y : len(x)    , None]],
string-ref
      'string-ref'      : ['primitive'  , [lambda x, y: x[y[0]]                         , None]],
string-copy
      'string-copy'     : ['primitive'  , [lambda x, y: x[:] if y is None else x[y[0]:] if y[1] is None else x[y[0]:y[1][0]], None]],
substring/shared
      'substring'       : ['primitive'  , [lambda x, y: x[y[0]:] if y[1] is None else x[y[0]:y[1][0]]   , None]],
string-copy!
      'string-copy!'    : ['primitive'  , [lambda x, y: fstring_copy(x,  *tolist(y))    , None]],
string-take 
string-take-right
string-drop 
string-drop-right
string-pad  
string-pad-right
string-trim 
string-trim-right 
string-trim-both

;変更 
string-set! 
      'string-set!'     : ['primitive'  , [lambda x, y: string_set(x,y[0],y[1][0])      , None]],
string-fill!

;比較 
string-compare 
string-compare-ci
string<>     
string=    
string<    
string>    
string<=    
string>=
string-ci<>  
string-ci= 
string-ci< 
string-ci> 
string-ci<= 
string-ci>=
string-hash  
string-hash-ci

;プレフィックスとサフィックス 
string-prefix-length    
string-suffix-length
string-prefix-length-ci 
string-suffix-length-ci

string-prefix?    
string-suffix?
string-prefix-ci? 
string-suffix-ci?

;検索 
string-index 
string-index-right
string-skip  
string-skip-right
string-count
      'string-count'        : ['primitive'   , [lambda x, y : x.count(y[0])                         , None]],
string-contains 
string-contains-ci

;アルファベットの大小文字変換 
string-titlecase  
string-upcase  
string-downcase
string-titlecase! 
string-upcase! 
string-downcase!

;反転と追加 
string-reverse 
      'string-reverse'  : ['primitive'  , [lambda x, y: x[::-1] if y is None else x[y[0]:][::-1] if y[1] is None else x[y[0]:y[1][0]][::-1], None]],
string-reverse!
      'string-reverse!' : ['primitive'  , [lambda x, y: fstring_reverse(x,y)    ,None]],
string-append
      'string-append'   : ['primitive'  , [lambda x=None, y=None: String("") if x is None else x if y is None else String(x).append(String(reduce(lambda s,t:s+t,map(lambda c:c.tostring(),tolist_(y)))))          , None]],
string-concatenate
string-concatenate/shared 
string-append/shared
string-concatenate-reverse 
string-concatenate-reverse/shared

;畳み込み、逆畳み込み、マップ 
string-map      
      ':string-map-n'   : ['primitive'  , [lambda x, y: String("".join(map(lambda *a:x(*Llist(*a)),*map(lambda c:c.tostring(), tolist_(y[0]))))),None]], 
string-map!
string-fold     
string-fold-right
string-unfold   
string-unfold-right
string-for-each 
string-for-each-index

;複製とローテート 
xsubstring 
string-xcopy!

;その他: 挿入、解析 
string-replace 
string-tokenize

;フィルタと削除 
string-filter 
string-delete

;低レベルの手続き 
string-parse-start+end
string-parse-final-start+end
let-string-start+end

check-substring-spec
substring-spec-ok?

make-kmp-restart-vector 
kmp-step string-kmp-partial-search
