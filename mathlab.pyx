# -*- coding: cp1252 -*-
# -*- coding: ISO-8859-1 -*-
# Python Math Lab
# Version 0.9.3
# (c) 2007 Stefan Mueller-Stach 
# and Michael Mardaus and Tobias Nagel
# uses Python for Nokia Series 60 

from __future__ import generators
import random, math, string, operator, sys, os

##
cpdef floorsqrt(a):
    """
    Return the floor of square root of the given integer.
    """
    if a < 2 ** 59:
        return int(math.sqrt(a))
    else:
        b_old = a
        b = pow(10, log(a, 10)//2 + 1)
        while b_old > b:
            b_old, b = b, (b+a//b)//2
        return b_old

cdef floorpowerroot(n, int k):
    """
    Return the floor of k-th power root of the given integer n.
    """
    cdef int sign
    if k == 1:
        return n
    elif k == 2:
        return floorsqrt(n)
    if n < 0:
        if not (k & 1):
            raise ValueError("%d has no real %d-th root." % (n, k))
        else:
            sign = -1
            n = -n
    else:
        sign = 1

    a = floorsqrt(n)
    b = 0
    while a > b:
        c = (a + b) // 2
        if c**k > n:
            a = c
        else:
            if b == c:
                a = b
                break
            b = c
    while (a+1)**k <= n: # needed when floorsqrt(n) is already small.
        a += 1

    if sign < 0:
        a = -a
    return a

cdef vp(n, p, int k=0):
    """
    Return p-adic valuation and indivisible part of given integer.

    For example:
    >>> vp(100, 2)
    (2, 25)

    That means, 100 is 2 times divisible by 2, and the factor 25 of
    100 is indivisible by 2.

    The optional argument k will be added to the valuation.
    """
    while not (n % p):
        k += 1
        n //= p
    return (k, n)

cdef log(n, int base=2):
    """
    Return the integer part of logarithm of the given natural number
    'n' to the 'base'.  The default value for 'base' is 2.
    """
    if n < base:
        return 0
    if base == 10:
        return _log10(n)
    fit = base
    result = 1
    stock = [(result, fit)]
    while fit < n:
        next = fit ** 2
        if next <= n:
            fit = next
            result += result
            stock.append((result, fit))
        else:
            break
    else: # just fit
        return result
    stock.reverse()
    for index, power in stock:
        prefit = fit * power
        if prefit == n:
            result += index
            break
        elif prefit < n:
            fit = prefit
            result += index
    return result

cdef _log10(n):
    return len(str(n))-1

cdef binarygcd(a, b):
    """
    Return the greatest common divisor of 2 integers a and b
    by binary gcd algorithm.
    """
    if a < b:
        a, b = b, a
    if b == 0:
        return a
    a, b = b, a % b
    if b == 0:
        return a
    k = 0
    while not a&1 and not b&1:
        k += 1
        a >>= 1
        b >>= 1
    while not a&1:
        a >>= 1
    while not b&1:
        b >>= 1
    while a:
        while not a & 1:
            a >>= 1
        if abs(a) < abs(b):
            a, b = b, a
        a = (a - b) >> 1
    return b << k
##

cdef bsgs(base,arg,mod):
    if not isprime(mod):
        return 'mod is not prime'
    #if not is_primitive_root(mod,base):
    #    return 'base is not primitive root'
    #Q = int(math.floor(math.sqrt(mod)))
    Q = floorsqrt(mod)
    while Q*Q+Q+1 < mod:
        Q = Q+1
    base_inv = inverse(base,mod)
    babysteps, giantsteps = [],[]
    for i in range(Q+1):
        babysteps.append(powermod(base,Q*i,mod))
    for l in range(Q):
        giantsteps.append((arg*powermod(base_inv,l,mod))%mod)
        if giantsteps[l] in babysteps:
            k = babysteps.index(giantsteps[l])
            return k*Q+l
        
cdef prho(base,arg,mod):
    b, y, z = [], [], []
    b.append(arg)
    y.append(0)
    z.append(1)
    found = k = 0
    while not found:
        if b[k]%3 == 0:
            b.append( (b[k]*b[k])%mod )
            y.append( (2*y[k])%(mod-1) )
            z.append( (2*z[k])%(mod-1) )
        elif b[k]%3 == 1:
            b.append( (b[k]*arg)%mod )
            y.append( (y[k])%(mod-1) )
            z.append( (z[k]+1)%(mod-1) )
        else:  # entspricht b[k]= 2 mod 3
            b.append( (b[k]*base)%mod )
            y.append( (y[k]+1)%(mod-1) )
            z.append( (z[k])%(mod-1) )
        if b[k+1] in b[:k+1]:
            j = k+1
            i = b.index(b[j])
            found = 1
        k = k + 1
    
    g, c, _ = gcd(z[j]-z[i],mod-1) 
    mod2 = (mod-1)/g                
    x = (((y[i]-y[j])//g)*c) % mod2
    for l in range(g):
        if powermod(base,(x+mod2*l),mod)==arg:
            return x+mod2*l
        
cdef fastpow(base,int expo):
    binary = []
    while expo > 0:
        binary.append(expo%2)
        expo = expo / 2
    erg = 1
    for i in range(len(binary)):
        erg = erg*erg
        if binary[-(i+1)] == 1:
            erg = erg * base
    return erg

cdef pohell(base,arg,mod):
    cdef int i
    factors = factorlist(mod-1)
    #fset = set(factors)
    factorbase, factorexp = [], []
    #for i in range(len(fset)):
    #    factorbase.append(fset.pop())                
    for i in factors:
        if i not in factorbase:
            factorbase.append(i)
    for i in range(len(factorbase)): 
        factorexp.append(factors.count(factorbase[i]))
    n , gamma, alpha, x, faktoren = [], [], [], [], []
    for i in range(len(factorbase)):
        faktoren.append(fastpow(factorbase[i],factorexp[i]))
        n.append((mod-1)/faktoren[i])
        gamma.append(powermod(base,n[i],mod))
        alpha.append(powermod(arg,n[i],mod))
        x.append(bsgs(gamma[i],alpha[i],mod))
        if i == 0:
            chinesenliste = [x[i],faktoren[i]]
        elif i > 0:
            chinesenliste = chinese(x[i],faktoren[i],chinesenliste[0],chinesenliste[1])
    return chinesenliste[0]
    
            
cdef dl(base,n,modulus,int limit):
    cdef int i
    if n >= modulus:
        n = n % modulus
    if n <= 0:
        return 'impossible'
    for i in range(limit):
        if powermod(base, i, modulus)==n:
            return i
    return 'nothing found'

cdef Z_sqrt_d_gcd(a1,a2,b1,b2,d):
    a, b = Zsqrtd(a1,a2,d), Zsqrtd(b1,b2,d)
    x1,x2,y1,y2=1,0,0,1                 
    while b!=0:                            
        q=a//b                          
        x1,x2,y1,y2=x2,x1-q*x2,y2,y1-q*y2  #x1->x2,x2->x3,y1->y2,y2->y3
        a,b=b,a%b
    return a,x1,y1 # ggt>0 and  ax1+bx2=ggt

cdef rsaKeymaker(int bits=128):#besser 768
    bits = bits//2 - 1
    p = nextprime(bigrand(int(bits*math.log10(2))))
    q = nextprime(bigrand(int(bits*math.log10(2))))    
    #p = 99023845792137856240952378990238457921378562409523786747653638475659484876127856240952378674787612847565948487619
    #q = 69023845792137856240952378990238457929978562409523786747653638475659484876127856240952378674787612847565948487653
    n = p * q
    phi = (p-1)*(q-1)
    #e = 0               
    #while gcd(e,phi)[0] != 1:  
    #    e = nextprime(bigrand(int(bits*2*math.log10(2))))
    e = nextprime(bigrand(int(bits*2*math.log10(2))))
    d = inverse(e,phi)
    publicKey = (n,e)
    privateKey = (n,d)
    return (publicKey, privateKey)

cdef rsaKey_to_file(name):
    dir = 'c:'
    if not os.path.isdir(dir+'\\RSA'):
        os.mkdir(dir+'\\RSA')
    if os.path.isfile(dir+'\\RSA\\keys\\prv\\own.prv'):
        return 2
    if not os.path.isdir(dir+'\\RSA\\keys'):
        print 'Keyerstellung kann einige Minuten in Anspruch nehmen'
        pubKey, prvKey = rsaKeymaker()
        os.mkdir(dir+'\\RSA\\keys')
        pub = open(dir+'\\RSA\\keys\\'+name+'.pub','w')
        pub.write(str(pubKey[0])+'\n'+str(pubKey[1])+'\n')
        pub.close()
        os.mkdir(dir+'\\RSA\\keys\\prv')
        prv = open(dir+'\\RSA\\keys\\prv\\own.prv','w')
        prv.write(str(prvKey[0])+'\n'+str(prvKey[1])+'\n')
        prv.close()
        return 1
    else:
        return 0
    
cdef asciitostring(list):
    a = ""
    for i in range(len(list)):
        a += chr(list[i])
    return a

cdef rsaEncrypt(msg, key):
    cdef int i,char
    a=[]
    if len(msg) % 16 != 0:
            msg += " "*(16-len(msg)%16)
    while len(msg) != 0:
        tmp= ""
        for i in range(16):
            char = ord(msg[i])
            if char>=100:
                tmp += str(char)
            else:
                tmp += "0"+str(char)
        base=long(tmp)    
        a.append(to_base62(pow(base,key[1],key[0])))
        msg = msg[16:]
    return a

cdef int rsaEn_to_file(msg, recp):
    dir = 'c:\\RSA\\keys'
    if os.path.isfile(dir+'\\'+str(recp)+'.pub'):
        file = open(dir+'\\'+str(recp)+'.pub','r')
        lines = file.readlines()
        file.close()
        N = long(lines[0].replace('\n',''))
        e = long(lines[1].replace('\n',''))
        cipher = rsaEncrypt(msg,(N,e))
        if not os.path.isdir('c:\\RSA\\msg'):
            os.mkdir('c:\\RSA\\msg')
        if os.path.isfile('c:\\RSA\\msg\\msg.py'):
            os.remove('c:\\RSA\\msg\\msg.py')
        file = open('c:\\RSA\\msg\\msg.py','w')
        for i in range(len(cipher)):
            file.write(cipher[i]+'\n')
        file.close()
        return 1
    else:
        return 0
            

cdef rsaDecrypt(msg, key):
    a = ""
    for i in range(1,len(msg)+1):
        tmp = pow(from_base62(msg[-i]),key[1],key[0])
        while tmp > 0:
            a = chr(tmp%1000) + a
            tmp //= 1000
    return a

cdef rsaDe_from_file():
    cdef int i
    if os.path.isfile('c:\\RSA\\keys\\prv\\own.prv') and os.path.isfile(sys.path[0]+'\\my\\msg.py'):
        homedir = sys.path[0]+'\\my'
        key = open('c:\\RSA\\keys\\prv\\own.prv','r')
        lines = key.readlines()
        key.close()
        N = long(lines[0].replace('\n',''))
        d = long(lines[1].replace('\n',''))
        msg = open(homedir+'\\msg.py','r')
        lines2 = msg.readlines()
        msg.close()
        for i in range(len(lines2)):
            lines2[i]=lines2[i].replace('\n','')
        return rsaDecrypt(lines2,(N,d))
    else:
        return None
    

cdef to_base62(n):
    alphabet=['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H',
              'I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
              'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r',
              's','t','u','v','w','x','y','z']
    v=""
    while n > 0:
        v = (alphabet[n%62])+v
        n //= 62
    return v

cdef from_base62(v):
    cdef int i
    alphabet=['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H',
              'I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
              'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r',
              's','t','u','v','w','x','y','z']
    n = 0
    for i in range(len(v)):
        n = 62 * n + alphabet.index(v[i])
    return n
    
cpdef bigrand(n):
    cdef int i
    erg = str(random.randint(1,9))
    for i in range(n-1):
        erg += str(random.randint(0,9))
    return long(erg)    
    
cpdef factorlist(m):
    list_of_factors = []
    #sq = math.sqrt(m)
    while m%2 == 0:
        list_of_factors.append(2)
        m = m//2
        #sq = math.sqrt(m)
    d = 3
    #while  d <= sq:
    while  d*d <= m:    
        if m % d == 0:
            list_of_factors.append(d)
            m = m//d
            #sq = math.sqrt(m)
        else:
            d = d+2
    if m > 1:
            list_of_factors.append(m)
    return list(list_of_factors)

cpdef primes(int n):
    cdef int i
    if n <= 1: return []
    X = [i for i in range(3,n+1) if i%2 != 0]     
    P = [2]                                       
    #sqrt_n = math.sqrt(n)
    sqrt_n = floorsqrt(n)                         
    while len(X) > 0 and X[0] <= sqrt_n:          
        p = X[0]                                  
        P.append(p)                               
        X = [a for a in X if a%p != 0]            
    return P + X                                  

cpdef isprime(n):
         #if n % 2 == 0 and not n == 2: return (0)
         if n % 2 == 0 and not n == 2: return False
         else:
                 #limit = long(math.sqrt(n)) + 1
                 #for l in range (3, limit, 2):
                         #if n % l == 0: return False
                 #return (1)
                 return(miller_rabin(n,20))
 
cpdef nextprime(n):
         np = n + 1
         while np:
                 #if np%2!=0 or np%3!=0 or np%5!=0: 
                 #if miller_rabin(np): return (np)#if isprime(np): return (np)
                 if miller_rabin(np): return (np)
                 np = np + 1
cdef int sgn(n):
     if n > 0:
         return 1
     elif n < 0:
         return -1
     else:
         return 0
    
cdef gcd(a,b):
    x1,x2,y1,y2=1,0,0,1                 
    sgna=sgn(a)  #unnoetig? 
    sgnb=sgn(b)
    a=abs(a)    #unnoetig? 
    b=abs(b)
    while b!=0:                            
        q=a//b                          
        x1,x2,y1,y2=x2,x1-q*x2,y2,y1-q*y2  #x1->x2,x2->x3,y1->y2,y2->y3
        a,b=b,a%b
    return a,x1*sgna,y1*sgnb # ggt>0 and  ax1+bx2=ggt

cdef lcm(a,b): 
    return a//gcd(a,b)[0]*b

cdef binomial(n,k):
    out = 1
    for i in range(1,k+1):
        out = (out * (n-i+1))//i
    return out

cdef factorial(int n):
    f = 1
    for i in range(1, n+1):
        f = f*i
    return f

cdef fibonacci(int n):
    cdef int x
    a,b = 0,1
    list=[1,1]
    for x in range(1,n-1):
        a,b=b,a+b
        list.append(a+b)
    return list
    
cdef eulerphi(n):
    negative_list=[]
    for p in factorlist(n):
        if not p in negative_list:
            n = n*(p-1)//p
            negative_list.append(p) 
    return n

cdef contfrac(number, int steps=8):
    l = []
    for i in range(steps):
        i = long(math.floor(number))
        l.append(i)
        if abs(number-i) < 0.00000001:
             break
        number = 1/(number-i)
    return l

cdef legendre(a,m): 
    a=a%m
    t=1
    while a!=0:
        while a%2==0:
             a=a//2
             if m%8==3 or m%8==5:
                 t=-t
        a,m=m,a
        if a%4==3 and m%4==3:
             t=-t
        a=a%m
    if m==1:
        return t
    return 0

cdef int is_primitive_root( modulus, b = 2L ):
    less_one = modulus - 1
    list_of_factors = factorlist( modulus - 1 )
    for factor in list_of_factors:
        if pow(b, less_one//factor, modulus) == 1:
            return 0
    return 1
 
cdef primitive_root(modulus):
    b = 2
    while ( is_primitive_root( modulus, b) == 0):
        b = b+1
    return b

cdef inverse(a,b):
    if a<0:
        while a<0:
             a += b
    y = gcd(a,b)
    if y[0] != 1:
        return None
    return y[1]%b

cdef chinese(a,m,b,n):
    modulus= lcm(m,n)
    d, u, v = gcd(m,n) #um+vn=d > 0 
    if (b-a)%d == 0:  # d must divide b-a, otherwise there is no solution
        c= (b-a)//d    # c(um+vn)=cd=b-a, hence x=b-vcn=a+ucm is the solution 
        return (a+u*c*m)%modulus, modulus
    else:
        pass

cdef solve_linear(a,b,n):
    g, c, _ = gcd(a,n)                 
    if b%g != 0: return None
    return ((b//g)*c) % n            

cdef powermod(a, m, n):
    ans = 1
    apow = a
    if (m < 0 or n < 1): return None
    while m != 0:
        if m%2 != 0:
            ans = (ans * apow) % n            
        apow = (apow * apow) % n              
        m //= 2
    return ans % n

cdef sqrtmod(a, p): #p Primzahl
    a %= p
    if p == 2: return a 
    if legendre(a, p) != 1: return None
    if p%4 == 3: return powermod(a, (p+1)//4, p)

    def mul(x, y):   
        return ((x[0]*y[0] + a*y[1]*x[1]) % p, (x[0]*y[1] + x[1]*y[0]) % p)
    
    def pow(x, n):  
        ans = (1,0)
        xpow = x
        while n != 0:
           if n%2 != 0: ans = mul(ans, xpow)
           xpow = mul(xpow, xpow)
           n //= 2
        return ans

    while True:
        z = random.randrange(2,p)
        u, v = pow((1,z), (p-1)//2)
        if v != 0:
            vinv = inverse(v, p)
            for x in [-u*vinv, (1-u)*vinv, (-1-u)*vinv]:
                if (x*x)%p == a: return x%p
#           assert False, "Bug in sqrtmod."
            return None
            

cdef real_class_number(d):
    #class number of real quadratic field with discriminant d =0,1 mod 4
    counter=0
    arrayB=[] # sammelt b's
    array2C=[] # sammelt 2c's
    class_number=0
    #f=long(math.floor(math.sqrt(d)))
    f=floorsqrt(d)
    t=f*f
    if t==d:
        #print "d ist Quadrat"
        return
    u=d%4
    if u<>0 and u<>1:
    #print "d ist nicht 0,1 mod 4"
        return
    if u==1:
        e=1
    else:
        e=2
    g = f//2;
    for a in range(1,f+1):      
        for b in range(e,f+1,2):
            h = b*b - d
            i = 2*a
            j = 4*a
            if (h%j == 0) and (a<= g and f-i < b): #test reduced ! 
                c = -h//j
                done=0
                for i in range(0,counter):
                    if (b==arrayB[i]) and (2*c==array2C[i]):
                        done=1
                if (gcd(gcd(a, b)[0],c)[0] == 1) and done==0:              
                    u,v=b,2*c
                    s,r=v,u
                    k=counter 
                    while (counter==k) or (s<>v or u<>r): 
                        a=(f+u)//v
                        u=a*v-u
                        v=(d-u*u)//v         
                        arrayB.append(u)
                        array2C.append(v)
                        counter=counter+1            
                    class_number = class_number + 1
                    #print "Reduzierte Form [", class_number, "]: (", a, ",", b, ",", -c, ")"
                    #print "Zykellaenge=", counter-k
            else:
                pass
    return class_number
    

cdef imaginary_class_number(d):
# class number of imaginary quadratic field with discriminant -d =0,1 mod 4
#   d = abs(d)
    f=floorsqrt(d)
    t=f*f
    if t==d:
        #print "d ist Quadrat"
        return
    u=-d%4
    if u<>0 and u<>1:
    #print "d ist nicht 0,1 mod 4"
        return
    h = 0
    g = 1
    if d%4 == 0:
        b = 0
    else:
        b = 1
    #bound = math.sqrt(d//3)
    bound = floorsqrt(d//3)
    while b <= bound:
        q =(b**2+d)//4
        a = b
        if a <= 1:
            a = 1
        while a**2 <= q:
            if q%a == 0:
                t=q//a
                ggt=gcd(a,b)[0]
                ggt=gcd(ggt,t)[0]
                if ggt > 1:
                    g = 0
                if g == 1:
                    if a == b or a**2 == q or b == 0:
                        h = h+1
                    else:
                        h = h+2
                else:
                    g = 1
            a = a+1
        b = b+2
    return h

cdef pollard(N, m):
    for a in [2, 3]:
        x = powermod(a, m, N) - 1
        g = gcd(x, N)[0]
        if g != 1 and g != N:
            return g
    return N

cdef randcurve(m):
    if m<2: return None
#   assert m > 2, "m must be > 2."
    a = random.randrange(m)
    while gcd(4*a**3 + 27, m)[0] != 1:
        a = random.randrange(m)
    return (a, 1, m), (0,1)

cdef elliptic_curve_method(N, m, int tries=5):
    for _ in range(tries):                     
        E, P = randcurve(N)                    
        try:                                   
            Q = ellcurve_mul(E, m, P)          
        except ZeroDivisionError, x:           
            g = gcd(x[0],N)[0]                    
            if g != 1 or g != N: return g
    return N            

cdef ellcurve_add(E, P1, P2):
    a, b, p = E
    if p <=2: return None
#   assert p > 2, "p must be odd."
    if P1 == "Identity": return P2
    if P2 == "Identity": return P1
    x1, y1 = P1; x2, y2 = P2
    x1 %= p; y1 %= p; x2 %= p; y2 %= p
    if x1 == x2 and y1 == p-y2: return "Identity"
    if P1 == P2:
        if y1 == 0: return "Identity"
        lam = (3*x1**2+a) * inverse(2*y1,p)
    else:
        lam = (y1 - y2) * inverse(x1 - x2, p)
    x3 = lam**2 - x1 - x2
    y3 = -lam*x3 - y1 + lam*x1
    return (x3%p, y3%p)

cdef ellcurve_mul(E, m, P):
    if m<0: return None
#   assert m >= 0, "m must be nonnegative."
    power = P
    mP = "Identity"
    while m != 0:
        if m%2 != 0: mP = ellcurve_add(E, mP, power)
        power = ellcurve_add(E, power, power)
        m /= 2
    return mP

cdef lcm_to(B):
    ans = 1
    logB = math.log(B)
    for p in primes(B):
        ans *= p**long(logB/math.log(p))
    return ans

cdef miller_rabin(n, int num_trials=5):
    cdef int i
    if n < 0: n = -n
    if n in [2,3]: return True
    if n <= 4: return False
    m = n - 1
    k = 0
    while m%2 == 0:
        k += 1; m /= 2
    # Now n - 1 = (2**k) * m with m odd
    for i in range(num_trials):
        #ab hier
        if n > 1000000000:
            laenge = len(str(n-1))
            endlaenge = random.randint(2,laenge-1)
            a = bigrand(endlaenge)
        else:
        #fuer diese zeile
            a = random.randrange(2,n-1)                  
        apow = powermod(a, m, n)
        if not (apow in [1, n-1]):            
            some_minus_one = False
            for r in range(k-1):              
                apow = (apow**2)%n
                if apow == n-1:
                    some_minus_one = True
                    break                     
        if (apow in [1, n-1]) or some_minus_one:
            prob_prime = True
        else:
            return False
    return True    

def gen(n,c=1):
    x = 1
    while True:
        x = (x**2 + c) % n
        yield x

cdef rho(n, max=500, maxc=10):  # Pollard's Rho Method
    seqslow = gen(n) 
    seqfast = gen(n)
    trials = 0
    c = 1   
    while c < maxc:
        while trials < max:        
            xb = seqslow.next() 
            seqfast.next()
            xk = seqfast.next() 
            trials += 1
            diff = abs(xk-xb)
            if not diff:  continue
            d = gcd(diff,n)[0]
            if n>d>1:                
                return rho(d, max, maxc) + rho(n//d, max, maxc)
        c += 1
        seqslow = gen(n,c) 
        seqfast = gen(n,c)
        trials = 0
    return [n]    # failure to factor


cdef sum(v):
    if len(v) == 0:
        return 0
    return reduce(operator.add, v)

cdef ggt(a,b):
    while b !=0:
        a,b=b,a%b
    return a

cdef isInteger(n):
    return type(n) in (int, long)

class Zsqrtd:
    def __init__(self,a,b=0,d=1):
        self.a,self.b,self.d = int(a),int(b),int(d)
        if self.d >= 0 and math.ceil(math.sqrt(self.d))==math.floor(math.sqrt(self.d)):
            self.z = (a+b*math.sqrt(self.d),0)
            self.d = 1
        else:
            self.z,self.d = (a,b),d
            
    def __ne__(self,v):
        if not isinstance(v, Zsqrtd):
            self,v = self._unify(v)
        if self.z[0]!=v.z[0] or self.z[1]!=v.z[1]:
            return True
        else:
            return False
        
    def _unify(self, other):
        return (self,Zsqrtd(other,d=self.d))    
        
    def __repr__(self):
        if self.z[1] < 0:
            return '%d - %d{%d}' %(self.z[0],int(math.fabs(self.z[1])),self.d)
        elif self.z[1] > 0:
            return '%d + %d{%d}' %(self.z[0],self.z[1],self.d)
        else:
            return '%d'%self.z[0]
    
    def __neg__(self):
        return Zsqrtd(-self.z[0],-self.z[1],self.d)
    
    def conj(self):
        return Zsqrtd(self.z[0],-self.z[1],self.d)
        
    def __add__(self,v):
        if not isinstance(v, Zsqrtd):
            self,v = self._unify(v)
        if self.d == v.d or v.d==1 or self.d==1:
            return Zsqrtd(self.z[0] + v.z[0],self.z[1] + v.z[1],self.d)
        else:
            return 'Fehler'
        
    def __radd__(self,v):
        return self + v
    
    def __sub__(self,v):
        return self + (-v)
        
    def __rsub__(self,v):
        return v + (-self)
    
    def __mul__(self,v):
        if not isinstance(v, Zsqrtd):
            self,v = self._unify(v)
        if self.d == v.d or v.d==1 or self.d==1:
            return Zsqrtd(self.z[0]*v.z[0]+self.z[1]*v.z[1]*self.d,self.z[0]*v.z[1]+self.z[1]*v.z[0] ,self.d)
        else:
            return 'Fehler'
        
    def __rmul__(self,v):
        return self * v
    
    def __div__(self,v):
        if not isinstance(v, Zsqrtd):
            self,v = self._unify(v)
        if self.d == v.d or v.d==1 or self.d==1:
            numerator = self * v.conj()
            denominator = v.z[0]**2 - v.z[1]**2*v.d
            erg = numerator.z[0]//denominator
            if math.fabs(numerator.z[0]%denominator) > math.fabs(denominator//2):
                erg += 1
            erg2 = numerator.z[1]//denominator
            if math.fabs(numerator.z[1]%denominator) > math.fabs(denominator//2):
                erg2 += 1
            return Zsqrtd(erg, erg2 ,self.d)
        else:
            return 'Fehler'
        
    def __rdiv__(self,v):
        if not isinstance(v, Zsqrtd):
            self,v = self._unify(v)
        if v.d == self.d or v.d==1 or self.d==1:
            numerator = v * self.conj()
            denominator = self.z[0]**2 - self.z[1]**2*self.d
            erg = numerator.z[0]//denominator
            if math.fabs(numerator.z[0]%denominator) > math.fabs(denominator//2):
                erg += 1
            erg2 = numerator.z[1]//denominator
            if math.fabs(numerator.z[1]%denominator) > math.fabs(denominator//2):
                erg2 += 1
            return Zsqrtd(erg, erg2 ,v.d)
        else:
            return 'Fehler'
        
    def __mod__(self,v):
        if not isinstance(v, Zsqrtd):
            self,v = self._unify(v)
        if self.d == v.d or v.d==1 or self.d==1:
            return self - (self/v)*v
        else:
            return 'Fehler'
        
    def __rmod__(self,v):
        if not isinstance(v, Zsqrtd):
            self,v = self._unify(v)
        if self.d == v.d or v.d==1 or self.d==1:
            return v - (v/self)*self
        else:
            return 'Fehler'
    
    def __truediv__(self, b):   return self.__div__(b)
    def __rtruediv__(self, b):  return self.__rdiv__(b)
    def __floordiv__(self, b):  return self.__div__(b)
    def __rfloordiv__(self, b): return self.__rdiv__(b)
        
