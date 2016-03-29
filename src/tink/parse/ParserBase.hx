package tink.parse;

using StringTools;
using tink.CoreApi;

typedef ListSyntax = { 
  ?start:StringSlice, 
  end:StringSlice, 
  sep:StringSlice, 
  ?allowTrailing:Bool 
 }

class ParserBase<Pos, Error> {
  
  var source:StringSlice;
  var pos:Int;
  var max:Int;

  function chomp(start, ?offset = 0)
    return source.string.substring(start, pos + offset);
  
  function init(source:StringSlice) {
    this.source = source.string;
    this.max = source.end;
    this.pos = source.start;    
  }
  
  inline function upNext(cond:Filter<Int>) {
    skipIgnored();
    return is(cond);
  }

  inline function is(cond:Filter<Int>) 
    return pos < max && cond[source.fastGet(pos)];
  
  inline function doReadWhile(cond:Filter<Int>)
    while (is(cond)) pos++;
    
  inline function readWhile(cond:Filter<Int>) {
    skipIgnored();
    var start = pos;
    doReadWhile(cond);
    return source[start...pos];
  }
  
  var lastSkip:Int;
  function skipIgnored():Continue {
    while (lastSkip != pos) {
      lastSkip = pos;
      doSkipIgnored();
    }
    lastSkip = pos;
    return null;
  }
  
  function doSkipIgnored() {}
  
  inline function isNext(s:StringSlice) 
    return source.hasSub(s, pos);
  
  function allow(s:StringSlice) 
    return skipIgnored() + allowHere(s);
  
  function allowHere(s:StringSlice) 
    return
      if (isNext(s)) {
        pos += s.length;
        true;
      }
      else false;
  
  function expect(s:StringSlice):Continue {
    if (!allow(s))
      die('expected $s');
    return null;
  }
  
  function upto(end:StringSlice, ?addEnd:Bool)
    return 
      switch source.indexOf(end, pos) {
        case -1: 
          Failure(makeError('expected $end', makePos(pos)));
        case v: 
          var ret = source[pos...v + if (addEnd) end.length else 0];
          pos = v + end.length;
          Success(ret);
      }
    
  function die(message:String):Dynamic
    return throw makeError(message, makePos(pos, pos + 1));
  
  function makeError(message:String, pos:Pos):Error 
    return throw 'ni';
  
  function read<A>(reader:Void->A) {
    skipIgnored();
    var start = pos,
        ret = reader();
        
    return {
      data: ret,
      pos: makePos(start, pos),
      bytesRead: pos - start
    }
  } 
  
  function done() {
    skipIgnored();
    return pos >= max;
  }

  function reject(s:StringSlice)
    throw makeError('unexpected $s', makePos(s.start, s.end));
  
  inline function makePos(from:Int, ?to:Int):Pos
    return doMakePos(from, if (to == null) from + 1 else to);
    
  function doMakePos(from:Int, to:Int):Pos 
    return throw 'ni';
    
  function parseRepeatedly(reader:Void->Void, settings:ListSyntax):Void {
    if (settings.start != null && !allow(settings.start)) return;
    if (allow(settings.end)) return;
    reader();
    while (allow(settings.sep)) {
      if (settings.allowTrailing && allow(settings.end))
        return;
      reader();
    }
    
    expect(settings.end);
  }
  
  function parseList<A>(reader:Void->A, settings):Array<A> {
    var ret = [];
    parseRepeatedly(function () ret.push(reader()), settings);
    return ret;
  }    
  
}

abstract Continue(Dynamic) {
  @:commutative @:op(a+b)
  static inline function then<A>(e:Continue, a:A):A 
    return a;
}