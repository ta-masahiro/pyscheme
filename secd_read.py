#!/usr/bin/python
#   -*- coding: utf-8 -*- 
#
READ_VER = '1709161617:string/vector/char/uniformvector/base'
#print "\tRead           :",READ_VER
#
# #'(syntax),#`(quasisyntax)に対応
# #\; #\"の入力がうまくいかないバグ修正
# 複数行の文字列に対応(実装が汚いので見直し・要)
# 2進、8進、16進、正確数の入力に対応

EOF = -1
from secd_common import Symbol,Vector,String,Values,tolist_

_quote, _quasiquote, _unquote, _unquotesplicing, _syntax, _quasisyntax, _unsyntax = \
'quote','quasiquote', 'unquote','unquote-splicing','syntax', 'quasisyntax', 'unsyntax'

_quotes_ = [_quote, _quasiquote, _unquote, _unquotesplicing, _syntax, _quasisyntax, _unsyntax] 

_if,  _define,  _definemacro,   _set,   _lambda,  _begin, _case, _definesyntax, _caselambda, _letopt = \
'if', 'define', 'define-macro', 'set!', 'lambda', 'begin', 'case', 'define-syntax', 'case-lambda', 'let-optionals*'

quotes = {"'":Symbol(_quote), "`":Symbol(_quasiquote), ",":Symbol(_unquote), ",@":Symbol(_unquotesplicing), "#'":Symbol(_syntax), "#`":Symbol(_quasisyntax), "#,":Symbol(_unsyntax) }
U_V    = {'u8':'B','u16':'H','u32':'L','u64':'L','s8':'b','s16':'h','s32':'l','s64':'l','f32':'f','f64':'d'}
V_U    = {'B':'u8','H':'u16','L':'u32','b':'s8','h':'s16','l':'s32','f':'f32','d':'f64'}
EOF    =  -1
PP=True
def read(f,prompt=''):
    " S式をファイルfから一つ読み込み, リストにして返す"
    token = get_token(f, prompt)
    if token == EOF:return EOF
    if token == '(':return get_S(f, '(', prompt)
    if token == '[':return get_S(f, '[', prompt)
    elif token in quotes:return [quotes[token], read(f,prompt)]
    #elif token[0] == "'":return [quotes["'"],token[1:]]  # case of '+token 
    elif token == '#\\;':return String(';')
    elif token == '#\\"':return String('"')
    elif token == '#':
        v = get_token(f, prompt)
        if v  == '(': return Vector(get_S(f, 'V', prompt))  # vectorは"#("で始まり")"で終わる([]ではない！)
        elif v[0] == '\\': return getchar(f, prompt, v[1:]) # バックスラッシュがあれば文字である
        elif v[0] in ['b','o','x','e','i','d']:return get_num(f,prompt,v)#2進、8進、16進、正確数
        elif v in ['u8','u16','u32','u64','s8','s16','s32','s64','f32','f64']:  # uniform vector
            vv=get_token(f,prompt)
            if vv=='(':return array.array(U_V[v],get_S(f,'V',prompt))
            else:return atom('#'+v+vv)
        else:return atom('#' + v)#文字でもVectorでも数字でもないなら通常文字として扱う
    elif token == ')': raise SyntaxError('unexpected )')
    elif token == ']': raise SyntaxError('unexpected ]')
    else:return atom(token)

import array

