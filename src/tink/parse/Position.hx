package tink.parse;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Position in PData;
#else

private class PData {
  
  public var min(default, null):Int;
  public var max(default, null):Int;
  public var file(default, null):String;
  
  public function new(min, max, file) {
    this.min = min;
    this.max = max;
    this.file = file;
  }
}
#end
abstract Position(PData) {
  inline function getData()
    return #if macro Context.getPosInfos #end (this)
      
  public var min(get, never):Int;
    inline function get_min()
      return getData().min;
      
  public var max(get, never):Int;
    inline function get_max()
      return getData().min;
      
  public var file(get, never):String;
    inline function get_file()
      return getData().file;
      
  public inline function new(min, max, file)
    this = Context.makePosition( { min: min, max: max, file: file } );}
  
}