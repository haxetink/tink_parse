package tink.parse;

using StringTools;

private class Data {
  
  public var string(default, null):String;
  public var start(default, null):Int;
  public var end(default, null):Int;
  public var length(default, null):Int;
  var representation:String;
  public inline function new(string, start, end) {
    this.string = string;
    this.start = start;
    this.end = end;
    if ((this.length = end - start) < 0) {//TODO: move this check out
      this.length = 0;
      this.end = this.start;
    }
  }
  
  public function toString() {
    if (representation == null)
      representation = string.substring(start, end);
    return representation;
  }
  
}

@:forward
abstract StringSlice(Data) from Data to Data {
  
  public function new(string:String, start, end) {
    inline function val(i:Int)
      return 
        if (i == string.length)
          i;
        else if (i < 0) 
          i % string.length + string.length;
        else
          i % string.length;
          
    this = new Data(string, val(start), val(end));
  }
  
  public inline function after(index:Int):StringSlice
    return new Data(this.string, wrap(index) + this.start, this.end);
    
  public inline function before(index:Int):StringSlice
    return new Data(this.string, this.start, this.start + clamp(index));
  
  public function clamp(index:Int) 
    return 
      if (index < 0) {
        if (-index > this.length) 0;
        else index + this.length;
      }
      else if (index > this.length) {
        this.length;
      }
      else {
        index;
      }
    
  public function wrap(index:Int):Int
    return 
        if (index < 0) 
          index + this.length;
        else index;
  
  @:arrayAccess public inline function get(index:Int):Int 
    return fastGet(wrap(index));
  
  @:arrayAccess public inline function slice(range:IntIterator):StringSlice
    return new StringSlice(this.string, wrap(@:privateAccess range.min) + this.start, clamp(@:privateAccess range.max) + this.start); 
  
  public inline function fastGet(index)
    return this.string.fastCodeAt(index + this.start);
    
  @:to public inline function toString()
    return this.toString();
  
  static var CHARS = [for (i in 0...0x80) new Data(String.fromCharCode(i), 0, 1)];
  
  @:from static public function ofString(s:String):StringSlice
    return 
      if (s == null || s == '') EMPTY;
      else if (s.length == 1)
        switch s.fastCodeAt(0) {
          case ascii if (ascii < CHARS.length): CHARS[ascii];
          default: new Data(s, 0, s.length);
        }
      else
        new Data(s, 0, s.length);
  
  static public var EMPTY(default, null):StringSlice = new Data('', 0, 0);
  
  public inline function startsWith(other:StringSlice)
    return hasSub(other);
  
  public function hasSub(other:StringSlice, at:Int = 0):Bool {
    
    at = wrap(at);
    if (at + other.length > this.length)
      return false;
    
    var a = this,
        b = (other:Data);
    return isEqual(a.string, a.start + at, other.length, b.string, b.start, b.length); 
  }
  
  public function indexOf(end:StringSlice, ?pos:Int = 0) {
    pos = wrap(pos);
    return 
      switch this.string.indexOf(end, pos + this.start) {
        case -1: -1;
        case v: v - this.start;
      }
  }
  
  static function isEqual(s1:String, p1:Int, l1:Int, s2:String, p2:Int, l2:Int) {
    if (l2 != l1) 
      return false;
    for (i in 0...l2)
      if (s1.fastCodeAt(p1 + i) != s2.fastCodeAt(p2 + i)) return false;
    return true;
  }
  
  @:commutative @:op(a == b) 
  static function equalsString(slice:StringSlice, string:String) 
    return 
      if (string == null || string.length != slice.length) false;
      else isEqual((slice : Data).string, (slice : Data).start, (slice : Data).length, string, 0, string.length);
  
  @:op(a == b) 
  static function equals(a:StringSlice, b:StringSlice) 
    return 
      a.length == b.length && a.startsWith(b);
}
