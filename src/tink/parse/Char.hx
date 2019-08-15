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
  
  @:from static function ofRange(i:IntIterator):Char @:privateAccess {
    #if tink_parse_unicode
      return new MatchRange(i.min, i.max);
    #else
      var ret = new Rep(0x100);
      if (i.max > 0x100)
        i = i.min ... 0x100;
      for (c in i)
        ret[c] = true;
      return ret;
    #end
  }

  @:from static function oneOf(chars:Array<Int>):Char {
    #if tink_parse_unicode
      return function (c) return chars.indexOf(c) != -1;
    #else
      var ret = new Rep(0x100);
      for (c in chars)
        ret[c] = true;//TODO: in theory we might want a bounds check here
      return ret;
    #end
  }

  static var byInt = new Map<Int, Char>();

  @:from static function ofCode(c:Int):Char 
    return switch byInt[c] {
      case null:  
        byInt[c] =
          #if tink_parse_unicode
            new MatchCode(c);
          #else
            {
              var ret = new Rep(0x100);
              ret[c] = true;//TODO: in theory we might want a bounds check here
              ret;
            }
          #end
      case v: v;
    }

  static var byString = new Map<String, Char>();
  @:from static function fromString(s:String):Char 
    return switch byString[s] {
      case null:
        byString[s] = 
          #if tink_parse_unicode
            function (c) return s.indexOf(String.fromCharCode(c)) != -1;
          #else
            {
              var ret = new Rep(0x100);
              for (pos in 0...s.length)
                ret[s.charCodeAt(pos)] = true;//TODO: in theory we might want a bounds check here
              ret;
            }
          #end
      case v: v;
    }

  @:from static inline function ofPredicate(p:Int->Bool):Char {
    #if tink_parse_unicode
      return new MatchPredicate(p);
    #else
      var ret = new Rep(0x100);
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
    
  @:op(a && b) static inline function and(a:Char, b:Char):Char
    return function (value) return a[value] && b[value];
    
  @:op(!b) static inline function not(a:Char):Char
    return function (value) return !a[value];

  static public var WHITE(default, never):Char = [9, 10, 11, 12, 13, 32];//TODO: for unicode this should include all sorts of other stuff
  
  static public var LOWER(default, never):Char = 'a'.code ... 'z'.code + 1;

  static public var UPPER(default, never):Char = 'A'.code ... 'Z'.code + 1;
    
  static public var DIGIT(default, never):Char = '0'.code ... '9'.code + 1;

  static public var LINEFEED(default, never):Char = 10;
  static public var CARRIAGE(default, never):Char = 13;

  static public var LINEBREAK(default, never):Char = LINEFEED || CARRIAGE;

  static public function Char(c:Char)
    return c;

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

private class MatchCode implements Matcher {
  var code:Int;
  public function new(code)
    this.code = code;

  public function matches(char)
    return char == code;
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