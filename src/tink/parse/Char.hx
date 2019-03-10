package tink.parse;

private typedef Rep = 
  #if tink_parse_unicode 
    Matcher 
  #else 
    haxe.ds.Vector<Bool> 
  #end
;

abstract Char(Rep) from Rep {

  @:arrayAccess public inline function matches(char:Int)
    return #if tink_parse_unicode this.matches(char) #else this[char] #end;
  
  @:from static function ofRange(i:IntIterator):Char {
    #if tink_parse_unicode
      return new MatchRange(@:privateAccess i.min, @:privateAccess i.max);
    #else
      var ret = new Rep(256);
      for (c in i)
        ret[c] = true;//TODO: in theory we might want a bounds check here
      return ret;
    #end
  }

  @:from static function oneOf(chars:Array<Int>):Char {
    #if tink_parse_unicode
      return function (c) return chars.indexOf(c) != -1;
    #else
      var ret = new Rep(256);
      for (c in chars)
        ret[c] = true;//TODO: in theory we might want a bounds check here
      return ret;
    #end
  }

  @:from static function fromString(s:String):Char {
    #if tink_parse_unicode
      return function (c) return s.indexOf(String.fromCharCode(c)) != -1;
    #else
      var ret = new Rep(256);
      for (pos in 0...s.length)
        ret[s.charCodeAt(pos)] = true;//TODO: in theory we might want a bounds check here
      return ret;
    #end
  }

  @:from static inline function ofPredicate(p:Int->Bool):Char {
    #if tink_parse_unicode
      return new MatchPredicate(p);
    #else
      var ret = new Rep(256);
      for (c in 0...ret.length)
        ret[c] = p(c);
      return ret;
    #end
  }

  //TODO: these operations can be optimized (at the very least the ones implemented via anonymous functions)
  @:op(a || b) static inline function or(a:Char, b:Char):Char
    return function (value) return a[value] || b[value];

  @:commutative
  @:op(a || b) static inline function orCode(a:Char, b:Int):Char
    return or(a, b);

  @:commutative
  @:op(a || b) static inline function orString(a:Char, s:String):Char
    return or(a, s);

  @:from static inline function ofCode(a:Int):Char 
    return function (v) return v == a;
    
  @:op(a && b) static inline function and(a:Char, b:Char):Char
    return function (value) return a[value] && b[value];
    
  @:op(!b) static inline function not(a:Char):Char
    return function (value) return !a[value];

  static public var WHITE(default, null):Char = [9, 10, 11, 12, 13, 32];//TODO: for unicode this should include all sorts of other stuff
  
  static public var LOWER(default, null):Char = 'a'.code ... 'z'.code + 1;

  static public var UPPER(default, null):Char = 'A'.code ... 'Z'.code + 1;
    
  static public var DIGIT(default, null):Char = '0'.code ... '9'.code + 1;

}

#if tink_parse_unicode
private interface Matcher {
  function matches(char:Int):Bool;
}

private class MatchPredicate implements Matcher {
  var predicate:Int->Bool;
  public function new(predicate)
    this.predicate = predicate;

  public function matches(char)
    return predicate(char); 
}
private class MatchRange implements Matcher {
  
  var min:Int;
  var max:Int;

  public function new(min, max) {
    this.min = min;
    this.max = max;
  }

  public function matches(char)
    return char >= min && char < max;
}
#end