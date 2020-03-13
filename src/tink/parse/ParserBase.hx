package tink.parse;

using StringTools;
using tink.CoreApi;

typedef ListSyntax = {
  @:optional var start(default, never):StringSlice;
  var end(default, never):StringSlice;
  @:optional var sep(default, never):StringSlice;
  @:optional var trailing(default, never):TrailingSeparator;
}

@:enum abstract TrailingSeparator(String) {
  var Always = "Always";
  var Never = "Never";
}

class ParserBase<Pos, Error> {

  var reporter:Reporter<Pos, Error>;
  var source:StringSlice;
  var pos:Int;
  var max:Int;
  var offset:Int;

  function chomp(start, ?offset = 0)
    return source[start...pos + offset];

  public function new(source:StringSlice, reporter, ?offset = 0) {
    this.source = source;
    this.max = source.length;
    this.pos = 0;
    this.reporter = reporter;
    this.offset = offset;
  }

  inline function upNext(cond:Char) {
    skipIgnored();
    return is(cond);
  }

  inline function current()
    return source.fastGet(pos);

  inline function is(cond:Char)
    return pos < max && cond[current()];

  inline function doReadWhile(cond:Char)
    while (is(cond)) pos++;

  inline function readWhile(cond:Char) {
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

  function expectHere(s:StringSlice):Continue {
    if (!allowHere(s))
      die('expected $s');
    return null;
  }

  function attempt<S, F>(s:Void->Outcome<S, F>) {
    var start = this.pos;
    var ret = s();
    if (!ret.isSuccess()) this.pos = start;
    return ret;
  }

  function lookahead<T>(fn:Void->T) {
    var start = pos;
    return Error.tryFinally(fn, function () pos = start);
  }

  function located<T>(f:Void->T):Located<T, Pos> {
    var start = pos;
    return { value: f(), pos: makePos(start, pos) };
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

  function first(a:Array<String>, before) {
    var ret = Failure(makeError('Failed to find either of ${a.join(",")}', makePos(pos, pos))),
        min = max;

    for (s in a)
      switch source.indexOf(s, pos) {
        case -1:
        case v:
          if (v < min) {
            min = v;
            ret = Success(s);
          }
      }


    switch ret {
      case Success(v):
        before(source[pos...min]);
        pos = min + v.length;
      default:
    }
    return ret;
  }

  function die(message:String, ?range:IntIterator):Dynamic {
    if (range == null) range = pos...pos + 1;
    return throw makeError(message, @:privateAccess makePos(range.min, range.max));
  }

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

  function reject(s:StringSlice, ?reason:String):Dynamic
    return
      if (reason == null) reject('unexpected $s');
      else throw makeError(reason, makePos(s.start, s.end));

  inline function makeError(message:String, pos:Pos)
    return reporter.makeError(message, pos);

  inline function makePos(from:Int, ?to:Int):Pos
    return reporter.makePos(offset + from, offset + if (to == null) from + 1 else to);

  function parseRepeatedly(reader:Void->Void, settings:ListSyntax):Void {
    if (settings.start != null && !allow(settings.start)) return;
    switch settings.sep {
      case null:
        while (!allow(settings.end)) reader();
      case sep:
        if (allow(settings.end)) return;
        while (true) {
          reader();
          switch settings.trailing {
            case null:
              var hasSep = allow(sep);
              if (allow(settings.end)) return;
              if (!hasSep)
                die('expected ${sep} or ${settings.end}');
            case Always:
              expect(sep);
              if (allow(settings.end)) return;
            case Never:
              if (allow(settings.end)) return;
              expect(sep);
          }
        }
    }
  }

  function parseList<A>(reader:Void->A, settings):Array<A> {
    var ret = [];
    parseRepeatedly(function () ret.push(reader()), settings);
    return ret;
  }

}

abstract Continue(Dynamic) {
  @:commutative @:op(a+b)
  @:extern static inline function then<A>(e:Continue, a:A):A
    return a;
}