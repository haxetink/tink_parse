package tink.parse;

abstract Filter<A>(A->Bool) from A->Bool to A->Bool {
  
  @:arrayAccess public inline function matches(value:A) 
    return this == null || this(value);
    
  @:op(a || b) static inline function or<A>(a:Filter<A>, b:Filter<A>):Filter<A>
    return function (value) return a[value] || b[value];

  @:commutative
  @:op(a || b) static inline function orValue<A>(a:Filter<A>, b:A):Filter<A>
    return function (value) return value == b || a[value];
  
  @:from static inline function ofConst<A>(a:A):Filter<A> 
    return function (v) return v == a;
    
  @:op(a && b) static inline function and<A>(a:Filter<A>, b:Filter<A>):Filter<A>
    return function (value) return a[value] && b[value];
    
  @:op(!b) static inline function not<A>(a:Filter<A>):Filter<A>
    return function (value) return !a[value];
    
  static public inline function all<A>():Filter<A> return null;
  static public inline function none<A>():Filter<A> return function (_) return false;
}