def get_S(f, br, Prompt):                               # br = '('|'['|'V'
    S = []
    while True:
        prompt=' '*len(Prompt)
        token = get_token(f, prompt)
        if token == EOF:return EOF
        if token == '(':
            S = S + [get_S(f, '(', prompt)]
        elif token == '[':                          # [に対応
            S = S + [get_S(f, '[', prompt)]
        elif br == '(' and token == ')':return S
        elif br == '[' and token == ']':return S
        elif br == 'V' and token == ')':return S
        elif token in quotes:                       # case of '、"、,、,@ and test of #'
            S = S + [[quotes[token], read(f,prompt)]]
        #elif token[0] == "'":S=S+[[quotes["'"],token[1:]]]  # case of '+token 
        elif token=='#\\;':S=S+[String(';')]        # case of ";"
        elif token=='#\\"':S=S+[String('"')]        # case of '"'
        elif token == '#':                          # vector、charに対応
            v = get_token(f, prompt)                # 次を読み込んで
            if v == '(':S = S + [Vector(get_S(f, 'V', prompt))]     # '('で包まれたらvector
            elif v[0] == '\\':S = S + [getchar(f, prompt, v[1:])]            # この場合は文字である
            elif v[0] in ['b','o','x','e','i','d']:S=S+[get_num(f,prompt,v)] #2進、8進、16進、正確数
            elif v in ['u8','u16','u32','u64','s8','s16','s32','s64','f32','f64']:
                vv=get_token(f,prompt)
                if vv=='(':S=S+ [array.array(U_V[v],get_S(f,'V',prompt))]
                else:S=S+ [atom('#'+v+vv)]
            else:S = S + [atom('#' + v)]            # 文字でもVectorでも数字でもないなら通常文字
        else :
            S = S + [atom(token)]
    pass

def getchar(f, prompt, v):
    if v == 'alarm'     : return String(chr(7))
    if v == 'backspace' : return String(chr(8))
    if v == 'delete'    : return String(chr(0x7f))
    if v == 'escape'    : return String(chr(0x1b))
    if v == 'newline'   : return String(chr(0x0a))
    if v == 'null'      : return String(chr(0))
    if v == 'return'    : return String(chr(0x0d))
    if v == 'space'     : return String(' ')
    if v == 'tab'       : return String(chr(9))
    if len(v) == 1      : return String(v)
    if v == "":
        v = get_token(f, prompt)
        if v in '",\'`': return String(v)
        if v in '()[]#':return String(v)

    raise TypeError(to_string(v) +  ":wrong char")

def get_num(f,prompt,v):
    h,body=v[0],v[1:]
    if h == 'b':return int(body,2)
    if h == 'o':return int(body,8)
    if h == 'd':return int(body)
    if h == 'x':return int(body,16)
    if h == 'e':return Fraction(body)
    if h == 'i':return 1.0 * int(body)
    raise TypeError(to_string(v)+":wrong number")


from fractions import Fraction

def atom(token):
    """ 単一要素(と思われるもの)まで分解されたtokenをatomとして
        適切な"型"を与える
        boolean,string,(char;対応中),int,float,Fraction,complex
        の順番でチェックし型を設定する
    """
    global FL_FLG
    if token == '#t': return True
    elif token == '#f': return False
    #elif token[0] == '"': return token[1:-1].decode('string_escape')
    elif token[0] == '"':
        return String(token[1:-1].decode('string_escape'))  #Sreingオブジェクトを使う
    try: return int(token)
    except ValueError:
        try:return float(token)         # ここでfloatとFanctionを
        except ValueError:              # 入れ替えると実数はすべて
            try: return Fraction(token) # Fractionで表す仕様になる
            except ValueError:
                if token=='i' or token=='j':return Symbol(token)
                try: return complex(token.replace('i', 'j', 1))
                except ValueError:
                    return Symbol(token)

Tokens = []
res=""          # resは前行で処理できなかった文字列を保持
                # 複数行の文字列を処理するときに使う
def get_token(f , prompt):
    """ トークンをファイルfから読み込む
        f が空文字ならコンソール入力とみなす
        コンソール入力の場合promptをプロンプトとして出力する
    """
    global Tokens
    global res
    if Tokens != []:
        # TokensにTokenが残っていればそれを返す
        return Tokens.pop(0)
    
    while Tokens == []:
        # コメント行は入力行から省かれる
        if f == "":
            # consoleから入力
            if res!="":s,res=tokenize(res+raw_input(' '*len(prompt)))
            else:s, res = tokenize(raw_input(prompt))
        else:
            # file:fから入力
            s = f.readline() 
            s=res+s
            if not s :return EOF 
            s, res = tokenize(s)
        if s!=[]:Tokens = s
    return Tokens.pop(0)

