package tink.parse;

class Char {
  
  static public var WHITE(default, null):Filter<Int> = function (c:Int) return c < 33;
  
  static public var LOWER(default, null):Filter<Int> = function (c:Int) return c >= 'a'.code && c <= 'z'.code;
  
  static public var UPPER(default, null):Filter<Int> = function (c:Int) return c >= 'A'.code && c <= 'Z'.code;
  
  static public var DIGIT(default, null):Filter<Int> = function (c:Int) return c >= '0'.code && c <= '9'.code;
    
}