import re

def tokenize(s):
    #tokenizer = r"""\s*(,@|[('`,)#]|"(?:[\\].|[^\\"])*"|;.*|[^\s('"`,;)#]*)(.*)"""
    #tokenizer = r"""\s*(,@|[(\['`,)\]#]|"(?:[\\].|[^\\"])*"|;.*|[^\s(\['"`,;)\]#]*)(.*)"""
    #tokenizer = r"""\s*(,@|#\\;|#\\"|[(\['`,)\]#]|"(?:[\\].|[^\\"])*"|;.*|[^\s(\['"`,;)\]#]*)(.*)"""
    #tokenizer = r"""\s*(,@|#'|#\\;|#\\"|[(\['`,)\]#]|"(?:[\\].|[^\\"])*"|;.*|[^\s(\['"`,;)\]#]*)(.*)"""
    tokenizer = r"""\s*(,@|#,|#`|#'|#\\;|#\\"|[(\['`,)\]#]|"(?:[\\].|[^\\"])*"|;.*|[^\s(\['"`,;)\]#]*)(.*)"""
    """ 1:空白 
        2:,@ 
        3:「(」「[」「'」「`」「,」「)」「]」「#」のいずれか
        4:文字列
        5:コメント
        6:空白「(」「’」「”」「`」「,」「;」「#」「)」以外の繰り返し
        7:全ての文字列
        これにより文字列は1～6のいずれかと、それ以外(7)に2分される
    """
    # r="""#\|#?([^#]|[^|]#)*\|#"""この正規表演で複数コメントにマッチするが組み合わせると動かない
    ss = []
    while s != "":
        token, s = re.match(tokenizer, s,re.DOTALL).groups()
        if token=='' and s!="" and s[0]=='"' and s[-1]!='"':
            return ss,s+'\n'
        if token != '' and token[0] != ';':ss = ss + [token]    #コメントはここでカット
        #if token != '' :ss = ss + [token]    
    return ss,""

isa = isinstance

def to_string(x):
    "Convert a Python object back into a Lisp-readable string."
    if x is None: return "()"
    elif x is True: return "#t"
    elif x is False: return "#f"
    elif isa(x, Symbol): return str(x)
    elif isa(x, str): return '"%s"' % x.encode('string_escape').replace('"',r'\"')
    #elif isa(x, String): return '"%s"' % (x.tostring()).encode('string_escape').replace('"',r'\"')
    elif isa(x, String):
        if len(x) <= 1 :    # 1文字cの場合は"c"でなく#\cと表す
            c = x.tostring()
            if      c == chr(7)     : c = 'alarm'
            elif    c == chr(8)     : c = 'backspace'
            elif    c == chr(0x7f)  : c = 'delete'
            elif    c == chr(0x1b)  : c = 'escape'
            elif    c == chr(0x0a)  : c = 'newline'
            elif    c == chr(0)     : c = 'null'
            elif    c == chr(0x0d)  : c = 'return'
            elif    c == ' '        : c = 'space'
            elif    c == chr(9)     : c = 'tab'
            return "#\\" + c
        return '"%s"' % (x.tostring()).encode('string_escape').replace('"',r'\"')
    elif isa(x, Vector):return '#('+' '.join(map(to_string, x)) + ')'
    elif isa(x, Values): return '#values'+'('+' '.join(map(to_string, tolist_(list(x))))+')'
    elif isa(x, list): return '('+' '.join(map(to_string, x))+')'
    elif isa(x, array.array): return '#'+V_U[x.typecode]+'('+' '.join(map(to_string,x))+')'
    elif isa(x, complex):
        if x.imag == 0: return str(x.real) 
        return str(x).replace('j', 'i')
    else: return str(x)

