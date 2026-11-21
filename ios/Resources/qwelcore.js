//region block: polyfills
if (typeof Math.imul === 'undefined') {
  Math.imul = function imul(a, b) {
    return (a & 4.29490176E9) * (b & 65535) + (a & 65535) * (b | 0) | 0;
  };
}
if (typeof ArrayBuffer.isView === 'undefined') {
  ArrayBuffer.isView = function (a) {
    return a != null && a.__proto__ != null && a.__proto__.__proto__ === Int8Array.prototype.__proto__;
  };
}
if (typeof Array.prototype.fill === 'undefined') {
  // Polyfill from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/fill#Polyfill
  Object.defineProperty(Array.prototype, 'fill', {value: function (value) {
    // Steps 1-2.
    if (this == null) {
      throw new TypeError('this is null or not defined');
    }
    var O = Object(this); // Steps 3-5.
    var len = O.length >>> 0; // Steps 6-7.
    var start = arguments[1];
    var relativeStart = start >> 0; // Step 8.
    var k = relativeStart < 0 ? Math.max(len + relativeStart, 0) : Math.min(relativeStart, len); // Steps 9-10.
    var end = arguments[2];
    var relativeEnd = end === undefined ? len : end >> 0; // Step 11.
    var finalValue = relativeEnd < 0 ? Math.max(len + relativeEnd, 0) : Math.min(relativeEnd, len); // Step 12.
    while (k < finalValue) {
      O[k] = value;
      k++;
    }
    ; // Step 13.
    return O;
  }});
}
[Int8Array, Int16Array, Uint16Array, Int32Array, Float32Array, Float64Array].forEach(function (TypedArray) {
  if (typeof TypedArray.prototype.fill === 'undefined') {
    Object.defineProperty(TypedArray.prototype, 'fill', {value: Array.prototype.fill});
  }
});
if (typeof Math.clz32 === 'undefined') {
  Math.clz32 = function (log, LN2) {
    return function (x) {
      var asUint = x >>> 0;
      if (asUint === 0) {
        return 32;
      }
      return 31 - (log(asUint) / LN2 | 0) | 0; // the "| 0" acts like math.floor
    };
  }(Math.log, Math.LN2);
}
if (typeof String.prototype.endsWith === 'undefined') {
  Object.defineProperty(String.prototype, 'endsWith', {value: function (searchString, position) {
    var subjectString = this.toString();
    if (position === undefined || position > subjectString.length) {
      position = subjectString.length;
    }
    position -= searchString.length;
    var lastIndex = subjectString.indexOf(searchString, position);
    return lastIndex !== -1 && lastIndex === position;
  }});
}
if (typeof String.prototype.startsWith === 'undefined') {
  Object.defineProperty(String.prototype, 'startsWith', {value: function (searchString, position) {
    position = position || 0;
    return this.lastIndexOf(searchString, position) === position;
  }});
}
//endregion
var qwelcore = function (_) {
  'use strict';
  //region block: imports
  var imul = Math.imul;
  var isView = ArrayBuffer.isView;
  var clz32 = Math.clz32;
  //endregion
  //region block: pre-declaration
  initMetadataForInterface(CharSequence, 'CharSequence');
  initMetadataForInterface(Comparable, 'Comparable');
  initMetadataForClass(Number_0, 'Number');
  initMetadataForClass(asSequence$$inlined$Sequence$1);
  initMetadataForClass(asIterable$$inlined$Iterable$1);
  initMetadataForClass(Char, 'Char', VOID, VOID, [Comparable]);
  initMetadataForInterface(Collection, 'Collection');
  initMetadataForInterface(KtList, 'List', VOID, VOID, [Collection]);
  initMetadataForInterface(KtSet, 'Set', VOID, VOID, [Collection]);
  initMetadataForInterface(Entry, 'Entry');
  initMetadataForInterface(KtMap, 'Map');
  initMetadataForCompanion(Companion);
  initMetadataForClass(Enum, 'Enum', VOID, VOID, [Comparable]);
  initMetadataForCompanion(Companion_0);
  initMetadataForClass(Long, 'Long', VOID, Number_0, [Number_0, Comparable]);
  initMetadataForInterface(FunctionAdapter, 'FunctionAdapter');
  initMetadataForClass(arrayIterator$1);
  initMetadataForObject(Digit, 'Digit');
  initMetadataForInterface(Comparator, 'Comparator');
  initMetadataForObject(Unit, 'Unit');
  initMetadataForClass(AbstractCollection, 'AbstractCollection', VOID, VOID, [Collection]);
  initMetadataForClass(AbstractMutableCollection, 'AbstractMutableCollection', VOID, AbstractCollection, [AbstractCollection, Collection]);
  initMetadataForClass(IteratorImpl, 'IteratorImpl');
  initMetadataForClass(ListIteratorImpl, 'ListIteratorImpl', VOID, IteratorImpl);
  initMetadataForClass(AbstractMutableList, 'AbstractMutableList', VOID, AbstractMutableCollection, [AbstractMutableCollection, Collection, KtList]);
  initMetadataForClass(AbstractMap, 'AbstractMap', VOID, VOID, [KtMap]);
  initMetadataForClass(AbstractMutableMap, 'AbstractMutableMap', VOID, AbstractMap, [AbstractMap, KtMap]);
  initMetadataForClass(AbstractMutableSet, 'AbstractMutableSet', VOID, AbstractMutableCollection, [AbstractMutableCollection, Collection, KtSet]);
  initMetadataForCompanion(Companion_1);
  initMetadataForInterface(RandomAccess, 'RandomAccess');
  initMetadataForClass(ArrayList, 'ArrayList', ArrayList_init_$Create$, AbstractMutableList, [AbstractMutableList, Collection, KtList, RandomAccess]);
  initMetadataForClass(HashMap, 'HashMap', HashMap_init_$Create$, AbstractMutableMap, [AbstractMutableMap, KtMap]);
  initMetadataForClass(HashMapEntrySetBase, 'HashMapEntrySetBase', VOID, AbstractMutableSet, [Collection, KtSet, AbstractMutableSet]);
  initMetadataForClass(HashMapEntrySet, 'HashMapEntrySet', VOID, HashMapEntrySetBase);
  initMetadataForClass(HashSet, 'HashSet', HashSet_init_$Create$, AbstractMutableSet, [AbstractMutableSet, Collection, KtSet]);
  initMetadataForCompanion(Companion_2);
  initMetadataForClass(Itr, 'Itr');
  initMetadataForClass(KeysItr, 'KeysItr', VOID, Itr);
  initMetadataForClass(EntriesItr, 'EntriesItr', VOID, Itr);
  initMetadataForClass(EntryRef, 'EntryRef', VOID, VOID, [Entry]);
  function containsAllEntries(m) {
    var tmp$ret$0;
    $l$block_0: {
      // Inline function 'kotlin.collections.all' call
      var tmp;
      if (isInterface(m, Collection)) {
        tmp = m.isEmpty_y1axqb_k$();
      } else {
        tmp = false;
      }
      if (tmp) {
        tmp$ret$0 = true;
        break $l$block_0;
      }
      var _iterator__ex2g4s = m.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s.next_20eer_k$();
        // Inline function 'kotlin.js.unsafeCast' call
        // Inline function 'kotlin.js.asDynamic' call
        var entry = element;
        var tmp_0;
        if (!(entry == null) ? isInterface(entry, Entry) : false) {
          tmp_0 = this.containsOtherEntry_yvdc55_k$(entry);
        } else {
          tmp_0 = false;
        }
        if (!tmp_0) {
          tmp$ret$0 = false;
          break $l$block_0;
        }
      }
      tmp$ret$0 = true;
    }
    return tmp$ret$0;
  }
  initMetadataForInterface(InternalMap, 'InternalMap');
  initMetadataForClass(InternalHashMap, 'InternalHashMap', InternalHashMap_init_$Create$, VOID, [InternalMap]);
  initMetadataForClass(LinkedHashMap, 'LinkedHashMap', LinkedHashMap_init_$Create$, HashMap, [HashMap, KtMap]);
  initMetadataForClass(LinkedHashSet, 'LinkedHashSet', LinkedHashSet_init_$Create$, HashSet, [HashSet, Collection, KtSet]);
  initMetadataForClass(Exception, 'Exception', Exception_init_$Create$, Error);
  initMetadataForClass(RuntimeException, 'RuntimeException', RuntimeException_init_$Create$, Exception);
  initMetadataForClass(IllegalArgumentException, 'IllegalArgumentException', IllegalArgumentException_init_$Create$, RuntimeException);
  initMetadataForClass(IllegalStateException, 'IllegalStateException', IllegalStateException_init_$Create$, RuntimeException);
  initMetadataForClass(UnsupportedOperationException, 'UnsupportedOperationException', UnsupportedOperationException_init_$Create$, RuntimeException);
  initMetadataForClass(NoSuchElementException, 'NoSuchElementException', NoSuchElementException_init_$Create$, RuntimeException);
  initMetadataForClass(IndexOutOfBoundsException, 'IndexOutOfBoundsException', IndexOutOfBoundsException_init_$Create$, RuntimeException);
  initMetadataForClass(ArithmeticException, 'ArithmeticException', ArithmeticException_init_$Create$, RuntimeException);
  initMetadataForClass(ConcurrentModificationException, 'ConcurrentModificationException', ConcurrentModificationException_init_$Create$, RuntimeException);
  initMetadataForClass(NumberFormatException, 'NumberFormatException', NumberFormatException_init_$Create$, IllegalArgumentException);
  initMetadataForClass(NullPointerException, 'NullPointerException', NullPointerException_init_$Create$, RuntimeException);
  initMetadataForClass(ClassCastException, 'ClassCastException', ClassCastException_init_$Create$, RuntimeException);
  initMetadataForInterface(KProperty1, 'KProperty1');
  initMetadataForClass(StringBuilder, 'StringBuilder', StringBuilder_init_$Create$_0, VOID, [CharSequence]);
  initMetadataForCompanion(Companion_3);
  initMetadataForClass(Regex, 'Regex');
  initMetadataForClass(MatchGroup, 'MatchGroup');
  initMetadataForInterface(MatchNamedGroupCollection, 'MatchNamedGroupCollection', VOID, VOID, [Collection]);
  initMetadataForClass(findNext$1$groups$1, VOID, VOID, AbstractCollection, [MatchNamedGroupCollection, AbstractCollection]);
  initMetadataForClass(AbstractList, 'AbstractList', VOID, AbstractCollection, [AbstractCollection, KtList]);
  initMetadataForClass(findNext$1$groupValues$1, VOID, VOID, AbstractList);
  initMetadataForClass(findNext$1);
  initMetadataForClass(IteratorImpl_0, 'IteratorImpl');
  initMetadataForClass(ListIteratorImpl_0, 'ListIteratorImpl', VOID, IteratorImpl_0);
  initMetadataForCompanion(Companion_4);
  initMetadataForCompanion(Companion_5);
  initMetadataForCompanion(Companion_6);
  initMetadataForObject(EmptyList, 'EmptyList', VOID, VOID, [KtList, RandomAccess]);
  initMetadataForClass(ArrayAsCollection, 'ArrayAsCollection', VOID, VOID, [Collection]);
  initMetadataForObject(EmptyIterator, 'EmptyIterator');
  initMetadataForClass(IndexedValue, 'IndexedValue');
  initMetadataForClass(IndexingIterable, 'IndexingIterable');
  initMetadataForClass(IndexingIterator, 'IndexingIterator');
  initMetadataForObject(EmptyMap, 'EmptyMap', VOID, VOID, [KtMap]);
  initMetadataForClass(IntIterator, 'IntIterator');
  initMetadataForClass(ReversedListReadOnly$listIterator$1);
  initMetadataForClass(ReversedListReadOnly, 'ReversedListReadOnly', VOID, AbstractList);
  initMetadataForInterface(DropTakeSequence, 'DropTakeSequence');
  initMetadataForClass(TakeSequence$iterator$1);
  initMetadataForClass(TakeSequence, 'TakeSequence', VOID, VOID, [DropTakeSequence]);
  initMetadataForClass(TransformingSequence$iterator$1);
  initMetadataForClass(TransformingSequence, 'TransformingSequence');
  initMetadataForClass(GeneratorSequence$iterator$1);
  initMetadataForClass(GeneratorSequence, 'GeneratorSequence');
  initMetadataForObject(EmptySequence, 'EmptySequence', VOID, VOID, [DropTakeSequence]);
  initMetadataForObject(EmptySet, 'EmptySet', VOID, VOID, [KtSet]);
  initMetadataForObject(NaturalOrderComparator, 'NaturalOrderComparator', VOID, VOID, [Comparator]);
  initMetadataForCompanion(Companion_7);
  initMetadataForClass(IntProgression, 'IntProgression');
  initMetadataForClass(IntRange, 'IntRange', VOID, IntProgression);
  initMetadataForClass(IntProgressionIterator, 'IntProgressionIterator', VOID, IntIterator);
  initMetadataForCompanion(Companion_8);
  initMetadataForClass(DelimitedRangesSequence$iterator$1);
  initMetadataForClass(DelimitedRangesSequence, 'DelimitedRangesSequence');
  initMetadataForClass(UnsafeLazyImpl, 'UnsafeLazyImpl');
  initMetadataForObject(UNINITIALIZED_VALUE, 'UNINITIALIZED_VALUE');
  initMetadataForCompanion(Companion_9);
  initMetadataForClass(Failure, 'Failure');
  initMetadataForClass(Pair, 'Pair');
  initMetadataForClass(Triple, 'Triple');
  initMetadataForCompanion(Companion_10);
  initMetadataForClass(ComponentDef, 'ComponentDef');
  initMetadataForObject(Components, 'Components');
  initMetadataForClass(Src, 'Src');
  initMetadataForClass(Ctx, 'Ctx', Ctx);
  initMetadataForClass(Comp, 'Comp');
  initMetadataForObject(ComposeCode, 'ComposeCode');
  initMetadataForClass(EchoParams, 'EchoParams', EchoParams);
  initMetadataForObject(Echo, 'Echo');
  initMetadataForObject(ExpressiveComponents, 'ExpressiveComponents');
  initMetadataForObject(IconNodes, 'IconNodes');
  initMetadataForClass(NodeKind, 'NodeKind', VOID, Enum);
  initMetadataForClass(Node, 'Node');
  initMetadataForClass(Box, 'Box');
  initMetadataForClass(Project, 'Project');
  initMetadataForClass(Page, 'Page');
  initMetadataForObject(TextMetrics, 'TextMetrics');
  initMetadataForClass(Swatch, 'Swatch');
  initMetadataForObject(DesignPalette, 'DesignPalette');
  initMetadataForClass(Widget, 'Widget');
  initMetadataForClass(PItem, 'PItem');
  initMetadataForClass(Bar, 'Bar');
  initMetadataForClass(Slider, 'Slider');
  initMetadataForClass(sam$kotlin_Comparator$0, 'sam$kotlin_Comparator$0', VOID, VOID, [Comparator, FunctionAdapter]);
  initMetadataForObject(PlayMode, 'PlayMode');
  initMetadataForObject(ProjectStore, 'ProjectStore');
  initMetadataForCompanion(Companion_11);
  initMetadataForClass(Tone, 'Tone', Tone);
  initMetadataForObject(ToneGen, 'ToneGen');
  initMetadataForObject(IconLibrary, 'IconLibrary');
  initMetadataForObject(SvgImport, 'SvgImport');
  initMetadataForObject(Math_0, 'Math');
  initMetadataForClass(Random, 'Random');
  initMetadataForClass(sam$kotlin_Comparator$0_0, 'sam$kotlin_Comparator$0', VOID, VOID, [Comparator, FunctionAdapter]);
  initMetadataForClass(JSONObject, 'JSONObject', JSONObject);
  initMetadataForClass(JSONArray, 'JSONArray', JSONArray);
  initMetadataForClass(TapState, 'TapState');
  //endregion
  function CharSequence() {
  }
  function Comparable() {
  }
  function Number_0() {
  }
  function toList(_this__u8e3s4) {
    switch (_this__u8e3s4.length) {
      case 0:
        return emptyList();
      case 1:
        return listOf(_this__u8e3s4[0]);
      default:
        return toMutableList(_this__u8e3s4);
    }
  }
  function indexOf(_this__u8e3s4, element) {
    if (element == null) {
      var inductionVariable = 0;
      var last = _this__u8e3s4.length - 1 | 0;
      if (inductionVariable <= last)
        do {
          var index = inductionVariable;
          inductionVariable = inductionVariable + 1 | 0;
          if (_this__u8e3s4[index] == null) {
            return index;
          }
        }
         while (inductionVariable <= last);
    } else {
      var inductionVariable_0 = 0;
      var last_0 = _this__u8e3s4.length - 1 | 0;
      if (inductionVariable_0 <= last_0)
        do {
          var index_0 = inductionVariable_0;
          inductionVariable_0 = inductionVariable_0 + 1 | 0;
          if (equals(element, _this__u8e3s4[index_0])) {
            return index_0;
          }
        }
         while (inductionVariable_0 <= last_0);
    }
    return -1;
  }
  function contains(_this__u8e3s4, element) {
    return indexOf_0(_this__u8e3s4, element) >= 0;
  }
  function single(_this__u8e3s4) {
    var tmp;
    switch (_this__u8e3s4.length) {
      case 0:
        throw NoSuchElementException_init_$Create$_0('Array is empty.');
      case 1:
        tmp = _this__u8e3s4[0];
        break;
      default:
        throw IllegalArgumentException_init_$Create$_0('Array has more than one element.');
    }
    return tmp;
  }
  function toMutableList(_this__u8e3s4) {
    return ArrayList_init_$Create$_1(asCollection(_this__u8e3s4));
  }
  function get_lastIndex(_this__u8e3s4) {
    return _this__u8e3s4.length - 1 | 0;
  }
  function indexOf_0(_this__u8e3s4, element) {
    var inductionVariable = 0;
    var last = _this__u8e3s4.length - 1 | 0;
    if (inductionVariable <= last)
      do {
        var index = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        if (element === _this__u8e3s4[index]) {
          return index;
        }
      }
       while (inductionVariable <= last);
    return -1;
  }
  function toSet(_this__u8e3s4) {
    switch (_this__u8e3s4.length) {
      case 0:
        return emptySet();
      case 1:
        return setOf(_this__u8e3s4[0]);
      default:
        return toCollection(_this__u8e3s4, LinkedHashSet_init_$Create$_0(mapCapacity(_this__u8e3s4.length)));
    }
  }
  function joinToString(_this__u8e3s4, separator, prefix, postfix, limit, truncated, transform) {
    separator = separator === VOID ? ', ' : separator;
    prefix = prefix === VOID ? '' : prefix;
    postfix = postfix === VOID ? '' : postfix;
    limit = limit === VOID ? -1 : limit;
    truncated = truncated === VOID ? '...' : truncated;
    transform = transform === VOID ? null : transform;
    return joinTo(_this__u8e3s4, StringBuilder_init_$Create$_0(), separator, prefix, postfix, limit, truncated, transform).toString();
  }
  function toCollection(_this__u8e3s4, destination) {
    var inductionVariable = 0;
    var last = _this__u8e3s4.length;
    while (inductionVariable < last) {
      var item = _this__u8e3s4[inductionVariable];
      inductionVariable = inductionVariable + 1 | 0;
      destination.add_utx5q5_k$(item);
    }
    return destination;
  }
  function joinTo(_this__u8e3s4, buffer, separator, prefix, postfix, limit, truncated, transform) {
    separator = separator === VOID ? ', ' : separator;
    prefix = prefix === VOID ? '' : prefix;
    postfix = postfix === VOID ? '' : postfix;
    limit = limit === VOID ? -1 : limit;
    truncated = truncated === VOID ? '...' : truncated;
    transform = transform === VOID ? null : transform;
    buffer.append_jgojdo_k$(prefix);
    var count = 0;
    var inductionVariable = 0;
    var last = _this__u8e3s4.length;
    $l$loop: while (inductionVariable < last) {
      var element = _this__u8e3s4[inductionVariable];
      inductionVariable = inductionVariable + 1 | 0;
      count = count + 1 | 0;
      if (count > 1) {
        buffer.append_jgojdo_k$(separator);
      }
      if (limit < 0 || count <= limit) {
        appendElement(buffer, element, transform);
      } else
        break $l$loop;
    }
    if (limit >= 0 && count > limit) {
      buffer.append_jgojdo_k$(truncated);
    }
    buffer.append_jgojdo_k$(postfix);
    return buffer;
  }
  function joinToString_0(_this__u8e3s4, separator, prefix, postfix, limit, truncated, transform) {
    separator = separator === VOID ? ', ' : separator;
    prefix = prefix === VOID ? '' : prefix;
    postfix = postfix === VOID ? '' : postfix;
    limit = limit === VOID ? -1 : limit;
    truncated = truncated === VOID ? '...' : truncated;
    transform = transform === VOID ? null : transform;
    return joinTo_0(_this__u8e3s4, StringBuilder_init_$Create$_0(), separator, prefix, postfix, limit, truncated, transform).toString();
  }
  function joinTo_0(_this__u8e3s4, buffer, separator, prefix, postfix, limit, truncated, transform) {
    separator = separator === VOID ? ', ' : separator;
    prefix = prefix === VOID ? '' : prefix;
    postfix = postfix === VOID ? '' : postfix;
    limit = limit === VOID ? -1 : limit;
    truncated = truncated === VOID ? '...' : truncated;
    transform = transform === VOID ? null : transform;
    buffer.append_jgojdo_k$(prefix);
    var count = 0;
    var _iterator__ex2g4s = _this__u8e3s4.iterator_jk1svi_k$();
    $l$loop: while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      count = count + 1 | 0;
      if (count > 1) {
        buffer.append_jgojdo_k$(separator);
      }
      if (limit < 0 || count <= limit) {
        appendElement(buffer, element, transform);
      } else
        break $l$loop;
    }
    if (limit >= 0 && count > limit) {
      buffer.append_jgojdo_k$(truncated);
    }
    buffer.append_jgojdo_k$(postfix);
    return buffer;
  }
  function withIndex(_this__u8e3s4) {
    return new IndexingIterable(withIndex$lambda(_this__u8e3s4));
  }
  function first(_this__u8e3s4) {
    if (_this__u8e3s4.isEmpty_y1axqb_k$())
      throw NoSuchElementException_init_$Create$_0('List is empty.');
    return _this__u8e3s4.get_c1px32_k$(0);
  }
  function last(_this__u8e3s4) {
    if (_this__u8e3s4.isEmpty_y1axqb_k$())
      throw NoSuchElementException_init_$Create$_0('List is empty.');
    return _this__u8e3s4.get_c1px32_k$(get_lastIndex_0(_this__u8e3s4));
  }
  function plus(_this__u8e3s4, elements) {
    if (isInterface(elements, Collection)) {
      var result = ArrayList_init_$Create$_0(_this__u8e3s4.get_size_woubt6_k$() + elements.get_size_woubt6_k$() | 0);
      result.addAll_h3ej1q_k$(_this__u8e3s4);
      result.addAll_h3ej1q_k$(elements);
      return result;
    } else {
      var result_0 = ArrayList_init_$Create$_1(_this__u8e3s4);
      addAll(result_0, elements);
      return result_0;
    }
  }
  function plus_0(_this__u8e3s4, element) {
    var result = ArrayList_init_$Create$_0(_this__u8e3s4.get_size_woubt6_k$() + 1 | 0);
    result.addAll_h3ej1q_k$(_this__u8e3s4);
    result.add_utx5q5_k$(element);
    return result;
  }
  function firstOrNull(_this__u8e3s4) {
    return _this__u8e3s4.isEmpty_y1axqb_k$() ? null : _this__u8e3s4.get_c1px32_k$(0);
  }
  function getOrNull(_this__u8e3s4, index) {
    return (0 <= index ? index < _this__u8e3s4.get_size_woubt6_k$() : false) ? _this__u8e3s4.get_c1px32_k$(index) : null;
  }
  function toList_0(_this__u8e3s4) {
    if (isInterface(_this__u8e3s4, Collection)) {
      var tmp;
      switch (_this__u8e3s4.get_size_woubt6_k$()) {
        case 0:
          tmp = emptyList();
          break;
        case 1:
          var tmp_0;
          if (isInterface(_this__u8e3s4, KtList)) {
            tmp_0 = _this__u8e3s4.get_c1px32_k$(0);
          } else {
            tmp_0 = _this__u8e3s4.iterator_jk1svi_k$().next_20eer_k$();
          }

          tmp = listOf(tmp_0);
          break;
        default:
          tmp = toMutableList_0(_this__u8e3s4);
          break;
      }
      return tmp;
    }
    return optimizeReadOnlyList(toMutableList_1(_this__u8e3s4));
  }
  function toMutableList_0(_this__u8e3s4) {
    return ArrayList_init_$Create$_1(_this__u8e3s4);
  }
  function sorted(_this__u8e3s4) {
    if (isInterface(_this__u8e3s4, Collection)) {
      if (_this__u8e3s4.get_size_woubt6_k$() <= 1)
        return toList_0(_this__u8e3s4);
      // Inline function 'kotlin.collections.toTypedArray' call
      var tmp = copyToArray(_this__u8e3s4);
      // Inline function 'kotlin.apply' call
      var this_0 = isArray(tmp) ? tmp : THROW_CCE();
      sort(this_0);
      return asList(this_0);
    }
    // Inline function 'kotlin.apply' call
    var this_1 = toMutableList_1(_this__u8e3s4);
    sort_0(this_1);
    return this_1;
  }
  function zip(_this__u8e3s4, other) {
    // Inline function 'kotlin.collections.zip' call
    var first = _this__u8e3s4.iterator_jk1svi_k$();
    var second = other.iterator_jk1svi_k$();
    var tmp0 = collectionSizeOrDefault(_this__u8e3s4, 10);
    // Inline function 'kotlin.comparisons.minOf' call
    var b = collectionSizeOrDefault(other, 10);
    var tmp$ret$0 = Math.min(tmp0, b);
    var list = ArrayList_init_$Create$_0(tmp$ret$0);
    while (first.hasNext_bitz1p_k$() && second.hasNext_bitz1p_k$()) {
      var tmp2 = first.next_20eer_k$();
      var t2 = second.next_20eer_k$();
      var tmp$ret$1 = to(tmp2, t2);
      list.add_utx5q5_k$(tmp$ret$1);
    }
    return list;
  }
  function toIntArray(_this__u8e3s4) {
    var result = new Int32Array(_this__u8e3s4.get_size_woubt6_k$());
    var index = 0;
    var _iterator__ex2g4s = _this__u8e3s4.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      var _unary__edvuaz = index;
      index = _unary__edvuaz + 1 | 0;
      result[_unary__edvuaz] = element;
    }
    return result;
  }
  function drop(_this__u8e3s4, n) {
    // Inline function 'kotlin.require' call
    if (!(n >= 0)) {
      var message = 'Requested element count ' + n + ' is less than zero.';
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    if (n === 0)
      return toList_0(_this__u8e3s4);
    var list;
    if (isInterface(_this__u8e3s4, Collection)) {
      var resultSize = _this__u8e3s4.get_size_woubt6_k$() - n | 0;
      if (resultSize <= 0)
        return emptyList();
      if (resultSize === 1)
        return listOf(last_0(_this__u8e3s4));
      list = ArrayList_init_$Create$_0(resultSize);
      if (isInterface(_this__u8e3s4, KtList)) {
        if (isInterface(_this__u8e3s4, RandomAccess)) {
          var inductionVariable = n;
          var last = _this__u8e3s4.get_size_woubt6_k$();
          if (inductionVariable < last)
            do {
              var index = inductionVariable;
              inductionVariable = inductionVariable + 1 | 0;
              list.add_utx5q5_k$(_this__u8e3s4.get_c1px32_k$(index));
            }
             while (inductionVariable < last);
        } else {
          // Inline function 'kotlin.collections.iterator' call
          var _iterator__ex2g4s = _this__u8e3s4.listIterator_70e65o_k$(n);
          while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
            var item = _iterator__ex2g4s.next_20eer_k$();
            list.add_utx5q5_k$(item);
          }
        }
        return list;
      }
    } else {
      list = ArrayList_init_$Create$();
    }
    var count = 0;
    var _iterator__ex2g4s_0 = _this__u8e3s4.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
      var item_0 = _iterator__ex2g4s_0.next_20eer_k$();
      if (count >= n)
        list.add_utx5q5_k$(item_0);
      else {
        count = count + 1 | 0;
      }
    }
    return optimizeReadOnlyList(list);
  }
  function min(_this__u8e3s4) {
    var iterator = _this__u8e3s4.iterator_jk1svi_k$();
    if (!iterator.hasNext_bitz1p_k$())
      throw NoSuchElementException_init_$Create$();
    var min = iterator.next_20eer_k$();
    while (iterator.hasNext_bitz1p_k$()) {
      var e = iterator.next_20eer_k$();
      // Inline function 'kotlin.comparisons.minOf' call
      var a = min;
      min = Math.min(a, e);
    }
    return min;
  }
  function max(_this__u8e3s4) {
    var iterator = _this__u8e3s4.iterator_jk1svi_k$();
    if (!iterator.hasNext_bitz1p_k$())
      throw NoSuchElementException_init_$Create$();
    var max = iterator.next_20eer_k$();
    while (iterator.hasNext_bitz1p_k$()) {
      var e = iterator.next_20eer_k$();
      // Inline function 'kotlin.comparisons.maxOf' call
      var a = max;
      max = Math.max(a, e);
    }
    return max;
  }
  function sortedWith(_this__u8e3s4, comparator) {
    if (isInterface(_this__u8e3s4, Collection)) {
      if (_this__u8e3s4.get_size_woubt6_k$() <= 1)
        return toList_0(_this__u8e3s4);
      // Inline function 'kotlin.collections.toTypedArray' call
      var tmp = copyToArray(_this__u8e3s4);
      // Inline function 'kotlin.apply' call
      var this_0 = isArray(tmp) ? tmp : THROW_CCE();
      sortWith(this_0, comparator);
      return asList(this_0);
    }
    // Inline function 'kotlin.apply' call
    var this_1 = toMutableList_1(_this__u8e3s4);
    sortWith_0(this_1, comparator);
    return this_1;
  }
  function toMutableList_1(_this__u8e3s4) {
    if (isInterface(_this__u8e3s4, Collection))
      return toMutableList_0(_this__u8e3s4);
    return toCollection_0(_this__u8e3s4, ArrayList_init_$Create$());
  }
  function last_0(_this__u8e3s4) {
    if (isInterface(_this__u8e3s4, KtList))
      return last(_this__u8e3s4);
    else {
      var iterator = _this__u8e3s4.iterator_jk1svi_k$();
      if (!iterator.hasNext_bitz1p_k$())
        throw NoSuchElementException_init_$Create$_0('Collection is empty.');
      var last_0 = iterator.next_20eer_k$();
      while (iterator.hasNext_bitz1p_k$())
        last_0 = iterator.next_20eer_k$();
      return last_0;
    }
  }
  function toCollection_0(_this__u8e3s4, destination) {
    var _iterator__ex2g4s = _this__u8e3s4.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s.next_20eer_k$();
      destination.add_utx5q5_k$(item);
    }
    return destination;
  }
  function toSet_0(_this__u8e3s4) {
    if (isInterface(_this__u8e3s4, Collection)) {
      var tmp;
      switch (_this__u8e3s4.get_size_woubt6_k$()) {
        case 0:
          tmp = emptySet();
          break;
        case 1:
          var tmp_0;
          if (isInterface(_this__u8e3s4, KtList)) {
            tmp_0 = _this__u8e3s4.get_c1px32_k$(0);
          } else {
            tmp_0 = _this__u8e3s4.iterator_jk1svi_k$().next_20eer_k$();
          }

          tmp = setOf(tmp_0);
          break;
        default:
          tmp = toCollection_0(_this__u8e3s4, LinkedHashSet_init_$Create$_0(mapCapacity(_this__u8e3s4.get_size_woubt6_k$())));
          break;
      }
      return tmp;
    }
    return optimizeReadOnlySet(toCollection_0(_this__u8e3s4, LinkedHashSet_init_$Create$()));
  }
  function asSequence(_this__u8e3s4) {
    // Inline function 'kotlin.sequences.Sequence' call
    return new asSequence$$inlined$Sequence$1(_this__u8e3s4);
  }
  function withIndex$lambda($this_withIndex) {
    return function () {
      return $this_withIndex.iterator_jk1svi_k$();
    };
  }
  function asSequence$$inlined$Sequence$1($this_asSequence) {
    this.$this_asSequence_1 = $this_asSequence;
  }
  protoOf(asSequence$$inlined$Sequence$1).iterator_jk1svi_k$ = function () {
    return this.$this_asSequence_1.iterator_jk1svi_k$();
  };
  function until(_this__u8e3s4, to) {
    if (to <= -2147483648)
      return Companion_getInstance_7().EMPTY_1;
    return numberRangeToNumber(_this__u8e3s4, to - 1 | 0);
  }
  function coerceIn(_this__u8e3s4, minimumValue, maximumValue) {
    if (minimumValue > maximumValue)
      throw IllegalArgumentException_init_$Create$_0('Cannot coerce value to an empty range: maximum ' + maximumValue + ' is less than minimum ' + minimumValue + '.');
    if (_this__u8e3s4 < minimumValue)
      return minimumValue;
    if (_this__u8e3s4 > maximumValue)
      return maximumValue;
    return _this__u8e3s4;
  }
  function coerceIn_0(_this__u8e3s4, minimumValue, maximumValue) {
    if (minimumValue > maximumValue)
      throw IllegalArgumentException_init_$Create$_0('Cannot coerce value to an empty range: maximum ' + maximumValue + ' is less than minimum ' + minimumValue + '.');
    if (_this__u8e3s4 < minimumValue)
      return minimumValue;
    if (_this__u8e3s4 > maximumValue)
      return maximumValue;
    return _this__u8e3s4;
  }
  function coerceAtLeast(_this__u8e3s4, minimumValue) {
    return _this__u8e3s4 < minimumValue ? minimumValue : _this__u8e3s4;
  }
  function coerceAtLeast_0(_this__u8e3s4, minimumValue) {
    return _this__u8e3s4 < minimumValue ? minimumValue : _this__u8e3s4;
  }
  function coerceAtMost(_this__u8e3s4, maximumValue) {
    return _this__u8e3s4 > maximumValue ? maximumValue : _this__u8e3s4;
  }
  function downTo(_this__u8e3s4, to) {
    return Companion_instance_8.fromClosedRange_y6bqsv_k$(_this__u8e3s4, to, -1);
  }
  function asIterable(_this__u8e3s4) {
    // Inline function 'kotlin.collections.Iterable' call
    return new asIterable$$inlined$Iterable$1(_this__u8e3s4);
  }
  function take(_this__u8e3s4, n) {
    // Inline function 'kotlin.require' call
    if (!(n >= 0)) {
      var message = 'Requested element count ' + n + ' is less than zero.';
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    var tmp;
    if (n === 0) {
      tmp = emptySequence();
    } else {
      if (isInterface(_this__u8e3s4, DropTakeSequence)) {
        tmp = _this__u8e3s4.take_6gva4v_k$(n);
      } else {
        tmp = new TakeSequence(_this__u8e3s4, n);
      }
    }
    return tmp;
  }
  function map(_this__u8e3s4, transform) {
    return new TransformingSequence(_this__u8e3s4, transform);
  }
  function asIterable$$inlined$Iterable$1($this_asIterable) {
    this.$this_asIterable_1 = $this_asIterable;
  }
  protoOf(asIterable$$inlined$Iterable$1).iterator_jk1svi_k$ = function () {
    return this.$this_asIterable_1.iterator_jk1svi_k$();
  };
  function _Char___init__impl__6a9atx(value) {
    return value;
  }
  function _get_value__a43j40($this) {
    return $this;
  }
  function _Char___init__impl__6a9atx_0(code) {
    // Inline function 'kotlin.UShort.toInt' call
    var tmp$ret$0 = _UShort___get_data__impl__g0245(code) & 65535;
    return _Char___init__impl__6a9atx(tmp$ret$0);
  }
  function Char__compareTo_impl_ypi4mb($this, other) {
    return _get_value__a43j40($this) - _get_value__a43j40(other) | 0;
  }
  function Char__minus_impl_a2frrh($this, other) {
    return _get_value__a43j40($this) - _get_value__a43j40(other) | 0;
  }
  function Char__toInt_impl_vasixd($this) {
    return _get_value__a43j40($this);
  }
  function toString($this) {
    // Inline function 'kotlin.js.unsafeCast' call
    return String.fromCharCode(_get_value__a43j40($this));
  }
  function Char() {
  }
  function KtList() {
  }
  function Collection() {
  }
  function KtSet() {
  }
  function Entry() {
  }
  function KtMap() {
  }
  function Companion() {
  }
  var Companion_instance;
  function Companion_getInstance() {
    return Companion_instance;
  }
  function Enum(name, ordinal) {
    this.name_1 = name;
    this.ordinal_1 = ordinal;
  }
  protoOf(Enum).compareTo_30rs7w_k$ = function (other) {
    return compareTo(this.ordinal_1, other.ordinal_1);
  };
  protoOf(Enum).compareTo_hpufkf_k$ = function (other) {
    return this.compareTo_30rs7w_k$(other instanceof Enum ? other : THROW_CCE());
  };
  protoOf(Enum).equals = function (other) {
    return this === other;
  };
  protoOf(Enum).hashCode = function () {
    return identityHashCode(this);
  };
  protoOf(Enum).toString = function () {
    return this.name_1;
  };
  function toString_0(_this__u8e3s4) {
    var tmp1_elvis_lhs = _this__u8e3s4 == null ? null : toString_1(_this__u8e3s4);
    return tmp1_elvis_lhs == null ? 'null' : tmp1_elvis_lhs;
  }
  function Companion_0() {
    Companion_instance_0 = this;
    this.MIN_VALUE_1 = new Long(0, -2147483648);
    this.MAX_VALUE_1 = new Long(-1, 2147483647);
    this.SIZE_BYTES_1 = 8;
    this.SIZE_BITS_1 = 64;
  }
  var Companion_instance_0;
  function Companion_getInstance_0() {
    if (Companion_instance_0 == null)
      new Companion_0();
    return Companion_instance_0;
  }
  function Long(low, high) {
    Companion_getInstance_0();
    Number_0.call(this);
    this.low_1 = low;
    this.high_1 = high;
  }
  protoOf(Long).compareTo_222nlo_k$ = function (other) {
    return compare(this, other);
  };
  protoOf(Long).compareTo_hpufkf_k$ = function (other) {
    return this.compareTo_222nlo_k$(other instanceof Long ? other : THROW_CCE());
  };
  protoOf(Long).plus_gdf42y_k$ = function (other) {
    return add(this, other);
  };
  protoOf(Long).minus_eruey4_k$ = function (other) {
    return subtract(this, other);
  };
  protoOf(Long).times_99rz9a_k$ = function (other) {
    return multiply(this, other);
  };
  protoOf(Long).div_c9tht9_k$ = function (other) {
    return divide(this, other);
  };
  protoOf(Long).unaryMinus_6uz0qp_k$ = function () {
    return this.inv_28kx_k$().plus_gdf42y_k$(new Long(1, 0));
  };
  protoOf(Long).shl_bg8if3_k$ = function (bitCount) {
    return shiftLeft(this, bitCount);
  };
  protoOf(Long).ushr_z7nmq8_k$ = function (bitCount) {
    return shiftRightUnsigned(this, bitCount);
  };
  protoOf(Long).and_5hkqyb_k$ = function (other) {
    return new Long(this.low_1 & other.low_1, this.high_1 & other.high_1);
  };
  protoOf(Long).or_yj0lj3_k$ = function (other) {
    return new Long(this.low_1 | other.low_1, this.high_1 | other.high_1);
  };
  protoOf(Long).xor_eoldvb_k$ = function (other) {
    return new Long(this.low_1 ^ other.low_1, this.high_1 ^ other.high_1);
  };
  protoOf(Long).inv_28kx_k$ = function () {
    return new Long(~this.low_1, ~this.high_1);
  };
  protoOf(Long).toInt_1tsl84_k$ = function () {
    return this.low_1;
  };
  protoOf(Long).toDouble_ygsx0s_k$ = function () {
    return toNumber(this);
  };
  protoOf(Long).toString = function () {
    return toStringImpl(this, 10);
  };
  protoOf(Long).equals = function (other) {
    var tmp;
    if (other instanceof Long) {
      tmp = equalsLong(this, other);
    } else {
      tmp = false;
    }
    return tmp;
  };
  protoOf(Long).hashCode = function () {
    return hashCode_0(this);
  };
  protoOf(Long).valueOf = function () {
    return this.toDouble_ygsx0s_k$();
  };
  function implement(interfaces) {
    var maxSize = 1;
    var masks = [];
    var inductionVariable = 0;
    var last = interfaces.length;
    while (inductionVariable < last) {
      var i = interfaces[inductionVariable];
      inductionVariable = inductionVariable + 1 | 0;
      var currentSize = maxSize;
      var tmp0_elvis_lhs = i.prototype.$imask$;
      var imask = tmp0_elvis_lhs == null ? i.$imask$ : tmp0_elvis_lhs;
      if (!(imask == null)) {
        masks.push(imask);
        currentSize = imask.length;
      }
      var iid = i.$metadata$.iid;
      var tmp;
      if (iid == null) {
        tmp = null;
      } else {
        // Inline function 'kotlin.let' call
        tmp = bitMaskWith(iid);
      }
      var iidImask = tmp;
      if (!(iidImask == null)) {
        masks.push(iidImask);
        currentSize = Math.max(currentSize, iidImask.length);
      }
      if (currentSize > maxSize) {
        maxSize = currentSize;
      }
    }
    return compositeBitMask(maxSize, masks);
  }
  function bitMaskWith(activeBit) {
    var numberIndex = activeBit >> 5;
    var intArray = new Int32Array(numberIndex + 1 | 0);
    var positionInNumber = activeBit & 31;
    var numberWithSettledBit = 1 << positionInNumber;
    intArray[numberIndex] = intArray[numberIndex] | numberWithSettledBit;
    return intArray;
  }
  function compositeBitMask(capacity, masks) {
    var tmp = 0;
    var tmp_0 = new Int32Array(capacity);
    while (tmp < capacity) {
      var tmp_1 = tmp;
      var result = 0;
      var inductionVariable = 0;
      var last = masks.length;
      while (inductionVariable < last) {
        var mask = masks[inductionVariable];
        inductionVariable = inductionVariable + 1 | 0;
        if (tmp_1 < mask.length) {
          result = result | mask[tmp_1];
        }
      }
      tmp_0[tmp_1] = result;
      tmp = tmp + 1 | 0;
    }
    return tmp_0;
  }
  function isBitSet(_this__u8e3s4, possibleActiveBit) {
    var numberIndex = possibleActiveBit >> 5;
    if (numberIndex > _this__u8e3s4.length)
      return false;
    var positionInNumber = possibleActiveBit & 31;
    var numberWithSettledBit = 1 << positionInNumber;
    return !((_this__u8e3s4[numberIndex] & numberWithSettledBit) === 0);
  }
  function FunctionAdapter() {
  }
  function arrayIterator(array) {
    return new arrayIterator$1(array);
  }
  function charArrayOf(arr) {
    var tmp0 = 'CharArray';
    // Inline function 'withType' call
    var array = new Uint16Array(arr);
    array.$type$ = tmp0;
    // Inline function 'kotlin.js.unsafeCast' call
    return array;
  }
  function arrayIterator$1($array) {
    this.$array_1 = $array;
    this.index_1 = 0;
  }
  protoOf(arrayIterator$1).hasNext_bitz1p_k$ = function () {
    return !(this.index_1 === this.$array_1.length);
  };
  protoOf(arrayIterator$1).next_20eer_k$ = function () {
    var tmp;
    if (!(this.index_1 === this.$array_1.length)) {
      var _unary__edvuaz = this.index_1;
      this.index_1 = _unary__edvuaz + 1 | 0;
      tmp = this.$array_1[_unary__edvuaz];
    } else {
      throw NoSuchElementException_init_$Create$_0('' + this.index_1);
    }
    return tmp;
  };
  function get_buf() {
    _init_properties_bitUtils_kt__nfcg4k();
    return buf;
  }
  var buf;
  function get_bufFloat64() {
    _init_properties_bitUtils_kt__nfcg4k();
    return bufFloat64;
  }
  var bufFloat64;
  var bufFloat32;
  function get_bufInt32() {
    _init_properties_bitUtils_kt__nfcg4k();
    return bufInt32;
  }
  var bufInt32;
  function get_lowIndex() {
    _init_properties_bitUtils_kt__nfcg4k();
    return lowIndex;
  }
  var lowIndex;
  function get_highIndex() {
    _init_properties_bitUtils_kt__nfcg4k();
    return highIndex;
  }
  var highIndex;
  function getNumberHashCode(obj) {
    _init_properties_bitUtils_kt__nfcg4k();
    // Inline function 'kotlin.js.jsBitwiseOr' call
    // Inline function 'kotlin.js.unsafeCast' call
    // Inline function 'kotlin.js.asDynamic' call
    if ((obj | 0) === obj) {
      return numberToInt(obj);
    }
    get_bufFloat64()[0] = obj;
    return imul(get_bufInt32()[get_highIndex()], 31) + get_bufInt32()[get_lowIndex()] | 0;
  }
  var properties_initialized_bitUtils_kt_i2bo3e;
  function _init_properties_bitUtils_kt__nfcg4k() {
    if (!properties_initialized_bitUtils_kt_i2bo3e) {
      properties_initialized_bitUtils_kt_i2bo3e = true;
      buf = new ArrayBuffer(8);
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      bufFloat64 = new Float64Array(get_buf());
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      bufFloat32 = new Float32Array(get_buf());
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      bufInt32 = new Int32Array(get_buf());
      // Inline function 'kotlin.run' call
      get_bufFloat64()[0] = -1.0;
      lowIndex = !(get_bufInt32()[0] === 0) ? 1 : 0;
      highIndex = 1 - get_lowIndex() | 0;
    }
  }
  function charSequenceGet(a, index) {
    var tmp;
    if (isString(a)) {
      // Inline function 'kotlin.js.asDynamic' call
      // Inline function 'kotlin.js.unsafeCast' call
      var tmp$ret$1 = a.charCodeAt(index);
      tmp = numberToChar(tmp$ret$1);
    } else {
      tmp = a.get_kdzpvg_k$(index);
    }
    return tmp;
  }
  function isString(a) {
    return typeof a === 'string';
  }
  function charSequenceLength(a) {
    var tmp;
    if (isString(a)) {
      // Inline function 'kotlin.js.asDynamic' call
      // Inline function 'kotlin.js.unsafeCast' call
      tmp = a.length;
    } else {
      tmp = a.get_length_g42xv3_k$();
    }
    return tmp;
  }
  function charSequenceSubSequence(a, startIndex, endIndex) {
    var tmp;
    if (isString(a)) {
      // Inline function 'kotlin.js.asDynamic' call
      // Inline function 'kotlin.js.unsafeCast' call
      tmp = a.substring(startIndex, endIndex);
    } else {
      tmp = a.subSequence_hm5hnj_k$(startIndex, endIndex);
    }
    return tmp;
  }
  function arrayToString(array) {
    return joinToString(array, ', ', '[', ']', VOID, VOID, arrayToString$lambda);
  }
  function arrayToString$lambda(it) {
    return toString_1(it);
  }
  function compareTo(a, b) {
    var tmp;
    switch (typeof a) {
      case 'number':
        var tmp_0;
        if (typeof b === 'number') {
          tmp_0 = doubleCompareTo(a, b);
        } else {
          if (b instanceof Long) {
            tmp_0 = doubleCompareTo(a, b.toDouble_ygsx0s_k$());
          } else {
            tmp_0 = primitiveCompareTo(a, b);
          }
        }

        tmp = tmp_0;
        break;
      case 'string':
      case 'boolean':
        tmp = primitiveCompareTo(a, b);
        break;
      default:
        tmp = compareToDoNotIntrinsicify(a, b);
        break;
    }
    return tmp;
  }
  function doubleCompareTo(a, b) {
    var tmp;
    if (a < b) {
      tmp = -1;
    } else if (a > b) {
      tmp = 1;
    } else if (a === b) {
      var tmp_0;
      if (a !== 0) {
        tmp_0 = 0;
      } else {
        // Inline function 'kotlin.js.asDynamic' call
        var ia = 1 / a;
        var tmp_1;
        // Inline function 'kotlin.js.asDynamic' call
        if (ia === 1 / b) {
          tmp_1 = 0;
        } else {
          if (ia < 0) {
            tmp_1 = -1;
          } else {
            tmp_1 = 1;
          }
        }
        tmp_0 = tmp_1;
      }
      tmp = tmp_0;
    } else if (a !== a) {
      tmp = b !== b ? 0 : 1;
    } else {
      tmp = -1;
    }
    return tmp;
  }
  function primitiveCompareTo(a, b) {
    return a < b ? -1 : a > b ? 1 : 0;
  }
  function compareToDoNotIntrinsicify(a, b) {
    return a.compareTo_hpufkf_k$(b);
  }
  function identityHashCode(obj) {
    return getObjectHashCode(obj);
  }
  function getObjectHashCode(obj) {
    // Inline function 'kotlin.js.jsIn' call
    if (!('kotlinHashCodeValue$' in obj)) {
      var hash = calculateRandomHash();
      var descriptor = new Object();
      descriptor.value = hash;
      descriptor.enumerable = false;
      Object.defineProperty(obj, 'kotlinHashCodeValue$', descriptor);
    }
    // Inline function 'kotlin.js.unsafeCast' call
    return obj['kotlinHashCodeValue$'];
  }
  function calculateRandomHash() {
    // Inline function 'kotlin.js.jsBitwiseOr' call
    return Math.random() * 4.294967296E9 | 0;
  }
  function defineProp(obj, name, getter, setter) {
    return Object.defineProperty(obj, name, {configurable: true, get: getter, set: setter});
  }
  function objectCreate(proto) {
    proto = proto === VOID ? null : proto;
    return Object.create(proto);
  }
  function toString_1(o) {
    var tmp;
    if (o == null) {
      tmp = 'null';
    } else if (isArrayish(o)) {
      tmp = '[...]';
    } else if (!(typeof o.toString === 'function')) {
      tmp = anyToString(o);
    } else {
      // Inline function 'kotlin.js.unsafeCast' call
      tmp = o.toString();
    }
    return tmp;
  }
  function anyToString(o) {
    return Object.prototype.toString.call(o);
  }
  function hashCode(obj) {
    if (obj == null)
      return 0;
    var typeOf = typeof obj;
    var tmp;
    switch (typeOf) {
      case 'object':
        tmp = 'function' === typeof obj.hashCode ? obj.hashCode() : getObjectHashCode(obj);
        break;
      case 'function':
        tmp = getObjectHashCode(obj);
        break;
      case 'number':
        tmp = getNumberHashCode(obj);
        break;
      case 'boolean':
        // Inline function 'kotlin.js.unsafeCast' call

        tmp = getBooleanHashCode(obj);
        break;
      case 'string':
        tmp = getStringHashCode(String(obj));
        break;
      case 'bigint':
        tmp = getBigIntHashCode(obj);
        break;
      case 'symbol':
        tmp = getSymbolHashCode(obj);
        break;
      default:
        tmp = function () {
          throw new Error('Unexpected typeof `' + typeOf + '`');
        }();
        break;
    }
    return tmp;
  }
  function getBooleanHashCode(value) {
    return value ? 1231 : 1237;
  }
  function getStringHashCode(str) {
    var hash = 0;
    var length = str.length;
    var inductionVariable = 0;
    var last = length - 1 | 0;
    if (inductionVariable <= last)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        // Inline function 'kotlin.js.asDynamic' call
        var code = str.charCodeAt(i);
        hash = imul(hash, 31) + code | 0;
      }
       while (!(i === last));
    return hash;
  }
  function getBigIntHashCode(value) {
    var shiftNumber = BigInt(32);
    var MASK = BigInt(4.294967295E9);
    var bigNumber = value < 0 ? -value : value;
    var hashCode = 0;
    var signum = value < 0 ? -1 : 1;
    while (bigNumber != 0) {
      // Inline function 'kotlin.js.unsafeCast' call
      var chunk = Number(bigNumber & MASK);
      hashCode = imul(31, hashCode) + chunk | 0;
      bigNumber = bigNumber >> shiftNumber;
    }
    return imul(hashCode, signum);
  }
  function getSymbolHashCode(value) {
    var hashCodeMap = symbolIsSharable(value) ? getSymbolMap() : getSymbolWeakMap();
    var cachedHashCode = hashCodeMap.get(value);
    if (cachedHashCode !== VOID)
      return cachedHashCode;
    var hash = calculateRandomHash();
    hashCodeMap.set(value, hash);
    return hash;
  }
  function symbolIsSharable(symbol) {
    return Symbol.keyFor(symbol) != VOID;
  }
  function getSymbolMap() {
    if (symbolMap === VOID) {
      symbolMap = new Map();
    }
    return symbolMap;
  }
  function getSymbolWeakMap() {
    if (symbolWeakMap === VOID) {
      symbolWeakMap = new WeakMap();
    }
    return symbolWeakMap;
  }
  var symbolMap;
  var symbolWeakMap;
  function equals(obj1, obj2) {
    if (obj1 == null) {
      return obj2 == null;
    }
    if (obj2 == null) {
      return false;
    }
    if (typeof obj1 === 'object' && typeof obj1.equals === 'function') {
      return obj1.equals(obj2);
    }
    if (obj1 !== obj1) {
      return obj2 !== obj2;
    }
    if (typeof obj1 === 'number' && typeof obj2 === 'number') {
      var tmp;
      if (obj1 === obj2) {
        var tmp_0;
        if (obj1 !== 0) {
          tmp_0 = true;
        } else {
          // Inline function 'kotlin.js.asDynamic' call
          var tmp_1 = 1 / obj1;
          // Inline function 'kotlin.js.asDynamic' call
          tmp_0 = tmp_1 === 1 / obj2;
        }
        tmp = tmp_0;
      } else {
        tmp = false;
      }
      return tmp;
    }
    return obj1 === obj2;
  }
  function unboxIntrinsic(x) {
    var message = 'Should be lowered';
    throw IllegalStateException_init_$Create$_0(toString_1(message));
  }
  function captureStack(instance, constructorFunction) {
    if (Error.captureStackTrace != null) {
      Error.captureStackTrace(instance, constructorFunction);
    } else {
      // Inline function 'kotlin.js.asDynamic' call
      instance.stack = (new Error()).stack;
    }
  }
  function protoOf(constructor) {
    return constructor.prototype;
  }
  function extendThrowable(this_, message, cause) {
    Error.call(this_);
    setPropertiesToThrowableInstance(this_, message, cause);
  }
  function setPropertiesToThrowableInstance(this_, message, cause) {
    var errorInfo = calculateErrorInfo(Object.getPrototypeOf(this_));
    if ((errorInfo & 1) === 0) {
      var tmp;
      if (message == null) {
        var tmp_0;
        if (!(message === null)) {
          var tmp1_elvis_lhs = cause == null ? null : cause.toString();
          tmp_0 = tmp1_elvis_lhs == null ? VOID : tmp1_elvis_lhs;
        } else {
          tmp_0 = VOID;
        }
        tmp = tmp_0;
      } else {
        tmp = message;
      }
      this_.message = tmp;
    }
    if ((errorInfo & 2) === 0) {
      this_.cause = cause;
    }
    this_.name = Object.getPrototypeOf(this_).constructor.name;
  }
  function ensureNotNull(v) {
    var tmp;
    if (v == null) {
      THROW_NPE();
    } else {
      tmp = v;
    }
    return tmp;
  }
  function THROW_NPE() {
    throw NullPointerException_init_$Create$();
  }
  function THROW_CCE() {
    throw ClassCastException_init_$Create$();
  }
  function THROW_IAE(msg) {
    throw IllegalArgumentException_init_$Create$_0(msg);
  }
  function get_ZERO() {
    _init_properties_longJs_kt__elc2w5();
    return ZERO;
  }
  var ZERO;
  function get_ONE() {
    _init_properties_longJs_kt__elc2w5();
    return ONE;
  }
  var ONE;
  function get_NEG_ONE() {
    _init_properties_longJs_kt__elc2w5();
    return NEG_ONE;
  }
  var NEG_ONE;
  function get_MAX_VALUE() {
    _init_properties_longJs_kt__elc2w5();
    return MAX_VALUE;
  }
  var MAX_VALUE;
  function get_MIN_VALUE() {
    _init_properties_longJs_kt__elc2w5();
    return MIN_VALUE;
  }
  var MIN_VALUE;
  function get_TWO_PWR_24_() {
    _init_properties_longJs_kt__elc2w5();
    return TWO_PWR_24_;
  }
  var TWO_PWR_24_;
  function compare(_this__u8e3s4, other) {
    _init_properties_longJs_kt__elc2w5();
    if (equalsLong(_this__u8e3s4, other)) {
      return 0;
    }
    var thisNeg = isNegative(_this__u8e3s4);
    var otherNeg = isNegative(other);
    return thisNeg && !otherNeg ? -1 : !thisNeg && otherNeg ? 1 : isNegative(subtract(_this__u8e3s4, other)) ? -1 : 1;
  }
  function add(_this__u8e3s4, other) {
    _init_properties_longJs_kt__elc2w5();
    var a48 = _this__u8e3s4.high_1 >>> 16 | 0;
    var a32 = _this__u8e3s4.high_1 & 65535;
    var a16 = _this__u8e3s4.low_1 >>> 16 | 0;
    var a00 = _this__u8e3s4.low_1 & 65535;
    var b48 = other.high_1 >>> 16 | 0;
    var b32 = other.high_1 & 65535;
    var b16 = other.low_1 >>> 16 | 0;
    var b00 = other.low_1 & 65535;
    var c48 = 0;
    var c32 = 0;
    var c16 = 0;
    var c00 = 0;
    c00 = c00 + (a00 + b00 | 0) | 0;
    c16 = c16 + (c00 >>> 16 | 0) | 0;
    c00 = c00 & 65535;
    c16 = c16 + (a16 + b16 | 0) | 0;
    c32 = c32 + (c16 >>> 16 | 0) | 0;
    c16 = c16 & 65535;
    c32 = c32 + (a32 + b32 | 0) | 0;
    c48 = c48 + (c32 >>> 16 | 0) | 0;
    c32 = c32 & 65535;
    c48 = c48 + (a48 + b48 | 0) | 0;
    c48 = c48 & 65535;
    return new Long(c16 << 16 | c00, c48 << 16 | c32);
  }
  function subtract(_this__u8e3s4, other) {
    _init_properties_longJs_kt__elc2w5();
    return add(_this__u8e3s4, other.unaryMinus_6uz0qp_k$());
  }
  function multiply(_this__u8e3s4, other) {
    _init_properties_longJs_kt__elc2w5();
    if (isZero(_this__u8e3s4)) {
      return get_ZERO();
    } else if (isZero(other)) {
      return get_ZERO();
    }
    if (equalsLong(_this__u8e3s4, get_MIN_VALUE())) {
      return isOdd(other) ? get_MIN_VALUE() : get_ZERO();
    } else if (equalsLong(other, get_MIN_VALUE())) {
      return isOdd(_this__u8e3s4) ? get_MIN_VALUE() : get_ZERO();
    }
    if (isNegative(_this__u8e3s4)) {
      var tmp;
      if (isNegative(other)) {
        tmp = multiply(negate(_this__u8e3s4), negate(other));
      } else {
        tmp = negate(multiply(negate(_this__u8e3s4), other));
      }
      return tmp;
    } else if (isNegative(other)) {
      return negate(multiply(_this__u8e3s4, negate(other)));
    }
    if (lessThan(_this__u8e3s4, get_TWO_PWR_24_()) && lessThan(other, get_TWO_PWR_24_())) {
      return fromNumber(toNumber(_this__u8e3s4) * toNumber(other));
    }
    var a48 = _this__u8e3s4.high_1 >>> 16 | 0;
    var a32 = _this__u8e3s4.high_1 & 65535;
    var a16 = _this__u8e3s4.low_1 >>> 16 | 0;
    var a00 = _this__u8e3s4.low_1 & 65535;
    var b48 = other.high_1 >>> 16 | 0;
    var b32 = other.high_1 & 65535;
    var b16 = other.low_1 >>> 16 | 0;
    var b00 = other.low_1 & 65535;
    var c48 = 0;
    var c32 = 0;
    var c16 = 0;
    var c00 = 0;
    c00 = c00 + imul(a00, b00) | 0;
    c16 = c16 + (c00 >>> 16 | 0) | 0;
    c00 = c00 & 65535;
    c16 = c16 + imul(a16, b00) | 0;
    c32 = c32 + (c16 >>> 16 | 0) | 0;
    c16 = c16 & 65535;
    c16 = c16 + imul(a00, b16) | 0;
    c32 = c32 + (c16 >>> 16 | 0) | 0;
    c16 = c16 & 65535;
    c32 = c32 + imul(a32, b00) | 0;
    c48 = c48 + (c32 >>> 16 | 0) | 0;
    c32 = c32 & 65535;
    c32 = c32 + imul(a16, b16) | 0;
    c48 = c48 + (c32 >>> 16 | 0) | 0;
    c32 = c32 & 65535;
    c32 = c32 + imul(a00, b32) | 0;
    c48 = c48 + (c32 >>> 16 | 0) | 0;
    c32 = c32 & 65535;
    c48 = c48 + (((imul(a48, b00) + imul(a32, b16) | 0) + imul(a16, b32) | 0) + imul(a00, b48) | 0) | 0;
    c48 = c48 & 65535;
    return new Long(c16 << 16 | c00, c48 << 16 | c32);
  }
  function divide(_this__u8e3s4, other) {
    _init_properties_longJs_kt__elc2w5();
    if (isZero(other)) {
      throw Exception_init_$Create$_0('division by zero');
    } else if (isZero(_this__u8e3s4)) {
      return get_ZERO();
    }
    if (equalsLong(_this__u8e3s4, get_MIN_VALUE())) {
      if (equalsLong(other, get_ONE()) || equalsLong(other, get_NEG_ONE())) {
        return get_MIN_VALUE();
      } else if (equalsLong(other, get_MIN_VALUE())) {
        return get_ONE();
      } else {
        var halfThis = shiftRight(_this__u8e3s4, 1);
        var approx = shiftLeft(halfThis.div_c9tht9_k$(other), 1);
        if (equalsLong(approx, get_ZERO())) {
          return isNegative(other) ? get_ONE() : get_NEG_ONE();
        } else {
          var rem = subtract(_this__u8e3s4, multiply(other, approx));
          return add(approx, rem.div_c9tht9_k$(other));
        }
      }
    } else if (equalsLong(other, get_MIN_VALUE())) {
      return get_ZERO();
    }
    if (isNegative(_this__u8e3s4)) {
      var tmp;
      if (isNegative(other)) {
        tmp = negate(_this__u8e3s4).div_c9tht9_k$(negate(other));
      } else {
        tmp = negate(negate(_this__u8e3s4).div_c9tht9_k$(other));
      }
      return tmp;
    } else if (isNegative(other)) {
      return negate(_this__u8e3s4.div_c9tht9_k$(negate(other)));
    }
    var res = get_ZERO();
    var rem_0 = _this__u8e3s4;
    while (greaterThanOrEqual(rem_0, other)) {
      var approxDouble = toNumber(rem_0) / toNumber(other);
      var approx2 = Math.max(1.0, Math.floor(approxDouble));
      var log2 = Math.ceil(Math.log(approx2) / Math.LN2);
      var delta = log2 <= 48 ? 1.0 : Math.pow(2.0, log2 - 48);
      var approxRes = fromNumber(approx2);
      var approxRem = multiply(approxRes, other);
      while (isNegative(approxRem) || greaterThan(approxRem, rem_0)) {
        approx2 = approx2 - delta;
        approxRes = fromNumber(approx2);
        approxRem = multiply(approxRes, other);
      }
      if (isZero(approxRes)) {
        approxRes = get_ONE();
      }
      res = add(res, approxRes);
      rem_0 = subtract(rem_0, approxRem);
    }
    return res;
  }
  function shiftLeft(_this__u8e3s4, numBits) {
    _init_properties_longJs_kt__elc2w5();
    var numBits_0 = numBits & 63;
    if (numBits_0 === 0) {
      return _this__u8e3s4;
    } else {
      if (numBits_0 < 32) {
        return new Long(_this__u8e3s4.low_1 << numBits_0, _this__u8e3s4.high_1 << numBits_0 | (_this__u8e3s4.low_1 >>> (32 - numBits_0 | 0) | 0));
      } else {
        return new Long(0, _this__u8e3s4.low_1 << (numBits_0 - 32 | 0));
      }
    }
  }
  function shiftRight(_this__u8e3s4, numBits) {
    _init_properties_longJs_kt__elc2w5();
    var numBits_0 = numBits & 63;
    if (numBits_0 === 0) {
      return _this__u8e3s4;
    } else {
      if (numBits_0 < 32) {
        return new Long(_this__u8e3s4.low_1 >>> numBits_0 | 0 | _this__u8e3s4.high_1 << (32 - numBits_0 | 0), _this__u8e3s4.high_1 >> numBits_0);
      } else {
        return new Long(_this__u8e3s4.high_1 >> (numBits_0 - 32 | 0), _this__u8e3s4.high_1 >= 0 ? 0 : -1);
      }
    }
  }
  function shiftRightUnsigned(_this__u8e3s4, numBits) {
    _init_properties_longJs_kt__elc2w5();
    var numBits_0 = numBits & 63;
    if (numBits_0 === 0) {
      return _this__u8e3s4;
    } else {
      if (numBits_0 < 32) {
        return new Long(_this__u8e3s4.low_1 >>> numBits_0 | 0 | _this__u8e3s4.high_1 << (32 - numBits_0 | 0), _this__u8e3s4.high_1 >>> numBits_0 | 0);
      } else {
        var tmp;
        if (numBits_0 === 32) {
          tmp = new Long(_this__u8e3s4.high_1, 0);
        } else {
          tmp = new Long(_this__u8e3s4.high_1 >>> (numBits_0 - 32 | 0) | 0, 0);
        }
        return tmp;
      }
    }
  }
  function toNumber(_this__u8e3s4) {
    _init_properties_longJs_kt__elc2w5();
    return _this__u8e3s4.high_1 * 4.294967296E9 + getLowBitsUnsigned(_this__u8e3s4);
  }
  function toStringImpl(_this__u8e3s4, radix) {
    _init_properties_longJs_kt__elc2w5();
    if (radix < 2 || 36 < radix) {
      throw Exception_init_$Create$_0('radix out of range: ' + radix);
    }
    if (isZero(_this__u8e3s4)) {
      return '0';
    }
    if (isNegative(_this__u8e3s4)) {
      if (equalsLong(_this__u8e3s4, get_MIN_VALUE())) {
        var radixLong = fromInt(radix);
        var div = _this__u8e3s4.div_c9tht9_k$(radixLong);
        var rem = subtract(multiply(div, radixLong), _this__u8e3s4).toInt_1tsl84_k$();
        var tmp = toStringImpl(div, radix);
        // Inline function 'kotlin.js.asDynamic' call
        // Inline function 'kotlin.js.unsafeCast' call
        return tmp + rem.toString(radix);
      } else {
        return '-' + toStringImpl(negate(_this__u8e3s4), radix);
      }
    }
    var digitsPerTime = radix === 2 ? 31 : radix <= 10 ? 9 : radix <= 21 ? 7 : radix <= 35 ? 6 : 5;
    var radixToPower = fromNumber(Math.pow(radix, digitsPerTime));
    var rem_0 = _this__u8e3s4;
    var result = '';
    while (true) {
      var remDiv = rem_0.div_c9tht9_k$(radixToPower);
      var intval = subtract(rem_0, multiply(remDiv, radixToPower)).toInt_1tsl84_k$();
      // Inline function 'kotlin.js.asDynamic' call
      // Inline function 'kotlin.js.unsafeCast' call
      var digits = intval.toString(radix);
      rem_0 = remDiv;
      if (isZero(rem_0)) {
        return digits + result;
      } else {
        while (digits.length < digitsPerTime) {
          digits = '0' + digits;
        }
        result = digits + result;
      }
    }
  }
  function equalsLong(_this__u8e3s4, other) {
    _init_properties_longJs_kt__elc2w5();
    return _this__u8e3s4.high_1 === other.high_1 && _this__u8e3s4.low_1 === other.low_1;
  }
  function hashCode_0(l) {
    _init_properties_longJs_kt__elc2w5();
    return l.low_1 ^ l.high_1;
  }
  function fromInt(value) {
    _init_properties_longJs_kt__elc2w5();
    return new Long(value, value < 0 ? -1 : 0);
  }
  function isNegative(_this__u8e3s4) {
    _init_properties_longJs_kt__elc2w5();
    return _this__u8e3s4.high_1 < 0;
  }
  function isZero(_this__u8e3s4) {
    _init_properties_longJs_kt__elc2w5();
    return _this__u8e3s4.high_1 === 0 && _this__u8e3s4.low_1 === 0;
  }
  function isOdd(_this__u8e3s4) {
    _init_properties_longJs_kt__elc2w5();
    return (_this__u8e3s4.low_1 & 1) === 1;
  }
  function negate(_this__u8e3s4) {
    _init_properties_longJs_kt__elc2w5();
    return _this__u8e3s4.unaryMinus_6uz0qp_k$();
  }
  function lessThan(_this__u8e3s4, other) {
    _init_properties_longJs_kt__elc2w5();
    return compare(_this__u8e3s4, other) < 0;
  }
  function fromNumber(value) {
    _init_properties_longJs_kt__elc2w5();
    if (isNaN_0(value)) {
      return get_ZERO();
    } else if (value <= -9.223372036854776E18) {
      return get_MIN_VALUE();
    } else if (value + 1 >= 9.223372036854776E18) {
      return get_MAX_VALUE();
    } else if (value < 0) {
      return negate(fromNumber(-value));
    } else {
      var twoPwr32 = 4.294967296E9;
      // Inline function 'kotlin.js.jsBitwiseOr' call
      var tmp = value % twoPwr32 | 0;
      // Inline function 'kotlin.js.jsBitwiseOr' call
      var tmp$ret$1 = value / twoPwr32 | 0;
      return new Long(tmp, tmp$ret$1);
    }
  }
  function greaterThan(_this__u8e3s4, other) {
    _init_properties_longJs_kt__elc2w5();
    return compare(_this__u8e3s4, other) > 0;
  }
  function greaterThanOrEqual(_this__u8e3s4, other) {
    _init_properties_longJs_kt__elc2w5();
    return compare(_this__u8e3s4, other) >= 0;
  }
  function getLowBitsUnsigned(_this__u8e3s4) {
    _init_properties_longJs_kt__elc2w5();
    return _this__u8e3s4.low_1 >= 0 ? _this__u8e3s4.low_1 : 4.294967296E9 + _this__u8e3s4.low_1;
  }
  var properties_initialized_longJs_kt_4syf89;
  function _init_properties_longJs_kt__elc2w5() {
    if (!properties_initialized_longJs_kt_4syf89) {
      properties_initialized_longJs_kt_4syf89 = true;
      ZERO = fromInt(0);
      ONE = fromInt(1);
      NEG_ONE = fromInt(-1);
      MAX_VALUE = new Long(-1, 2147483647);
      MIN_VALUE = new Long(0, -2147483648);
      TWO_PWR_24_ = fromInt(16777216);
    }
  }
  function createMetadata(kind, name, defaultConstructor, associatedObjectKey, associatedObjects, suspendArity) {
    var undef = VOID;
    var iid = kind === 'interface' ? generateInterfaceId() : VOID;
    return {kind: kind, simpleName: name, associatedObjectKey: associatedObjectKey, associatedObjects: associatedObjects, suspendArity: suspendArity, $kClass$: undef, defaultConstructor: defaultConstructor, iid: iid};
  }
  function generateInterfaceId() {
    if (globalInterfaceId === VOID) {
      globalInterfaceId = 0;
    }
    // Inline function 'kotlin.js.unsafeCast' call
    globalInterfaceId = globalInterfaceId + 1 | 0;
    // Inline function 'kotlin.js.unsafeCast' call
    return globalInterfaceId;
  }
  var globalInterfaceId;
  function initMetadataFor(kind, ctor, name, defaultConstructor, parent, interfaces, suspendArity, associatedObjectKey, associatedObjects) {
    if (!(parent == null)) {
      ctor.prototype = Object.create(parent.prototype);
      ctor.prototype.constructor = ctor;
    }
    var metadata = createMetadata(kind, name, defaultConstructor, associatedObjectKey, associatedObjects, suspendArity);
    ctor.$metadata$ = metadata;
    if (!(interfaces == null)) {
      var receiver = !equals(metadata.iid, VOID) ? ctor : ctor.prototype;
      receiver.$imask$ = implement(interfaces);
    }
  }
  function initMetadataForClass(ctor, name, defaultConstructor, parent, interfaces, suspendArity, associatedObjectKey, associatedObjects) {
    var kind = 'class';
    initMetadataFor(kind, ctor, name, defaultConstructor, parent, interfaces, suspendArity, associatedObjectKey, associatedObjects);
  }
  function initMetadataForObject(ctor, name, defaultConstructor, parent, interfaces, suspendArity, associatedObjectKey, associatedObjects) {
    var kind = 'object';
    initMetadataFor(kind, ctor, name, defaultConstructor, parent, interfaces, suspendArity, associatedObjectKey, associatedObjects);
  }
  function initMetadataForInterface(ctor, name, defaultConstructor, parent, interfaces, suspendArity, associatedObjectKey, associatedObjects) {
    var kind = 'interface';
    initMetadataFor(kind, ctor, name, defaultConstructor, parent, interfaces, suspendArity, associatedObjectKey, associatedObjects);
  }
  function initMetadataForLambda(ctor, parent, interfaces, suspendArity) {
    initMetadataForClass(ctor, 'Lambda', VOID, parent, interfaces, suspendArity, VOID, VOID);
  }
  function initMetadataForCoroutine(ctor, parent, interfaces, suspendArity) {
    initMetadataForClass(ctor, 'Coroutine', VOID, parent, interfaces, suspendArity, VOID, VOID);
  }
  function initMetadataForFunctionReference(ctor, parent, interfaces, suspendArity) {
    initMetadataForClass(ctor, 'FunctionReference', VOID, parent, interfaces, suspendArity, VOID, VOID);
  }
  function initMetadataForCompanion(ctor, parent, interfaces, suspendArity) {
    initMetadataForObject(ctor, 'Companion', VOID, parent, interfaces, suspendArity, VOID, VOID);
  }
  function arrayConcat(args) {
    var len = args.length;
    // Inline function 'kotlin.js.unsafeCast' call
    var typed = Array(len);
    var inductionVariable = 0;
    var last = len - 1 | 0;
    if (inductionVariable <= last)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var arr = args[i];
        if (!(!(arr == null) ? isArray(arr) : false)) {
          typed[i] = [].slice.call(arr);
        } else {
          typed[i] = arr;
        }
      }
       while (!(i === last));
    return [].concat.apply([], typed);
  }
  function numberToInt(a) {
    var tmp;
    if (a instanceof Long) {
      tmp = a.toInt_1tsl84_k$();
    } else {
      tmp = doubleToInt(a);
    }
    return tmp;
  }
  function doubleToInt(a) {
    var tmp;
    if (a > 2147483647) {
      tmp = 2147483647;
    } else if (a < -2147483648) {
      tmp = -2147483648;
    } else {
      // Inline function 'kotlin.js.jsBitwiseOr' call
      tmp = a | 0;
    }
    return tmp;
  }
  function numberToDouble(a) {
    // Inline function 'kotlin.js.unsafeCast' call
    return +a;
  }
  function toShort(a) {
    // Inline function 'kotlin.js.unsafeCast' call
    return a << 16 >> 16;
  }
  function numberToLong(a) {
    var tmp;
    if (a instanceof Long) {
      tmp = a;
    } else {
      tmp = fromNumber(a);
    }
    return tmp;
  }
  function numberToChar(a) {
    // Inline function 'kotlin.toUShort' call
    var this_0 = numberToInt(a);
    var tmp$ret$0 = _UShort___init__impl__jigrne(toShort(this_0));
    return _Char___init__impl__6a9atx_0(tmp$ret$0);
  }
  function toLong(a) {
    return fromInt(a);
  }
  function numberRangeToNumber(start, endInclusive) {
    return new IntRange(start, endInclusive);
  }
  function get_propertyRefClassMetadataCache() {
    _init_properties_reflectRuntime_kt__5r4uu3();
    return propertyRefClassMetadataCache;
  }
  var propertyRefClassMetadataCache;
  function metadataObject() {
    _init_properties_reflectRuntime_kt__5r4uu3();
    return createMetadata('class', VOID, VOID, VOID, VOID, VOID);
  }
  function getPropertyCallableRef(name, paramCount, superType, getter, setter) {
    _init_properties_reflectRuntime_kt__5r4uu3();
    getter.get = getter;
    getter.set = setter;
    getter.callableName = name;
    // Inline function 'kotlin.js.unsafeCast' call
    return getPropertyRefClass(getter, getKPropMetadata(paramCount, setter), getInterfaceMaskFor(getter, superType));
  }
  function getPropertyRefClass(obj, metadata, imask) {
    _init_properties_reflectRuntime_kt__5r4uu3();
    obj.$metadata$ = metadata;
    obj.constructor = obj;
    obj.$imask$ = imask;
    return obj;
  }
  function getKPropMetadata(paramCount, setter) {
    _init_properties_reflectRuntime_kt__5r4uu3();
    return get_propertyRefClassMetadataCache()[paramCount][setter == null ? 0 : 1];
  }
  function getInterfaceMaskFor(obj, superType) {
    _init_properties_reflectRuntime_kt__5r4uu3();
    var tmp0_elvis_lhs = obj.$imask$;
    var tmp;
    if (tmp0_elvis_lhs == null) {
      // Inline function 'kotlin.arrayOf' call
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      var tmp$ret$2 = [superType];
      tmp = implement(tmp$ret$2);
    } else {
      tmp = tmp0_elvis_lhs;
    }
    return tmp;
  }
  var properties_initialized_reflectRuntime_kt_inkhwd;
  function _init_properties_reflectRuntime_kt__5r4uu3() {
    if (!properties_initialized_reflectRuntime_kt_inkhwd) {
      properties_initialized_reflectRuntime_kt_inkhwd = true;
      // Inline function 'kotlin.arrayOf' call
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      var tmp = [metadataObject(), metadataObject()];
      // Inline function 'kotlin.arrayOf' call
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      var tmp_0 = [metadataObject(), metadataObject()];
      // Inline function 'kotlin.arrayOf' call
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      // Inline function 'kotlin.arrayOf' call
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      propertyRefClassMetadataCache = [tmp, tmp_0, [metadataObject(), metadataObject()]];
    }
  }
  function isArrayish(o) {
    return isJsArray(o) || isView(o);
  }
  function isJsArray(obj) {
    // Inline function 'kotlin.js.unsafeCast' call
    return Array.isArray(obj);
  }
  function isInterface(obj, iface) {
    return isInterfaceImpl(obj, iface.$metadata$.iid);
  }
  function isInterfaceImpl(obj, iface) {
    // Inline function 'kotlin.js.unsafeCast' call
    var tmp0_elvis_lhs = obj.$imask$;
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return false;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var mask = tmp;
    return isBitSet(mask, iface);
  }
  function isArray(obj) {
    var tmp;
    if (isJsArray(obj)) {
      // Inline function 'kotlin.js.asDynamic' call
      tmp = !obj.$type$;
    } else {
      tmp = false;
    }
    return tmp;
  }
  function isNumber(a) {
    var tmp;
    if (typeof a === 'number') {
      tmp = true;
    } else {
      tmp = a instanceof Long;
    }
    return tmp;
  }
  function isComparable(value) {
    var type = typeof value;
    return type === 'string' || type === 'boolean' || isNumber(value) || isInterface(value, Comparable);
  }
  function isCharSequence(value) {
    return typeof value === 'string' || isInterface(value, CharSequence);
  }
  function calculateErrorInfo(proto) {
    var tmp0_safe_receiver = proto.constructor;
    var metadata = tmp0_safe_receiver == null ? null : tmp0_safe_receiver.$metadata$;
    var tmp2_safe_receiver = metadata == null ? null : metadata.errorInfo;
    if (tmp2_safe_receiver == null)
      null;
    else {
      // Inline function 'kotlin.let' call
      return tmp2_safe_receiver;
    }
    var result = 0;
    if (hasProp(proto, 'message'))
      result = result | 1;
    if (hasProp(proto, 'cause'))
      result = result | 2;
    if (!(result === 3)) {
      var parentProto = getPrototypeOf(proto);
      if (parentProto != Error.prototype) {
        result = result | calculateErrorInfo(parentProto);
      }
    }
    if (!(metadata == null)) {
      metadata.errorInfo = result;
    }
    return result;
  }
  function hasProp(proto, propName) {
    return proto.hasOwnProperty(propName);
  }
  function getPrototypeOf(obj) {
    return Object.getPrototypeOf(obj);
  }
  function get_VOID() {
    _init_properties_void_kt__3zg9as();
    return VOID;
  }
  var VOID;
  var properties_initialized_void_kt_e4ret2;
  function _init_properties_void_kt__3zg9as() {
    if (!properties_initialized_void_kt_e4ret2) {
      properties_initialized_void_kt_e4ret2 = true;
      VOID = void 0;
    }
  }
  function asList(_this__u8e3s4) {
    // Inline function 'kotlin.js.unsafeCast' call
    // Inline function 'kotlin.js.asDynamic' call
    return new ArrayList(_this__u8e3s4);
  }
  function sort(_this__u8e3s4) {
    if (_this__u8e3s4.length > 1) {
      sortArray(_this__u8e3s4);
    }
  }
  function sortWith(_this__u8e3s4, comparator) {
    if (_this__u8e3s4.length > 1) {
      sortArrayWith(_this__u8e3s4, comparator);
    }
  }
  function copyOf(_this__u8e3s4, newSize) {
    // Inline function 'kotlin.require' call
    if (!(newSize >= 0)) {
      var message = 'Invalid new array size: ' + newSize + '.';
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    return fillFrom(_this__u8e3s4, new Int32Array(newSize));
  }
  function copyOf_0(_this__u8e3s4, newSize) {
    // Inline function 'kotlin.require' call
    if (!(newSize >= 0)) {
      var message = 'Invalid new array size: ' + newSize + '.';
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    return arrayCopyResize(_this__u8e3s4, newSize, null);
  }
  function reverse(_this__u8e3s4) {
    var midPoint = (_this__u8e3s4.get_size_woubt6_k$() / 2 | 0) - 1 | 0;
    if (midPoint < 0)
      return Unit_instance;
    var reverseIndex = get_lastIndex_0(_this__u8e3s4);
    var inductionVariable = 0;
    if (inductionVariable <= midPoint)
      do {
        var index = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var tmp = _this__u8e3s4.get_c1px32_k$(index);
        _this__u8e3s4.set_82063s_k$(index, _this__u8e3s4.get_c1px32_k$(reverseIndex));
        _this__u8e3s4.set_82063s_k$(reverseIndex, tmp);
        reverseIndex = reverseIndex - 1 | 0;
      }
       while (!(index === midPoint));
  }
  function isDigitImpl(_this__u8e3s4) {
    return digitToIntImpl(_this__u8e3s4) >= 0;
  }
  function digitToIntImpl(_this__u8e3s4) {
    // Inline function 'kotlin.code' call
    var ch = Char__toInt_impl_vasixd(_this__u8e3s4);
    var index = binarySearchRange(Digit_getInstance().rangeStart_1, ch);
    var diff = ch - Digit_getInstance().rangeStart_1[index] | 0;
    return diff < 10 ? diff : -1;
  }
  function binarySearchRange(array, needle) {
    var bottom = 0;
    var top = array.length - 1 | 0;
    var middle = -1;
    var value = 0;
    while (bottom <= top) {
      middle = (bottom + top | 0) / 2 | 0;
      value = array[middle];
      if (needle > value)
        bottom = middle + 1 | 0;
      else if (needle === value)
        return middle;
      else
        top = middle - 1 | 0;
    }
    return middle - (needle < value ? 1 : 0) | 0;
  }
  function Digit() {
    Digit_instance = this;
    var tmp = this;
    // Inline function 'kotlin.intArrayOf' call
    tmp.rangeStart_1 = new Int32Array([48, 1632, 1776, 1984, 2406, 2534, 2662, 2790, 2918, 3046, 3174, 3302, 3430, 3558, 3664, 3792, 3872, 4160, 4240, 6112, 6160, 6470, 6608, 6784, 6800, 6992, 7088, 7232, 7248, 42528, 43216, 43264, 43472, 43504, 43600, 44016, 65296]);
  }
  var Digit_instance;
  function Digit_getInstance() {
    if (Digit_instance == null)
      new Digit();
    return Digit_instance;
  }
  function isWhitespaceImpl(_this__u8e3s4) {
    // Inline function 'kotlin.code' call
    var ch = Char__toInt_impl_vasixd(_this__u8e3s4);
    return (9 <= ch ? ch <= 13 : false) || (28 <= ch ? ch <= 32 : false) || ch === 160 || (ch > 4096 && (ch === 5760 || (8192 <= ch ? ch <= 8202 : false) || ch === 8232 || ch === 8233 || ch === 8239 || ch === 8287 || ch === 12288));
  }
  function Comparator() {
  }
  function isNaN_0(_this__u8e3s4) {
    return !(_this__u8e3s4 === _this__u8e3s4);
  }
  function takeHighestOneBit(_this__u8e3s4) {
    var tmp;
    if (_this__u8e3s4 === 0) {
      tmp = 0;
    } else {
      // Inline function 'kotlin.countLeadingZeroBits' call
      tmp = 1 << (31 - clz32(_this__u8e3s4) | 0);
    }
    return tmp;
  }
  function Unit() {
  }
  protoOf(Unit).toString = function () {
    return 'kotlin.Unit';
  };
  var Unit_instance;
  function Unit_getInstance() {
    return Unit_instance;
  }
  function ulongToString(value, base) {
    if (value.compareTo_222nlo_k$(new Long(0, 0)) >= 0)
      return toString_2(value, base);
    // Inline function 'kotlin.Long.div' call
    var quotient = value.ushr_z7nmq8_k$(1).div_c9tht9_k$(toLong(base)).shl_bg8if3_k$(1);
    // Inline function 'kotlin.Long.times' call
    var tmp$ret$1 = quotient.times_99rz9a_k$(toLong(base));
    var rem = value.minus_eruey4_k$(tmp$ret$1);
    if (rem.compareTo_222nlo_k$(toLong(base)) >= 0) {
      // Inline function 'kotlin.Long.minus' call
      rem = rem.minus_eruey4_k$(toLong(base));
      // Inline function 'kotlin.Long.plus' call
      quotient = quotient.plus_gdf42y_k$(toLong(1));
    }
    return toString_2(quotient, base) + toString_2(rem, base);
  }
  function collectionToArray(collection) {
    return collectionToArrayCommonImpl(collection);
  }
  function listOf(element) {
    return arrayListOf([element]);
  }
  function mapCapacity(expectedSize) {
    return expectedSize;
  }
  function sort_0(_this__u8e3s4) {
    collectionsSort(_this__u8e3s4, naturalOrder());
  }
  function checkIndexOverflow(index) {
    if (index < 0) {
      throwIndexOverflow();
    }
    return index;
  }
  function sortWith_0(_this__u8e3s4, comparator) {
    collectionsSort(_this__u8e3s4, comparator);
  }
  function copyToArray(collection) {
    var tmp;
    // Inline function 'kotlin.js.asDynamic' call
    if (collection.toArray !== undefined) {
      // Inline function 'kotlin.js.asDynamic' call
      // Inline function 'kotlin.js.unsafeCast' call
      tmp = collection.toArray();
    } else {
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      tmp = collectionToArray(collection);
    }
    return tmp;
  }
  function collectionsSort(list, comparator) {
    if (list.get_size_woubt6_k$() <= 1)
      return Unit_instance;
    var array = copyToArray(list);
    sortArrayWith(array, comparator);
    var inductionVariable = 0;
    var last = array.length;
    if (inductionVariable < last)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        list.set_82063s_k$(i, array[i]);
      }
       while (inductionVariable < last);
  }
  function setOf(element) {
    return hashSetOf([element]);
  }
  function AbstractMutableCollection() {
    AbstractCollection.call(this);
  }
  protoOf(AbstractMutableCollection).addAll_h3ej1q_k$ = function (elements) {
    this.checkIsMutable_jn1ih0_k$();
    var modified = false;
    var _iterator__ex2g4s = elements.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      if (this.add_utx5q5_k$(element))
        modified = true;
    }
    return modified;
  };
  protoOf(AbstractMutableCollection).toJSON = function () {
    return this.toArray();
  };
  protoOf(AbstractMutableCollection).checkIsMutable_jn1ih0_k$ = function () {
  };
  function IteratorImpl($outer) {
    this.$this_1 = $outer;
    this.index_1 = 0;
    this.last_1 = -1;
  }
  protoOf(IteratorImpl).hasNext_bitz1p_k$ = function () {
    return this.index_1 < this.$this_1.get_size_woubt6_k$();
  };
  protoOf(IteratorImpl).next_20eer_k$ = function () {
    if (!this.hasNext_bitz1p_k$())
      throw NoSuchElementException_init_$Create$();
    var tmp = this;
    var _unary__edvuaz = this.index_1;
    this.index_1 = _unary__edvuaz + 1 | 0;
    tmp.last_1 = _unary__edvuaz;
    return this.$this_1.get_c1px32_k$(this.last_1);
  };
  function ListIteratorImpl($outer, index) {
    this.$this_2 = $outer;
    IteratorImpl.call(this, $outer);
    Companion_instance_4.checkPositionIndex_w4k0on_k$(index, this.$this_2.get_size_woubt6_k$());
    this.index_1 = index;
  }
  protoOf(ListIteratorImpl).hasPrevious_qh0629_k$ = function () {
    return this.index_1 > 0;
  };
  protoOf(ListIteratorImpl).previous_l2dfd5_k$ = function () {
    if (!this.hasPrevious_qh0629_k$())
      throw NoSuchElementException_init_$Create$();
    var tmp = this;
    this.index_1 = this.index_1 - 1 | 0;
    tmp.last_1 = this.index_1;
    return this.$this_2.get_c1px32_k$(this.last_1);
  };
  function AbstractMutableList() {
    AbstractMutableCollection.call(this);
    this.modCount_1 = 0;
  }
  protoOf(AbstractMutableList).add_utx5q5_k$ = function (element) {
    this.checkIsMutable_jn1ih0_k$();
    this.add_dl6gt3_k$(this.get_size_woubt6_k$(), element);
    return true;
  };
  protoOf(AbstractMutableList).iterator_jk1svi_k$ = function () {
    return new IteratorImpl(this);
  };
  protoOf(AbstractMutableList).contains_aljjnj_k$ = function (element) {
    return this.indexOf_si1fv9_k$(element) >= 0;
  };
  protoOf(AbstractMutableList).indexOf_si1fv9_k$ = function (element) {
    var tmp$ret$1;
    $l$block: {
      // Inline function 'kotlin.collections.indexOfFirst' call
      var index = 0;
      var _iterator__ex2g4s = this.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var item = _iterator__ex2g4s.next_20eer_k$();
        if (equals(item, element)) {
          tmp$ret$1 = index;
          break $l$block;
        }
        index = index + 1 | 0;
      }
      tmp$ret$1 = -1;
    }
    return tmp$ret$1;
  };
  protoOf(AbstractMutableList).listIterator_70e65o_k$ = function (index) {
    return new ListIteratorImpl(this, index);
  };
  protoOf(AbstractMutableList).equals = function (other) {
    if (other === this)
      return true;
    if (!(!(other == null) ? isInterface(other, KtList) : false))
      return false;
    return Companion_instance_4.orderedEquals_jt170c_k$(this, other);
  };
  protoOf(AbstractMutableList).hashCode = function () {
    return Companion_instance_4.orderedHashCode_srkix_k$(this);
  };
  function AbstractMutableMap() {
    AbstractMap.call(this);
    this.keysView_1 = null;
    this.valuesView_1 = null;
  }
  function AbstractMutableSet() {
    AbstractMutableCollection.call(this);
  }
  protoOf(AbstractMutableSet).equals = function (other) {
    if (other === this)
      return true;
    if (!(!(other == null) ? isInterface(other, KtSet) : false))
      return false;
    return Companion_instance_6.setEquals_mjzluv_k$(this, other);
  };
  protoOf(AbstractMutableSet).hashCode = function () {
    return Companion_instance_6.unorderedHashCode_8c2ypq_k$(this);
  };
  function arrayOfUninitializedElements(capacity) {
    // Inline function 'kotlin.require' call
    if (!(capacity >= 0)) {
      var message = 'capacity must be non-negative.';
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    // Inline function 'kotlin.arrayOfNulls' call
    // Inline function 'kotlin.js.unsafeCast' call
    // Inline function 'kotlin.js.asDynamic' call
    return Array(capacity);
  }
  function resetRange(_this__u8e3s4, fromIndex, toIndex) {
    // Inline function 'kotlin.js.nativeFill' call
    // Inline function 'kotlin.js.asDynamic' call
    _this__u8e3s4.fill(null, fromIndex, toIndex);
  }
  function copyOfUninitializedElements(_this__u8e3s4, newSize) {
    // Inline function 'kotlin.js.unsafeCast' call
    // Inline function 'kotlin.js.asDynamic' call
    return copyOf_0(_this__u8e3s4, newSize);
  }
  function Companion_1() {
    Companion_instance_1 = this;
    var tmp = this;
    // Inline function 'kotlin.also' call
    var this_0 = ArrayList_init_$Create$_0(0);
    this_0.isReadOnly_1 = true;
    tmp.Empty_1 = this_0;
  }
  var Companion_instance_1;
  function Companion_getInstance_1() {
    if (Companion_instance_1 == null)
      new Companion_1();
    return Companion_instance_1;
  }
  function ArrayList_init_$Init$($this) {
    // Inline function 'kotlin.emptyArray' call
    var tmp$ret$0 = [];
    ArrayList.call($this, tmp$ret$0);
    return $this;
  }
  function ArrayList_init_$Create$() {
    return ArrayList_init_$Init$(objectCreate(protoOf(ArrayList)));
  }
  function ArrayList_init_$Init$_0(initialCapacity, $this) {
    // Inline function 'kotlin.emptyArray' call
    var tmp$ret$0 = [];
    ArrayList.call($this, tmp$ret$0);
    // Inline function 'kotlin.require' call
    if (!(initialCapacity >= 0)) {
      var message = 'Negative initial capacity: ' + initialCapacity;
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    return $this;
  }
  function ArrayList_init_$Create$_0(initialCapacity) {
    return ArrayList_init_$Init$_0(initialCapacity, objectCreate(protoOf(ArrayList)));
  }
  function ArrayList_init_$Init$_1(elements, $this) {
    // Inline function 'kotlin.collections.toTypedArray' call
    var tmp$ret$0 = copyToArray(elements);
    ArrayList.call($this, tmp$ret$0);
    return $this;
  }
  function ArrayList_init_$Create$_1(elements) {
    return ArrayList_init_$Init$_1(elements, objectCreate(protoOf(ArrayList)));
  }
  function increaseLength($this, amount) {
    var previous = $this.get_size_woubt6_k$();
    // Inline function 'kotlin.js.asDynamic' call
    $this.array_1.length = $this.get_size_woubt6_k$() + amount | 0;
    return previous;
  }
  function rangeCheck($this, index) {
    // Inline function 'kotlin.apply' call
    Companion_instance_4.checkElementIndex_s0yg86_k$(index, $this.get_size_woubt6_k$());
    return index;
  }
  function insertionRangeCheck($this, index) {
    // Inline function 'kotlin.apply' call
    Companion_instance_4.checkPositionIndex_w4k0on_k$(index, $this.get_size_woubt6_k$());
    return index;
  }
  function ArrayList(array) {
    Companion_getInstance_1();
    AbstractMutableList.call(this);
    this.array_1 = array;
    this.isReadOnly_1 = false;
  }
  protoOf(ArrayList).build_nmwvly_k$ = function () {
    this.checkIsMutable_jn1ih0_k$();
    this.isReadOnly_1 = true;
    return this.get_size_woubt6_k$() > 0 ? this : Companion_getInstance_1().Empty_1;
  };
  protoOf(ArrayList).get_size_woubt6_k$ = function () {
    return this.array_1.length;
  };
  protoOf(ArrayList).get_c1px32_k$ = function (index) {
    var tmp = this.array_1[rangeCheck(this, index)];
    return (tmp == null ? true : !(tmp == null)) ? tmp : THROW_CCE();
  };
  protoOf(ArrayList).set_82063s_k$ = function (index, element) {
    this.checkIsMutable_jn1ih0_k$();
    rangeCheck(this, index);
    // Inline function 'kotlin.apply' call
    var this_0 = this.array_1[index];
    this.array_1[index] = element;
    var tmp = this_0;
    return (tmp == null ? true : !(tmp == null)) ? tmp : THROW_CCE();
  };
  protoOf(ArrayList).add_utx5q5_k$ = function (element) {
    this.checkIsMutable_jn1ih0_k$();
    // Inline function 'kotlin.js.asDynamic' call
    this.array_1.push(element);
    this.modCount_1 = this.modCount_1 + 1 | 0;
    return true;
  };
  protoOf(ArrayList).add_dl6gt3_k$ = function (index, element) {
    this.checkIsMutable_jn1ih0_k$();
    // Inline function 'kotlin.js.asDynamic' call
    this.array_1.splice(insertionRangeCheck(this, index), 0, element);
    this.modCount_1 = this.modCount_1 + 1 | 0;
  };
  protoOf(ArrayList).addAll_h3ej1q_k$ = function (elements) {
    this.checkIsMutable_jn1ih0_k$();
    if (elements.isEmpty_y1axqb_k$())
      return false;
    var offset = increaseLength(this, elements.get_size_woubt6_k$());
    // Inline function 'kotlin.collections.forEachIndexed' call
    var index = 0;
    var _iterator__ex2g4s = elements.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s.next_20eer_k$();
      var _unary__edvuaz = index;
      index = _unary__edvuaz + 1 | 0;
      var index_0 = checkIndexOverflow(_unary__edvuaz);
      this.array_1[offset + index_0 | 0] = item;
    }
    this.modCount_1 = this.modCount_1 + 1 | 0;
    return true;
  };
  protoOf(ArrayList).removeAt_6niowx_k$ = function (index) {
    this.checkIsMutable_jn1ih0_k$();
    rangeCheck(this, index);
    this.modCount_1 = this.modCount_1 + 1 | 0;
    var tmp;
    if (index === get_lastIndex_0(this)) {
      // Inline function 'kotlin.js.asDynamic' call
      tmp = this.array_1.pop();
    } else {
      // Inline function 'kotlin.js.asDynamic' call
      tmp = this.array_1.splice(index, 1)[0];
    }
    return tmp;
  };
  protoOf(ArrayList).indexOf_si1fv9_k$ = function (element) {
    return indexOf(this.array_1, element);
  };
  protoOf(ArrayList).toString = function () {
    return arrayToString(this.array_1);
  };
  protoOf(ArrayList).toArray_jjyjqa_k$ = function () {
    return [].slice.call(this.array_1);
  };
  protoOf(ArrayList).toArray = function () {
    return this.toArray_jjyjqa_k$();
  };
  protoOf(ArrayList).checkIsMutable_jn1ih0_k$ = function () {
    if (this.isReadOnly_1)
      throw UnsupportedOperationException_init_$Create$();
  };
  var _stableSortingIsSupported;
  function sortArrayWith(array, comparator) {
    if (getStableSortingIsSupported()) {
      var comparison = sortArrayWith$lambda(comparator);
      // Inline function 'kotlin.js.asDynamic' call
      array.sort(comparison);
    } else {
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      mergeSort(array, 0, get_lastIndex(array), comparator);
    }
  }
  function sortArray(array) {
    if (getStableSortingIsSupported()) {
      var comparison = sortArray$lambda;
      // Inline function 'kotlin.js.asDynamic' call
      array.sort(comparison);
    } else {
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      mergeSort(array, 0, get_lastIndex(array), naturalOrder());
    }
  }
  function getStableSortingIsSupported() {
    var tmp0_safe_receiver = _stableSortingIsSupported;
    if (tmp0_safe_receiver == null)
      null;
    else {
      // Inline function 'kotlin.let' call
      return tmp0_safe_receiver;
    }
    _stableSortingIsSupported = false;
    // Inline function 'kotlin.js.unsafeCast' call
    var array = [];
    var inductionVariable = 0;
    if (inductionVariable < 600)
      do {
        var index = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        // Inline function 'kotlin.js.asDynamic' call
        array.push(index);
      }
       while (inductionVariable < 600);
    var comparison = getStableSortingIsSupported$lambda;
    // Inline function 'kotlin.js.asDynamic' call
    array.sort(comparison);
    var inductionVariable_0 = 1;
    var last = array.length;
    if (inductionVariable_0 < last)
      do {
        var index_0 = inductionVariable_0;
        inductionVariable_0 = inductionVariable_0 + 1 | 0;
        var a = array[index_0 - 1 | 0];
        var b = array[index_0];
        if ((a & 3) === (b & 3) && a >= b)
          return false;
      }
       while (inductionVariable_0 < last);
    _stableSortingIsSupported = true;
    return true;
  }
  function mergeSort(array, start, endInclusive, comparator) {
    // Inline function 'kotlin.arrayOfNulls' call
    var size = array.length;
    // Inline function 'kotlin.js.unsafeCast' call
    // Inline function 'kotlin.js.asDynamic' call
    var buffer = Array(size);
    var result = mergeSort_0(array, buffer, start, endInclusive, comparator);
    if (!(result === array)) {
      var inductionVariable = start;
      if (inductionVariable <= endInclusive)
        do {
          var i = inductionVariable;
          inductionVariable = inductionVariable + 1 | 0;
          array[i] = result[i];
        }
         while (!(i === endInclusive));
    }
  }
  function mergeSort_0(array, buffer, start, end, comparator) {
    if (start === end) {
      return array;
    }
    var median = (start + end | 0) / 2 | 0;
    var left = mergeSort_0(array, buffer, start, median, comparator);
    var right = mergeSort_0(array, buffer, median + 1 | 0, end, comparator);
    var target = left === buffer ? array : buffer;
    var leftIndex = start;
    var rightIndex = median + 1 | 0;
    var inductionVariable = start;
    if (inductionVariable <= end)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        if (leftIndex <= median && rightIndex <= end) {
          var leftValue = left[leftIndex];
          var rightValue = right[rightIndex];
          if (comparator.compare(leftValue, rightValue) <= 0) {
            target[i] = leftValue;
            leftIndex = leftIndex + 1 | 0;
          } else {
            target[i] = rightValue;
            rightIndex = rightIndex + 1 | 0;
          }
        } else if (leftIndex <= median) {
          target[i] = left[leftIndex];
          leftIndex = leftIndex + 1 | 0;
        } else {
          target[i] = right[rightIndex];
          rightIndex = rightIndex + 1 | 0;
        }
      }
       while (!(i === end));
    return target;
  }
  function sortArrayWith$lambda($comparator) {
    return function (a, b) {
      return $comparator.compare(a, b);
    };
  }
  function sortArray$lambda(a, b) {
    return compareTo(a, b);
  }
  function getStableSortingIsSupported$lambda(a, b) {
    return (a & 3) - (b & 3) | 0;
  }
  function HashMap_init_$Init$(internalMap, $this) {
    AbstractMutableMap.call($this);
    HashMap.call($this);
    $this.internalMap_1 = internalMap;
    return $this;
  }
  function HashMap_init_$Init$_0($this) {
    HashMap_init_$Init$(InternalHashMap_init_$Create$(), $this);
    return $this;
  }
  function HashMap_init_$Create$() {
    return HashMap_init_$Init$_0(objectCreate(protoOf(HashMap)));
  }
  function HashMap_init_$Init$_1(initialCapacity, loadFactor, $this) {
    HashMap_init_$Init$(InternalHashMap_init_$Create$_1(initialCapacity, loadFactor), $this);
    return $this;
  }
  function HashMap_init_$Init$_2(initialCapacity, $this) {
    HashMap_init_$Init$_1(initialCapacity, 1.0, $this);
    return $this;
  }
  function HashMap_init_$Init$_3(original, $this) {
    HashMap_init_$Init$(InternalHashMap_init_$Create$_0(original), $this);
    return $this;
  }
  protoOf(HashMap).containsKey_aw81wo_k$ = function (key) {
    return this.internalMap_1.contains_vbgn2f_k$(key);
  };
  protoOf(HashMap).get_entries_p20ztl_k$ = function () {
    var tmp0_elvis_lhs = this.entriesView_1;
    var tmp;
    if (tmp0_elvis_lhs == null) {
      // Inline function 'kotlin.also' call
      var this_0 = new HashMapEntrySet(this.internalMap_1);
      this.entriesView_1 = this_0;
      tmp = this_0;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    return tmp;
  };
  protoOf(HashMap).get_wei43m_k$ = function (key) {
    return this.internalMap_1.get_wei43m_k$(key);
  };
  protoOf(HashMap).put_4fpzoq_k$ = function (key, value) {
    return this.internalMap_1.put_4fpzoq_k$(key, value);
  };
  protoOf(HashMap).get_size_woubt6_k$ = function () {
    return this.internalMap_1.get_size_woubt6_k$();
  };
  function HashMap() {
    this.entriesView_1 = null;
  }
  function HashMapEntrySet(backing) {
    HashMapEntrySetBase.call(this, backing);
  }
  protoOf(HashMapEntrySet).iterator_jk1svi_k$ = function () {
    return this.backing_1.entriesIterator_or017i_k$();
  };
  function HashMapEntrySetBase(backing) {
    AbstractMutableSet.call(this);
    this.backing_1 = backing;
  }
  protoOf(HashMapEntrySetBase).get_size_woubt6_k$ = function () {
    return this.backing_1.get_size_woubt6_k$();
  };
  protoOf(HashMapEntrySetBase).isEmpty_y1axqb_k$ = function () {
    return this.backing_1.get_size_woubt6_k$() === 0;
  };
  protoOf(HashMapEntrySetBase).contains_pftbw2_k$ = function (element) {
    return this.backing_1.containsEntry_jg6xfi_k$(element);
  };
  protoOf(HashMapEntrySetBase).contains_aljjnj_k$ = function (element) {
    if (!(!(element == null) ? isInterface(element, Entry) : false))
      return false;
    return this.contains_pftbw2_k$((!(element == null) ? isInterface(element, Entry) : false) ? element : THROW_CCE());
  };
  protoOf(HashMapEntrySetBase).add_k8z7xs_k$ = function (element) {
    throw UnsupportedOperationException_init_$Create$();
  };
  protoOf(HashMapEntrySetBase).add_utx5q5_k$ = function (element) {
    return this.add_k8z7xs_k$((!(element == null) ? isInterface(element, Entry) : false) ? element : THROW_CCE());
  };
  protoOf(HashMapEntrySetBase).addAll_h3ej1q_k$ = function (elements) {
    throw UnsupportedOperationException_init_$Create$();
  };
  protoOf(HashMapEntrySetBase).containsAll_bwkf3g_k$ = function (elements) {
    return this.backing_1.containsAllEntries_m9iqdx_k$(elements);
  };
  protoOf(HashMapEntrySetBase).checkIsMutable_jn1ih0_k$ = function () {
    return this.backing_1.checkIsMutable_h5js84_k$();
  };
  function HashSet_init_$Init$(map, $this) {
    AbstractMutableSet.call($this);
    HashSet.call($this);
    $this.internalMap_1 = map;
    return $this;
  }
  function HashSet_init_$Init$_0($this) {
    HashSet_init_$Init$(InternalHashMap_init_$Create$(), $this);
    return $this;
  }
  function HashSet_init_$Create$() {
    return HashSet_init_$Init$_0(objectCreate(protoOf(HashSet)));
  }
  function HashSet_init_$Init$_1(initialCapacity, loadFactor, $this) {
    HashSet_init_$Init$(InternalHashMap_init_$Create$_1(initialCapacity, loadFactor), $this);
    return $this;
  }
  function HashSet_init_$Init$_2(initialCapacity, $this) {
    HashSet_init_$Init$_1(initialCapacity, 1.0, $this);
    return $this;
  }
  function HashSet_init_$Create$_0(initialCapacity) {
    return HashSet_init_$Init$_2(initialCapacity, objectCreate(protoOf(HashSet)));
  }
  protoOf(HashSet).add_utx5q5_k$ = function (element) {
    return this.internalMap_1.put_4fpzoq_k$(element, true) == null;
  };
  protoOf(HashSet).contains_aljjnj_k$ = function (element) {
    return this.internalMap_1.contains_vbgn2f_k$(element);
  };
  protoOf(HashSet).isEmpty_y1axqb_k$ = function () {
    return this.internalMap_1.get_size_woubt6_k$() === 0;
  };
  protoOf(HashSet).iterator_jk1svi_k$ = function () {
    return this.internalMap_1.keysIterator_mjslfm_k$();
  };
  protoOf(HashSet).get_size_woubt6_k$ = function () {
    return this.internalMap_1.get_size_woubt6_k$();
  };
  function HashSet() {
  }
  function computeHashSize($this, capacity) {
    return takeHighestOneBit(imul(coerceAtLeast_0(capacity, 1), 3));
  }
  function computeShift($this, hashSize) {
    // Inline function 'kotlin.countLeadingZeroBits' call
    return clz32(hashSize) + 1 | 0;
  }
  function checkForComodification($this) {
    if (!($this.map_1.modCount_1 === $this.expectedModCount_1))
      throw ConcurrentModificationException_init_$Create$_0('The backing map has been modified after this entry was obtained.');
  }
  function InternalHashMap_init_$Init$($this) {
    InternalHashMap_init_$Init$_0(8, $this);
    return $this;
  }
  function InternalHashMap_init_$Create$() {
    return InternalHashMap_init_$Init$(objectCreate(protoOf(InternalHashMap)));
  }
  function InternalHashMap_init_$Init$_0(initialCapacity, $this) {
    InternalHashMap.call($this, arrayOfUninitializedElements(initialCapacity), null, new Int32Array(initialCapacity), new Int32Array(computeHashSize(Companion_instance_2, initialCapacity)), 2, 0);
    return $this;
  }
  function InternalHashMap_init_$Init$_1(original, $this) {
    InternalHashMap_init_$Init$_0(original.get_size_woubt6_k$(), $this);
    $this.putAll_wgg6cj_k$(original);
    return $this;
  }
  function InternalHashMap_init_$Create$_0(original) {
    return InternalHashMap_init_$Init$_1(original, objectCreate(protoOf(InternalHashMap)));
  }
  function InternalHashMap_init_$Init$_2(initialCapacity, loadFactor, $this) {
    InternalHashMap_init_$Init$_0(initialCapacity, $this);
    // Inline function 'kotlin.require' call
    if (!(loadFactor > 0)) {
      var message = 'Non-positive load factor: ' + loadFactor;
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    return $this;
  }
  function InternalHashMap_init_$Create$_1(initialCapacity, loadFactor) {
    return InternalHashMap_init_$Init$_2(initialCapacity, loadFactor, objectCreate(protoOf(InternalHashMap)));
  }
  function _get_capacity__a9k9f3($this) {
    return $this.keysArray_1.length;
  }
  function _get_hashSize__tftcho($this) {
    return $this.hashArray_1.length;
  }
  function registerModification($this) {
    $this.modCount_1 = $this.modCount_1 + 1 | 0;
  }
  function ensureExtraCapacity($this, n) {
    if (shouldCompact($this, n)) {
      compact($this, true);
    } else {
      ensureCapacity($this, $this.length_1 + n | 0);
    }
  }
  function shouldCompact($this, extraCapacity) {
    var spareCapacity = _get_capacity__a9k9f3($this) - $this.length_1 | 0;
    var gaps = $this.length_1 - $this.get_size_woubt6_k$() | 0;
    return spareCapacity < extraCapacity && (gaps + spareCapacity | 0) >= extraCapacity && gaps >= (_get_capacity__a9k9f3($this) / 4 | 0);
  }
  function ensureCapacity($this, minCapacity) {
    if (minCapacity < 0)
      throw RuntimeException_init_$Create$_0('too many elements');
    if (minCapacity > _get_capacity__a9k9f3($this)) {
      var newSize = Companion_instance_4.newCapacity_k5ozfy_k$(_get_capacity__a9k9f3($this), minCapacity);
      $this.keysArray_1 = copyOfUninitializedElements($this.keysArray_1, newSize);
      var tmp = $this;
      var tmp0_safe_receiver = $this.valuesArray_1;
      tmp.valuesArray_1 = tmp0_safe_receiver == null ? null : copyOfUninitializedElements(tmp0_safe_receiver, newSize);
      $this.presenceArray_1 = copyOf($this.presenceArray_1, newSize);
      var newHashSize = computeHashSize(Companion_instance_2, newSize);
      if (newHashSize > _get_hashSize__tftcho($this)) {
        rehash($this, newHashSize);
      }
    }
  }
  function allocateValuesArray($this) {
    var curValuesArray = $this.valuesArray_1;
    if (!(curValuesArray == null))
      return curValuesArray;
    var newValuesArray = arrayOfUninitializedElements(_get_capacity__a9k9f3($this));
    $this.valuesArray_1 = newValuesArray;
    return newValuesArray;
  }
  function hash($this, key) {
    return key == null ? 0 : imul(hashCode(key), -1640531527) >>> $this.hashShift_1 | 0;
  }
  function compact($this, updateHashArray) {
    var i = 0;
    var j = 0;
    var valuesArray = $this.valuesArray_1;
    while (i < $this.length_1) {
      var hash = $this.presenceArray_1[i];
      if (hash >= 0) {
        $this.keysArray_1[j] = $this.keysArray_1[i];
        if (!(valuesArray == null)) {
          valuesArray[j] = valuesArray[i];
        }
        if (updateHashArray) {
          $this.presenceArray_1[j] = hash;
          $this.hashArray_1[hash] = j + 1 | 0;
        }
        j = j + 1 | 0;
      }
      i = i + 1 | 0;
    }
    resetRange($this.keysArray_1, j, $this.length_1);
    if (valuesArray == null)
      null;
    else {
      resetRange(valuesArray, j, $this.length_1);
    }
    $this.length_1 = j;
  }
  function rehash($this, newHashSize) {
    registerModification($this);
    if ($this.length_1 > $this._size_1) {
      compact($this, false);
    }
    $this.hashArray_1 = new Int32Array(newHashSize);
    $this.hashShift_1 = computeShift(Companion_instance_2, newHashSize);
    var i = 0;
    while (i < $this.length_1) {
      var _unary__edvuaz = i;
      i = _unary__edvuaz + 1 | 0;
      if (!putRehash($this, _unary__edvuaz)) {
        throw IllegalStateException_init_$Create$_0('This cannot happen with fixed magic multiplier and grow-only hash array. Have object hashCodes changed?');
      }
    }
  }
  function putRehash($this, i) {
    var hash_0 = hash($this, $this.keysArray_1[i]);
    var probesLeft = $this.maxProbeDistance_1;
    while (true) {
      var index = $this.hashArray_1[hash_0];
      if (index === 0) {
        $this.hashArray_1[hash_0] = i + 1 | 0;
        $this.presenceArray_1[i] = hash_0;
        return true;
      }
      probesLeft = probesLeft - 1 | 0;
      if (probesLeft < 0)
        return false;
      var _unary__edvuaz = hash_0;
      hash_0 = _unary__edvuaz - 1 | 0;
      if (_unary__edvuaz === 0)
        hash_0 = _get_hashSize__tftcho($this) - 1 | 0;
    }
  }
  function findKey($this, key) {
    var hash_0 = hash($this, key);
    var probesLeft = $this.maxProbeDistance_1;
    while (true) {
      var index = $this.hashArray_1[hash_0];
      if (index === 0)
        return -1;
      if (index > 0 && equals($this.keysArray_1[index - 1 | 0], key))
        return index - 1 | 0;
      probesLeft = probesLeft - 1 | 0;
      if (probesLeft < 0)
        return -1;
      var _unary__edvuaz = hash_0;
      hash_0 = _unary__edvuaz - 1 | 0;
      if (_unary__edvuaz === 0)
        hash_0 = _get_hashSize__tftcho($this) - 1 | 0;
    }
  }
  function addKey($this, key) {
    $this.checkIsMutable_h5js84_k$();
    retry: while (true) {
      var hash_0 = hash($this, key);
      var tentativeMaxProbeDistance = coerceAtMost(imul($this.maxProbeDistance_1, 2), _get_hashSize__tftcho($this) / 2 | 0);
      var probeDistance = 0;
      while (true) {
        var index = $this.hashArray_1[hash_0];
        if (index <= 0) {
          if ($this.length_1 >= _get_capacity__a9k9f3($this)) {
            ensureExtraCapacity($this, 1);
            continue retry;
          }
          var _unary__edvuaz = $this.length_1;
          $this.length_1 = _unary__edvuaz + 1 | 0;
          var putIndex = _unary__edvuaz;
          $this.keysArray_1[putIndex] = key;
          $this.presenceArray_1[putIndex] = hash_0;
          $this.hashArray_1[hash_0] = putIndex + 1 | 0;
          $this._size_1 = $this._size_1 + 1 | 0;
          registerModification($this);
          if (probeDistance > $this.maxProbeDistance_1)
            $this.maxProbeDistance_1 = probeDistance;
          return putIndex;
        }
        if (equals($this.keysArray_1[index - 1 | 0], key)) {
          return -index | 0;
        }
        probeDistance = probeDistance + 1 | 0;
        if (probeDistance > tentativeMaxProbeDistance) {
          rehash($this, imul(_get_hashSize__tftcho($this), 2));
          continue retry;
        }
        var _unary__edvuaz_0 = hash_0;
        hash_0 = _unary__edvuaz_0 - 1 | 0;
        if (_unary__edvuaz_0 === 0)
          hash_0 = _get_hashSize__tftcho($this) - 1 | 0;
      }
    }
  }
  function contentEquals($this, other) {
    return $this._size_1 === other.get_size_woubt6_k$() && $this.containsAllEntries_m9iqdx_k$(other.get_entries_p20ztl_k$());
  }
  function putEntry($this, entry) {
    var index = addKey($this, entry.get_key_18j28a_k$());
    var valuesArray = allocateValuesArray($this);
    if (index >= 0) {
      valuesArray[index] = entry.get_value_j01efc_k$();
      return true;
    }
    var oldValue = valuesArray[(-index | 0) - 1 | 0];
    if (!equals(entry.get_value_j01efc_k$(), oldValue)) {
      valuesArray[(-index | 0) - 1 | 0] = entry.get_value_j01efc_k$();
      return true;
    }
    return false;
  }
  function putAllEntries($this, from) {
    if (from.isEmpty_y1axqb_k$())
      return false;
    ensureExtraCapacity($this, from.get_size_woubt6_k$());
    var it = from.iterator_jk1svi_k$();
    var updated = false;
    while (it.hasNext_bitz1p_k$()) {
      if (putEntry($this, it.next_20eer_k$()))
        updated = true;
    }
    return updated;
  }
  function Companion_2() {
    this.MAGIC_1 = -1640531527;
    this.INITIAL_CAPACITY_1 = 8;
    this.INITIAL_MAX_PROBE_DISTANCE_1 = 2;
    this.TOMBSTONE_1 = -1;
  }
  var Companion_instance_2;
  function Companion_getInstance_2() {
    return Companion_instance_2;
  }
  function Itr(map) {
    this.map_1 = map;
    this.index_1 = 0;
    this.lastIndex_1 = -1;
    this.expectedModCount_1 = this.map_1.modCount_1;
    this.initNext_evzkid_k$();
  }
  protoOf(Itr).initNext_evzkid_k$ = function () {
    while (this.index_1 < this.map_1.length_1 && this.map_1.presenceArray_1[this.index_1] < 0) {
      this.index_1 = this.index_1 + 1 | 0;
    }
  };
  protoOf(Itr).hasNext_bitz1p_k$ = function () {
    return this.index_1 < this.map_1.length_1;
  };
  protoOf(Itr).checkForComodification_o4dljl_k$ = function () {
    if (!(this.map_1.modCount_1 === this.expectedModCount_1))
      throw ConcurrentModificationException_init_$Create$();
  };
  function KeysItr(map) {
    Itr.call(this, map);
  }
  protoOf(KeysItr).next_20eer_k$ = function () {
    this.checkForComodification_o4dljl_k$();
    if (this.index_1 >= this.map_1.length_1)
      throw NoSuchElementException_init_$Create$();
    var tmp = this;
    var _unary__edvuaz = this.index_1;
    this.index_1 = _unary__edvuaz + 1 | 0;
    tmp.lastIndex_1 = _unary__edvuaz;
    var result = this.map_1.keysArray_1[this.lastIndex_1];
    this.initNext_evzkid_k$();
    return result;
  };
  function EntriesItr(map) {
    Itr.call(this, map);
  }
  protoOf(EntriesItr).next_20eer_k$ = function () {
    this.checkForComodification_o4dljl_k$();
    if (this.index_1 >= this.map_1.length_1)
      throw NoSuchElementException_init_$Create$();
    var tmp = this;
    var _unary__edvuaz = this.index_1;
    this.index_1 = _unary__edvuaz + 1 | 0;
    tmp.lastIndex_1 = _unary__edvuaz;
    var result = new EntryRef(this.map_1, this.lastIndex_1);
    this.initNext_evzkid_k$();
    return result;
  };
  protoOf(EntriesItr).nextHashCode_b13whm_k$ = function () {
    if (this.index_1 >= this.map_1.length_1)
      throw NoSuchElementException_init_$Create$();
    var tmp = this;
    var _unary__edvuaz = this.index_1;
    this.index_1 = _unary__edvuaz + 1 | 0;
    tmp.lastIndex_1 = _unary__edvuaz;
    // Inline function 'kotlin.hashCode' call
    var tmp0_safe_receiver = this.map_1.keysArray_1[this.lastIndex_1];
    var tmp1_elvis_lhs = tmp0_safe_receiver == null ? null : hashCode(tmp0_safe_receiver);
    var tmp_0 = tmp1_elvis_lhs == null ? 0 : tmp1_elvis_lhs;
    // Inline function 'kotlin.hashCode' call
    var tmp0_safe_receiver_0 = ensureNotNull(this.map_1.valuesArray_1)[this.lastIndex_1];
    var tmp1_elvis_lhs_0 = tmp0_safe_receiver_0 == null ? null : hashCode(tmp0_safe_receiver_0);
    var result = tmp_0 ^ (tmp1_elvis_lhs_0 == null ? 0 : tmp1_elvis_lhs_0);
    this.initNext_evzkid_k$();
    return result;
  };
  protoOf(EntriesItr).nextAppendString_konuli_k$ = function (sb) {
    if (this.index_1 >= this.map_1.length_1)
      throw NoSuchElementException_init_$Create$();
    var tmp = this;
    var _unary__edvuaz = this.index_1;
    this.index_1 = _unary__edvuaz + 1 | 0;
    tmp.lastIndex_1 = _unary__edvuaz;
    var key = this.map_1.keysArray_1[this.lastIndex_1];
    if (equals(key, this.map_1))
      sb.append_22ad7x_k$('(this Map)');
    else
      sb.append_t8pm91_k$(key);
    sb.append_58al37_k$(_Char___init__impl__6a9atx(61));
    var value = ensureNotNull(this.map_1.valuesArray_1)[this.lastIndex_1];
    if (equals(value, this.map_1))
      sb.append_22ad7x_k$('(this Map)');
    else
      sb.append_t8pm91_k$(value);
    this.initNext_evzkid_k$();
  };
  function EntryRef(map, index) {
    this.map_1 = map;
    this.index_1 = index;
    this.expectedModCount_1 = this.map_1.modCount_1;
  }
  protoOf(EntryRef).get_key_18j28a_k$ = function () {
    checkForComodification(this);
    return this.map_1.keysArray_1[this.index_1];
  };
  protoOf(EntryRef).get_value_j01efc_k$ = function () {
    checkForComodification(this);
    return ensureNotNull(this.map_1.valuesArray_1)[this.index_1];
  };
  protoOf(EntryRef).equals = function (other) {
    var tmp;
    var tmp_0;
    if (!(other == null) ? isInterface(other, Entry) : false) {
      tmp_0 = equals(other.get_key_18j28a_k$(), this.get_key_18j28a_k$());
    } else {
      tmp_0 = false;
    }
    if (tmp_0) {
      tmp = equals(other.get_value_j01efc_k$(), this.get_value_j01efc_k$());
    } else {
      tmp = false;
    }
    return tmp;
  };
  protoOf(EntryRef).hashCode = function () {
    // Inline function 'kotlin.hashCode' call
    var tmp0_safe_receiver = this.get_key_18j28a_k$();
    var tmp1_elvis_lhs = tmp0_safe_receiver == null ? null : hashCode(tmp0_safe_receiver);
    var tmp = tmp1_elvis_lhs == null ? 0 : tmp1_elvis_lhs;
    // Inline function 'kotlin.hashCode' call
    var tmp0_safe_receiver_0 = this.get_value_j01efc_k$();
    var tmp1_elvis_lhs_0 = tmp0_safe_receiver_0 == null ? null : hashCode(tmp0_safe_receiver_0);
    return tmp ^ (tmp1_elvis_lhs_0 == null ? 0 : tmp1_elvis_lhs_0);
  };
  protoOf(EntryRef).toString = function () {
    return toString_0(this.get_key_18j28a_k$()) + '=' + toString_0(this.get_value_j01efc_k$());
  };
  function InternalHashMap(keysArray, valuesArray, presenceArray, hashArray, maxProbeDistance, length) {
    this.keysArray_1 = keysArray;
    this.valuesArray_1 = valuesArray;
    this.presenceArray_1 = presenceArray;
    this.hashArray_1 = hashArray;
    this.maxProbeDistance_1 = maxProbeDistance;
    this.length_1 = length;
    this.hashShift_1 = computeShift(Companion_instance_2, _get_hashSize__tftcho(this));
    this.modCount_1 = 0;
    this._size_1 = 0;
    this.isReadOnly_1 = false;
  }
  protoOf(InternalHashMap).get_size_woubt6_k$ = function () {
    return this._size_1;
  };
  protoOf(InternalHashMap).get_wei43m_k$ = function (key) {
    var index = findKey(this, key);
    if (index < 0)
      return null;
    return ensureNotNull(this.valuesArray_1)[index];
  };
  protoOf(InternalHashMap).contains_vbgn2f_k$ = function (key) {
    return findKey(this, key) >= 0;
  };
  protoOf(InternalHashMap).put_4fpzoq_k$ = function (key, value) {
    var index = addKey(this, key);
    var valuesArray = allocateValuesArray(this);
    if (index < 0) {
      var oldValue = valuesArray[(-index | 0) - 1 | 0];
      valuesArray[(-index | 0) - 1 | 0] = value;
      return oldValue;
    } else {
      valuesArray[index] = value;
      return null;
    }
  };
  protoOf(InternalHashMap).putAll_wgg6cj_k$ = function (from) {
    this.checkIsMutable_h5js84_k$();
    putAllEntries(this, from.get_entries_p20ztl_k$());
  };
  protoOf(InternalHashMap).equals = function (other) {
    var tmp;
    if (other === this) {
      tmp = true;
    } else {
      var tmp_0;
      if (!(other == null) ? isInterface(other, KtMap) : false) {
        tmp_0 = contentEquals(this, other);
      } else {
        tmp_0 = false;
      }
      tmp = tmp_0;
    }
    return tmp;
  };
  protoOf(InternalHashMap).hashCode = function () {
    var result = 0;
    var it = this.entriesIterator_or017i_k$();
    while (it.hasNext_bitz1p_k$()) {
      result = result + it.nextHashCode_b13whm_k$() | 0;
    }
    return result;
  };
  protoOf(InternalHashMap).toString = function () {
    var sb = StringBuilder_init_$Create$(2 + imul(this._size_1, 3) | 0);
    sb.append_22ad7x_k$('{');
    var i = 0;
    var it = this.entriesIterator_or017i_k$();
    while (it.hasNext_bitz1p_k$()) {
      if (i > 0) {
        sb.append_22ad7x_k$(', ');
      }
      it.nextAppendString_konuli_k$(sb);
      i = i + 1 | 0;
    }
    sb.append_22ad7x_k$('}');
    return sb.toString();
  };
  protoOf(InternalHashMap).checkIsMutable_h5js84_k$ = function () {
    if (this.isReadOnly_1)
      throw UnsupportedOperationException_init_$Create$();
  };
  protoOf(InternalHashMap).containsEntry_jg6xfi_k$ = function (entry) {
    var index = findKey(this, entry.get_key_18j28a_k$());
    if (index < 0)
      return false;
    return equals(ensureNotNull(this.valuesArray_1)[index], entry.get_value_j01efc_k$());
  };
  protoOf(InternalHashMap).containsOtherEntry_yvdc55_k$ = function (entry) {
    return this.containsEntry_jg6xfi_k$(isInterface(entry, Entry) ? entry : THROW_CCE());
  };
  protoOf(InternalHashMap).keysIterator_mjslfm_k$ = function () {
    return new KeysItr(this);
  };
  protoOf(InternalHashMap).entriesIterator_or017i_k$ = function () {
    return new EntriesItr(this);
  };
  function InternalMap() {
  }
  function LinkedHashMap_init_$Init$($this) {
    HashMap_init_$Init$_0($this);
    LinkedHashMap.call($this);
    return $this;
  }
  function LinkedHashMap_init_$Create$() {
    return LinkedHashMap_init_$Init$(objectCreate(protoOf(LinkedHashMap)));
  }
  function LinkedHashMap_init_$Init$_0(initialCapacity, $this) {
    HashMap_init_$Init$_2(initialCapacity, $this);
    LinkedHashMap.call($this);
    return $this;
  }
  function LinkedHashMap_init_$Create$_0(initialCapacity) {
    return LinkedHashMap_init_$Init$_0(initialCapacity, objectCreate(protoOf(LinkedHashMap)));
  }
  function LinkedHashMap_init_$Init$_1(original, $this) {
    HashMap_init_$Init$_3(original, $this);
    LinkedHashMap.call($this);
    return $this;
  }
  function LinkedHashMap_init_$Create$_1(original) {
    return LinkedHashMap_init_$Init$_1(original, objectCreate(protoOf(LinkedHashMap)));
  }
  function LinkedHashMap() {
  }
  function LinkedHashSet_init_$Init$($this) {
    HashSet_init_$Init$_0($this);
    LinkedHashSet.call($this);
    return $this;
  }
  function LinkedHashSet_init_$Create$() {
    return LinkedHashSet_init_$Init$(objectCreate(protoOf(LinkedHashSet)));
  }
  function LinkedHashSet_init_$Init$_0(initialCapacity, loadFactor, $this) {
    HashSet_init_$Init$_1(initialCapacity, loadFactor, $this);
    LinkedHashSet.call($this);
    return $this;
  }
  function LinkedHashSet_init_$Init$_1(initialCapacity, $this) {
    LinkedHashSet_init_$Init$_0(initialCapacity, 1.0, $this);
    return $this;
  }
  function LinkedHashSet_init_$Create$_0(initialCapacity) {
    return LinkedHashSet_init_$Init$_1(initialCapacity, objectCreate(protoOf(LinkedHashSet)));
  }
  protoOf(LinkedHashSet).checkIsMutable_jn1ih0_k$ = function () {
    return this.internalMap_1.checkIsMutable_h5js84_k$();
  };
  function LinkedHashSet() {
  }
  function RandomAccess() {
  }
  function Exception_init_$Init$($this) {
    extendThrowable($this);
    Exception.call($this);
    return $this;
  }
  function Exception_init_$Create$() {
    var tmp = Exception_init_$Init$(objectCreate(protoOf(Exception)));
    captureStack(tmp, Exception_init_$Create$);
    return tmp;
  }
  function Exception_init_$Init$_0(message, $this) {
    extendThrowable($this, message);
    Exception.call($this);
    return $this;
  }
  function Exception_init_$Create$_0(message) {
    var tmp = Exception_init_$Init$_0(message, objectCreate(protoOf(Exception)));
    captureStack(tmp, Exception_init_$Create$_0);
    return tmp;
  }
  function Exception() {
    captureStack(this, Exception);
  }
  function IllegalArgumentException_init_$Init$($this) {
    RuntimeException_init_$Init$($this);
    IllegalArgumentException.call($this);
    return $this;
  }
  function IllegalArgumentException_init_$Create$() {
    var tmp = IllegalArgumentException_init_$Init$(objectCreate(protoOf(IllegalArgumentException)));
    captureStack(tmp, IllegalArgumentException_init_$Create$);
    return tmp;
  }
  function IllegalArgumentException_init_$Init$_0(message, $this) {
    RuntimeException_init_$Init$_0(message, $this);
    IllegalArgumentException.call($this);
    return $this;
  }
  function IllegalArgumentException_init_$Create$_0(message) {
    var tmp = IllegalArgumentException_init_$Init$_0(message, objectCreate(protoOf(IllegalArgumentException)));
    captureStack(tmp, IllegalArgumentException_init_$Create$_0);
    return tmp;
  }
  function IllegalArgumentException() {
    captureStack(this, IllegalArgumentException);
  }
  function IllegalStateException_init_$Init$($this) {
    RuntimeException_init_$Init$($this);
    IllegalStateException.call($this);
    return $this;
  }
  function IllegalStateException_init_$Create$() {
    var tmp = IllegalStateException_init_$Init$(objectCreate(protoOf(IllegalStateException)));
    captureStack(tmp, IllegalStateException_init_$Create$);
    return tmp;
  }
  function IllegalStateException_init_$Init$_0(message, $this) {
    RuntimeException_init_$Init$_0(message, $this);
    IllegalStateException.call($this);
    return $this;
  }
  function IllegalStateException_init_$Create$_0(message) {
    var tmp = IllegalStateException_init_$Init$_0(message, objectCreate(protoOf(IllegalStateException)));
    captureStack(tmp, IllegalStateException_init_$Create$_0);
    return tmp;
  }
  function IllegalStateException() {
    captureStack(this, IllegalStateException);
  }
  function UnsupportedOperationException_init_$Init$($this) {
    RuntimeException_init_$Init$($this);
    UnsupportedOperationException.call($this);
    return $this;
  }
  function UnsupportedOperationException_init_$Create$() {
    var tmp = UnsupportedOperationException_init_$Init$(objectCreate(protoOf(UnsupportedOperationException)));
    captureStack(tmp, UnsupportedOperationException_init_$Create$);
    return tmp;
  }
  function UnsupportedOperationException_init_$Init$_0(message, $this) {
    RuntimeException_init_$Init$_0(message, $this);
    UnsupportedOperationException.call($this);
    return $this;
  }
  function UnsupportedOperationException_init_$Create$_0(message) {
    var tmp = UnsupportedOperationException_init_$Init$_0(message, objectCreate(protoOf(UnsupportedOperationException)));
    captureStack(tmp, UnsupportedOperationException_init_$Create$_0);
    return tmp;
  }
  function UnsupportedOperationException() {
    captureStack(this, UnsupportedOperationException);
  }
  function RuntimeException_init_$Init$($this) {
    Exception_init_$Init$($this);
    RuntimeException.call($this);
    return $this;
  }
  function RuntimeException_init_$Create$() {
    var tmp = RuntimeException_init_$Init$(objectCreate(protoOf(RuntimeException)));
    captureStack(tmp, RuntimeException_init_$Create$);
    return tmp;
  }
  function RuntimeException_init_$Init$_0(message, $this) {
    Exception_init_$Init$_0(message, $this);
    RuntimeException.call($this);
    return $this;
  }
  function RuntimeException_init_$Create$_0(message) {
    var tmp = RuntimeException_init_$Init$_0(message, objectCreate(protoOf(RuntimeException)));
    captureStack(tmp, RuntimeException_init_$Create$_0);
    return tmp;
  }
  function RuntimeException() {
    captureStack(this, RuntimeException);
  }
  function NoSuchElementException_init_$Init$($this) {
    RuntimeException_init_$Init$($this);
    NoSuchElementException.call($this);
    return $this;
  }
  function NoSuchElementException_init_$Create$() {
    var tmp = NoSuchElementException_init_$Init$(objectCreate(protoOf(NoSuchElementException)));
    captureStack(tmp, NoSuchElementException_init_$Create$);
    return tmp;
  }
  function NoSuchElementException_init_$Init$_0(message, $this) {
    RuntimeException_init_$Init$_0(message, $this);
    NoSuchElementException.call($this);
    return $this;
  }
  function NoSuchElementException_init_$Create$_0(message) {
    var tmp = NoSuchElementException_init_$Init$_0(message, objectCreate(protoOf(NoSuchElementException)));
    captureStack(tmp, NoSuchElementException_init_$Create$_0);
    return tmp;
  }
  function NoSuchElementException() {
    captureStack(this, NoSuchElementException);
  }
  function IndexOutOfBoundsException_init_$Init$($this) {
    RuntimeException_init_$Init$($this);
    IndexOutOfBoundsException.call($this);
    return $this;
  }
  function IndexOutOfBoundsException_init_$Create$() {
    var tmp = IndexOutOfBoundsException_init_$Init$(objectCreate(protoOf(IndexOutOfBoundsException)));
    captureStack(tmp, IndexOutOfBoundsException_init_$Create$);
    return tmp;
  }
  function IndexOutOfBoundsException_init_$Init$_0(message, $this) {
    RuntimeException_init_$Init$_0(message, $this);
    IndexOutOfBoundsException.call($this);
    return $this;
  }
  function IndexOutOfBoundsException_init_$Create$_0(message) {
    var tmp = IndexOutOfBoundsException_init_$Init$_0(message, objectCreate(protoOf(IndexOutOfBoundsException)));
    captureStack(tmp, IndexOutOfBoundsException_init_$Create$_0);
    return tmp;
  }
  function IndexOutOfBoundsException() {
    captureStack(this, IndexOutOfBoundsException);
  }
  function ArithmeticException_init_$Init$($this) {
    RuntimeException_init_$Init$($this);
    ArithmeticException.call($this);
    return $this;
  }
  function ArithmeticException_init_$Create$() {
    var tmp = ArithmeticException_init_$Init$(objectCreate(protoOf(ArithmeticException)));
    captureStack(tmp, ArithmeticException_init_$Create$);
    return tmp;
  }
  function ArithmeticException_init_$Init$_0(message, $this) {
    RuntimeException_init_$Init$_0(message, $this);
    ArithmeticException.call($this);
    return $this;
  }
  function ArithmeticException_init_$Create$_0(message) {
    var tmp = ArithmeticException_init_$Init$_0(message, objectCreate(protoOf(ArithmeticException)));
    captureStack(tmp, ArithmeticException_init_$Create$_0);
    return tmp;
  }
  function ArithmeticException() {
    captureStack(this, ArithmeticException);
  }
  function ConcurrentModificationException_init_$Init$($this) {
    RuntimeException_init_$Init$($this);
    ConcurrentModificationException.call($this);
    return $this;
  }
  function ConcurrentModificationException_init_$Create$() {
    var tmp = ConcurrentModificationException_init_$Init$(objectCreate(protoOf(ConcurrentModificationException)));
    captureStack(tmp, ConcurrentModificationException_init_$Create$);
    return tmp;
  }
  function ConcurrentModificationException_init_$Init$_0(message, $this) {
    RuntimeException_init_$Init$_0(message, $this);
    ConcurrentModificationException.call($this);
    return $this;
  }
  function ConcurrentModificationException_init_$Create$_0(message) {
    var tmp = ConcurrentModificationException_init_$Init$_0(message, objectCreate(protoOf(ConcurrentModificationException)));
    captureStack(tmp, ConcurrentModificationException_init_$Create$_0);
    return tmp;
  }
  function ConcurrentModificationException() {
    captureStack(this, ConcurrentModificationException);
  }
  function NumberFormatException_init_$Init$($this) {
    IllegalArgumentException_init_$Init$($this);
    NumberFormatException.call($this);
    return $this;
  }
  function NumberFormatException_init_$Create$() {
    var tmp = NumberFormatException_init_$Init$(objectCreate(protoOf(NumberFormatException)));
    captureStack(tmp, NumberFormatException_init_$Create$);
    return tmp;
  }
  function NumberFormatException_init_$Init$_0(message, $this) {
    IllegalArgumentException_init_$Init$_0(message, $this);
    NumberFormatException.call($this);
    return $this;
  }
  function NumberFormatException_init_$Create$_0(message) {
    var tmp = NumberFormatException_init_$Init$_0(message, objectCreate(protoOf(NumberFormatException)));
    captureStack(tmp, NumberFormatException_init_$Create$_0);
    return tmp;
  }
  function NumberFormatException() {
    captureStack(this, NumberFormatException);
  }
  function NullPointerException_init_$Init$($this) {
    RuntimeException_init_$Init$($this);
    NullPointerException.call($this);
    return $this;
  }
  function NullPointerException_init_$Create$() {
    var tmp = NullPointerException_init_$Init$(objectCreate(protoOf(NullPointerException)));
    captureStack(tmp, NullPointerException_init_$Create$);
    return tmp;
  }
  function NullPointerException() {
    captureStack(this, NullPointerException);
  }
  function ClassCastException_init_$Init$($this) {
    RuntimeException_init_$Init$($this);
    ClassCastException.call($this);
    return $this;
  }
  function ClassCastException_init_$Create$() {
    var tmp = ClassCastException_init_$Init$(objectCreate(protoOf(ClassCastException)));
    captureStack(tmp, ClassCastException_init_$Create$);
    return tmp;
  }
  function ClassCastException() {
    captureStack(this, ClassCastException);
  }
  function lazy(initializer) {
    return new UnsafeLazyImpl(initializer);
  }
  function fillFrom(src, dst) {
    var srcLen = src.length;
    var dstLen = dst.length;
    var index = 0;
    // Inline function 'kotlin.js.unsafeCast' call
    var arr = dst;
    while (index < srcLen && index < dstLen) {
      var tmp = index;
      var _unary__edvuaz = index;
      index = _unary__edvuaz + 1 | 0;
      arr[tmp] = src[_unary__edvuaz];
    }
    return dst;
  }
  function arrayCopyResize(source, newSize, defaultValue) {
    // Inline function 'kotlin.js.unsafeCast' call
    var result = source.slice(0, newSize);
    // Inline function 'kotlin.copyArrayType' call
    if (source.$type$ !== undefined) {
      result.$type$ = source.$type$;
    }
    var index = source.length;
    if (newSize > index) {
      // Inline function 'kotlin.js.asDynamic' call
      result.length = newSize;
      while (index < newSize) {
        var _unary__edvuaz = index;
        index = _unary__edvuaz + 1 | 0;
        result[_unary__edvuaz] = defaultValue;
      }
    }
    return result;
  }
  function roundToInt(_this__u8e3s4) {
    var tmp;
    if (isNaN_0(_this__u8e3s4)) {
      throw IllegalArgumentException_init_$Create$_0('Cannot round NaN value.');
    } else if (_this__u8e3s4 > 2147483647) {
      tmp = 2147483647;
    } else if (_this__u8e3s4 < -2147483648) {
      tmp = -2147483648;
    } else {
      tmp = numberToInt(Math.round(_this__u8e3s4));
    }
    return tmp;
  }
  function KProperty1() {
  }
  function reset(_this__u8e3s4) {
    _this__u8e3s4.lastIndex = 0;
  }
  function StringBuilder_init_$Init$(capacity, $this) {
    StringBuilder_init_$Init$_0($this);
    return $this;
  }
  function StringBuilder_init_$Create$(capacity) {
    return StringBuilder_init_$Init$(capacity, objectCreate(protoOf(StringBuilder)));
  }
  function StringBuilder_init_$Init$_0($this) {
    StringBuilder.call($this, '');
    return $this;
  }
  function StringBuilder_init_$Create$_0() {
    return StringBuilder_init_$Init$_0(objectCreate(protoOf(StringBuilder)));
  }
  function StringBuilder(content) {
    this.string_1 = content;
  }
  protoOf(StringBuilder).get_length_g42xv3_k$ = function () {
    // Inline function 'kotlin.js.asDynamic' call
    return this.string_1.length;
  };
  protoOf(StringBuilder).get_kdzpvg_k$ = function (index) {
    // Inline function 'kotlin.text.getOrElse' call
    var this_0 = this.string_1;
    var tmp;
    if (0 <= index ? index <= (charSequenceLength(this_0) - 1 | 0) : false) {
      tmp = charSequenceGet(this_0, index);
    } else {
      throw IndexOutOfBoundsException_init_$Create$_0('index: ' + index + ', length: ' + this.get_length_g42xv3_k$() + '}');
    }
    return tmp;
  };
  protoOf(StringBuilder).subSequence_hm5hnj_k$ = function (startIndex, endIndex) {
    // Inline function 'kotlin.text.substring' call
    // Inline function 'kotlin.js.asDynamic' call
    return this.string_1.substring(startIndex, endIndex);
  };
  protoOf(StringBuilder).append_58al37_k$ = function (value) {
    this.string_1 = this.string_1 + toString(value);
    return this;
  };
  protoOf(StringBuilder).append_jgojdo_k$ = function (value) {
    this.string_1 = this.string_1 + toString_0(value);
    return this;
  };
  protoOf(StringBuilder).append_xdc1zw_k$ = function (value, startIndex, endIndex) {
    return this.appendRange_arc5oa_k$(value == null ? 'null' : value, startIndex, endIndex);
  };
  protoOf(StringBuilder).append_t8pm91_k$ = function (value) {
    this.string_1 = this.string_1 + toString_0(value);
    return this;
  };
  protoOf(StringBuilder).append_uppzia_k$ = function (value) {
    return this.append_22ad7x_k$(value.toString());
  };
  protoOf(StringBuilder).append_22ad7x_k$ = function (value) {
    var tmp = this;
    var tmp_0 = this.string_1;
    tmp.string_1 = tmp_0 + (value == null ? 'null' : value);
    return this;
  };
  protoOf(StringBuilder).setLength_oy0ork_k$ = function (newLength) {
    if (newLength < 0) {
      throw IllegalArgumentException_init_$Create$_0('Negative new length: ' + newLength + '.');
    }
    if (newLength <= this.get_length_g42xv3_k$()) {
      var tmp = this;
      // Inline function 'kotlin.text.substring' call
      // Inline function 'kotlin.js.asDynamic' call
      tmp.string_1 = this.string_1.substring(0, newLength);
    } else {
      var inductionVariable = this.get_length_g42xv3_k$();
      if (inductionVariable < newLength)
        do {
          var i = inductionVariable;
          inductionVariable = inductionVariable + 1 | 0;
          this.string_1 = this.string_1 + toString(_Char___init__impl__6a9atx(0));
        }
         while (inductionVariable < newLength);
    }
  };
  protoOf(StringBuilder).toString = function () {
    return this.string_1;
  };
  protoOf(StringBuilder).appendRange_arc5oa_k$ = function (value, startIndex, endIndex) {
    var stringCsq = toString_1(value);
    Companion_instance_4.checkBoundsIndexes_tsopv1_k$(startIndex, endIndex, stringCsq.length);
    var tmp = this;
    var tmp_0 = this.string_1;
    // Inline function 'kotlin.text.substring' call
    // Inline function 'kotlin.js.asDynamic' call
    tmp.string_1 = tmp_0 + stringCsq.substring(startIndex, endIndex);
    return this;
  };
  function uppercaseChar(_this__u8e3s4) {
    // Inline function 'kotlin.text.uppercase' call
    // Inline function 'kotlin.js.asDynamic' call
    // Inline function 'kotlin.js.unsafeCast' call
    var uppercase = toString(_this__u8e3s4).toUpperCase();
    return uppercase.length > 1 ? _this__u8e3s4 : charSequenceGet(uppercase, 0);
  }
  function isDigit(_this__u8e3s4) {
    if (_Char___init__impl__6a9atx(48) <= _this__u8e3s4 ? _this__u8e3s4 <= _Char___init__impl__6a9atx(57) : false) {
      return true;
    }
    if (Char__compareTo_impl_ypi4mb(_this__u8e3s4, _Char___init__impl__6a9atx(128)) < 0) {
      return false;
    }
    return isDigitImpl(_this__u8e3s4);
  }
  function isWhitespace(_this__u8e3s4) {
    return isWhitespaceImpl(_this__u8e3s4);
  }
  function toString_2(_this__u8e3s4, radix) {
    return toStringImpl(_this__u8e3s4, checkRadix(radix));
  }
  function checkRadix(radix) {
    if (!(2 <= radix ? radix <= 36 : false)) {
      throw IllegalArgumentException_init_$Create$_0('radix ' + radix + ' was not in valid range 2..36');
    }
    return radix;
  }
  function toInt(_this__u8e3s4) {
    var tmp0_elvis_lhs = toIntOrNull(_this__u8e3s4);
    var tmp;
    if (tmp0_elvis_lhs == null) {
      numberFormatError(_this__u8e3s4);
    } else {
      tmp = tmp0_elvis_lhs;
    }
    return tmp;
  }
  function digitOf(char, radix) {
    // Inline function 'kotlin.let' call
    var it = Char__compareTo_impl_ypi4mb(char, _Char___init__impl__6a9atx(48)) >= 0 && Char__compareTo_impl_ypi4mb(char, _Char___init__impl__6a9atx(57)) <= 0 ? Char__minus_impl_a2frrh(char, _Char___init__impl__6a9atx(48)) : Char__compareTo_impl_ypi4mb(char, _Char___init__impl__6a9atx(65)) >= 0 && Char__compareTo_impl_ypi4mb(char, _Char___init__impl__6a9atx(90)) <= 0 ? Char__minus_impl_a2frrh(char, _Char___init__impl__6a9atx(65)) + 10 | 0 : Char__compareTo_impl_ypi4mb(char, _Char___init__impl__6a9atx(97)) >= 0 && Char__compareTo_impl_ypi4mb(char, _Char___init__impl__6a9atx(122)) <= 0 ? Char__minus_impl_a2frrh(char, _Char___init__impl__6a9atx(97)) + 10 | 0 : Char__compareTo_impl_ypi4mb(char, _Char___init__impl__6a9atx(128)) < 0 ? -1 : Char__compareTo_impl_ypi4mb(char, _Char___init__impl__6a9atx(65313)) >= 0 && Char__compareTo_impl_ypi4mb(char, _Char___init__impl__6a9atx(65338)) <= 0 ? Char__minus_impl_a2frrh(char, _Char___init__impl__6a9atx(65313)) + 10 | 0 : Char__compareTo_impl_ypi4mb(char, _Char___init__impl__6a9atx(65345)) >= 0 && Char__compareTo_impl_ypi4mb(char, _Char___init__impl__6a9atx(65370)) <= 0 ? Char__minus_impl_a2frrh(char, _Char___init__impl__6a9atx(65345)) + 10 | 0 : digitToIntImpl(char);
    return it >= radix ? -1 : it;
  }
  function toDoubleOrNull(_this__u8e3s4) {
    // Inline function 'kotlin.js.asDynamic' call
    // Inline function 'kotlin.js.unsafeCast' call
    // Inline function 'kotlin.takeIf' call
    var this_0 = +_this__u8e3s4;
    var tmp;
    if (!(isNaN_0(this_0) && !isNaN_1(_this__u8e3s4) || (this_0 === 0.0 && isBlank(_this__u8e3s4)))) {
      tmp = this_0;
    } else {
      tmp = null;
    }
    return tmp;
  }
  function isNaN_1(_this__u8e3s4) {
    // Inline function 'kotlin.text.lowercase' call
    // Inline function 'kotlin.js.asDynamic' call
    switch (_this__u8e3s4.toLowerCase()) {
      case 'nan':
      case '+nan':
      case '-nan':
        return true;
      default:
        return false;
    }
  }
  function Regex_init_$Init$(pattern, $this) {
    Regex.call($this, pattern, emptySet());
    return $this;
  }
  function Regex_init_$Create$(pattern) {
    return Regex_init_$Init$(pattern, objectCreate(protoOf(Regex)));
  }
  function Companion_3() {
    Companion_instance_3 = this;
    this.patternEscape_1 = new RegExp('[\\\\^$*+?.()|[\\]{}]', 'g');
    this.replacementEscape_1 = new RegExp('[\\\\$]', 'g');
    this.nativeReplacementEscape_1 = new RegExp('\\$', 'g');
  }
  protoOf(Companion_3).escape_984trb_k$ = function (literal) {
    // Inline function 'kotlin.text.nativeReplace' call
    var pattern = this.patternEscape_1;
    // Inline function 'kotlin.js.asDynamic' call
    return literal.replace(pattern, '\\$&');
  };
  protoOf(Companion_3).nativeEscapeReplacement_5elzqg_k$ = function (literal) {
    // Inline function 'kotlin.text.nativeReplace' call
    var pattern = this.nativeReplacementEscape_1;
    // Inline function 'kotlin.js.asDynamic' call
    return literal.replace(pattern, '$$$$');
  };
  var Companion_instance_3;
  function Companion_getInstance_3() {
    if (Companion_instance_3 == null)
      new Companion_3();
    return Companion_instance_3;
  }
  function Regex$findAll$lambda(this$0, $input, $startIndex) {
    return function () {
      return this$0.find_jq9i5o_k$($input, $startIndex);
    };
  }
  function Regex$findAll$lambda_0(match) {
    return match.next_20eer_k$();
  }
  function Regex$replace$lambda($replacement) {
    return function (it) {
      return substituteGroupRefs(it, $replacement);
    };
  }
  function Regex(pattern, options) {
    Companion_getInstance_3();
    this.pattern_1 = pattern;
    this.options_1 = toSet_0(options);
    this.nativePattern_1 = new RegExp(pattern, toFlags(options, 'gu'));
    this.nativeStickyPattern_1 = null;
    this.nativeMatchesEntirePattern_1 = null;
  }
  protoOf(Regex).containsMatchIn_gpzk5u_k$ = function (input) {
    reset(this.nativePattern_1);
    return this.nativePattern_1.test(toString_1(input));
  };
  protoOf(Regex).find_jq9i5o_k$ = function (input, startIndex) {
    if (startIndex < 0 || startIndex > charSequenceLength(input)) {
      throw IndexOutOfBoundsException_init_$Create$_0('Start index out of bounds: ' + startIndex + ', input length: ' + charSequenceLength(input));
    }
    return findNext(this.nativePattern_1, toString_1(input), startIndex, this.nativePattern_1);
  };
  protoOf(Regex).find$default_xakyli_k$ = function (input, startIndex, $super) {
    startIndex = startIndex === VOID ? 0 : startIndex;
    return $super === VOID ? this.find_jq9i5o_k$(input, startIndex) : $super.find_jq9i5o_k$.call(this, input, startIndex);
  };
  protoOf(Regex).findAll_98v6rh_k$ = function (input, startIndex) {
    if (startIndex < 0 || startIndex > charSequenceLength(input)) {
      throw IndexOutOfBoundsException_init_$Create$_0('Start index out of bounds: ' + startIndex + ', input length: ' + charSequenceLength(input));
    }
    var tmp = Regex$findAll$lambda(this, input, startIndex);
    return generateSequence(tmp, Regex$findAll$lambda_0);
  };
  protoOf(Regex).findAll$default_xha0o9_k$ = function (input, startIndex, $super) {
    startIndex = startIndex === VOID ? 0 : startIndex;
    return $super === VOID ? this.findAll_98v6rh_k$(input, startIndex) : $super.findAll_98v6rh_k$.call(this, input, startIndex);
  };
  protoOf(Regex).replace_1ix0wf_k$ = function (input, replacement) {
    if (!contains_0(replacement, _Char___init__impl__6a9atx(92)) && !contains_0(replacement, _Char___init__impl__6a9atx(36))) {
      var tmp0 = toString_1(input);
      // Inline function 'kotlin.text.nativeReplace' call
      var pattern = this.nativePattern_1;
      // Inline function 'kotlin.js.asDynamic' call
      return tmp0.replace(pattern, replacement);
    }
    return this.replace_dbivij_k$(input, Regex$replace$lambda(replacement));
  };
  protoOf(Regex).replace_dbivij_k$ = function (input, transform) {
    var match = this.find$default_xakyli_k$(input);
    if (match == null)
      return toString_1(input);
    var lastStart = 0;
    var length = charSequenceLength(input);
    var sb = StringBuilder_init_$Create$(length);
    do {
      var foundMatch = ensureNotNull(match);
      sb.append_xdc1zw_k$(input, lastStart, foundMatch.get_range_ixu978_k$().get_start_iypx6h_k$());
      sb.append_jgojdo_k$(transform(foundMatch));
      lastStart = foundMatch.get_range_ixu978_k$().get_endInclusive_r07xpi_k$() + 1 | 0;
      match = foundMatch.next_20eer_k$();
    }
     while (lastStart < length && !(match == null));
    if (lastStart < length) {
      sb.append_xdc1zw_k$(input, lastStart, length);
    }
    return sb.toString();
  };
  protoOf(Regex).split_p7ck23_k$ = function (input, limit) {
    requireNonNegativeLimit(limit);
    // Inline function 'kotlin.let' call
    var it = this.findAll$default_xha0o9_k$(input);
    var matches = limit === 0 ? it : take(it, limit - 1 | 0);
    // Inline function 'kotlin.collections.mutableListOf' call
    var result = ArrayList_init_$Create$();
    var lastStart = 0;
    var _iterator__ex2g4s = matches.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var match = _iterator__ex2g4s.next_20eer_k$();
      result.add_utx5q5_k$(toString_1(charSequenceSubSequence(input, lastStart, match.get_range_ixu978_k$().get_start_iypx6h_k$())));
      lastStart = match.get_range_ixu978_k$().get_endInclusive_r07xpi_k$() + 1 | 0;
    }
    result.add_utx5q5_k$(toString_1(charSequenceSubSequence(input, lastStart, charSequenceLength(input))));
    return result;
  };
  protoOf(Regex).toString = function () {
    return this.nativePattern_1.toString();
  };
  function toFlags(_this__u8e3s4, prepend) {
    return joinToString_0(_this__u8e3s4, '', prepend, VOID, VOID, VOID, toFlags$lambda);
  }
  function findNext(_this__u8e3s4, input, from, nextPattern) {
    _this__u8e3s4.lastIndex = from;
    var match = _this__u8e3s4.exec(input);
    if (match == null)
      return null;
    var range = numberRangeToNumber(match.index, _this__u8e3s4.lastIndex - 1 | 0);
    return new findNext$1(range, match, nextPattern, input);
  }
  function substituteGroupRefs(match, replacement) {
    var index = 0;
    var result = StringBuilder_init_$Create$_0();
    while (index < replacement.length) {
      var _unary__edvuaz = index;
      index = _unary__edvuaz + 1 | 0;
      var char = charSequenceGet(replacement, _unary__edvuaz);
      if (char === _Char___init__impl__6a9atx(92)) {
        if (index === replacement.length)
          throw IllegalArgumentException_init_$Create$_0('The Char to be escaped is missing');
        var _unary__edvuaz_0 = index;
        index = _unary__edvuaz_0 + 1 | 0;
        result.append_58al37_k$(charSequenceGet(replacement, _unary__edvuaz_0));
      } else if (char === _Char___init__impl__6a9atx(36)) {
        if (index === replacement.length)
          throw IllegalArgumentException_init_$Create$_0('Capturing group index is missing');
        if (charSequenceGet(replacement, index) === _Char___init__impl__6a9atx(123)) {
          index = index + 1 | 0;
          var endIndex = readGroupName(replacement, index);
          if (index === endIndex)
            throw IllegalArgumentException_init_$Create$_0('Named capturing group reference should have a non-empty name');
          if (endIndex === replacement.length || !(charSequenceGet(replacement, endIndex) === _Char___init__impl__6a9atx(125)))
            throw IllegalArgumentException_init_$Create$_0("Named capturing group reference is missing trailing '}'");
          // Inline function 'kotlin.text.substring' call
          var startIndex = index;
          // Inline function 'kotlin.js.asDynamic' call
          var groupName = replacement.substring(startIndex, endIndex);
          var tmp0_safe_receiver = get(match.get_groups_dy12vx_k$(), groupName);
          var tmp1_elvis_lhs = tmp0_safe_receiver == null ? null : tmp0_safe_receiver.value_1;
          result.append_22ad7x_k$(tmp1_elvis_lhs == null ? '' : tmp1_elvis_lhs);
          index = endIndex + 1 | 0;
        } else {
          var containsArg = charSequenceGet(replacement, index);
          if (!(_Char___init__impl__6a9atx(48) <= containsArg ? containsArg <= _Char___init__impl__6a9atx(57) : false))
            throw IllegalArgumentException_init_$Create$_0('Invalid capturing group reference');
          var groups = match.get_groups_dy12vx_k$();
          var endIndex_0 = readGroupIndex(replacement, index, groups.get_size_woubt6_k$());
          // Inline function 'kotlin.text.substring' call
          var startIndex_0 = index;
          // Inline function 'kotlin.js.asDynamic' call
          var tmp$ret$3 = replacement.substring(startIndex_0, endIndex_0);
          var groupIndex = toInt(tmp$ret$3);
          if (groupIndex >= groups.get_size_woubt6_k$())
            throw IndexOutOfBoundsException_init_$Create$_0('Group with index ' + groupIndex + ' does not exist');
          var tmp2_safe_receiver = groups.get_c1px32_k$(groupIndex);
          var tmp3_elvis_lhs = tmp2_safe_receiver == null ? null : tmp2_safe_receiver.value_1;
          result.append_22ad7x_k$(tmp3_elvis_lhs == null ? '' : tmp3_elvis_lhs);
          index = endIndex_0;
        }
      } else {
        result.append_58al37_k$(char);
      }
    }
    return result.toString();
  }
  function MatchGroup(value) {
    this.value_1 = value;
  }
  protoOf(MatchGroup).toString = function () {
    return 'MatchGroup(value=' + this.value_1 + ')';
  };
  protoOf(MatchGroup).hashCode = function () {
    return getStringHashCode(this.value_1);
  };
  protoOf(MatchGroup).equals = function (other) {
    if (this === other)
      return true;
    if (!(other instanceof MatchGroup))
      return false;
    var tmp0_other_with_cast = other instanceof MatchGroup ? other : THROW_CCE();
    if (!(this.value_1 === tmp0_other_with_cast.value_1))
      return false;
    return true;
  };
  function readGroupName(_this__u8e3s4, startIndex) {
    var index = startIndex;
    $l$loop: while (index < _this__u8e3s4.length) {
      if (charSequenceGet(_this__u8e3s4, index) === _Char___init__impl__6a9atx(125)) {
        break $l$loop;
      } else {
        index = index + 1 | 0;
      }
    }
    return index;
  }
  function get(_this__u8e3s4, name) {
    var tmp0_elvis_lhs = isInterface(_this__u8e3s4, MatchNamedGroupCollection) ? _this__u8e3s4 : null;
    var tmp;
    if (tmp0_elvis_lhs == null) {
      throw UnsupportedOperationException_init_$Create$_0('Retrieving groups by name is not supported on this platform.');
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var namedGroups = tmp;
    return namedGroups.get_6bo4tg_k$(name);
  }
  function readGroupIndex(_this__u8e3s4, startIndex, groupCount) {
    var index = startIndex + 1 | 0;
    var groupIndex = Char__minus_impl_a2frrh(charSequenceGet(_this__u8e3s4, startIndex), _Char___init__impl__6a9atx(48));
    $l$loop_0: while (true) {
      var tmp;
      if (index < _this__u8e3s4.length) {
        var containsArg = charSequenceGet(_this__u8e3s4, index);
        tmp = _Char___init__impl__6a9atx(48) <= containsArg ? containsArg <= _Char___init__impl__6a9atx(57) : false;
      } else {
        tmp = false;
      }
      if (!tmp) {
        break $l$loop_0;
      }
      var newGroupIndex = imul(groupIndex, 10) + Char__minus_impl_a2frrh(charSequenceGet(_this__u8e3s4, index), _Char___init__impl__6a9atx(48)) | 0;
      if (0 <= newGroupIndex ? newGroupIndex < groupCount : false) {
        groupIndex = newGroupIndex;
        index = index + 1 | 0;
      } else {
        break $l$loop_0;
      }
    }
    return index;
  }
  function toFlags$lambda(it) {
    return it.value_1;
  }
  function findNext$o$groups$o$iterator$lambda(this$0) {
    return function (it) {
      return this$0.get_c1px32_k$(it);
    };
  }
  function hasOwnPrototypeProperty($this, o, name) {
    // Inline function 'kotlin.js.unsafeCast' call
    return Object.prototype.hasOwnProperty.call(o, name);
  }
  function advanceToNextCharacter($this, index) {
    if (index < get_lastIndex_1($this.$input_1)) {
      // Inline function 'kotlin.js.asDynamic' call
      // Inline function 'kotlin.js.unsafeCast' call
      var code1 = $this.$input_1.charCodeAt(index);
      if (55296 <= code1 ? code1 <= 56319 : false) {
        // Inline function 'kotlin.js.asDynamic' call
        // Inline function 'kotlin.js.unsafeCast' call
        var code2 = $this.$input_1.charCodeAt(index + 1 | 0);
        if (56320 <= code2 ? code2 <= 57343 : false) {
          return index + 2 | 0;
        }
      }
    }
    return index + 1 | 0;
  }
  function findNext$1$groups$1($match, this$0) {
    this.$match_1 = $match;
    this.this$0__1 = this$0;
    AbstractCollection.call(this);
  }
  protoOf(findNext$1$groups$1).get_size_woubt6_k$ = function () {
    return this.$match_1.length;
  };
  protoOf(findNext$1$groups$1).iterator_jk1svi_k$ = function () {
    var tmp = asSequence(get_indices(this));
    return map(tmp, findNext$o$groups$o$iterator$lambda(this)).iterator_jk1svi_k$();
  };
  protoOf(findNext$1$groups$1).get_c1px32_k$ = function (index) {
    // Inline function 'kotlin.js.get' call
    // Inline function 'kotlin.js.asDynamic' call
    var tmp0_safe_receiver = this.$match_1[index];
    var tmp;
    if (tmp0_safe_receiver == null) {
      tmp = null;
    } else {
      // Inline function 'kotlin.let' call
      tmp = new MatchGroup(tmp0_safe_receiver);
    }
    return tmp;
  };
  protoOf(findNext$1$groups$1).get_6bo4tg_k$ = function (name) {
    // Inline function 'kotlin.js.asDynamic' call
    var tmp0_elvis_lhs = this.$match_1.groups;
    var tmp;
    if (tmp0_elvis_lhs == null) {
      throw IllegalArgumentException_init_$Create$_0('Capturing group with name {' + name + '} does not exist. No named capturing group was defined in Regex');
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var groups = tmp;
    if (!hasOwnPrototypeProperty(this.this$0__1, groups, name))
      throw IllegalArgumentException_init_$Create$_0('Capturing group with name {' + name + '} does not exist');
    var value = groups[name];
    var tmp_0;
    if (value == undefined) {
      tmp_0 = null;
    } else {
      tmp_0 = new MatchGroup((!(value == null) ? typeof value === 'string' : false) ? value : THROW_CCE());
    }
    return tmp_0;
  };
  function findNext$1$groupValues$1($match) {
    this.$match_1 = $match;
    AbstractList.call(this);
  }
  protoOf(findNext$1$groupValues$1).get_size_woubt6_k$ = function () {
    return this.$match_1.length;
  };
  protoOf(findNext$1$groupValues$1).get_c1px32_k$ = function (index) {
    // Inline function 'kotlin.js.get' call
    // Inline function 'kotlin.js.asDynamic' call
    var tmp0_elvis_lhs = this.$match_1[index];
    return tmp0_elvis_lhs == null ? '' : tmp0_elvis_lhs;
  };
  function findNext$1($range, $match, $nextPattern, $input) {
    this.$range_1 = $range;
    this.$match_1 = $match;
    this.$nextPattern_1 = $nextPattern;
    this.$input_1 = $input;
    this.range_1 = $range;
    var tmp = this;
    tmp.groups_1 = new findNext$1$groups$1($match, this);
    this.groupValues__1 = null;
  }
  protoOf(findNext$1).get_range_ixu978_k$ = function () {
    return this.range_1;
  };
  protoOf(findNext$1).get_groups_dy12vx_k$ = function () {
    return this.groups_1;
  };
  protoOf(findNext$1).get_groupValues_rkv314_k$ = function () {
    if (this.groupValues__1 == null) {
      var tmp = this;
      tmp.groupValues__1 = new findNext$1$groupValues$1(this.$match_1);
    }
    return ensureNotNull(this.groupValues__1);
  };
  protoOf(findNext$1).next_20eer_k$ = function () {
    return findNext(this.$nextPattern_1, this.$input_1, this.$range_1.isEmpty_y1axqb_k$() ? advanceToNextCharacter(this, this.$range_1.get_start_iypx6h_k$()) : this.$range_1.get_endInclusive_r07xpi_k$() + 1 | 0, this.$nextPattern_1);
  };
  function replace(_this__u8e3s4, oldValue, newValue, ignoreCase) {
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    var tmp1 = new RegExp(Companion_getInstance_3().escape_984trb_k$(oldValue), ignoreCase ? 'gui' : 'gu');
    // Inline function 'kotlin.text.nativeReplace' call
    var replacement = Companion_getInstance_3().nativeEscapeReplacement_5elzqg_k$(newValue);
    // Inline function 'kotlin.js.asDynamic' call
    return _this__u8e3s4.replace(tmp1, replacement);
  }
  function repeat(_this__u8e3s4, n) {
    // Inline function 'kotlin.require' call
    if (!(n >= 0)) {
      var message = "Count 'n' must be non-negative, but was " + n + '.';
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    var tmp;
    switch (n) {
      case 0:
        tmp = '';
        break;
      case 1:
        tmp = toString_1(_this__u8e3s4);
        break;
      default:
        var result = '';
        // Inline function 'kotlin.text.isEmpty' call

        if (!(charSequenceLength(_this__u8e3s4) === 0)) {
          var s = toString_1(_this__u8e3s4);
          var count = n;
          $l$loop: while (true) {
            if ((count & 1) === 1) {
              result = result + s;
            }
            count = count >>> 1 | 0;
            if (count === 0) {
              break $l$loop;
            }
            s = s + s;
          }
        }

        return result;
    }
    return tmp;
  }
  function startsWith(_this__u8e3s4, prefix, ignoreCase) {
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    if (!ignoreCase) {
      // Inline function 'kotlin.text.nativeStartsWith' call
      // Inline function 'kotlin.js.asDynamic' call
      return _this__u8e3s4.startsWith(prefix, 0);
    } else
      return regionMatches(_this__u8e3s4, 0, prefix, 0, prefix.length, ignoreCase);
  }
  function replaceFirst(_this__u8e3s4, oldValue, newValue, ignoreCase) {
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    var tmp1 = new RegExp(Companion_getInstance_3().escape_984trb_k$(oldValue), ignoreCase ? 'ui' : 'u');
    // Inline function 'kotlin.text.nativeReplace' call
    var replacement = Companion_getInstance_3().nativeEscapeReplacement_5elzqg_k$(newValue);
    // Inline function 'kotlin.js.asDynamic' call
    return _this__u8e3s4.replace(tmp1, replacement);
  }
  function endsWith(_this__u8e3s4, suffix, ignoreCase) {
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    if (!ignoreCase) {
      // Inline function 'kotlin.text.nativeEndsWith' call
      // Inline function 'kotlin.js.asDynamic' call
      return _this__u8e3s4.endsWith(suffix);
    } else
      return regionMatches(_this__u8e3s4, _this__u8e3s4.length - suffix.length | 0, suffix, 0, suffix.length, ignoreCase);
  }
  function regionMatches(_this__u8e3s4, thisOffset, other, otherOffset, length, ignoreCase) {
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    return regionMatchesImpl(_this__u8e3s4, thisOffset, other, otherOffset, length, ignoreCase);
  }
  function AbstractCollection$toString$lambda(this$0) {
    return function (it) {
      return it === this$0 ? '(this Collection)' : toString_0(it);
    };
  }
  function AbstractCollection() {
  }
  protoOf(AbstractCollection).contains_aljjnj_k$ = function (element) {
    var tmp$ret$0;
    $l$block_0: {
      // Inline function 'kotlin.collections.any' call
      var tmp;
      if (isInterface(this, Collection)) {
        tmp = this.isEmpty_y1axqb_k$();
      } else {
        tmp = false;
      }
      if (tmp) {
        tmp$ret$0 = false;
        break $l$block_0;
      }
      var _iterator__ex2g4s = this.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var element_0 = _iterator__ex2g4s.next_20eer_k$();
        if (equals(element_0, element)) {
          tmp$ret$0 = true;
          break $l$block_0;
        }
      }
      tmp$ret$0 = false;
    }
    return tmp$ret$0;
  };
  protoOf(AbstractCollection).containsAll_bwkf3g_k$ = function (elements) {
    var tmp$ret$0;
    $l$block_0: {
      // Inline function 'kotlin.collections.all' call
      var tmp;
      if (isInterface(elements, Collection)) {
        tmp = elements.isEmpty_y1axqb_k$();
      } else {
        tmp = false;
      }
      if (tmp) {
        tmp$ret$0 = true;
        break $l$block_0;
      }
      var _iterator__ex2g4s = elements.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s.next_20eer_k$();
        if (!this.contains_aljjnj_k$(element)) {
          tmp$ret$0 = false;
          break $l$block_0;
        }
      }
      tmp$ret$0 = true;
    }
    return tmp$ret$0;
  };
  protoOf(AbstractCollection).isEmpty_y1axqb_k$ = function () {
    return this.get_size_woubt6_k$() === 0;
  };
  protoOf(AbstractCollection).toString = function () {
    return joinToString_0(this, ', ', '[', ']', VOID, VOID, AbstractCollection$toString$lambda(this));
  };
  protoOf(AbstractCollection).toArray = function () {
    return collectionToArray(this);
  };
  function IteratorImpl_0($outer) {
    this.$this_1 = $outer;
    this.index_1 = 0;
  }
  protoOf(IteratorImpl_0).hasNext_bitz1p_k$ = function () {
    return this.index_1 < this.$this_1.get_size_woubt6_k$();
  };
  protoOf(IteratorImpl_0).next_20eer_k$ = function () {
    if (!this.hasNext_bitz1p_k$())
      throw NoSuchElementException_init_$Create$();
    var _unary__edvuaz = this.index_1;
    this.index_1 = _unary__edvuaz + 1 | 0;
    return this.$this_1.get_c1px32_k$(_unary__edvuaz);
  };
  function ListIteratorImpl_0($outer, index) {
    this.$this_2 = $outer;
    IteratorImpl_0.call(this, $outer);
    Companion_instance_4.checkPositionIndex_w4k0on_k$(index, this.$this_2.get_size_woubt6_k$());
    this.index_1 = index;
  }
  protoOf(ListIteratorImpl_0).hasPrevious_qh0629_k$ = function () {
    return this.index_1 > 0;
  };
  protoOf(ListIteratorImpl_0).previous_l2dfd5_k$ = function () {
    if (!this.hasPrevious_qh0629_k$())
      throw NoSuchElementException_init_$Create$();
    this.index_1 = this.index_1 - 1 | 0;
    return this.$this_2.get_c1px32_k$(this.index_1);
  };
  function Companion_4() {
    this.maxArraySize_1 = 2147483639;
  }
  protoOf(Companion_4).checkElementIndex_s0yg86_k$ = function (index, size) {
    if (index < 0 || index >= size) {
      throw IndexOutOfBoundsException_init_$Create$_0('index: ' + index + ', size: ' + size);
    }
  };
  protoOf(Companion_4).checkPositionIndex_w4k0on_k$ = function (index, size) {
    if (index < 0 || index > size) {
      throw IndexOutOfBoundsException_init_$Create$_0('index: ' + index + ', size: ' + size);
    }
  };
  protoOf(Companion_4).checkBoundsIndexes_tsopv1_k$ = function (startIndex, endIndex, size) {
    if (startIndex < 0 || endIndex > size) {
      throw IndexOutOfBoundsException_init_$Create$_0('startIndex: ' + startIndex + ', endIndex: ' + endIndex + ', size: ' + size);
    }
    if (startIndex > endIndex) {
      throw IllegalArgumentException_init_$Create$_0('startIndex: ' + startIndex + ' > endIndex: ' + endIndex);
    }
  };
  protoOf(Companion_4).newCapacity_k5ozfy_k$ = function (oldCapacity, minCapacity) {
    var newCapacity = oldCapacity + (oldCapacity >> 1) | 0;
    if ((newCapacity - minCapacity | 0) < 0)
      newCapacity = minCapacity;
    if ((newCapacity - 2147483639 | 0) > 0)
      newCapacity = minCapacity > 2147483639 ? 2147483647 : 2147483639;
    return newCapacity;
  };
  protoOf(Companion_4).orderedHashCode_srkix_k$ = function (c) {
    var hashCode_0 = 1;
    var _iterator__ex2g4s = c.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var e = _iterator__ex2g4s.next_20eer_k$();
      var tmp = imul(31, hashCode_0);
      var tmp1_elvis_lhs = e == null ? null : hashCode(e);
      hashCode_0 = tmp + (tmp1_elvis_lhs == null ? 0 : tmp1_elvis_lhs) | 0;
    }
    return hashCode_0;
  };
  protoOf(Companion_4).orderedEquals_jt170c_k$ = function (c, other) {
    if (!(c.get_size_woubt6_k$() === other.get_size_woubt6_k$()))
      return false;
    var otherIterator = other.iterator_jk1svi_k$();
    var _iterator__ex2g4s = c.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var elem = _iterator__ex2g4s.next_20eer_k$();
      var elemOther = otherIterator.next_20eer_k$();
      if (!equals(elem, elemOther)) {
        return false;
      }
    }
    return true;
  };
  var Companion_instance_4;
  function Companion_getInstance_4() {
    return Companion_instance_4;
  }
  function AbstractList() {
    AbstractCollection.call(this);
  }
  protoOf(AbstractList).iterator_jk1svi_k$ = function () {
    return new IteratorImpl_0(this);
  };
  protoOf(AbstractList).indexOf_si1fv9_k$ = function (element) {
    var tmp$ret$1;
    $l$block: {
      // Inline function 'kotlin.collections.indexOfFirst' call
      var index = 0;
      var _iterator__ex2g4s = this.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var item = _iterator__ex2g4s.next_20eer_k$();
        if (equals(item, element)) {
          tmp$ret$1 = index;
          break $l$block;
        }
        index = index + 1 | 0;
      }
      tmp$ret$1 = -1;
    }
    return tmp$ret$1;
  };
  protoOf(AbstractList).listIterator_70e65o_k$ = function (index) {
    return new ListIteratorImpl_0(this, index);
  };
  protoOf(AbstractList).equals = function (other) {
    if (other === this)
      return true;
    if (!(!(other == null) ? isInterface(other, KtList) : false))
      return false;
    return Companion_instance_4.orderedEquals_jt170c_k$(this, other);
  };
  protoOf(AbstractList).hashCode = function () {
    return Companion_instance_4.orderedHashCode_srkix_k$(this);
  };
  function toString_3($this, entry) {
    return toString_4($this, entry.get_key_18j28a_k$()) + '=' + toString_4($this, entry.get_value_j01efc_k$());
  }
  function toString_4($this, o) {
    return o === $this ? '(this Map)' : toString_0(o);
  }
  function implFindEntry($this, key) {
    var tmp0 = $this.get_entries_p20ztl_k$();
    var tmp$ret$1;
    $l$block: {
      // Inline function 'kotlin.collections.firstOrNull' call
      var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s.next_20eer_k$();
        if (equals(element.get_key_18j28a_k$(), key)) {
          tmp$ret$1 = element;
          break $l$block;
        }
      }
      tmp$ret$1 = null;
    }
    return tmp$ret$1;
  }
  function Companion_5() {
  }
  var Companion_instance_5;
  function Companion_getInstance_5() {
    return Companion_instance_5;
  }
  function AbstractMap$toString$lambda(this$0) {
    return function (it) {
      return toString_3(this$0, it);
    };
  }
  function AbstractMap() {
    this._keys_1 = null;
    this._values_1 = null;
  }
  protoOf(AbstractMap).containsKey_aw81wo_k$ = function (key) {
    return !(implFindEntry(this, key) == null);
  };
  protoOf(AbstractMap).containsEntry_50dpfo_k$ = function (entry) {
    if (!(!(entry == null) ? isInterface(entry, Entry) : false))
      return false;
    var key = entry.get_key_18j28a_k$();
    var value = entry.get_value_j01efc_k$();
    // Inline function 'kotlin.collections.get' call
    var ourValue = (isInterface(this, KtMap) ? this : THROW_CCE()).get_wei43m_k$(key);
    if (!equals(value, ourValue)) {
      return false;
    }
    var tmp;
    if (ourValue == null) {
      // Inline function 'kotlin.collections.containsKey' call
      tmp = !(isInterface(this, KtMap) ? this : THROW_CCE()).containsKey_aw81wo_k$(key);
    } else {
      tmp = false;
    }
    if (tmp) {
      return false;
    }
    return true;
  };
  protoOf(AbstractMap).equals = function (other) {
    if (other === this)
      return true;
    if (!(!(other == null) ? isInterface(other, KtMap) : false))
      return false;
    if (!(this.get_size_woubt6_k$() === other.get_size_woubt6_k$()))
      return false;
    var tmp0 = other.get_entries_p20ztl_k$();
    var tmp$ret$0;
    $l$block_0: {
      // Inline function 'kotlin.collections.all' call
      var tmp;
      if (isInterface(tmp0, Collection)) {
        tmp = tmp0.isEmpty_y1axqb_k$();
      } else {
        tmp = false;
      }
      if (tmp) {
        tmp$ret$0 = true;
        break $l$block_0;
      }
      var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s.next_20eer_k$();
        if (!this.containsEntry_50dpfo_k$(element)) {
          tmp$ret$0 = false;
          break $l$block_0;
        }
      }
      tmp$ret$0 = true;
    }
    return tmp$ret$0;
  };
  protoOf(AbstractMap).get_wei43m_k$ = function (key) {
    var tmp0_safe_receiver = implFindEntry(this, key);
    return tmp0_safe_receiver == null ? null : tmp0_safe_receiver.get_value_j01efc_k$();
  };
  protoOf(AbstractMap).hashCode = function () {
    return hashCode(this.get_entries_p20ztl_k$());
  };
  protoOf(AbstractMap).isEmpty_y1axqb_k$ = function () {
    return this.get_size_woubt6_k$() === 0;
  };
  protoOf(AbstractMap).get_size_woubt6_k$ = function () {
    return this.get_entries_p20ztl_k$().get_size_woubt6_k$();
  };
  protoOf(AbstractMap).toString = function () {
    var tmp = this.get_entries_p20ztl_k$();
    return joinToString_0(tmp, ', ', '{', '}', VOID, VOID, AbstractMap$toString$lambda(this));
  };
  function Companion_6() {
  }
  protoOf(Companion_6).unorderedHashCode_8c2ypq_k$ = function (c) {
    var hashCode_0 = 0;
    var _iterator__ex2g4s = c.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      var tmp = hashCode_0;
      var tmp1_elvis_lhs = element == null ? null : hashCode(element);
      hashCode_0 = tmp + (tmp1_elvis_lhs == null ? 0 : tmp1_elvis_lhs) | 0;
    }
    return hashCode_0;
  };
  protoOf(Companion_6).setEquals_mjzluv_k$ = function (c, other) {
    if (!(c.get_size_woubt6_k$() === other.get_size_woubt6_k$()))
      return false;
    return c.containsAll_bwkf3g_k$(other);
  };
  var Companion_instance_6;
  function Companion_getInstance_6() {
    return Companion_instance_6;
  }
  function collectionToArrayCommonImpl(collection) {
    if (collection.isEmpty_y1axqb_k$()) {
      // Inline function 'kotlin.emptyArray' call
      return [];
    }
    // Inline function 'kotlin.arrayOfNulls' call
    var size = collection.get_size_woubt6_k$();
    var destination = Array(size);
    var iterator = collection.iterator_jk1svi_k$();
    var index = 0;
    while (iterator.hasNext_bitz1p_k$()) {
      var _unary__edvuaz = index;
      index = _unary__edvuaz + 1 | 0;
      destination[_unary__edvuaz] = iterator.next_20eer_k$();
    }
    return destination;
  }
  function listOf_0(elements) {
    return elements.length > 0 ? asList(elements) : emptyList();
  }
  function get_indices(_this__u8e3s4) {
    return numberRangeToNumber(0, _this__u8e3s4.get_size_woubt6_k$() - 1 | 0);
  }
  function arrayListOf(elements) {
    return elements.length === 0 ? ArrayList_init_$Create$() : ArrayList_init_$Create$_1(new ArrayAsCollection(elements, true));
  }
  function emptyList() {
    return EmptyList_getInstance();
  }
  function get_lastIndex_0(_this__u8e3s4) {
    return _this__u8e3s4.get_size_woubt6_k$() - 1 | 0;
  }
  function optimizeReadOnlyList(_this__u8e3s4) {
    switch (_this__u8e3s4.get_size_woubt6_k$()) {
      case 0:
        return emptyList();
      case 1:
        return listOf(_this__u8e3s4.get_c1px32_k$(0));
      default:
        return _this__u8e3s4;
    }
  }
  function throwIndexOverflow() {
    throw ArithmeticException_init_$Create$_0('Index overflow has happened.');
  }
  function EmptyList() {
    EmptyList_instance = this;
    this.serialVersionUID_1 = new Long(-1478467534, -1720727600);
  }
  protoOf(EmptyList).equals = function (other) {
    var tmp;
    if (!(other == null) ? isInterface(other, KtList) : false) {
      tmp = other.isEmpty_y1axqb_k$();
    } else {
      tmp = false;
    }
    return tmp;
  };
  protoOf(EmptyList).hashCode = function () {
    return 1;
  };
  protoOf(EmptyList).toString = function () {
    return '[]';
  };
  protoOf(EmptyList).get_size_woubt6_k$ = function () {
    return 0;
  };
  protoOf(EmptyList).isEmpty_y1axqb_k$ = function () {
    return true;
  };
  protoOf(EmptyList).contains_a7ux40_k$ = function (element) {
    return false;
  };
  protoOf(EmptyList).contains_aljjnj_k$ = function (element) {
    if (!false)
      return false;
    var tmp;
    if (false) {
      tmp = element;
    } else {
      tmp = THROW_CCE();
    }
    return this.contains_a7ux40_k$(tmp);
  };
  protoOf(EmptyList).get_c1px32_k$ = function (index) {
    throw IndexOutOfBoundsException_init_$Create$_0("Empty list doesn't contain element at index " + index + '.');
  };
  protoOf(EmptyList).indexOf_31ms1i_k$ = function (element) {
    return -1;
  };
  protoOf(EmptyList).indexOf_si1fv9_k$ = function (element) {
    if (!false)
      return -1;
    var tmp;
    if (false) {
      tmp = element;
    } else {
      tmp = THROW_CCE();
    }
    return this.indexOf_31ms1i_k$(tmp);
  };
  protoOf(EmptyList).iterator_jk1svi_k$ = function () {
    return EmptyIterator_instance;
  };
  protoOf(EmptyList).listIterator_70e65o_k$ = function (index) {
    if (!(index === 0))
      throw IndexOutOfBoundsException_init_$Create$_0('Index: ' + index);
    return EmptyIterator_instance;
  };
  var EmptyList_instance;
  function EmptyList_getInstance() {
    if (EmptyList_instance == null)
      new EmptyList();
    return EmptyList_instance;
  }
  function ArrayAsCollection(values, isVarargs) {
    this.values_1 = values;
    this.isVarargs_1 = isVarargs;
  }
  protoOf(ArrayAsCollection).get_size_woubt6_k$ = function () {
    return this.values_1.length;
  };
  protoOf(ArrayAsCollection).isEmpty_y1axqb_k$ = function () {
    // Inline function 'kotlin.collections.isEmpty' call
    return this.values_1.length === 0;
  };
  protoOf(ArrayAsCollection).iterator_jk1svi_k$ = function () {
    return arrayIterator(this.values_1);
  };
  function EmptyIterator() {
  }
  protoOf(EmptyIterator).hasNext_bitz1p_k$ = function () {
    return false;
  };
  protoOf(EmptyIterator).hasPrevious_qh0629_k$ = function () {
    return false;
  };
  protoOf(EmptyIterator).next_20eer_k$ = function () {
    throw NoSuchElementException_init_$Create$();
  };
  protoOf(EmptyIterator).previous_l2dfd5_k$ = function () {
    throw NoSuchElementException_init_$Create$();
  };
  var EmptyIterator_instance;
  function EmptyIterator_getInstance() {
    return EmptyIterator_instance;
  }
  function asCollection(_this__u8e3s4) {
    return new ArrayAsCollection(_this__u8e3s4, false);
  }
  function IndexedValue(index, value) {
    this.index_1 = index;
    this.value_1 = value;
  }
  protoOf(IndexedValue).component2_7eebsb_k$ = function () {
    return this.value_1;
  };
  protoOf(IndexedValue).toString = function () {
    return 'IndexedValue(index=' + this.index_1 + ', value=' + toString_0(this.value_1) + ')';
  };
  protoOf(IndexedValue).hashCode = function () {
    var result = this.index_1;
    result = imul(result, 31) + (this.value_1 == null ? 0 : hashCode(this.value_1)) | 0;
    return result;
  };
  protoOf(IndexedValue).equals = function (other) {
    if (this === other)
      return true;
    if (!(other instanceof IndexedValue))
      return false;
    var tmp0_other_with_cast = other instanceof IndexedValue ? other : THROW_CCE();
    if (!(this.index_1 === tmp0_other_with_cast.index_1))
      return false;
    if (!equals(this.value_1, tmp0_other_with_cast.value_1))
      return false;
    return true;
  };
  function collectionSizeOrDefault(_this__u8e3s4, default_0) {
    var tmp;
    if (isInterface(_this__u8e3s4, Collection)) {
      tmp = _this__u8e3s4.get_size_woubt6_k$();
    } else {
      tmp = default_0;
    }
    return tmp;
  }
  function IndexingIterable(iteratorFactory) {
    this.iteratorFactory_1 = iteratorFactory;
  }
  protoOf(IndexingIterable).iterator_jk1svi_k$ = function () {
    return new IndexingIterator(this.iteratorFactory_1());
  };
  function IndexingIterator(iterator) {
    this.iterator_1 = iterator;
    this.index_1 = 0;
  }
  protoOf(IndexingIterator).hasNext_bitz1p_k$ = function () {
    return this.iterator_1.hasNext_bitz1p_k$();
  };
  protoOf(IndexingIterator).next_20eer_k$ = function () {
    var _unary__edvuaz = this.index_1;
    this.index_1 = _unary__edvuaz + 1 | 0;
    return new IndexedValue(checkIndexOverflow(_unary__edvuaz), this.iterator_1.next_20eer_k$());
  };
  function mapOf(pairs) {
    return pairs.length > 0 ? toMap(pairs, LinkedHashMap_init_$Create$_0(mapCapacity(pairs.length))) : emptyMap();
  }
  function emptyMap() {
    var tmp = EmptyMap_getInstance();
    return isInterface(tmp, KtMap) ? tmp : THROW_CCE();
  }
  function toMutableMap(_this__u8e3s4) {
    return LinkedHashMap_init_$Create$_1(_this__u8e3s4);
  }
  function toMap(_this__u8e3s4, destination) {
    // Inline function 'kotlin.apply' call
    putAll(destination, _this__u8e3s4);
    return destination;
  }
  function EmptyMap() {
    EmptyMap_instance = this;
    this.serialVersionUID_1 = new Long(-888910638, 1920087921);
  }
  protoOf(EmptyMap).equals = function (other) {
    var tmp;
    if (!(other == null) ? isInterface(other, KtMap) : false) {
      tmp = other.isEmpty_y1axqb_k$();
    } else {
      tmp = false;
    }
    return tmp;
  };
  protoOf(EmptyMap).hashCode = function () {
    return 0;
  };
  protoOf(EmptyMap).toString = function () {
    return '{}';
  };
  protoOf(EmptyMap).get_size_woubt6_k$ = function () {
    return 0;
  };
  protoOf(EmptyMap).isEmpty_y1axqb_k$ = function () {
    return true;
  };
  protoOf(EmptyMap).containsKey_v2r3nj_k$ = function (key) {
    return false;
  };
  protoOf(EmptyMap).containsKey_aw81wo_k$ = function (key) {
    if (!(key == null ? true : !(key == null)))
      return false;
    return this.containsKey_v2r3nj_k$((key == null ? true : !(key == null)) ? key : THROW_CCE());
  };
  protoOf(EmptyMap).get_eccq09_k$ = function (key) {
    return null;
  };
  protoOf(EmptyMap).get_wei43m_k$ = function (key) {
    if (!(key == null ? true : !(key == null)))
      return null;
    return this.get_eccq09_k$((key == null ? true : !(key == null)) ? key : THROW_CCE());
  };
  protoOf(EmptyMap).get_entries_p20ztl_k$ = function () {
    return EmptySet_getInstance();
  };
  var EmptyMap_instance;
  function EmptyMap_getInstance() {
    if (EmptyMap_instance == null)
      new EmptyMap();
    return EmptyMap_instance;
  }
  function putAll(_this__u8e3s4, pairs) {
    var inductionVariable = 0;
    var last = pairs.length;
    while (inductionVariable < last) {
      var _destruct__k2r9zo = pairs[inductionVariable];
      inductionVariable = inductionVariable + 1 | 0;
      var key = _destruct__k2r9zo.component1_7eebsc_k$();
      var value = _destruct__k2r9zo.component2_7eebsb_k$();
      _this__u8e3s4.put_4fpzoq_k$(key, value);
    }
  }
  function addAll(_this__u8e3s4, elements) {
    if (isInterface(elements, Collection))
      return _this__u8e3s4.addAll_h3ej1q_k$(elements);
    else {
      var result = false;
      var _iterator__ex2g4s = elements.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var item = _iterator__ex2g4s.next_20eer_k$();
        if (_this__u8e3s4.add_utx5q5_k$(item))
          result = true;
      }
      return result;
    }
  }
  function IntIterator() {
  }
  protoOf(IntIterator).next_20eer_k$ = function () {
    return this.nextInt_ujorgc_k$();
  };
  function asReversed(_this__u8e3s4) {
    return new ReversedListReadOnly(_this__u8e3s4);
  }
  function ReversedListReadOnly$listIterator$1(this$0, $index) {
    this.this$0__1 = this$0;
    this.delegateIterator_1 = this$0.delegate_1.listIterator_70e65o_k$(reversePositionIndex(this$0, $index));
  }
  protoOf(ReversedListReadOnly$listIterator$1).hasNext_bitz1p_k$ = function () {
    return this.delegateIterator_1.hasPrevious_qh0629_k$();
  };
  protoOf(ReversedListReadOnly$listIterator$1).hasPrevious_qh0629_k$ = function () {
    return this.delegateIterator_1.hasNext_bitz1p_k$();
  };
  protoOf(ReversedListReadOnly$listIterator$1).next_20eer_k$ = function () {
    return this.delegateIterator_1.previous_l2dfd5_k$();
  };
  protoOf(ReversedListReadOnly$listIterator$1).previous_l2dfd5_k$ = function () {
    return this.delegateIterator_1.next_20eer_k$();
  };
  function ReversedListReadOnly(delegate) {
    AbstractList.call(this);
    this.delegate_1 = delegate;
  }
  protoOf(ReversedListReadOnly).get_size_woubt6_k$ = function () {
    return this.delegate_1.get_size_woubt6_k$();
  };
  protoOf(ReversedListReadOnly).get_c1px32_k$ = function (index) {
    return this.delegate_1.get_c1px32_k$(reverseElementIndex(this, index));
  };
  protoOf(ReversedListReadOnly).iterator_jk1svi_k$ = function () {
    return this.listIterator_70e65o_k$(0);
  };
  protoOf(ReversedListReadOnly).listIterator_70e65o_k$ = function (index) {
    return new ReversedListReadOnly$listIterator$1(this, index);
  };
  function reverseElementIndex(_this__u8e3s4, index) {
    var tmp;
    if (0 <= index ? index <= get_lastIndex_0(_this__u8e3s4) : false) {
      tmp = get_lastIndex_0(_this__u8e3s4) - index | 0;
    } else {
      throw IndexOutOfBoundsException_init_$Create$_0('Element index ' + index + ' must be in range [' + numberRangeToNumber(0, get_lastIndex_0(_this__u8e3s4)).toString() + '].');
    }
    return tmp;
  }
  function reversePositionIndex(_this__u8e3s4, index) {
    var tmp;
    if (0 <= index ? index <= _this__u8e3s4.get_size_woubt6_k$() : false) {
      tmp = _this__u8e3s4.get_size_woubt6_k$() - index | 0;
    } else {
      throw IndexOutOfBoundsException_init_$Create$_0('Position index ' + index + ' must be in range [' + numberRangeToNumber(0, _this__u8e3s4.get_size_woubt6_k$()).toString() + '].');
    }
    return tmp;
  }
  function generateSequence(seedFunction, nextFunction) {
    return new GeneratorSequence(seedFunction, nextFunction);
  }
  function emptySequence() {
    return EmptySequence_instance;
  }
  function DropTakeSequence() {
  }
  function TakeSequence$iterator$1(this$0) {
    this.left_1 = this$0.count_1;
    this.iterator_1 = this$0.sequence_1.iterator_jk1svi_k$();
  }
  protoOf(TakeSequence$iterator$1).next_20eer_k$ = function () {
    if (this.left_1 === 0)
      throw NoSuchElementException_init_$Create$();
    this.left_1 = this.left_1 - 1 | 0;
    return this.iterator_1.next_20eer_k$();
  };
  protoOf(TakeSequence$iterator$1).hasNext_bitz1p_k$ = function () {
    return this.left_1 > 0 && this.iterator_1.hasNext_bitz1p_k$();
  };
  function TakeSequence(sequence, count) {
    this.sequence_1 = sequence;
    this.count_1 = count;
    // Inline function 'kotlin.require' call
    if (!(this.count_1 >= 0)) {
      var message = 'count must be non-negative, but was ' + this.count_1 + '.';
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
  }
  protoOf(TakeSequence).take_6gva4v_k$ = function (n) {
    return n >= this.count_1 ? this : new TakeSequence(this.sequence_1, n);
  };
  protoOf(TakeSequence).iterator_jk1svi_k$ = function () {
    return new TakeSequence$iterator$1(this);
  };
  function TransformingSequence$iterator$1(this$0) {
    this.this$0__1 = this$0;
    this.iterator_1 = this$0.sequence_1.iterator_jk1svi_k$();
  }
  protoOf(TransformingSequence$iterator$1).next_20eer_k$ = function () {
    return this.this$0__1.transformer_1(this.iterator_1.next_20eer_k$());
  };
  protoOf(TransformingSequence$iterator$1).hasNext_bitz1p_k$ = function () {
    return this.iterator_1.hasNext_bitz1p_k$();
  };
  function TransformingSequence(sequence, transformer) {
    this.sequence_1 = sequence;
    this.transformer_1 = transformer;
  }
  protoOf(TransformingSequence).iterator_jk1svi_k$ = function () {
    return new TransformingSequence$iterator$1(this);
  };
  function calcNext($this) {
    $this.nextItem_1 = $this.nextState_1 === -2 ? $this.this$0__1.getInitialValue_1() : $this.this$0__1.getNextValue_1(ensureNotNull($this.nextItem_1));
    $this.nextState_1 = $this.nextItem_1 == null ? 0 : 1;
  }
  function GeneratorSequence$iterator$1(this$0) {
    this.this$0__1 = this$0;
    this.nextItem_1 = null;
    this.nextState_1 = -2;
  }
  protoOf(GeneratorSequence$iterator$1).next_20eer_k$ = function () {
    if (this.nextState_1 < 0) {
      calcNext(this);
    }
    if (this.nextState_1 === 0)
      throw NoSuchElementException_init_$Create$();
    var tmp = this.nextItem_1;
    var result = !(tmp == null) ? tmp : THROW_CCE();
    this.nextState_1 = -1;
    return result;
  };
  protoOf(GeneratorSequence$iterator$1).hasNext_bitz1p_k$ = function () {
    if (this.nextState_1 < 0) {
      calcNext(this);
    }
    return this.nextState_1 === 1;
  };
  function GeneratorSequence(getInitialValue, getNextValue) {
    this.getInitialValue_1 = getInitialValue;
    this.getNextValue_1 = getNextValue;
  }
  protoOf(GeneratorSequence).iterator_jk1svi_k$ = function () {
    return new GeneratorSequence$iterator$1(this);
  };
  function EmptySequence() {
  }
  protoOf(EmptySequence).iterator_jk1svi_k$ = function () {
    return EmptyIterator_instance;
  };
  protoOf(EmptySequence).take_6gva4v_k$ = function (n) {
    return EmptySequence_instance;
  };
  var EmptySequence_instance;
  function EmptySequence_getInstance() {
    return EmptySequence_instance;
  }
  function setOf_0(elements) {
    return toSet(elements);
  }
  function EmptySet() {
    EmptySet_instance = this;
    this.serialVersionUID_1 = new Long(1993859828, 793161749);
  }
  protoOf(EmptySet).equals = function (other) {
    var tmp;
    if (!(other == null) ? isInterface(other, KtSet) : false) {
      tmp = other.isEmpty_y1axqb_k$();
    } else {
      tmp = false;
    }
    return tmp;
  };
  protoOf(EmptySet).hashCode = function () {
    return 0;
  };
  protoOf(EmptySet).toString = function () {
    return '[]';
  };
  protoOf(EmptySet).get_size_woubt6_k$ = function () {
    return 0;
  };
  protoOf(EmptySet).isEmpty_y1axqb_k$ = function () {
    return true;
  };
  protoOf(EmptySet).contains_a7ux40_k$ = function (element) {
    return false;
  };
  protoOf(EmptySet).contains_aljjnj_k$ = function (element) {
    if (!false)
      return false;
    var tmp;
    if (false) {
      tmp = element;
    } else {
      tmp = THROW_CCE();
    }
    return this.contains_a7ux40_k$(tmp);
  };
  protoOf(EmptySet).containsAll_4yme17_k$ = function (elements) {
    return elements.isEmpty_y1axqb_k$();
  };
  protoOf(EmptySet).containsAll_bwkf3g_k$ = function (elements) {
    return this.containsAll_4yme17_k$(elements);
  };
  protoOf(EmptySet).iterator_jk1svi_k$ = function () {
    return EmptyIterator_instance;
  };
  var EmptySet_instance;
  function EmptySet_getInstance() {
    if (EmptySet_instance == null)
      new EmptySet();
    return EmptySet_instance;
  }
  function emptySet() {
    return EmptySet_getInstance();
  }
  function optimizeReadOnlySet(_this__u8e3s4) {
    switch (_this__u8e3s4.get_size_woubt6_k$()) {
      case 0:
        return emptySet();
      case 1:
        return setOf(_this__u8e3s4.iterator_jk1svi_k$().next_20eer_k$());
      default:
        return _this__u8e3s4;
    }
  }
  function hashSetOf(elements) {
    return toCollection(elements, HashSet_init_$Create$_0(mapCapacity(elements.length)));
  }
  function naturalOrder() {
    var tmp = NaturalOrderComparator_instance;
    return isInterface(tmp, Comparator) ? tmp : THROW_CCE();
  }
  function NaturalOrderComparator() {
  }
  protoOf(NaturalOrderComparator).compare_ftmrut_k$ = function (a, b) {
    return compareTo(a, b);
  };
  protoOf(NaturalOrderComparator).compare = function (a, b) {
    var tmp = (!(a == null) ? isComparable(a) : false) ? a : THROW_CCE();
    return this.compare_ftmrut_k$(tmp, (!(b == null) ? isComparable(b) : false) ? b : THROW_CCE());
  };
  var NaturalOrderComparator_instance;
  function NaturalOrderComparator_getInstance() {
    return NaturalOrderComparator_instance;
  }
  function compareValues(a, b) {
    if (a === b)
      return 0;
    if (a == null)
      return -1;
    if (b == null)
      return 1;
    return compareTo((!(a == null) ? isComparable(a) : false) ? a : THROW_CCE(), b);
  }
  function getProgressionLastElement(start, end, step) {
    var tmp;
    if (step > 0) {
      tmp = start >= end ? end : end - differenceModulo(end, start, step) | 0;
    } else if (step < 0) {
      tmp = start <= end ? end : end + differenceModulo(start, end, -step | 0) | 0;
    } else {
      throw IllegalArgumentException_init_$Create$_0('Step is zero.');
    }
    return tmp;
  }
  function differenceModulo(a, b, c) {
    return mod(mod(a, c) - mod(b, c) | 0, c);
  }
  function mod(a, b) {
    var mod = a % b | 0;
    return mod >= 0 ? mod : mod + b | 0;
  }
  function Companion_7() {
    Companion_instance_7 = this;
    this.EMPTY_1 = new IntRange(1, 0);
  }
  var Companion_instance_7;
  function Companion_getInstance_7() {
    if (Companion_instance_7 == null)
      new Companion_7();
    return Companion_instance_7;
  }
  function IntRange(start, endInclusive) {
    Companion_getInstance_7();
    IntProgression.call(this, start, endInclusive, 1);
  }
  protoOf(IntRange).get_start_iypx6h_k$ = function () {
    return this.first_1;
  };
  protoOf(IntRange).get_endInclusive_r07xpi_k$ = function () {
    return this.last_1;
  };
  protoOf(IntRange).isEmpty_y1axqb_k$ = function () {
    return this.first_1 > this.last_1;
  };
  protoOf(IntRange).equals = function (other) {
    var tmp;
    if (other instanceof IntRange) {
      tmp = this.isEmpty_y1axqb_k$() && other.isEmpty_y1axqb_k$() || (this.first_1 === other.first_1 && this.last_1 === other.last_1);
    } else {
      tmp = false;
    }
    return tmp;
  };
  protoOf(IntRange).hashCode = function () {
    return this.isEmpty_y1axqb_k$() ? -1 : imul(31, this.first_1) + this.last_1 | 0;
  };
  protoOf(IntRange).toString = function () {
    return '' + this.first_1 + '..' + this.last_1;
  };
  function IntProgressionIterator(first, last, step) {
    IntIterator.call(this);
    this.step_1 = step;
    this.finalElement_1 = last;
    this.hasNext_1 = this.step_1 > 0 ? first <= last : first >= last;
    this.next_1 = this.hasNext_1 ? first : this.finalElement_1;
  }
  protoOf(IntProgressionIterator).hasNext_bitz1p_k$ = function () {
    return this.hasNext_1;
  };
  protoOf(IntProgressionIterator).nextInt_ujorgc_k$ = function () {
    var value = this.next_1;
    if (value === this.finalElement_1) {
      if (!this.hasNext_1)
        throw NoSuchElementException_init_$Create$();
      this.hasNext_1 = false;
    } else {
      this.next_1 = this.next_1 + this.step_1 | 0;
    }
    return value;
  };
  function Companion_8() {
  }
  protoOf(Companion_8).fromClosedRange_y6bqsv_k$ = function (rangeStart, rangeEnd, step) {
    return new IntProgression(rangeStart, rangeEnd, step);
  };
  var Companion_instance_8;
  function Companion_getInstance_8() {
    return Companion_instance_8;
  }
  function IntProgression(start, endInclusive, step) {
    if (step === 0)
      throw IllegalArgumentException_init_$Create$_0('Step must be non-zero.');
    if (step === -2147483648)
      throw IllegalArgumentException_init_$Create$_0('Step must be greater than Int.MIN_VALUE to avoid overflow on negation.');
    this.first_1 = start;
    this.last_1 = getProgressionLastElement(start, endInclusive, step);
    this.step_1 = step;
  }
  protoOf(IntProgression).iterator_jk1svi_k$ = function () {
    return new IntProgressionIterator(this.first_1, this.last_1, this.step_1);
  };
  protoOf(IntProgression).isEmpty_y1axqb_k$ = function () {
    return this.step_1 > 0 ? this.first_1 > this.last_1 : this.first_1 < this.last_1;
  };
  protoOf(IntProgression).equals = function (other) {
    var tmp;
    if (other instanceof IntProgression) {
      tmp = this.isEmpty_y1axqb_k$() && other.isEmpty_y1axqb_k$() || (this.first_1 === other.first_1 && this.last_1 === other.last_1 && this.step_1 === other.step_1);
    } else {
      tmp = false;
    }
    return tmp;
  };
  protoOf(IntProgression).hashCode = function () {
    return this.isEmpty_y1axqb_k$() ? -1 : imul(31, imul(31, this.first_1) + this.last_1 | 0) + this.step_1 | 0;
  };
  protoOf(IntProgression).toString = function () {
    return this.step_1 > 0 ? '' + this.first_1 + '..' + this.last_1 + ' step ' + this.step_1 : '' + this.first_1 + ' downTo ' + this.last_1 + ' step ' + (-this.step_1 | 0);
  };
  function appendElement(_this__u8e3s4, element, transform) {
    if (!(transform == null))
      _this__u8e3s4.append_jgojdo_k$(transform(element));
    else {
      if (element == null ? true : isCharSequence(element))
        _this__u8e3s4.append_jgojdo_k$(element);
      else {
        if (element instanceof Char)
          _this__u8e3s4.append_58al37_k$(element.value_1);
        else {
          _this__u8e3s4.append_jgojdo_k$(toString_1(element));
        }
      }
    }
  }
  function equals_0(_this__u8e3s4, other, ignoreCase) {
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    if (_this__u8e3s4 === other)
      return true;
    if (!ignoreCase)
      return false;
    var thisUpper = uppercaseChar(_this__u8e3s4);
    var otherUpper = uppercaseChar(other);
    var tmp;
    if (thisUpper === otherUpper) {
      tmp = true;
    } else {
      // Inline function 'kotlin.text.lowercaseChar' call
      // Inline function 'kotlin.text.lowercase' call
      // Inline function 'kotlin.js.asDynamic' call
      // Inline function 'kotlin.js.unsafeCast' call
      var tmp$ret$2 = toString(thisUpper).toLowerCase();
      var tmp_0 = charSequenceGet(tmp$ret$2, 0);
      // Inline function 'kotlin.text.lowercaseChar' call
      // Inline function 'kotlin.text.lowercase' call
      // Inline function 'kotlin.js.asDynamic' call
      // Inline function 'kotlin.js.unsafeCast' call
      var tmp$ret$6 = toString(otherUpper).toLowerCase();
      tmp = tmp_0 === charSequenceGet(tmp$ret$6, 0);
    }
    return tmp;
  }
  function toIntOrNull(_this__u8e3s4) {
    return toIntOrNull_0(_this__u8e3s4, 10);
  }
  function toIntOrNull_0(_this__u8e3s4, radix) {
    checkRadix(radix);
    var length = _this__u8e3s4.length;
    if (length === 0)
      return null;
    var start;
    var isNegative;
    var limit;
    var firstChar = charSequenceGet(_this__u8e3s4, 0);
    if (Char__compareTo_impl_ypi4mb(firstChar, _Char___init__impl__6a9atx(48)) < 0) {
      if (length === 1)
        return null;
      start = 1;
      if (firstChar === _Char___init__impl__6a9atx(45)) {
        isNegative = true;
        limit = -2147483648;
      } else if (firstChar === _Char___init__impl__6a9atx(43)) {
        isNegative = false;
        limit = -2147483647;
      } else
        return null;
    } else {
      start = 0;
      isNegative = false;
      limit = -2147483647;
    }
    var limitForMaxRadix = -59652323;
    var limitBeforeMul = limitForMaxRadix;
    var result = 0;
    var inductionVariable = start;
    if (inductionVariable < length)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var digit = digitOf(charSequenceGet(_this__u8e3s4, i), radix);
        if (digit < 0)
          return null;
        if (result < limitBeforeMul) {
          if (limitBeforeMul === limitForMaxRadix) {
            limitBeforeMul = limit / radix | 0;
            if (result < limitBeforeMul) {
              return null;
            }
          } else {
            return null;
          }
        }
        result = imul(result, radix);
        if (result < (limit + digit | 0))
          return null;
        result = result - digit | 0;
      }
       while (inductionVariable < length);
    return isNegative ? result : -result | 0;
  }
  function numberFormatError(input) {
    throw NumberFormatException_init_$Create$_0("Invalid number format: '" + input + "'");
  }
  function trimEnd(_this__u8e3s4, chars) {
    // Inline function 'kotlin.text.trimEnd' call
    var tmp0 = isCharSequence(_this__u8e3s4) ? _this__u8e3s4 : THROW_CCE();
    var tmp$ret$1;
    $l$block: {
      // Inline function 'kotlin.text.trimEnd' call
      var inductionVariable = charSequenceLength(tmp0) - 1 | 0;
      if (0 <= inductionVariable)
        do {
          var index = inductionVariable;
          inductionVariable = inductionVariable + -1 | 0;
          var it = charSequenceGet(tmp0, index);
          if (!contains(chars, it)) {
            tmp$ret$1 = charSequenceSubSequence(tmp0, 0, index + 1 | 0);
            break $l$block;
          }
        }
         while (0 <= inductionVariable);
      tmp$ret$1 = '';
    }
    return toString_1(tmp$ret$1);
  }
  function substringAfterLast(_this__u8e3s4, delimiter, missingDelimiterValue) {
    missingDelimiterValue = missingDelimiterValue === VOID ? _this__u8e3s4 : missingDelimiterValue;
    var index = lastIndexOf_0(_this__u8e3s4, delimiter);
    var tmp;
    if (index === -1) {
      tmp = missingDelimiterValue;
    } else {
      var tmp1 = index + 1 | 0;
      // Inline function 'kotlin.text.substring' call
      var endIndex = _this__u8e3s4.length;
      // Inline function 'kotlin.js.asDynamic' call
      tmp = _this__u8e3s4.substring(tmp1, endIndex);
    }
    return tmp;
  }
  function substringAfter(_this__u8e3s4, delimiter, missingDelimiterValue) {
    missingDelimiterValue = missingDelimiterValue === VOID ? _this__u8e3s4 : missingDelimiterValue;
    var index = indexOf_1(_this__u8e3s4, delimiter);
    var tmp;
    if (index === -1) {
      tmp = missingDelimiterValue;
    } else {
      var tmp1 = index + 1 | 0;
      // Inline function 'kotlin.text.substring' call
      var endIndex = _this__u8e3s4.length;
      // Inline function 'kotlin.js.asDynamic' call
      tmp = _this__u8e3s4.substring(tmp1, endIndex);
    }
    return tmp;
  }
  function substringBeforeLast(_this__u8e3s4, delimiter, missingDelimiterValue) {
    missingDelimiterValue = missingDelimiterValue === VOID ? _this__u8e3s4 : missingDelimiterValue;
    var index = lastIndexOf_0(_this__u8e3s4, delimiter);
    var tmp;
    if (index === -1) {
      tmp = missingDelimiterValue;
    } else {
      // Inline function 'kotlin.text.substring' call
      // Inline function 'kotlin.js.asDynamic' call
      tmp = _this__u8e3s4.substring(0, index);
    }
    return tmp;
  }
  function lastIndexOf(_this__u8e3s4, string, startIndex, ignoreCase) {
    startIndex = startIndex === VOID ? get_lastIndex_1(_this__u8e3s4) : startIndex;
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    var tmp;
    var tmp_0;
    if (ignoreCase) {
      tmp_0 = true;
    } else {
      tmp_0 = !(typeof _this__u8e3s4 === 'string');
    }
    if (tmp_0) {
      tmp = indexOf_2(_this__u8e3s4, string, startIndex, 0, ignoreCase, true);
    } else {
      // Inline function 'kotlin.text.nativeLastIndexOf' call
      // Inline function 'kotlin.js.asDynamic' call
      tmp = _this__u8e3s4.lastIndexOf(string, startIndex);
    }
    return tmp;
  }
  function lastIndexOf_0(_this__u8e3s4, char, startIndex, ignoreCase) {
    startIndex = startIndex === VOID ? get_lastIndex_1(_this__u8e3s4) : startIndex;
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    var tmp;
    var tmp_0;
    if (ignoreCase) {
      tmp_0 = true;
    } else {
      tmp_0 = !(typeof _this__u8e3s4 === 'string');
    }
    if (tmp_0) {
      // Inline function 'kotlin.charArrayOf' call
      var tmp$ret$0 = charArrayOf([char]);
      tmp = lastIndexOfAny(_this__u8e3s4, tmp$ret$0, startIndex, ignoreCase);
    } else {
      // Inline function 'kotlin.text.nativeLastIndexOf' call
      // Inline function 'kotlin.text.nativeLastIndexOf' call
      var str = toString(char);
      // Inline function 'kotlin.js.asDynamic' call
      tmp = _this__u8e3s4.lastIndexOf(str, startIndex);
    }
    return tmp;
  }
  function substringAfter_0(_this__u8e3s4, delimiter, missingDelimiterValue) {
    missingDelimiterValue = missingDelimiterValue === VOID ? _this__u8e3s4 : missingDelimiterValue;
    var index = indexOf_3(_this__u8e3s4, delimiter);
    var tmp;
    if (index === -1) {
      tmp = missingDelimiterValue;
    } else {
      var tmp1 = index + delimiter.length | 0;
      // Inline function 'kotlin.text.substring' call
      var endIndex = _this__u8e3s4.length;
      // Inline function 'kotlin.js.asDynamic' call
      tmp = _this__u8e3s4.substring(tmp1, endIndex);
    }
    return tmp;
  }
  function removePrefix(_this__u8e3s4, prefix) {
    if (startsWith_0(_this__u8e3s4, prefix)) {
      // Inline function 'kotlin.text.substring' call
      var startIndex = charSequenceLength(prefix);
      // Inline function 'kotlin.js.asDynamic' call
      return _this__u8e3s4.substring(startIndex);
    }
    return _this__u8e3s4;
  }
  function split(_this__u8e3s4, delimiters, ignoreCase, limit) {
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    limit = limit === VOID ? 0 : limit;
    if (delimiters.length === 1) {
      return split_0(_this__u8e3s4, toString(delimiters[0]), ignoreCase, limit);
    }
    // Inline function 'kotlin.collections.map' call
    var this_0 = asIterable(rangesDelimitedBy(_this__u8e3s4, delimiters, VOID, ignoreCase, limit));
    // Inline function 'kotlin.collections.mapTo' call
    var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_0, 10));
    var _iterator__ex2g4s = this_0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s.next_20eer_k$();
      var tmp$ret$0 = substring(_this__u8e3s4, item);
      destination.add_utx5q5_k$(tmp$ret$0);
    }
    return destination;
  }
  function substringBefore(_this__u8e3s4, delimiter, missingDelimiterValue) {
    missingDelimiterValue = missingDelimiterValue === VOID ? _this__u8e3s4 : missingDelimiterValue;
    var index = indexOf_1(_this__u8e3s4, delimiter);
    var tmp;
    if (index === -1) {
      tmp = missingDelimiterValue;
    } else {
      // Inline function 'kotlin.text.substring' call
      // Inline function 'kotlin.js.asDynamic' call
      tmp = _this__u8e3s4.substring(0, index);
    }
    return tmp;
  }
  function padStart(_this__u8e3s4, length, padChar) {
    padChar = padChar === VOID ? _Char___init__impl__6a9atx(32) : padChar;
    return toString_1(padStart_0(isCharSequence(_this__u8e3s4) ? _this__u8e3s4 : THROW_CCE(), length, padChar));
  }
  function trim(_this__u8e3s4) {
    // Inline function 'kotlin.text.trim' call
    var startIndex = 0;
    var endIndex = charSequenceLength(_this__u8e3s4) - 1 | 0;
    var startFound = false;
    $l$loop: while (startIndex <= endIndex) {
      var index = !startFound ? startIndex : endIndex;
      var p0 = charSequenceGet(_this__u8e3s4, index);
      var match = isWhitespace(p0);
      if (!startFound) {
        if (!match)
          startFound = true;
        else
          startIndex = startIndex + 1 | 0;
      } else {
        if (!match)
          break $l$loop;
        else
          endIndex = endIndex - 1 | 0;
      }
    }
    return charSequenceSubSequence(_this__u8e3s4, startIndex, endIndex + 1 | 0);
  }
  function isBlank(_this__u8e3s4) {
    var tmp$ret$1;
    $l$block: {
      // Inline function 'kotlin.text.all' call
      var inductionVariable = 0;
      while (inductionVariable < charSequenceLength(_this__u8e3s4)) {
        var element = charSequenceGet(_this__u8e3s4, inductionVariable);
        inductionVariable = inductionVariable + 1 | 0;
        if (!isWhitespace(element)) {
          tmp$ret$1 = false;
          break $l$block;
        }
      }
      tmp$ret$1 = true;
    }
    return tmp$ret$1;
  }
  function indexOf_1(_this__u8e3s4, char, startIndex, ignoreCase) {
    startIndex = startIndex === VOID ? 0 : startIndex;
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    var tmp;
    var tmp_0;
    if (ignoreCase) {
      tmp_0 = true;
    } else {
      tmp_0 = !(typeof _this__u8e3s4 === 'string');
    }
    if (tmp_0) {
      // Inline function 'kotlin.charArrayOf' call
      var tmp$ret$0 = charArrayOf([char]);
      tmp = indexOfAny(_this__u8e3s4, tmp$ret$0, startIndex, ignoreCase);
    } else {
      // Inline function 'kotlin.text.nativeIndexOf' call
      // Inline function 'kotlin.text.nativeIndexOf' call
      var str = toString(char);
      // Inline function 'kotlin.js.asDynamic' call
      tmp = _this__u8e3s4.indexOf(str, startIndex);
    }
    return tmp;
  }
  function get_lastIndex_1(_this__u8e3s4) {
    return charSequenceLength(_this__u8e3s4) - 1 | 0;
  }
  function indexOf_2(_this__u8e3s4, other, startIndex, endIndex, ignoreCase, last) {
    last = last === VOID ? false : last;
    var indices = !last ? numberRangeToNumber(coerceAtLeast_0(startIndex, 0), coerceAtMost(endIndex, charSequenceLength(_this__u8e3s4))) : downTo(coerceAtMost(startIndex, get_lastIndex_1(_this__u8e3s4)), coerceAtLeast_0(endIndex, 0));
    var tmp;
    if (typeof _this__u8e3s4 === 'string') {
      tmp = typeof other === 'string';
    } else {
      tmp = false;
    }
    if (tmp) {
      var inductionVariable = indices.first_1;
      var last_0 = indices.last_1;
      var step = indices.step_1;
      if (step > 0 && inductionVariable <= last_0 || (step < 0 && last_0 <= inductionVariable))
        do {
          var index = inductionVariable;
          inductionVariable = inductionVariable + step | 0;
          if (regionMatches(other, 0, _this__u8e3s4, index, other.length, ignoreCase))
            return index;
        }
         while (!(index === last_0));
    } else {
      var inductionVariable_0 = indices.first_1;
      var last_1 = indices.last_1;
      var step_0 = indices.step_1;
      if (step_0 > 0 && inductionVariable_0 <= last_1 || (step_0 < 0 && last_1 <= inductionVariable_0))
        do {
          var index_0 = inductionVariable_0;
          inductionVariable_0 = inductionVariable_0 + step_0 | 0;
          if (regionMatchesImpl(other, 0, _this__u8e3s4, index_0, charSequenceLength(other), ignoreCase))
            return index_0;
        }
         while (!(index_0 === last_1));
    }
    return -1;
  }
  function lastIndexOfAny(_this__u8e3s4, chars, startIndex, ignoreCase) {
    startIndex = startIndex === VOID ? get_lastIndex_1(_this__u8e3s4) : startIndex;
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    var tmp;
    if (!ignoreCase && chars.length === 1) {
      tmp = typeof _this__u8e3s4 === 'string';
    } else {
      tmp = false;
    }
    if (tmp) {
      var char = single(chars);
      // Inline function 'kotlin.text.nativeLastIndexOf' call
      // Inline function 'kotlin.text.nativeLastIndexOf' call
      var str = toString(char);
      // Inline function 'kotlin.js.asDynamic' call
      return _this__u8e3s4.lastIndexOf(str, startIndex);
    }
    var inductionVariable = coerceAtMost(startIndex, get_lastIndex_1(_this__u8e3s4));
    if (0 <= inductionVariable)
      do {
        var index = inductionVariable;
        inductionVariable = inductionVariable + -1 | 0;
        var charAtIndex = charSequenceGet(_this__u8e3s4, index);
        var tmp$ret$4;
        $l$block: {
          // Inline function 'kotlin.collections.any' call
          var inductionVariable_0 = 0;
          var last = chars.length;
          while (inductionVariable_0 < last) {
            var element = chars[inductionVariable_0];
            inductionVariable_0 = inductionVariable_0 + 1 | 0;
            if (equals_0(element, charAtIndex, ignoreCase)) {
              tmp$ret$4 = true;
              break $l$block;
            }
          }
          tmp$ret$4 = false;
        }
        if (tmp$ret$4)
          return index;
      }
       while (0 <= inductionVariable);
    return -1;
  }
  function indexOf_3(_this__u8e3s4, string, startIndex, ignoreCase) {
    startIndex = startIndex === VOID ? 0 : startIndex;
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    var tmp;
    var tmp_0;
    if (ignoreCase) {
      tmp_0 = true;
    } else {
      tmp_0 = !(typeof _this__u8e3s4 === 'string');
    }
    if (tmp_0) {
      tmp = indexOf_2(_this__u8e3s4, string, startIndex, charSequenceLength(_this__u8e3s4), ignoreCase);
    } else {
      // Inline function 'kotlin.text.nativeIndexOf' call
      // Inline function 'kotlin.js.asDynamic' call
      tmp = _this__u8e3s4.indexOf(string, startIndex);
    }
    return tmp;
  }
  function startsWith_0(_this__u8e3s4, prefix, ignoreCase) {
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    var tmp;
    var tmp_0;
    if (!ignoreCase) {
      tmp_0 = typeof _this__u8e3s4 === 'string';
    } else {
      tmp_0 = false;
    }
    if (tmp_0) {
      tmp = typeof prefix === 'string';
    } else {
      tmp = false;
    }
    if (tmp)
      return startsWith(_this__u8e3s4, prefix);
    else {
      return regionMatchesImpl(_this__u8e3s4, 0, prefix, 0, charSequenceLength(prefix), ignoreCase);
    }
  }
  function split_0(_this__u8e3s4, delimiter, ignoreCase, limit) {
    requireNonNegativeLimit(limit);
    var currentOffset = 0;
    var nextIndex = indexOf_3(_this__u8e3s4, delimiter, currentOffset, ignoreCase);
    if (nextIndex === -1 || limit === 1) {
      return listOf(toString_1(_this__u8e3s4));
    }
    var isLimited = limit > 0;
    var result = ArrayList_init_$Create$_0(isLimited ? coerceAtMost(limit, 10) : 10);
    $l$loop: do {
      var tmp1 = currentOffset;
      // Inline function 'kotlin.text.substring' call
      var endIndex = nextIndex;
      var tmp$ret$0 = toString_1(charSequenceSubSequence(_this__u8e3s4, tmp1, endIndex));
      result.add_utx5q5_k$(tmp$ret$0);
      currentOffset = nextIndex + delimiter.length | 0;
      if (isLimited && result.get_size_woubt6_k$() === (limit - 1 | 0))
        break $l$loop;
      nextIndex = indexOf_3(_this__u8e3s4, delimiter, currentOffset, ignoreCase);
    }
     while (!(nextIndex === -1));
    var tmp4 = currentOffset;
    // Inline function 'kotlin.text.substring' call
    var endIndex_0 = charSequenceLength(_this__u8e3s4);
    var tmp$ret$1 = toString_1(charSequenceSubSequence(_this__u8e3s4, tmp4, endIndex_0));
    result.add_utx5q5_k$(tmp$ret$1);
    return result;
  }
  function substring(_this__u8e3s4, range) {
    return toString_1(charSequenceSubSequence(_this__u8e3s4, range.get_start_iypx6h_k$(), range.get_endInclusive_r07xpi_k$() + 1 | 0));
  }
  function rangesDelimitedBy(_this__u8e3s4, delimiters, startIndex, ignoreCase, limit) {
    startIndex = startIndex === VOID ? 0 : startIndex;
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    limit = limit === VOID ? 0 : limit;
    requireNonNegativeLimit(limit);
    return new DelimitedRangesSequence(_this__u8e3s4, startIndex, limit, rangesDelimitedBy$lambda(delimiters, ignoreCase));
  }
  function padStart_0(_this__u8e3s4, length, padChar) {
    padChar = padChar === VOID ? _Char___init__impl__6a9atx(32) : padChar;
    if (length < 0)
      throw IllegalArgumentException_init_$Create$_0('Desired length ' + length + ' is less than zero.');
    if (length <= charSequenceLength(_this__u8e3s4))
      return charSequenceSubSequence(_this__u8e3s4, 0, charSequenceLength(_this__u8e3s4));
    var sb = StringBuilder_init_$Create$(length);
    var inductionVariable = 1;
    var last = length - charSequenceLength(_this__u8e3s4) | 0;
    if (inductionVariable <= last)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        sb.append_58al37_k$(padChar);
      }
       while (!(i === last));
    sb.append_jgojdo_k$(_this__u8e3s4);
    return sb;
  }
  function indexOfAny(_this__u8e3s4, chars, startIndex, ignoreCase) {
    startIndex = startIndex === VOID ? 0 : startIndex;
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    var tmp;
    if (!ignoreCase && chars.length === 1) {
      tmp = typeof _this__u8e3s4 === 'string';
    } else {
      tmp = false;
    }
    if (tmp) {
      var char = single(chars);
      // Inline function 'kotlin.text.nativeIndexOf' call
      // Inline function 'kotlin.text.nativeIndexOf' call
      var str = toString(char);
      // Inline function 'kotlin.js.asDynamic' call
      return _this__u8e3s4.indexOf(str, startIndex);
    }
    var inductionVariable = coerceAtLeast_0(startIndex, 0);
    var last = get_lastIndex_1(_this__u8e3s4);
    if (inductionVariable <= last)
      do {
        var index = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var charAtIndex = charSequenceGet(_this__u8e3s4, index);
        var tmp$ret$4;
        $l$block: {
          // Inline function 'kotlin.collections.any' call
          var inductionVariable_0 = 0;
          var last_0 = chars.length;
          while (inductionVariable_0 < last_0) {
            var element = chars[inductionVariable_0];
            inductionVariable_0 = inductionVariable_0 + 1 | 0;
            if (equals_0(element, charAtIndex, ignoreCase)) {
              tmp$ret$4 = true;
              break $l$block;
            }
          }
          tmp$ret$4 = false;
        }
        if (tmp$ret$4)
          return index;
      }
       while (!(index === last));
    return -1;
  }
  function regionMatchesImpl(_this__u8e3s4, thisOffset, other, otherOffset, length, ignoreCase) {
    if (otherOffset < 0 || thisOffset < 0 || thisOffset > (charSequenceLength(_this__u8e3s4) - length | 0) || otherOffset > (charSequenceLength(other) - length | 0)) {
      return false;
    }
    var inductionVariable = 0;
    if (inductionVariable < length)
      do {
        var index = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        if (!equals_0(charSequenceGet(_this__u8e3s4, thisOffset + index | 0), charSequenceGet(other, otherOffset + index | 0), ignoreCase))
          return false;
      }
       while (inductionVariable < length);
    return true;
  }
  function requireNonNegativeLimit(limit) {
    // Inline function 'kotlin.require' call
    if (!(limit >= 0)) {
      var message = 'Limit must be non-negative, but was ' + limit;
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    return Unit_instance;
  }
  function calcNext_0($this) {
    if ($this.nextSearchIndex_1 < 0) {
      $this.nextState_1 = 0;
      $this.nextItem_1 = null;
    } else {
      var tmp;
      var tmp_0;
      if ($this.this$0__1.limit_1 > 0) {
        $this.counter_1 = $this.counter_1 + 1 | 0;
        tmp_0 = $this.counter_1 >= $this.this$0__1.limit_1;
      } else {
        tmp_0 = false;
      }
      if (tmp_0) {
        tmp = true;
      } else {
        tmp = $this.nextSearchIndex_1 > charSequenceLength($this.this$0__1.input_1);
      }
      if (tmp) {
        $this.nextItem_1 = numberRangeToNumber($this.currentStartIndex_1, get_lastIndex_1($this.this$0__1.input_1));
        $this.nextSearchIndex_1 = -1;
      } else {
        var match = $this.this$0__1.getNextMatch_1($this.this$0__1.input_1, $this.nextSearchIndex_1);
        if (match == null) {
          $this.nextItem_1 = numberRangeToNumber($this.currentStartIndex_1, get_lastIndex_1($this.this$0__1.input_1));
          $this.nextSearchIndex_1 = -1;
        } else {
          var index = match.component1_7eebsc_k$();
          var length = match.component2_7eebsb_k$();
          $this.nextItem_1 = until($this.currentStartIndex_1, index);
          $this.currentStartIndex_1 = index + length | 0;
          $this.nextSearchIndex_1 = $this.currentStartIndex_1 + (length === 0 ? 1 : 0) | 0;
        }
      }
      $this.nextState_1 = 1;
    }
  }
  function DelimitedRangesSequence$iterator$1(this$0) {
    this.this$0__1 = this$0;
    this.nextState_1 = -1;
    this.currentStartIndex_1 = coerceIn_0(this$0.startIndex_1, 0, charSequenceLength(this$0.input_1));
    this.nextSearchIndex_1 = this.currentStartIndex_1;
    this.nextItem_1 = null;
    this.counter_1 = 0;
  }
  protoOf(DelimitedRangesSequence$iterator$1).next_20eer_k$ = function () {
    if (this.nextState_1 === -1) {
      calcNext_0(this);
    }
    if (this.nextState_1 === 0)
      throw NoSuchElementException_init_$Create$();
    var tmp = this.nextItem_1;
    var result = tmp instanceof IntRange ? tmp : THROW_CCE();
    this.nextItem_1 = null;
    this.nextState_1 = -1;
    return result;
  };
  protoOf(DelimitedRangesSequence$iterator$1).hasNext_bitz1p_k$ = function () {
    if (this.nextState_1 === -1) {
      calcNext_0(this);
    }
    return this.nextState_1 === 1;
  };
  function DelimitedRangesSequence(input, startIndex, limit, getNextMatch) {
    this.input_1 = input;
    this.startIndex_1 = startIndex;
    this.limit_1 = limit;
    this.getNextMatch_1 = getNextMatch;
  }
  protoOf(DelimitedRangesSequence).iterator_jk1svi_k$ = function () {
    return new DelimitedRangesSequence$iterator$1(this);
  };
  function contains_0(_this__u8e3s4, char, ignoreCase) {
    ignoreCase = ignoreCase === VOID ? false : ignoreCase;
    return indexOf_1(_this__u8e3s4, char, VOID, ignoreCase) >= 0;
  }
  function rangesDelimitedBy$lambda($delimiters, $ignoreCase) {
    return function ($this$DelimitedRangesSequence, currentIndex) {
      // Inline function 'kotlin.let' call
      var it = indexOfAny($this$DelimitedRangesSequence, $delimiters, currentIndex, $ignoreCase);
      return it < 0 ? null : to(it, 1);
    };
  }
  function MatchNamedGroupCollection() {
  }
  function UnsafeLazyImpl(initializer) {
    this.initializer_1 = initializer;
    this._value_1 = UNINITIALIZED_VALUE_instance;
  }
  protoOf(UnsafeLazyImpl).get_value_j01efc_k$ = function () {
    if (this._value_1 === UNINITIALIZED_VALUE_instance) {
      this._value_1 = ensureNotNull(this.initializer_1)();
      this.initializer_1 = null;
    }
    var tmp = this._value_1;
    return (tmp == null ? true : !(tmp == null)) ? tmp : THROW_CCE();
  };
  protoOf(UnsafeLazyImpl).isInitialized_2wsk3a_k$ = function () {
    return !(this._value_1 === UNINITIALIZED_VALUE_instance);
  };
  protoOf(UnsafeLazyImpl).toString = function () {
    return this.isInitialized_2wsk3a_k$() ? toString_0(this.get_value_j01efc_k$()) : 'Lazy value not initialized yet.';
  };
  function UNINITIALIZED_VALUE() {
  }
  var UNINITIALIZED_VALUE_instance;
  function UNINITIALIZED_VALUE_getInstance() {
    return UNINITIALIZED_VALUE_instance;
  }
  function _Result___init__impl__xyqfz8(value) {
    return value;
  }
  function _Result___get_value__impl__bjfvqg($this) {
    return $this;
  }
  function _Result___get_isFailure__impl__jpiriv($this) {
    var tmp = _Result___get_value__impl__bjfvqg($this);
    return tmp instanceof Failure;
  }
  function Companion_9() {
  }
  var Companion_instance_9;
  function Companion_getInstance_9() {
    return Companion_instance_9;
  }
  function Failure(exception) {
    this.exception_1 = exception;
  }
  protoOf(Failure).equals = function (other) {
    var tmp;
    if (other instanceof Failure) {
      tmp = equals(this.exception_1, other.exception_1);
    } else {
      tmp = false;
    }
    return tmp;
  };
  protoOf(Failure).hashCode = function () {
    return hashCode(this.exception_1);
  };
  protoOf(Failure).toString = function () {
    return 'Failure(' + this.exception_1.toString() + ')';
  };
  function createFailure(exception) {
    return new Failure(exception);
  }
  function Pair(first, second) {
    this.first_1 = first;
    this.second_1 = second;
  }
  protoOf(Pair).toString = function () {
    return '(' + toString_0(this.first_1) + ', ' + toString_0(this.second_1) + ')';
  };
  protoOf(Pair).component1_7eebsc_k$ = function () {
    return this.first_1;
  };
  protoOf(Pair).component2_7eebsb_k$ = function () {
    return this.second_1;
  };
  protoOf(Pair).hashCode = function () {
    var result = this.first_1 == null ? 0 : hashCode(this.first_1);
    result = imul(result, 31) + (this.second_1 == null ? 0 : hashCode(this.second_1)) | 0;
    return result;
  };
  protoOf(Pair).equals = function (other) {
    if (this === other)
      return true;
    if (!(other instanceof Pair))
      return false;
    var tmp0_other_with_cast = other instanceof Pair ? other : THROW_CCE();
    if (!equals(this.first_1, tmp0_other_with_cast.first_1))
      return false;
    if (!equals(this.second_1, tmp0_other_with_cast.second_1))
      return false;
    return true;
  };
  function to(_this__u8e3s4, that) {
    return new Pair(_this__u8e3s4, that);
  }
  function Triple(first, second, third) {
    this.first_1 = first;
    this.second_1 = second;
    this.third_1 = third;
  }
  protoOf(Triple).toString = function () {
    return '(' + toString_0(this.first_1) + ', ' + toString_0(this.second_1) + ', ' + toString_0(this.third_1) + ')';
  };
  protoOf(Triple).component2_7eebsb_k$ = function () {
    return this.second_1;
  };
  protoOf(Triple).component3_7eebsa_k$ = function () {
    return this.third_1;
  };
  protoOf(Triple).hashCode = function () {
    var result = this.first_1 == null ? 0 : hashCode(this.first_1);
    result = imul(result, 31) + (this.second_1 == null ? 0 : hashCode(this.second_1)) | 0;
    result = imul(result, 31) + (this.third_1 == null ? 0 : hashCode(this.third_1)) | 0;
    return result;
  };
  protoOf(Triple).equals = function (other) {
    if (this === other)
      return true;
    if (!(other instanceof Triple))
      return false;
    var tmp0_other_with_cast = other instanceof Triple ? other : THROW_CCE();
    if (!equals(this.first_1, tmp0_other_with_cast.first_1))
      return false;
    if (!equals(this.second_1, tmp0_other_with_cast.second_1))
      return false;
    if (!equals(this.third_1, tmp0_other_with_cast.third_1))
      return false;
    return true;
  };
  function _UInt___init__impl__l7qpdl(data) {
    return data;
  }
  function _UInt___get_data__impl__f0vqqw($this) {
    return $this;
  }
  function _UShort___init__impl__jigrne(data) {
    return data;
  }
  function _UShort___get_data__impl__g0245($this) {
    return $this;
  }
  function toString_5(_this__u8e3s4, radix) {
    // Inline function 'kotlin.UInt.toInt' call
    var tmp1 = _UInt___get_data__impl__f0vqqw(_this__u8e3s4);
    // Inline function 'kotlin.uintToString' call
    var base = checkRadix(radix);
    // Inline function 'kotlin.uintToLong' call
    var tmp$ret$1 = toLong(tmp1).and_5hkqyb_k$(new Long(-1, 0));
    return ulongToString(tmp$ret$1, base);
  }
  function Companion_10() {
    this.TAG_1 = '~';
  }
  var Companion_instance_10;
  function Companion_getInstance_10() {
    return Companion_instance_10;
  }
  function ComponentDef(id, name, w, h, builder) {
    this.id_1 = id;
    this.name_1 = name;
    this.w_1 = w;
    this.h_1 = h;
    this.builder_1 = builder;
  }
  protoOf(ComponentDef).build_gglqo9_k$ = function (ox, oy, group, tone) {
    var tmp;
    // Inline function 'kotlin.text.isEmpty' call
    if (charSequenceLength(group) === 0) {
      tmp = group;
    } else {
      tmp = group + '~' + this.id_1;
    }
    return this.builder_1(ox, oy, tmp, tone);
  };
  function button($this, id, title, container, content, strokeTok) {
    return new ComponentDef(id, title, 120.0, 40.0, Components$button$lambda(container, strokeTok, content));
  }
  function button$default($this, id, title, container, content, strokeTok, $super) {
    strokeTok = strokeTok === VOID ? -1 : strokeTok;
    return button($this, id, title, container, content, strokeTok);
  }
  function _get_byId__d4l6m1($this) {
    var tmp0 = $this.byId$delegate_1;
    // Inline function 'kotlin.getValue' call
    byId$factory();
    return tmp0.get_value_j01efc_k$();
  }
  function Components$button$lambda($container, $strokeTok, $content) {
    return function (ox, oy, g, t) {
      return listOf_0([Components_getInstance().rect_l2nxf2_k$(t, tr('container', []), g, ox, oy, 120.0, 40.0, 9999.0, $container, $strokeTok, $strokeTok >= 0 ? 1.0 : 0.0), Components_getInstance().label_uq5396_k$(t, g, 'Button', ox + 60.0, oy + 20.0, 14.0, 500, $content)]);
    };
  }
  function Components$classic$lambda(ox, oy, g, t) {
    return listOf_0([Components_getInstance().rect$default_ne0c8u_k$(t, 'FAB', g, ox, oy, 56.0, 56.0, 16.0, 2), Components_getInstance().rect$default_ne0c8u_k$(t, tr('plus_h', []), g, ox + 16.0, oy + 27.0, 24.0, 2.0, 1.0, 3), Components_getInstance().rect$default_ne0c8u_k$(t, tr('plus_v', []), g, ox + 27.0, oy + 16.0, 2.0, 24.0, 1.0, 3)]);
  }
  function Components$classic$lambda_0(ox, oy, g, t) {
    return listOf_0([Components_getInstance().rect$default_ne0c8u_k$(t, tr('container', []), g, ox, oy, 140.0, 56.0, 16.0, 2), Components_getInstance().label_uq5396_k$(t, g, tr('create', []), ox + 70.0, oy + 28.0, 14.0, 500, 3)]);
  }
  function Components$classic$lambda_1(ox, oy, g, t) {
    return listOf_0([Components_getInstance().rect$default_ne0c8u_k$(t, tr('card', []), g, ox, oy, 328.0, 120.0, 12.0, 16), Components_getInstance().labelLeft_4kh12r_k$(t, g, tr('title', []), ox + 16.0, oy + 28.0, 16.0, 500, 17), Components_getInstance().labelLeft_4kh12r_k$(t, g, tr('supporting_text', []), ox + 16.0, oy + 52.0, 14.0, 400, 18)]);
  }
  function Components$classic$lambda_2(ox, oy, g, t) {
    return listOf_0([w(Components_getInstance().rect_l2nxf2_k$(t, tr('chip', []), g, ox, oy, 96.0, 32.0, 8.0, -1, 20, 1.0), 'chip:bg'), w(Components_getInstance().label_uq5396_k$(t, g, 'Filter', ox + 48.0, oy + 16.0, 14.0, 500, 18), 'chip:label')]);
  }
  function Components$classic$lambda_3(ox, oy, g, t) {
    return listOf_0([w(Components_getInstance().rect$default_ne0c8u_k$(t, tr('track', []), g, ox, oy, 52.0, 32.0, 9999.0, 0), 'switch:track'), w(Components_getInstance().oval_w4fudg_k$(t, tr('thumb', []), g, ox + 24.0, oy + 4.0, 24.0, 24.0, 1), 'switch:thumb')]);
  }
  function Components$classic$lambda_4(ox, oy, g, t) {
    return listOf_0([w(Components_getInstance().rect_l2nxf2_k$(t, tr('field', []), g, ox, oy, 280.0, 56.0, 4.0, -1, 19, 1.0), 'focus:box'), w(Components_getInstance().labelLeft_4kh12r_k$(t, g, 'Label', ox + 16.0, oy + 28.0, 16.0, 400, 18), 'focus:label')]);
  }
  function Components$classic$lambda_5(ox, oy, g, t) {
    return plus(listOf_0([Components_getInstance().rect$default_ne0c8u_k$(t, tr('background', []), g, ox, oy, 360.0, 64.0, 0.0, 12), Components_getInstance().labelLeft_4kh12r_k$(t, g, tr('title', []), ox + 64.0, oy + 32.0, 22.0, 400, 17)]), IconNodes_instance.menu_8qjpfe_k$(t, g, ox + 28.0, oy + 32.0, 17));
  }
  function Components$classic$lambda_6(ox, oy, g, t) {
    var out = ArrayList_init_$Create$();
    // Inline function 'kotlin.collections.plusAssign' call
    var element = Components_getInstance().rect$default_ne0c8u_k$(t, tr('background', []), g, ox, oy, 360.0, 80.0, 0.0, 14);
    out.add_utx5q5_k$(element);
    // Inline function 'kotlin.collections.plusAssign' call
    var element_0 = w(Components_getInstance().rect$default_ne0c8u_k$(t, tr('indicator', []), g, ox + 28.0, oy + 12.0, 64.0, 32.0, 9999.0, 5), 'pick:ind');
    out.add_utx5q5_k$(element_0);
    var names = listOf_0([tr('home', []), tr('search', []), tr('profile', [])]);
    var icons = listOf_0(['home', 'search', 'person']);
    var inductionVariable = 0;
    if (inductionVariable < 3)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var cx = ox + 60.0 + i * 120.0;
        // Inline function 'kotlin.collections.plusAssign' call
        var elements = pick_0(IconNodes_instance.icon$default_pzaq2z_k$(t, icons.get_c1px32_k$(i), g, cx, oy + 28.0, 24.0, i === 0 ? 6 : 18), i, 6, 18);
        addAll(out, elements);
        // Inline function 'kotlin.collections.plusAssign' call
        var element_1 = pick(Components_getInstance().label_uq5396_k$(t, g, names.get_c1px32_k$(i), cx, oy + 58.0, 12.0, i === 0 ? 700 : 500, i === 0 ? 17 : 18), i, 17, 18);
        out.add_utx5q5_k$(element_1);
      }
       while (inductionVariable < 3);
    return out;
  }
  function Components$classic$lambda_7(ox, oy, g, t) {
    return listOf_0([w(Components_getInstance().ring_233v8i_k$(t, tr('ring', []), g, ox + 2.0, oy + 2.0, 20.0, 0, 2.0), 'radio:ring'), w(Components_getInstance().oval_w4fudg_k$(t, tr('dot', []), g, ox + 7.0, oy + 7.0, 10.0, 10.0, 0), 'radio:dot')]);
  }
  function Components$classic$lambda_8(ox, oy, g, t) {
    return listOf_0([w(Components_getInstance().rect$default_ne0c8u_k$(t, tr('box', []), g, ox + 3.0, oy + 3.0, 18.0, 18.0, 2.0, 0), 'check:box'), w(Components_getInstance().rect$default_ne0c8u_k$(t, tr('check_1', []), g, ox + 7.0, oy + 12.0, 6.0, 2.0, 1.0, 1).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, 45.0), 'check:mark'), w(Components_getInstance().rect$default_ne0c8u_k$(t, tr('check_2', []), g, ox + 9.5, oy + 11.0, 9.0, 2.0, 1.0, 1).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, -50.0), 'check:mark')]);
  }
  function Components$classic$lambda_9(ox, oy, g, t) {
    return listOf_0([w(Components_getInstance().rect$default_ne0c8u_k$(t, tr('track', []), g, ox, oy + 8.0, 280.0, 4.0, 9999.0, 5), 'slider:track'), w(Components_getInstance().rect$default_ne0c8u_k$(t, tr('active_part', []), g, ox, oy + 8.0, 150.0, 4.0, 9999.0, 0), 'slider:active'), w(Components_getInstance().oval_w4fudg_k$(t, tr('slider', []), g, ox + 140.0, oy, 20.0, 20.0, 0), 'slider:thumb')]);
  }
  function Components$classic$lambda_10(ox, oy, g, t) {
    return listOf_0([w(Components_getInstance().rect$default_ne0c8u_k$(t, tr('track', []), g, ox, oy, 280.0, 4.0, 9999.0, 5), 'progress:track'), w(Components_getInstance().rect$default_ne0c8u_k$(t, tr('progress', []), g, ox, oy, 168.0, 4.0, 9999.0, 0), 'progress:active')]);
  }
  function Components$classic$lambda_11(ox, oy, g, t) {
    return listOf(Components_getInstance().rect$default_ne0c8u_k$(t, tr('divider', []), g, ox, oy, 328.0, 1.0, 0.0, 20));
  }
  function Components$classic$lambda_12(ox, oy, g, t) {
    return listOf_0([Components_getInstance().oval_w4fudg_k$(t, tr('badge', []), g, ox, oy, 16.0, 16.0, 10), Components_getInstance().label_uq5396_k$(t, g, '3', ox + 8.0, oy + 8.0, 10.0, 500, 1)]);
  }
  function Components$classic$lambda_13(ox, oy, g, t) {
    return listOf_0([Components_getInstance().rect$default_ne0c8u_k$(t, tr('search', []), g, ox, oy, 328.0, 56.0, 9999.0, 15), Components_getInstance().ring_233v8i_k$(t, tr('lens', []), g, ox + 16.0, oy + 17.0, 16.0, 18, 2.0), Components_getInstance().rect$default_ne0c8u_k$(t, tr('lens_handle', []), g, ox + 30.0, oy + 33.0, 8.0, 2.0, 1.0, 18).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, 45.0), Components_getInstance().labelLeft_4kh12r_k$(t, g, tr('search', []), ox + 52.0, oy + 28.0, 16.0, 400, 18)]);
  }
  function Components$classic$lambda_14(ox, oy, g, t) {
    return listOf_0([Components_getInstance().rect$default_ne0c8u_k$(t, tr('background', []), g, ox, oy, 360.0, 72.0, 0.0, 12), Components_getInstance().oval_w4fudg_k$(t, tr('avatar', []), g, ox + 16.0, oy + 16.0, 40.0, 40.0, 2), Components_getInstance().labelLeft_4kh12r_k$(t, g, tr('title', []), ox + 72.0, oy + 28.0, 16.0, 400, 17), Components_getInstance().labelLeft_4kh12r_k$(t, g, tr('supporting_text', []), ox + 72.0, oy + 48.0, 14.0, 400, 18)]);
  }
  function Components$classic$lambda_15(ox, oy, g, t) {
    var out = ArrayList_init_$Create$();
    // Inline function 'kotlin.collections.plusAssign' call
    var element = Components_getInstance().rect$default_ne0c8u_k$(t, tr('background', []), g, ox, oy, 360.0, 48.0, 0.0, 12);
    out.add_utx5q5_k$(element);
    // Inline function 'kotlin.collections.plusAssign' call
    var element_0 = Components_getInstance().rect$default_ne0c8u_k$(t, tr('line', []), g, ox, oy + 47.0, 360.0, 1.0, 0.0, 20);
    out.add_utx5q5_k$(element_0);
    var names = listOf_0([tr('first', []), tr('second', []), tr('third', [])]);
    var inductionVariable = 0;
    if (inductionVariable < 3)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        // Inline function 'kotlin.collections.plusAssign' call
        var element_1 = pick(Components_getInstance().label_uq5396_k$(t, g, names.get_c1px32_k$(i), ox + 60.0 + i * 120.0, oy + 22.0, 14.0, 500, i === 0 ? 0 : 18), i, 0, 18);
        out.add_utx5q5_k$(element_1);
      }
       while (inductionVariable < 3);
    // Inline function 'kotlin.collections.plusAssign' call
    var element_2 = w(Components_getInstance().rect$default_ne0c8u_k$(t, tr('indicator', []), g, ox + 20.0, oy + 45.0, 80.0, 3.0, 1.5, 0), 'pick:ind');
    out.add_utx5q5_k$(element_2);
    return out;
  }
  function Components$classic$lambda_16(ox, oy, g, t) {
    var out = ArrayList_init_$Create$();
    // Inline function 'kotlin.collections.plusAssign' call
    var element = Components_getInstance().rect_l2nxf2_k$(t, tr('outline', []), g, ox, oy, 288.0, 40.0, 9999.0, -1, 19, 1.0);
    out.add_utx5q5_k$(element);
    // Inline function 'kotlin.collections.plusAssign' call
    var element_0 = w(Components_getInstance().rect$default_ne0c8u_k$(t, tr('selected', []), g, ox + 1.0, oy + 1.0, 95.0, 38.0, 9999.0, 5), 'pick:fit');
    out.add_utx5q5_k$(element_0);
    var names = listOf_0([tr('day', []), tr('week', []), tr('month', [])]);
    var inductionVariable = 0;
    if (inductionVariable < 3)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        // Inline function 'kotlin.collections.plusAssign' call
        var element_1 = pick(Components_getInstance().label_uq5396_k$(t, g, names.get_c1px32_k$(i), ox + 48.0 + i * 96.0, oy + 20.0, 14.0, 500, i === 0 ? 6 : 17), i, 6, 17);
        out.add_utx5q5_k$(element_1);
      }
       while (inductionVariable < 3);
    return out;
  }
  function Components$classic$lambda_17(ox, oy, g, t) {
    return listOf_0([Components_getInstance().rect$default_ne0c8u_k$(t, tr('background', []), g, ox, oy, 328.0, 48.0, 4.0, 21), Components_getInstance().labelLeft_4kh12r_k$(t, g, tr('message', []), ox + 16.0, oy + 24.0, 14.0, 400, 12), Components_getInstance().label_uq5396_k$(t, g, tr('cancel', []), ox + 280.0, oy + 24.0, 14.0, 500, 2)]);
  }
  function Components$classic$lambda_18(ox, oy, g, t) {
    return listOf_0([Components_getInstance().rect$default_ne0c8u_k$(t, tr('window', []), g, ox, oy, 312.0, 192.0, 28.0, 15), Components_getInstance().labelLeft_4kh12r_k$(t, g, tr('title', []), ox + 24.0, oy + 40.0, 24.0, 400, 17), Components_getInstance().labelLeft_4kh12r_k$(t, g, tr('dialog_text', []), ox + 24.0, oy + 80.0, 14.0, 400, 18), Components_getInstance().label_uq5396_k$(t, g, tr('cancel', []), ox + 200.0, oy + 156.0, 14.0, 500, 0), Components_getInstance().label_uq5396_k$(t, g, tr('ok', []), ox + 270.0, oy + 156.0, 14.0, 500, 0)]);
  }
  function Components$byId$delegate$lambda() {
    // Inline function 'kotlin.collections.associateBy' call
    var this_0 = Components_getInstance().all_1;
    var capacity = coerceAtLeast_0(mapCapacity(collectionSizeOrDefault(this_0, 10)), 16);
    // Inline function 'kotlin.collections.associateByTo' call
    var destination = LinkedHashMap_init_$Create$_0(capacity);
    var _iterator__ex2g4s = this_0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      var tmp$ret$0 = element.id_1;
      destination.put_4fpzoq_k$(tmp$ret$0, element);
    }
    return destination;
  }
  function Components$groups$delegate$lambda() {
    var placed = HashSet_init_$Create$();
    // Inline function 'kotlin.collections.map' call
    var this_0 = Components_getInstance().groupIds_1;
    // Inline function 'kotlin.collections.mapTo' call
    var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_0, 10));
    var _iterator__ex2g4s = this_0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s.next_20eer_k$();
      var key = item.component1_7eebsc_k$();
      var ids = item.component2_7eebsb_k$();
      // Inline function 'kotlin.collections.mapNotNull' call
      // Inline function 'kotlin.collections.mapNotNullTo' call
      var destination_0 = ArrayList_init_$Create$();
      // Inline function 'kotlin.collections.forEach' call
      var _iterator__ex2g4s_0 = ids.iterator_jk1svi_k$();
      while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s_0.next_20eer_k$();
        var tmp0_safe_receiver = _get_byId__d4l6m1(Components_getInstance()).get_wei43m_k$(element);
        if (tmp0_safe_receiver == null)
          null;
        else {
          // Inline function 'kotlin.let' call
          destination_0.add_utx5q5_k$(tmp0_safe_receiver);
        }
      }
      // Inline function 'kotlin.also' call
      // Inline function 'kotlin.collections.map' call
      // Inline function 'kotlin.collections.mapTo' call
      var destination_1 = ArrayList_init_$Create$_0(collectionSizeOrDefault(destination_0, 10));
      var _iterator__ex2g4s_1 = destination_0.iterator_jk1svi_k$();
      while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
        var item_0 = _iterator__ex2g4s_1.next_20eer_k$();
        var tmp$ret$7 = item_0.id_1;
        destination_1.add_utx5q5_k$(tmp$ret$7);
      }
      // Inline function 'kotlin.collections.plusAssign' call
      addAll(placed, destination_1);
      var tmp$ret$13 = to(key, destination_0);
      destination.add_utx5q5_k$(tmp$ret$13);
    }
    var out = destination;
    // Inline function 'kotlin.collections.filter' call
    var tmp0 = Components_getInstance().all_1;
    // Inline function 'kotlin.collections.filterTo' call
    var destination_2 = ArrayList_init_$Create$();
    var _iterator__ex2g4s_2 = tmp0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_2.hasNext_bitz1p_k$()) {
      var element_0 = _iterator__ex2g4s_2.next_20eer_k$();
      if (!placed.contains_aljjnj_k$(element_0.id_1)) {
        destination_2.add_utx5q5_k$(element_0);
      }
    }
    var rest = destination_2;
    return rest.isEmpty_y1axqb_k$() ? out : plus_0(out, to('actions', rest));
  }
  function Components() {
    Components_instance = this;
    var tmp = this;
    var tmp_0 = button$default(this, 'btn-filled', 'Filled button', 0, 1);
    var tmp_1 = button$default(this, 'btn-tonal', 'Tonal button', 5, 6);
    var tmp_2 = button(this, 'btn-outlined', 'Outlined button', -1, 0, 19);
    var tmp_3 = new ComponentDef('fab', 'FAB', 56.0, 56.0, Components$classic$lambda);
    var tmp_4 = new ComponentDef('ext-fab', 'Extended FAB', 140.0, 56.0, Components$classic$lambda_0);
    var tmp_5 = new ComponentDef('card', 'Card (filled)', 328.0, 120.0, Components$classic$lambda_1);
    var tmp_6 = new ComponentDef('chip', 'Chip', 96.0, 32.0, Components$classic$lambda_2);
    var tmp_7 = new ComponentDef('switch', 'Switch', 52.0, 32.0, Components$classic$lambda_3);
    var tmp_8 = new ComponentDef('textfield', 'Outlined text field', 280.0, 56.0, Components$classic$lambda_4);
    var tmp_9 = new ComponentDef('top-bar', 'Top app bar', 360.0, 64.0, Components$classic$lambda_5);
    var tmp_10 = new ComponentDef('nav-bar', 'Navigation bar', 360.0, 80.0, Components$classic$lambda_6);
    var tmp_11 = new ComponentDef('radio', 'Radio button', 24.0, 24.0, Components$classic$lambda_7);
    var tmp_12 = new ComponentDef('checkbox', 'Checkbox', 24.0, 24.0, Components$classic$lambda_8);
    var tmp_13 = new ComponentDef('slider', 'Slider', 280.0, 20.0, Components$classic$lambda_9);
    var tmp_14 = new ComponentDef('progress', 'Linear progress', 280.0, 4.0, Components$classic$lambda_10);
    var tmp_15 = new ComponentDef('divider', 'Divider', 328.0, 1.0, Components$classic$lambda_11);
    var tmp_16 = new ComponentDef('badge', 'Badge', 16.0, 16.0, Components$classic$lambda_12);
    var tmp_17 = new ComponentDef('search', 'Search bar', 328.0, 56.0, Components$classic$lambda_13);
    var tmp_18 = new ComponentDef('list-item', 'List item', 360.0, 72.0, Components$classic$lambda_14);
    var tmp_19 = new ComponentDef('tabs', 'Tabs', 360.0, 48.0, Components$classic$lambda_15);
    var tmp_20 = new ComponentDef('segmented', 'Segmented button', 288.0, 40.0, Components$classic$lambda_16);
    var tmp_21 = new ComponentDef('snackbar', 'Snackbar', 328.0, 48.0, Components$classic$lambda_17);
    tmp.classic_1 = listOf_0([tmp_0, tmp_1, tmp_2, tmp_3, tmp_4, tmp_5, tmp_6, tmp_7, tmp_8, tmp_9, tmp_10, tmp_11, tmp_12, tmp_13, tmp_14, tmp_15, tmp_16, tmp_17, tmp_18, tmp_19, tmp_20, tmp_21, new ComponentDef('dialog', 'Dialog', 312.0, 192.0, Components$classic$lambda_18)]);
    this.all_1 = plus(this.classic_1, ExpressiveComponents_getInstance().list_1);
    var tmp_22 = this;
    tmp_22.byId$delegate_1 = lazy(Components$byId$delegate$lambda);
    this.groupIds_1 = listOf_0([to('actions', listOf_0(['btn-filled', 'btn-tonal', 'btn-outlined', 'btn-elevated', 'btn-text', 'btn-m', 'btn-l', 'btn-xl', 'btn-square', 'btn-morph', 'btn-morph-square', 'btn-morph-tonal', 'icon-btn', 'icon-btn-tonal', 'icon-btn-outlined', 'icon-btn-square', 'fab', 'ext-fab', 'fab-small', 'fab-large', 'fab-menu', 'split-button', 'button-group', 'toolbar-floating'])), to('navigation', listOf_0(['top-bar', 'top-bar-center', 'top-bar-medium', 'top-bar-large', 'nav-bar', 'nav-bar-flex', 'bottom-bar', 'nav-rail', 'nav-drawer', 'tabs', 'search', 'menu'])), to('containment', listOf_0(['card', 'card-elevated', 'card-outlined', 'card-media', 'card-expressive', 'bottom-sheet', 'carousel', 'list-item', 'list-3line', 'list-segmented', 'list-switch', 'list-checkbox', 'dialog', 'divider', 'avatar-stack', 'stat-card'])), to('communication', listOf_0(['snackbar', 'tooltip', 'badge', 'badge-large', 'loading', 'progress', 'progress-circular', 'progress-wavy', 'banner'])), to('selection', listOf_0(['chip', 'chip-filter', 'chip-assist', 'chip-input', 'segmented', 'switch', 'switch-off', 'switch-icon', 'checkbox', 'checkbox-off', 'radio', 'radio-off', 'slider', 'slider-expressive', 'slider-wavy', 'date-picker'])), to('inputs', listOf_0(['textfield', 'textfield-filled', 'textfield-error', 'quantity']))]);
    var tmp_23 = this;
    tmp_23.groups$delegate_1 = lazy(Components$groups$delegate$lambda);
  }
  protoOf(Components).rect_l2nxf2_k$ = function (t, name, g, x, y, w, h, corner, fillTok, strokeTok, sw) {
    return new Node(newId(), NodeKind_RECT_getInstance(), name, x, y, w, h, VOID, fillTok >= 0 ? t.color$default_xk5c97_k$(fillTok) : 0, strokeTok >= 0 ? t.color$default_xk5c97_k$(strokeTok) : 0, sw, VOID, corner, VOID, VOID, VOID, VOID, g, VOID, VOID, VOID, VOID, VOID, VOID, VOID, fillTok, strokeTok);
  };
  protoOf(Components).rect$default_ne0c8u_k$ = function (t, name, g, x, y, w, h, corner, fillTok, strokeTok, sw, $super) {
    strokeTok = strokeTok === VOID ? -1 : strokeTok;
    sw = sw === VOID ? 0.0 : sw;
    return $super === VOID ? this.rect_l2nxf2_k$(t, name, g, x, y, w, h, corner, fillTok, strokeTok, sw) : $super.rect_l2nxf2_k$.call(this, t, name, g, x, y, w, h, corner, fillTok, strokeTok, sw);
  };
  protoOf(Components).oval_w4fudg_k$ = function (t, name, g, x, y, w, h, fillTok) {
    return new Node(newId(), NodeKind_ELLIPSE_getInstance(), name, x, y, w, h, VOID, t.color$default_xk5c97_k$(fillTok), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, g, VOID, VOID, VOID, VOID, VOID, VOID, VOID, fillTok);
  };
  protoOf(Components).label_uq5396_k$ = function (t, g, text, cx, cy, size, weight, tok) {
    // Inline function 'kotlin.let' call
    var it = withTextSize(new Node(newId(), NodeKind_TEXT_getInstance(), text, 0.0, 0.0, 1.0, 1.0, VOID, t.color$default_xk5c97_k$(tok), VOID, VOID, VOID, VOID, VOID, text, size, weight, g, VOID, VOID, true, VOID, VOID, VOID, VOID, tok));
    return it.copy$default_q375vp_k$(VOID, VOID, VOID, cx - it.w_1 / 2.0, cy - it.h_1 / 2.0);
  };
  protoOf(Components).labelLeft_4kh12r_k$ = function (t, g, text, x, cy, size, weight, tok) {
    // Inline function 'kotlin.let' call
    return this.label_uq5396_k$(t, g, text, 0.0, cy, size, weight, tok).copy$default_q375vp_k$(VOID, VOID, VOID, x);
  };
  protoOf(Components).ring_233v8i_k$ = function (t, name, g, x, y, d, strokeTok, sw) {
    return new Node(newId(), NodeKind_ELLIPSE_getInstance(), name, x, y, d, d, VOID, 0, t.color$default_xk5c97_k$(strokeTok), sw, VOID, VOID, VOID, VOID, VOID, VOID, g, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, strokeTok);
  };
  var Components_instance;
  function Components_getInstance() {
    if (Components_instance == null)
      new Components();
    return Components_instance;
  }
  function byId$factory() {
    return getPropertyCallableRef('byId', 1, KProperty1, function (receiver) {
      return _get_byId__d4l6m1(receiver);
    }, null);
  }
  function num($this, v) {
    // Inline function 'kotlin.math.roundToInt' call
    var this_0 = v * 100.0;
    var r = roundToInt(this_0) / 100.0;
    return r === numberToInt(r) ? numberToInt(r).toString() : trimEnd(trimEnd(formatNumber('%.2f', [r]), charArrayOf([_Char___init__impl__6a9atx(48)])), charArrayOf([_Char___init__impl__6a9atx(46)]));
  }
  function dp($this, v) {
    return num($this, v) + '.dp';
  }
  function hex($this, argb) {
    return 'Color(0x' + formatNumber('%08X', [argb]) + ')';
  }
  function colorExpr($this, argb, token) {
    if (0 <= token ? token <= ($this.tokenNames_1.get_size_woubt6_k$() - 1 | 0) : false)
      return 'MaterialTheme.colorScheme.' + $this.tokenNames_1.get_c1px32_k$(token);
    switch (argb) {
      case -16777216:
        return 'Color.Black';
      case -1:
        return 'Color.White';
      case 0:
        return 'Color.Transparent';
      default:
        return hex($this, argb);
    }
  }
  function esc($this, s) {
    return replace(replace(replace(replace(s, '\\', '\\\\'), '"', '\\"'), '$', '\\$'), '\n', '\\n');
  }
  function pascal($this, s) {
    // Inline function 'kotlin.text.split' call
    // Inline function 'kotlin.collections.filter' call
    var tmp0 = Regex_init_$Create$('[^A-Za-z0-9]+').split_p7ck23_k$(s, 0);
    // Inline function 'kotlin.collections.filterTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      // Inline function 'kotlin.text.isNotEmpty' call
      if (charSequenceLength(element) > 0) {
        destination.add_utx5q5_k$(element);
      }
    }
    var tmp = destination;
    var name = joinToString_0(tmp, '', VOID, VOID, VOID, VOID, ComposeCode$pascal$lambda);
    var tmp_0;
    var tmp_1;
    // Inline function 'kotlin.text.isEmpty' call
    if (charSequenceLength(name) === 0) {
      tmp_1 = true;
    } else {
      tmp_1 = isDigit(charSequenceGet(name, 0));
    }
    if (tmp_1) {
      tmp_0 = 'X' + name;
    } else {
      tmp_0 = name;
    }
    return tmp_0;
  }
  function Src(depth) {
    this.depth_1 = depth;
    this.sb_1 = StringBuilder_init_$Create$_0();
  }
  protoOf(Src).a_p9d5m1_k$ = function (s) {
    this.sb_1.append_22ad7x_k$(repeat('    ', this.depth_1)).append_22ad7x_k$(s).append_58al37_k$(_Char___init__impl__6a9atx(10));
  };
  protoOf(Src).raw_h13x4y_k$ = function (s) {
    this.sb_1.append_22ad7x_k$(s);
  };
  protoOf(Src).inc_ry5d6a_k$ = function () {
    this.depth_1 = this.depth_1 + 1 | 0;
  };
  protoOf(Src).dec_msx87i_k$ = function () {
    this.depth_1 = this.depth_1 - 1 | 0;
  };
  protoOf(Src).call_xunhn6_k$ = function (head, args, body) {
    this.a_p9d5m1_k$(head + '(');
    this.inc_ry5d6a_k$();
    var _iterator__ex2g4s = args.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var x = _iterator__ex2g4s.next_20eer_k$();
      this.a_p9d5m1_k$(x + ',');
    }
    this.dec_msx87i_k$();
    if (body == null) {
      this.a_p9d5m1_k$(')');
    } else {
      this.a_p9d5m1_k$(') {');
      this.inc_ry5d6a_k$();
      body(this);
      this.dec_msx87i_k$();
      this.a_p9d5m1_k$('}');
    }
  };
  protoOf(Src).call$default_6xmtdb_k$ = function (head, args, body, $super) {
    body = body === VOID ? null : body;
    var tmp;
    if ($super === VOID) {
      this.call_xunhn6_k$(head, args, body);
      tmp = Unit_instance;
    } else {
      tmp = $super.call_xunhn6_k$.call(this, head, args, body);
    }
    return tmp;
  };
  protoOf(Src).slot_1821w1_k$ = function (name, body) {
    this.a_p9d5m1_k$(name + ' = {');
    this.inc_ry5d6a_k$();
    body(this);
    this.dec_msx87i_k$();
    this.a_p9d5m1_k$('},');
  };
  function Ctx() {
    this.states_1 = ArrayList_init_$Create$();
    this.vectors_1 = LinkedHashMap_init_$Create$();
    this.vectorSrc_1 = ArrayList_init_$Create$();
    this.pathShapes_1 = LinkedHashMap_init_$Create$();
    this.pathSrc_1 = ArrayList_init_$Create$();
    this.fallbacks_1 = ArrayList_init_$Create$();
    this.needPathHelper_1 = false;
    this.needAngle_1 = false;
    this.usesImage_1 = false;
    this.opts_1 = null;
    this.uriDeclared_1 = false;
    this.toggles_1 = HashMap_init_$Create$();
    this.counters_1 = HashMap_init_$Create$();
  }
  protoOf(Ctx).uri_2hkc_k$ = function () {
    if (!this.uriDeclared_1) {
      this.uriDeclared_1 = true;
      var tmp0 = this.states_1;
      // Inline function 'kotlin.collections.plusAssign' call
      var element = 'val uriHandler = LocalUriHandler.current';
      tmp0.add_utx5q5_k$(element);
    }
    return 'uriHandler';
  };
  protoOf(Ctx).next_bw7zqf_k$ = function (prefix) {
    var tmp0_elvis_lhs = this.counters_1.get_wei43m_k$(prefix);
    var n = (tmp0_elvis_lhs == null ? 0 : tmp0_elvis_lhs) + 1 | 0;
    // Inline function 'kotlin.collections.set' call
    this.counters_1.put_4fpzoq_k$(prefix, n);
    return prefix + n;
  };
  protoOf(Ctx).state_xyteun_k$ = function (prefix, init) {
    var n = this.next_bw7zqf_k$(prefix);
    var tmp0 = this.states_1;
    // Inline function 'kotlin.collections.plusAssign' call
    var element = 'var ' + n + ' by remember { mutableStateOf(' + init + ') }';
    tmp0.add_utx5q5_k$(element);
    return n;
  };
  protoOf(Ctx).pathShape_69hh0p_k$ = function (n) {
    // Inline function 'kotlin.text.trim' call
    var this_0 = n.path_1;
    var d = toString_1(trim(isCharSequence(this_0) ? this_0 : THROW_CCE()));
    var tmp;
    // Inline function 'kotlin.text.isEmpty' call
    if (charSequenceLength(d) === 0) {
      tmp = true;
    } else {
      tmp = d.length > 60000;
    }
    if (tmp)
      return null;
    var key = d + '|' + n.evenOdd_1;
    // Inline function 'kotlin.collections.getOrPut' call
    var this_1 = this.pathShapes_1;
    var value = this_1.get_wei43m_k$(key);
    var tmp_0;
    if (value == null) {
      this.needPathHelper_1 = true;
      var name = 'VexelPath' + (this.pathShapes_1.get_size_woubt6_k$() + 1 | 0);
      var sb = new StringBuilder('private val ' + name + ' = GenericShape { s, _ ->\n');
      if (n.evenOdd_1) {
        sb.append_22ad7x_k$('    fillType = PathFillType.EvenOdd\n');
      }
      sb.append_22ad7x_k$('    addPath(vexelPath("').append_22ad7x_k$(d).append_22ad7x_k$('", s.width, s.height))\n}\n');
      var tmp0 = this.pathSrc_1;
      // Inline function 'kotlin.collections.plusAssign' call
      var element = sb.toString();
      tmp0.add_utx5q5_k$(element);
      var answer = name;
      this_1.put_4fpzoq_k$(key, answer);
      tmp_0 = answer;
    } else {
      tmp_0 = value;
    }
    return tmp_0;
  };
  protoOf(Ctx).vector_ccipu8_k$ = function (n) {
    // Inline function 'kotlin.text.trim' call
    var this_0 = n.path_1;
    var d = toString_1(trim(isCharSequence(this_0) ? this_0 : THROW_CCE()));
    var tmp;
    // Inline function 'kotlin.text.isEmpty' call
    if (charSequenceLength(d) === 0) {
      tmp = true;
    } else {
      tmp = d.length > 60000;
    }
    if (tmp)
      return null;
    var key = d + '|' + n.evenOdd_1;
    // Inline function 'kotlin.collections.getOrPut' call
    var this_1 = this.vectors_1;
    var value = this_1.get_wei43m_k$(key);
    var tmp_0;
    if (value == null) {
      var tmp_1 = ComposeCode_getInstance();
      // Inline function 'kotlin.text.ifBlank' call
      var this_2 = n.name_1;
      var tmp_2;
      if (isBlank(this_2)) {
        tmp_2 = 'Icon';
      } else {
        tmp_2 = this_2;
      }
      var tmp$ret$3 = tmp_2;
      var name = 'Vexel' + pascal(tmp_1, tmp$ret$3) + (this.vectors_1.get_size_woubt6_k$() + 1 | 0);
      var sb = new StringBuilder('private val ' + name + ': ImageVector = ImageVector.Builder(\n');
      sb.append_22ad7x_k$('    name = "').append_22ad7x_k$(esc(ComposeCode_getInstance(), n.name_1)).append_22ad7x_k$('",\n');
      sb.append_22ad7x_k$('    defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = 1f, viewportHeight = 1f,\n');
      sb.append_22ad7x_k$(').addPath(\n');
      sb.append_22ad7x_k$('    pathData = PathParser().parsePathString("').append_22ad7x_k$(d).append_22ad7x_k$('").toNodes(),\n');
      if (n.evenOdd_1) {
        sb.append_22ad7x_k$('    pathFillType = PathFillType.EvenOdd,\n');
      }
      sb.append_22ad7x_k$('    fill = SolidColor(Color.Black),\n');
      sb.append_22ad7x_k$(').build()\n');
      var tmp1 = this.vectorSrc_1;
      // Inline function 'kotlin.collections.plusAssign' call
      var element = sb.toString();
      tmp1.add_utx5q5_k$(element);
      var answer = name;
      this_1.put_4fpzoq_k$(key, answer);
      tmp_0 = answer;
    } else {
      tmp_0 = value;
    }
    return tmp_0;
  };
  function shapeOf($this, n, c) {
    var comment = null;
    var tmp;
    switch (n.kind_1.ordinal_1) {
      case 0:
        var tmp_0;
        if (n.corner_1 > 0.5) {
          var tmp2 = n.corner_1;
          var tmp0 = n.w_1;
          // Inline function 'kotlin.math.min' call
          var b = n.h_1;
          // Inline function 'kotlin.math.min' call
          var b_0 = Math.min(tmp0, b) / 2.0;
          var tmp$ret$1 = Math.min(tmp2, b_0);
          tmp_0 = 'RoundedCornerShape(' + dp($this, tmp$ret$1) + ')';
        } else {
          tmp_0 = null;
        }

        tmp = tmp_0;
        break;
      case 1:
        var tmp_1;
        // Inline function 'kotlin.math.abs' call

        var x = n.w_1 - n.h_1;
        if (Math.abs(x) < 0.5) {
          tmp_1 = 'CircleShape';
        } else {
          tmp_1 = 'GenericShape { s, _ -> addOval(Rect(Offset.Zero, s)) }';
        }

        tmp = tmp_1;
        break;
      case 2:
        var ms = $this.materialShapes_1.get_wei43m_k$(n.shapeId_1);
        var tmp_2;
        if (!(ms == null)) {
          tmp_2 = 'MaterialShapes.' + ms + '.toShape()';
        } else {
          var sides = toIntOrNull(substringAfterLast(n.shapeId_1, _Char___init__impl__6a9atx(45)));
          var tmp_3;
          if (startsWith(n.shapeId_1, 'star-') && !(sides == null)) {
            tmp_3 = 'RoundedPolygon.star(' + sides + ').toShape()';
          } else if (n.shapeId_1 === 'hexagon') {
            tmp_3 = 'RoundedPolygon(6).toShape()';
          } else if (n.shapeId_1 === 'octagon') {
            tmp_3 = 'RoundedPolygon(8).toShape()';
          } else {
            comment = 'shape "' + n.shapeId_1 + '" is not in MaterialShapes, replace it with your own RoundedPolygon';
            tmp_3 = 'RoundedPolygon(6).toShape()';
          }
          tmp_2 = tmp_3;
        }

        tmp = tmp_2;
        break;
      case 4:
        var tmp1_elvis_lhs = c.pathShape_69hh0p_k$(n);
        var tmp_4;
        if (tmp1_elvis_lhs == null) {
          // Inline function 'kotlin.run' call
          comment = 'path is too large to inline, a rectangle is used instead';
          tmp_4 = null;
        } else {
          tmp_4 = tmp1_elvis_lhs;
        }

        tmp = tmp_4;
        break;
      default:
        tmp = null;
        break;
    }
    var expr = tmp;
    return to(expr, comment);
  }
  function gradientBrush($this, n, c, comment) {
    var cols = colorExpr($this, n.fill_1, n.fillToken_1) + ', ' + colorExpr($this, n.fill2__1, -1);
    var tmp;
    if (n.gradKind_1 === 2) {
      tmp = 'Brush.radialGradient(listOf(' + cols + '))';
    } else {
      // Inline function 'kotlin.math.abs' call
      var x = n.gradAngle_1 - 90.0;
      if (Math.abs(x) < 1.0) {
        tmp = 'Brush.verticalGradient(listOf(' + cols + '))';
      } else {
        // Inline function 'kotlin.math.abs' call
        var x_0 = n.gradAngle_1;
        if (Math.abs(x_0) < 1.0) {
          tmp = 'Brush.horizontalGradient(listOf(' + cols + '))';
        } else {
          c.needAngle_1 = true;
          tmp = 'angledGradient(' + num($this, n.gradAngle_1) + 'f, ' + cols + ')';
        }
      }
    }
    return tmp;
  }
  function actionExpr($this, n, c) {
    var a = n.action_1;
    var tmp;
    if (startsWith(a, 'goto:')) {
      var tmp0_safe_receiver = c.opts_1;
      var tmp1_safe_receiver = tmp0_safe_receiver == null ? null : tmp0_safe_receiver.pageIds_1;
      var tmp2_safe_receiver = tmp1_safe_receiver == null ? null : tmp1_safe_receiver.indexOf_si1fv9_k$(substringAfter(a, _Char___init__impl__6a9atx(58)));
      var tmp_0;
      if (tmp2_safe_receiver == null) {
        tmp_0 = null;
      } else {
        // Inline function 'kotlin.takeIf' call
        var tmp_1;
        if (tmp2_safe_receiver >= 0) {
          tmp_1 = tmp2_safe_receiver;
        } else {
          tmp_1 = null;
        }
        tmp_0 = tmp_1;
      }
      var tmp3_safe_receiver = tmp_0;
      var tmp_2;
      if (tmp3_safe_receiver == null) {
        tmp_2 = null;
      } else {
        // Inline function 'kotlin.let' call
        tmp_2 = 'onGoTo(' + tmp3_safe_receiver + ')';
      }
      tmp = tmp_2;
    } else if (a === 'back') {
      tmp = !(c.opts_1 == null) ? 'onBack()' : null;
    } else if (startsWith(a, 'url:')) {
      // Inline function 'kotlin.text.trim' call
      var this_0 = substringAfter(a, _Char___init__impl__6a9atx(58));
      // Inline function 'kotlin.takeIf' call
      var this_1 = toString_1(trim(isCharSequence(this_0) ? this_0 : THROW_CCE()));
      var tmp_3;
      // Inline function 'kotlin.text.isNotEmpty' call
      if (charSequenceLength(this_1) > 0) {
        tmp_3 = this_1;
      } else {
        tmp_3 = null;
      }
      var tmp4_safe_receiver = tmp_3;
      var tmp_4;
      if (tmp4_safe_receiver == null) {
        tmp_4 = null;
      } else {
        // Inline function 'kotlin.let' call
        var full = startsWith(tmp4_safe_receiver, 'http://') || startsWith(tmp4_safe_receiver, 'https://') ? tmp4_safe_receiver : 'https://' + tmp4_safe_receiver;
        tmp_4 = c.uri_2hkc_k$() + '.openUri("' + esc(ComposeCode_getInstance(), full) + '")';
      }
      tmp = tmp_4;
    } else if (startsWith(a, 'toggle:')) {
      var tmp5_safe_receiver = c.toggles_1.get_wei43m_k$(substringAfter(a, _Char___init__impl__6a9atx(58)));
      var tmp_5;
      if (tmp5_safe_receiver == null) {
        tmp_5 = null;
      } else {
        // Inline function 'kotlin.let' call
        tmp_5 = tmp5_safe_receiver + ' = !' + tmp5_safe_receiver;
      }
      tmp = tmp_5;
    } else {
      tmp = null;
    }
    return tmp;
  }
  function layer($this, n, c, ind, ox, oy, mask) {
    var mods = ArrayList_init_$Create$();
    // Inline function 'kotlin.collections.plusAssign' call
    var element = 'offset(' + dp($this, n.x_1 - ox) + ', ' + dp($this, n.y_1 - oy) + ')';
    mods.add_utx5q5_k$(element);
    if (!n.kind_1.equals(NodeKind_TEXT_getInstance())) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_0 = 'size(' + dp($this, n.w_1) + ', ' + dp($this, n.h_1) + ')';
      mods.add_utx5q5_k$(element_0);
    }
    // Inline function 'kotlin.math.abs' call
    var x = n.rotation_1;
    if (Math.abs(x) > 0.01) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_1 = 'rotate(' + num($this, n.rotation_1) + 'f)';
      mods.add_utx5q5_k$(element_1);
    }
    if (n.opacity_1 < 0.999) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_2 = 'alpha(' + num($this, n.opacity_1) + 'f)';
      mods.add_utx5q5_k$(element_2);
    }
    var _destruct__k2r9zo = shapeOf($this, n, c);
    var shapeExpr = _destruct__k2r9zo.component1_7eebsc_k$();
    var shapeComment = _destruct__k2r9zo.component2_7eebsb_k$();
    var notes = ArrayList_init_$Create$();
    if (shapeComment == null)
      null;
    else {
      // Inline function 'kotlin.let' call
      // Inline function 'kotlin.collections.plusAssign' call
      notes.add_utx5q5_k$(shapeComment);
    }
    var shapeArg = shapeExpr == null ? 'RectangleShape' : shapeExpr;
    var act = actionExpr($this, n, c);
    var pre = {_v: ''};
    if (n.kind_1.equals(NodeKind_RECT_getInstance()) && n.pressCorner_1 >= 0.0) {
      var id = c.next_bw7zqf_k$('press');
      var tmp11 = n.w_1;
      // Inline function 'kotlin.math.min' call
      var b = n.h_1;
      var half = Math.min(tmp11, b) / 2.0;
      // Inline function 'kotlin.math.min' call
      var a = n.corner_1;
      var rest = Math.min(a, half);
      // Inline function 'kotlin.math.min' call
      var a_0 = n.pressCorner_1;
      var down = Math.min(a_0, half);
      pre._v = ind + '// pressed: the corner goes ' + num($this, rest) + ' -> ' + num($this, down) + ' while held\n' + (ind + 'val ' + id + 'Source = remember { MutableInteractionSource() }\n') + (ind + 'val ' + id + 'Down by ' + id + 'Source.collectIsPressedAsState()\n') + (ind + 'val ' + id + 'Corner by animateDpAsState(\n') + (ind + '    targetValue = if (' + id + 'Down) ' + dp($this, down) + ' else ' + dp($this, rest) + ',\n') + (ind + '    animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessMedium),\n') + (ind + '    label = "' + id + '",\n' + ind + ')\n');
      shapeArg = 'RoundedCornerShape(' + id + 'Corner)';
      // Inline function 'kotlin.collections.plusAssign' call
      var element_3 = 'clickable(interactionSource = ' + id + 'Source, indication = null, onClick = { ' + (act == null ? '' : act) + ' })';
      mods.add_utx5q5_k$(element_3);
    } else if (!(act == null)) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_4 = 'clickable(onClick = { ' + act + ' })';
      mods.add_utx5q5_k$(element_4);
    }
    if (n.get_hasShadow_3tjd81_k$()) {
      var col = colorExpr($this, n.shadowColor_1, -1);
      // Inline function 'kotlin.collections.plusAssign' call
      var element_5 = 'shadow(' + dp($this, n.shadowBlur_1 / 2.0) + ', ' + shapeArg + ', ambientColor = ' + col + ', spotColor = ' + col + ')';
      mods.add_utx5q5_k$(element_5);
      var tmp;
      // Inline function 'kotlin.math.abs' call
      var x_0 = n.shadowDx_1;
      if (Math.abs(x_0) > 0.5) {
        tmp = true;
      } else {
        // Inline function 'kotlin.math.abs' call
        var x_1 = n.shadowDy_1 - 4.0;
        tmp = Math.abs(x_1) > 0.5;
      }
      if (tmp) {
        // Inline function 'kotlin.collections.plusAssign' call
        var element_6 = 'shadow offset (' + num($this, n.shadowDx_1) + ', ' + num($this, n.shadowDy_1) + '): Modifier.shadow has no offset, wrap the layer in a Box with that offset if it matters';
        notes.add_utx5q5_k$(element_6);
      }
    }
    if (n.softBlur_1 > 0.5) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_7 = 'blur(' + dp($this, n.softBlur_1 * 0.58) + ', BlurredEdgeTreatment.Unbounded)';
      mods.add_utx5q5_k$(element_7);
      // Inline function 'kotlin.collections.plusAssign' call
      var element_8 = 'layer blur: Modifier.blur works on Android 12 and newer, older versions draw it sharp';
      notes.add_utx5q5_k$(element_8);
    }
    if (n.blur_1 > 0.5) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_9 = 'backdrop blur ' + num($this, n.blur_1) + ': not built into Compose, use the Haze library (Modifier.hazeEffect)';
      notes.add_utx5q5_k$(element_9);
    }
    if (!n.kind_1.equals(NodeKind_TEXT_getInstance()) && !n.kind_1.equals(NodeKind_IMAGE_getInstance())) {
      if (n.get_hasGradient_845ojj_k$()) {
        // Inline function 'kotlin.collections.plusAssign' call
        var element_10 = 'background(' + gradientBrush($this, n, c, StringBuilder_init_$Create$_0()) + ', ' + shapeArg + ')';
        mods.add_utx5q5_k$(element_10);
      } else if (!((n.fill_1 >>> 24 | 0) === 0)) {
        // Inline function 'kotlin.collections.plusAssign' call
        var element_11 = 'background(' + colorExpr($this, n.fill_1, n.fillToken_1) + ', ' + shapeArg + ')';
        mods.add_utx5q5_k$(element_11);
      }
      if (!((n.stroke_1 >>> 24 | 0) === 0) && n.strokeWidth_1 > 0.0) {
        // Inline function 'kotlin.collections.plusAssign' call
        var element_12 = 'border(' + dp($this, n.strokeWidth_1) + ', ' + colorExpr($this, n.stroke_1, n.strokeToken_1) + ', ' + shapeArg + ')';
        mods.add_utx5q5_k$(element_12);
      }
    }
    var sb = StringBuilder_init_$Create$_0();
    var tmp_0 = sb.append_22ad7x_k$(ind).append_22ad7x_k$('// ');
    // Inline function 'kotlin.text.ifBlank' call
    var this_0 = n.name_1;
    var tmp_1;
    if (isBlank(this_0)) {
      // Inline function 'kotlin.text.lowercase' call
      // Inline function 'kotlin.js.asDynamic' call
      tmp_1 = n.kind_1.name_1.toLowerCase();
    } else {
      tmp_1 = this_0;
    }
    var tmp$ret$26 = tmp_1;
    tmp_0.append_22ad7x_k$(tmp$ret$26).append_58al37_k$(_Char___init__impl__6a9atx(10));
    var _iterator__ex2g4s = notes.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var x_2 = _iterator__ex2g4s.next_20eer_k$();
      sb.append_22ad7x_k$(ind).append_22ad7x_k$('// ').append_22ad7x_k$(x_2).append_58al37_k$(_Char___init__impl__6a9atx(10));
    }
    var modifier = joinToString_0(mods, '\n' + ind + '        .', 'Modifier\n' + ind + '        .');
    if (mask == null)
      return sb.append_22ad7x_k$(layer$body(pre, n, ind, modifier, c)).toString();
    var _destruct__k2r9zo_0 = shapeOf($this, mask, c);
    var mShape = _destruct__k2r9zo_0.component1_7eebsc_k$();
    var mComment = _destruct__k2r9zo_0.component2_7eebsb_k$();
    var tmp_2 = sb.append_22ad7x_k$(ind).append_22ad7x_k$('// clipped by the mask "');
    // Inline function 'kotlin.text.ifBlank' call
    var this_1 = mask.name_1;
    var tmp_3;
    if (isBlank(this_1)) {
      // Inline function 'kotlin.text.lowercase' call
      // Inline function 'kotlin.js.asDynamic' call
      tmp_3 = mask.kind_1.name_1.toLowerCase();
    } else {
      tmp_3 = this_1;
    }
    var tmp$ret$30 = tmp_3;
    tmp_2.append_22ad7x_k$(tmp$ret$30).append_22ad7x_k$('"');
    // Inline function 'kotlin.math.abs' call
    var x_3 = mask.rotation_1;
    if (Math.abs(x_3) > 0.01) {
      sb.append_22ad7x_k$(' (mask rotation ').append_22ad7x_k$(num($this, mask.rotation_1)).append_22ad7x_k$(' is not applied)');
    }
    if (mComment == null)
      null;
    else {
      // Inline function 'kotlin.let' call
      sb.append_22ad7x_k$('; ').append_22ad7x_k$(mComment);
    }
    sb.append_58al37_k$(_Char___init__impl__6a9atx(10));
    var inner = layer($this, n, c, ind + '    ', mask.x_1, mask.y_1, null);
    var tmp_4 = sb.append_22ad7x_k$(ind).append_22ad7x_k$('Box(\n').append_22ad7x_k$(ind).append_22ad7x_k$('    Modifier\n').append_22ad7x_k$(ind).append_22ad7x_k$('        .offset(' + dp($this, mask.x_1 - ox) + ', ' + dp($this, mask.y_1 - oy) + ')\n').append_22ad7x_k$(ind).append_22ad7x_k$('        .size(' + dp($this, mask.w_1) + ', ' + dp($this, mask.h_1) + ')\n').append_22ad7x_k$(ind);
    tmp_4.append_22ad7x_k$('        .clip(' + (mShape == null ? 'RectangleShape' : mShape) + '),\n').append_22ad7x_k$(ind).append_22ad7x_k$(') {\n').append_22ad7x_k$(inner).append_22ad7x_k$(ind).append_22ad7x_k$('}\n');
    return sb.toString();
  }
  function layer$default($this, n, c, ind, ox, oy, mask, $super) {
    mask = mask === VOID ? null : mask;
    return layer($this, n, c, ind, ox, oy, mask);
  }
  function Comp(id, nodes, tpl, ox, oy) {
    this.id_1 = id;
    this.nodes_1 = nodes;
    this.tpl_1 = tpl;
    this.ox_1 = ox;
    this.oy_1 = oy;
    var tmp = this;
    var tmp0_elvis_lhs = boundsOf(this.nodes_1);
    tmp.box_1 = tmp0_elvis_lhs == null ? new Box(0.0, 0.0, 0.0, 0.0) : tmp0_elvis_lhs;
    var tmp_0 = this;
    // Inline function 'kotlin.collections.filter' call
    var tmp0 = this.nodes_1;
    // Inline function 'kotlin.collections.filterTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      if (element.kind_1.equals(NodeKind_TEXT_getInstance())) {
        destination.add_utx5q5_k$(element);
      }
    }
    tmp_0.texts_1 = destination;
    var tmp_1 = this;
    // Inline function 'kotlin.collections.filter' call
    var tmp0_0 = this.tpl_1;
    // Inline function 'kotlin.collections.filterTo' call
    var destination_0 = ArrayList_init_$Create$();
    var _iterator__ex2g4s_0 = tmp0_0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
      var element_0 = _iterator__ex2g4s_0.next_20eer_k$();
      if (element_0.kind_1.equals(NodeKind_TEXT_getInstance())) {
        destination_0.add_utx5q5_k$(element_0);
      }
    }
    tmp_1.tplTexts_1 = destination_0;
    var tmp_2 = this;
    // Inline function 'kotlin.collections.filter' call
    var tmp0_1 = this.nodes_1;
    // Inline function 'kotlin.collections.filterTo' call
    var destination_1 = ArrayList_init_$Create$();
    var _iterator__ex2g4s_1 = tmp0_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
      var element_1 = _iterator__ex2g4s_1.next_20eer_k$();
      if (element_1.kind_1.equals(NodeKind_PATH_getInstance()) && !((element_1.fill_1 >>> 24 | 0) === 0)) {
        destination_1.add_utx5q5_k$(element_1);
      }
    }
    tmp_2.icons_1 = destination_1;
    this.first_1 = firstOrNull(this.nodes_1);
  }
  protoOf(Comp).get_x_1mhr67_k$ = function () {
    return this.box_1.l_1 - this.ox_1;
  };
  protoOf(Comp).get_y_1mhr68_k$ = function () {
    return this.box_1.t_1 - this.oy_1;
  };
  protoOf(Comp).get_w_1mhr66_k$ = function () {
    return this.box_1.get_w_1mhr66_k$();
  };
  protoOf(Comp).get_h_1mhr5r_k$ = function () {
    return this.box_1.get_h_1mhr5r_k$();
  };
  protoOf(Comp).role_wr68n8_k$ = function (r) {
    var tmp0 = this.nodes_1;
    var tmp$ret$1;
    $l$block: {
      // Inline function 'kotlin.collections.firstOrNull' call
      var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s.next_20eer_k$();
        if (element.widget_1 === r) {
          tmp$ret$1 = element;
          break $l$block;
        }
      }
      tmp$ret$1 = null;
    }
    return tmp$ret$1;
  };
  protoOf(Comp).at_2er_k$ = function () {
    return 'Modifier.offset(' + dp(ComposeCode_getInstance(), this.get_x_1mhr67_k$()) + ', ' + dp(ComposeCode_getInstance(), this.get_y_1mhr68_k$()) + ')';
  };
  protoOf(Comp).sized_1t5ytf_k$ = function () {
    return this.at_2er_k$() + '.size(' + dp(ComposeCode_getInstance(), this.get_w_1mhr66_k$()) + ', ' + dp(ComposeCode_getInstance(), this.get_h_1mhr5r_k$()) + ')';
  };
  protoOf(Comp).wide_267rn_k$ = function () {
    return this.at_2er_k$() + '.width(' + dp(ComposeCode_getInstance(), this.get_w_1mhr66_k$()) + ')';
  };
  protoOf(Comp).text_chy86p_k$ = function (i, fallback) {
    var tmp0_elvis_lhs = getOrNull(this.texts_1, i);
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return 'Text("' + esc(ComposeCode_getInstance(), fallback) + '")';
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var n = tmp;
    var t = getOrNull(this.tplTexts_1, i);
    var extra = StringBuilder_init_$Create$_0();
    var tmp_0;
    if (!(t == null)) {
      // Inline function 'kotlin.math.abs' call
      var x = n.fontSize_1 - t.fontSize_1;
      tmp_0 = Math.abs(x) > 0.01;
    } else {
      tmp_0 = false;
    }
    if (tmp_0) {
      extra.append_22ad7x_k$(', fontSize = ' + num(ComposeCode_getInstance(), n.fontSize_1) + '.sp');
    }
    if (!(t == null) && !(n.weight_1 === t.weight_1)) {
      extra.append_22ad7x_k$(', fontWeight = FontWeight.W' + n.weight_1);
    }
    return 'Text("' + esc(ComposeCode_getInstance(), n.text_1) + '"' + extra.toString() + ')';
  };
  protoOf(Comp).text$default_p2kv6r_k$ = function (i, fallback, $super) {
    fallback = fallback === VOID ? '' : fallback;
    return $super === VOID ? this.text_chy86p_k$(i, fallback) : $super.text_chy86p_k$.call(this, i, fallback);
  };
  protoOf(Comp).shapeArg_la6q1v_k$ = function (defaultCorner) {
    var tmp0_safe_receiver = this.first_1;
    var tmp;
    if (tmp0_safe_receiver == null) {
      tmp = null;
    } else {
      // Inline function 'kotlin.takeIf' call
      var tmp_0;
      if (tmp0_safe_receiver.kind_1.equals(NodeKind_RECT_getInstance())) {
        tmp_0 = tmp0_safe_receiver;
      } else {
        tmp_0 = null;
      }
      tmp = tmp_0;
    }
    var tmp1_elvis_lhs = tmp;
    var tmp_1;
    if (tmp1_elvis_lhs == null) {
      return null;
    } else {
      tmp_1 = tmp1_elvis_lhs;
    }
    var n = tmp_1;
    var tmp2 = n.w_1;
    // Inline function 'kotlin.math.min' call
    var b = n.h_1;
    var half = Math.min(tmp2, b) / 2.0;
    // Inline function 'kotlin.math.min' call
    var a = n.corner_1;
    var eff = Math.min(a, half);
    var tmp_2;
    // Inline function 'kotlin.math.min' call
    // Inline function 'kotlin.math.abs' call
    var x = eff - Math.min(defaultCorner, half);
    if (Math.abs(x) < 0.5) {
      tmp_2 = null;
    } else {
      tmp_2 = 'RoundedCornerShape(' + dp(ComposeCode_getInstance(), eff) + ')';
    }
    return tmp_2;
  };
  function iconCall($this, n, c, plain, modifier) {
    var tmp;
    if (n == null) {
      tmp = null;
    } else {
      // Inline function 'kotlin.let' call
      tmp = c.vector_ccipu8_k$(n);
    }
    var vec = tmp;
    var expr = vec == null ? plain : vec;
    var m = modifier == null ? !(n == null) && !(vec == null) ? 'Modifier.size(' + dp($this, n.w_1) + ', ' + dp($this, n.h_1) + ')' : null : modifier;
    return !(m == null) ? 'Icon(' + expr + ', contentDescription = null, modifier = ' + m + ')' : 'Icon(' + expr + ', contentDescription = null)';
  }
  function iconCall$default($this, n, c, plain, modifier, $super) {
    modifier = modifier === VOID ? null : modifier;
    return iconCall($this, n, c, plain, modifier);
  }
  function clamp01($this, v) {
    return coerceIn(v, 0.0, 1.0);
  }
  function f($this, v) {
    return num($this, v) + 'f';
  }
  function emitMaterial($this, k, c, s) {
    switch (k.id_1) {
      case 'btn-filled':
      case 'btn-tonal':
      case 'btn-outlined':
      case 'btn-elevated':
      case 'btn-text':
      case 'btn-m':
      case 'btn-l':
      case 'btn-xl':
      case 'btn-square':
        var fn;
        switch (k.id_1) {
          case 'btn-tonal':
            fn = 'FilledTonalButton';
            break;
          case 'btn-outlined':
            fn = 'OutlinedButton';
            break;
          case 'btn-elevated':
            fn = 'ElevatedButton';
            break;
          case 'btn-text':
            fn = 'TextButton';
            break;
          default:
            fn = 'Button';
            break;
        }

        var args = arrayListOf(['onClick = { }', 'modifier = ' + k.sized_1t5ytf_k$()]);
        var tmp2_safe_receiver = k.shapeArg_la6q1v_k$(9999.0);
        if (tmp2_safe_receiver == null)
          null;
        else {
          // Inline function 'kotlin.let' call
          // Inline function 'kotlin.collections.plusAssign' call
          var element = 'shape = ' + tmp2_safe_receiver;
          args.add_utx5q5_k$(element);
        }

        s.call_xunhn6_k$(fn, args, ComposeCode$emitMaterial$lambda(k));
        break;
      case 'icon-btn':
      case 'icon-btn-tonal':
      case 'icon-btn-outlined':
      case 'icon-btn-square':
        var fn_0;
        switch (k.id_1) {
          case 'icon-btn-tonal':
            fn_0 = 'FilledTonalIconButton';
            break;
          case 'icon-btn-outlined':
            fn_0 = 'OutlinedIconButton';
            break;
          default:
            fn_0 = 'FilledIconButton';
            break;
        }

        var args_0 = arrayListOf(['onClick = { }', 'modifier = ' + k.sized_1t5ytf_k$()]);
        var tmp4_safe_receiver = k.shapeArg_la6q1v_k$(9999.0);
        if (tmp4_safe_receiver == null)
          null;
        else {
          // Inline function 'kotlin.let' call
          // Inline function 'kotlin.collections.plusAssign' call
          var element_0 = 'shape = ' + tmp4_safe_receiver;
          args_0.add_utx5q5_k$(element_0);
        }

        s.call_xunhn6_k$(fn_0, args_0, ComposeCode$emitMaterial$lambda_0(k, c));
        break;
      case 'fab':
      case 'fab-small':
      case 'fab-large':
        var fn_1;
        switch (k.id_1) {
          case 'fab-small':
            fn_1 = 'SmallFloatingActionButton';
            break;
          case 'fab-large':
            fn_1 = 'LargeFloatingActionButton';
            break;
          default:
            fn_1 = 'FloatingActionButton';
            break;
        }

        var args_1 = arrayListOf(['onClick = { }', 'modifier = ' + k.at_2er_k$()]);
        s.call_xunhn6_k$(fn_1, args_1, ComposeCode$emitMaterial$lambda_1(k, c));
        break;
      case 'ext-fab':
        var tmp = listOf_0(['onClick = { }', 'modifier = ' + k.sized_1t5ytf_k$()]);
        s.call_xunhn6_k$('ExtendedFloatingActionButton', tmp, ComposeCode$emitMaterial$lambda_2(k));
        break;
      case 'card':
      case 'card-elevated':
      case 'card-outlined':
      case 'card-media':
      case 'card-expressive':
      case 'stat-card':
        return emitCard($this, k, c, s);
      case 'dialog':
      case 'bottom-sheet':
      case 'menu':
      case 'tooltip':
      case 'banner':
        return emitSurface($this, k, c, s);
      case 'chip':
        var st = c.state_xyteun_k$('filter', 'false');
        var tmp_0 = listOf_0(['selected = ' + st, 'onClick = { ' + st + ' = !' + st + ' }', 'modifier = ' + k.at_2er_k$()]);
        s.call_xunhn6_k$('FilterChip', tmp_0, ComposeCode$emitMaterial$lambda_3);
        s.sb_1.setLength_oy0ork_k$(s.sb_1.get_length_g42xv3_k$() - 0 | 0);
        return emitChipLabel($this, k, s, st);
      case 'chip-filter':
        var st_0 = c.state_xyteun_k$('filter', 'true');
        emitFilterChip($this, k, s, st_0);
        break;
      case 'chip-assist':
        s.a_p9d5m1_k$('AssistChip(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('onClick = { },');
        s.a_p9d5m1_k$('label = { ' + k.text_chy86p_k$(0, 'Assist') + ' },');
        s.a_p9d5m1_k$('leadingIcon = { ' + iconCall($this, firstOrNull(k.icons_1), c, 'Icons.Filled.Check', 'Modifier.size(AssistChipDefaults.IconSize)') + ' },');
        s.a_p9d5m1_k$('modifier = ' + k.at_2er_k$() + ',');
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(')');
        break;
      case 'chip-input':
        s.a_p9d5m1_k$('InputChip(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('selected = false,');
        s.a_p9d5m1_k$('onClick = { },');
        s.a_p9d5m1_k$('label = { ' + k.text_chy86p_k$(0, 'Input') + ' },');
        s.a_p9d5m1_k$('trailingIcon = { Icon(Icons.Filled.Close, contentDescription = null, modifier = Modifier.size(InputChipDefaults.IconSize)) },');
        s.a_p9d5m1_k$('modifier = ' + k.at_2er_k$() + ',');
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(')');
        break;
      case 'switch':
      case 'switch-off':
      case 'switch-icon':
        var tmp6_elvis_lhs = k.role_wr68n8_k$('switch:track');
        var tmp_1;
        if (tmp6_elvis_lhs == null) {
          return false;
        } else {
          tmp_1 = tmp6_elvis_lhs;
        }

        var track = tmp_1;
        var tmp7_elvis_lhs = k.role_wr68n8_k$('switch:thumb');
        var tmp_2;
        if (tmp7_elvis_lhs == null) {
          return false;
        } else {
          tmp_2 = tmp7_elvis_lhs;
        }

        var thumb = tmp_2;
        var st_1 = c.state_xyteun_k$('checked', (thumb.get_cx_knto1u_k$() > track.get_cx_knto1u_k$()).toString());
        s.a_p9d5m1_k$('Switch(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('checked = ' + st_1 + ',');
        s.a_p9d5m1_k$('onCheckedChange = { ' + st_1 + ' = it },');
        s.a_p9d5m1_k$('modifier = ' + k.at_2er_k$() + ',');
        if (k.id_1 === 'switch-icon') {
          s.a_p9d5m1_k$('thumbContent = if (' + st_1 + ') {');
          s.inc_ry5d6a_k$();
          s.a_p9d5m1_k$('{ Icon(Icons.Filled.Check, contentDescription = null, modifier = Modifier.size(SwitchDefaults.IconSize)) }');
          s.dec_msx87i_k$();
          s.a_p9d5m1_k$('} else null,');
        }

        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(')');
        break;
      case 'checkbox':
      case 'checkbox-off':
        var tmp8_elvis_lhs = k.role_wr68n8_k$('check:box');
        var tmp_3;
        if (tmp8_elvis_lhs == null) {
          return false;
        } else {
          tmp_3 = tmp8_elvis_lhs;
        }

        var box = tmp_3;
        var st_2 = c.state_xyteun_k$('checked', (!((box.fill_1 >>> 24 | 0) === 0)).toString());
        s.call$default_6xmtdb_k$('Checkbox', listOf_0(['checked = ' + st_2, 'onCheckedChange = { ' + st_2 + ' = it }', 'modifier = Modifier.offset(' + dp($this, k.get_x_1mhr67_k$() - (40.0 - k.get_w_1mhr66_k$()) / 2.0) + ', ' + dp($this, k.get_y_1mhr68_k$() - (40.0 - k.get_h_1mhr5r_k$()) / 2.0) + ')']));
        break;
      case 'radio':
      case 'radio-off':
        var st_3 = c.state_xyteun_k$('selected', (!(k.role_wr68n8_k$('radio:dot') == null)).toString());
        s.call$default_6xmtdb_k$('RadioButton', listOf_0(['selected = ' + st_3, 'onClick = { ' + st_3 + ' = !' + st_3 + ' }', 'modifier = Modifier.offset(' + dp($this, k.get_x_1mhr67_k$() - (40.0 - k.get_w_1mhr66_k$()) / 2.0) + ', ' + dp($this, k.get_y_1mhr68_k$() - (40.0 - k.get_h_1mhr5r_k$()) / 2.0) + ')']));
        break;
      case 'slider':
      case 'slider-expressive':
      case 'slider-wavy':
        var tmp9_elvis_lhs = k.role_wr68n8_k$('slider:thumb');
        var tmp_4;
        if (tmp9_elvis_lhs == null) {
          return false;
        } else {
          tmp_4 = tmp9_elvis_lhs;
        }

        var thumb_0 = tmp_4;
        var st_4 = c.state_xyteun_k$('value', f($this, clamp01($this, (thumb_0.get_cx_knto1u_k$() - k.box_1.l_1) / k.get_w_1mhr66_k$())));
        s.call$default_6xmtdb_k$('Slider', listOf_0(['value = ' + st_4, 'onValueChange = { ' + st_4 + ' = it }', 'modifier = Modifier.offset(' + dp($this, k.get_x_1mhr67_k$()) + ', ' + dp($this, k.get_y_1mhr68_k$() + k.get_h_1mhr5r_k$() / 2.0 - 24.0) + ').width(' + dp($this, k.get_w_1mhr66_k$()) + ')']));
        break;
      case 'progress':
      case 'progress-wavy':
        var tmp10_elvis_lhs = k.role_wr68n8_k$('progress:active');
        var tmp_5;
        if (tmp10_elvis_lhs == null) {
          return false;
        } else {
          tmp_5 = tmp10_elvis_lhs;
        }

        var act = tmp_5;
        var v = clamp01($this, act.w_1 / k.get_w_1mhr66_k$());
        s.call$default_6xmtdb_k$('LinearProgressIndicator', listOf_0(['progress = { ' + f($this, v) + ' }', 'modifier = ' + k.wide_267rn_k$()]));
        break;
      case 'progress-circular':
        s.call$default_6xmtdb_k$('CircularProgressIndicator', listOf_0(['progress = { 0.75f }', 'modifier = ' + k.sized_1t5ytf_k$()]));
        break;
      case 'loading':
        s.call$default_6xmtdb_k$('CircularProgressIndicator', listOf('modifier = ' + k.sized_1t5ytf_k$()));
        break;
      case 'textfield':
      case 'textfield-error':
      case 'textfield-filled':
        var st_5 = c.state_xyteun_k$('text', '""');
        var filled = k.id_1 === 'textfield-filled';
        var err = k.id_1 === 'textfield-error';
        var fn_2 = filled ? 'TextField' : 'OutlinedTextField';
        s.a_p9d5m1_k$(fn_2 + '(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('value = ' + st_5 + ',');
        s.a_p9d5m1_k$('onValueChange = { ' + st_5 + ' = it },');
        s.a_p9d5m1_k$('label = { ' + k.text_chy86p_k$(0, 'Label') + ' },');
        if (err) {
          s.a_p9d5m1_k$('isError = true,');
          if (k.texts_1.get_size_woubt6_k$() > 1) {
            s.a_p9d5m1_k$('supportingText = { ' + k.text$default_p2kv6r_k$(1) + ' },');
          }
        }

        s.a_p9d5m1_k$('modifier = ' + k.at_2er_k$() + '.width(' + dp($this, k.get_w_1mhr66_k$()) + '),');
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(')');
        break;
      case 'search':
        var st_6 = c.state_xyteun_k$('query', '""');
        s.a_p9d5m1_k$('TextField(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('value = ' + st_6 + ',');
        s.a_p9d5m1_k$('onValueChange = { ' + st_6 + ' = it },');
        s.a_p9d5m1_k$('placeholder = { ' + k.text_chy86p_k$(0, 'Search') + ' },');
        s.a_p9d5m1_k$('leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },');
        s.a_p9d5m1_k$('singleLine = true,');
        s.a_p9d5m1_k$('shape = CircleShape,');
        s.a_p9d5m1_k$('colors = TextFieldDefaults.colors(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('focusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh,');
        s.a_p9d5m1_k$('unfocusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh,');
        s.a_p9d5m1_k$('focusedIndicatorColor = Color.Transparent,');
        s.a_p9d5m1_k$('unfocusedIndicatorColor = Color.Transparent,');
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$('),');
        s.a_p9d5m1_k$('modifier = ' + k.sized_1t5ytf_k$() + ',');
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(')');
        break;
      case 'divider':
        s.call$default_6xmtdb_k$('HorizontalDivider', listOf('modifier = ' + k.wide_267rn_k$()));
        break;
      case 'badge':
      case 'badge-large':
        var tmp_6 = listOf('modifier = ' + k.at_2er_k$());
        s.call_xunhn6_k$('Badge', tmp_6, ComposeCode$emitMaterial$lambda_4(k));
        break;
      case 'tabs':
        if (k.texts_1.isEmpty_y1axqb_k$())
          return false;
        var st_7 = c.state_xyteun_k$('tab', '0');
        s.a_p9d5m1_k$('TabRow(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('selectedTabIndex = ' + st_7 + ',');
        s.a_p9d5m1_k$('modifier = ' + k.wide_267rn_k$() + ',');
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(') {');
        s.inc_ry5d6a_k$();
        var inductionVariable = 0;
        var last = k.texts_1.get_size_woubt6_k$() - 1 | 0;
        if (inductionVariable <= last)
          do {
            var i = inductionVariable;
            inductionVariable = inductionVariable + 1 | 0;
            s.a_p9d5m1_k$('Tab(');
            s.inc_ry5d6a_k$();
            s.a_p9d5m1_k$('selected = ' + st_7 + ' == ' + i + ',');
            s.a_p9d5m1_k$('onClick = { ' + st_7 + ' = ' + i + ' },');
            s.a_p9d5m1_k$('text = { ' + k.text$default_p2kv6r_k$(i) + ' },');
            s.dec_msx87i_k$();
            s.a_p9d5m1_k$(')');
          }
           while (inductionVariable <= last);
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$('}');
        break;
      case 'segmented':
        if (k.texts_1.isEmpty_y1axqb_k$())
          return false;
        var st_8 = c.state_xyteun_k$('segment', '0');
        var n = k.texts_1.get_size_woubt6_k$();
        s.a_p9d5m1_k$('SingleChoiceSegmentedButtonRow(modifier = ' + k.wide_267rn_k$() + ') {');
        s.inc_ry5d6a_k$();
        var inductionVariable_0 = 0;
        if (inductionVariable_0 < n)
          do {
            var i_0 = inductionVariable_0;
            inductionVariable_0 = inductionVariable_0 + 1 | 0;
            s.a_p9d5m1_k$('SegmentedButton(');
            s.inc_ry5d6a_k$();
            s.a_p9d5m1_k$('selected = ' + st_8 + ' == ' + i_0 + ',');
            s.a_p9d5m1_k$('onClick = { ' + st_8 + ' = ' + i_0 + ' },');
            s.a_p9d5m1_k$('shape = SegmentedButtonDefaults.itemShape(index = ' + i_0 + ', count = ' + n + '),');
            s.a_p9d5m1_k$('label = { ' + k.text$default_p2kv6r_k$(i_0) + ' },');
            s.dec_msx87i_k$();
            s.a_p9d5m1_k$(')');
          }
           while (inductionVariable_0 < n);
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$('}');
        break;
      case 'nav-bar':
      case 'nav-bar-flex':
        if (k.texts_1.isEmpty_y1axqb_k$())
          return false;
        var st_9 = c.state_xyteun_k$('item', '0');
        s.a_p9d5m1_k$('NavigationBar(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('modifier = ' + k.sized_1t5ytf_k$() + ',');
        s.a_p9d5m1_k$('windowInsets = WindowInsets(0, 0, 0, 0),');
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(') {');
        s.inc_ry5d6a_k$();
        var inductionVariable_1 = 0;
        var last_0 = k.texts_1.get_size_woubt6_k$() - 1 | 0;
        if (inductionVariable_1 <= last_0)
          do {
            var i_1 = inductionVariable_1;
            inductionVariable_1 = inductionVariable_1 + 1 | 0;
            s.a_p9d5m1_k$('NavigationBarItem(');
            s.inc_ry5d6a_k$();
            s.a_p9d5m1_k$('selected = ' + st_9 + ' == ' + i_1 + ',');
            s.a_p9d5m1_k$('onClick = { ' + st_9 + ' = ' + i_1 + ' },');
            s.a_p9d5m1_k$('icon = { ' + iconCall$default($this, getOrNull(k.icons_1, i_1), c, 'Icons.Filled.Check') + ' },');
            s.a_p9d5m1_k$('label = { ' + k.text$default_p2kv6r_k$(i_1) + ' },');
            if (k.id_1 === 'nav-bar-flex') {
              s.a_p9d5m1_k$('alwaysShowLabel = false,');
            }
            s.dec_msx87i_k$();
            s.a_p9d5m1_k$(')');
          }
           while (inductionVariable_1 <= last_0);
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$('}');
        break;
      case 'nav-rail':
        if (k.texts_1.isEmpty_y1axqb_k$())
          return false;
        var st_10 = c.state_xyteun_k$('item', '0');
        s.a_p9d5m1_k$('NavigationRail(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('modifier = ' + k.sized_1t5ytf_k$() + ',');
        s.a_p9d5m1_k$('header = { FloatingActionButton(onClick = { }) { Icon(Icons.Filled.Add, contentDescription = null) } },');
        s.a_p9d5m1_k$('windowInsets = WindowInsets(0, 0, 0, 0),');
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(') {');
        s.inc_ry5d6a_k$();
        var inductionVariable_2 = 0;
        var last_1 = k.texts_1.get_size_woubt6_k$() - 1 | 0;
        if (inductionVariable_2 <= last_1)
          do {
            var i_2 = inductionVariable_2;
            inductionVariable_2 = inductionVariable_2 + 1 | 0;
            s.a_p9d5m1_k$('NavigationRailItem(');
            s.inc_ry5d6a_k$();
            s.a_p9d5m1_k$('selected = ' + st_10 + ' == ' + i_2 + ',');
            s.a_p9d5m1_k$('onClick = { ' + st_10 + ' = ' + i_2 + ' },');
            s.a_p9d5m1_k$('icon = { ' + iconCall$default($this, getOrNull(k.icons_1, i_2), c, 'Icons.Filled.Check') + ' },');
            s.a_p9d5m1_k$('label = { ' + k.text$default_p2kv6r_k$(i_2) + ' },');
            s.dec_msx87i_k$();
            s.a_p9d5m1_k$(')');
          }
           while (inductionVariable_2 <= last_1);
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$('}');
        break;
      case 'bottom-bar':
        s.a_p9d5m1_k$('BottomAppBar(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('modifier = ' + k.sized_1t5ytf_k$() + ',');
        s.a_p9d5m1_k$('windowInsets = WindowInsets(0, 0, 0, 0),');
        s.a_p9d5m1_k$('actions = {');
        s.inc_ry5d6a_k$();
        var _iterator__ex2g4s = k.icons_1.iterator_jk1svi_k$();
        while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
          var ic = _iterator__ex2g4s.next_20eer_k$();
          s.a_p9d5m1_k$('IconButton(onClick = { }) { ' + iconCall$default($this, ic, c, 'Icons.Filled.Check') + ' }');
        }

        s.dec_msx87i_k$();
        s.a_p9d5m1_k$('},');
        s.a_p9d5m1_k$('floatingActionButton = { FloatingActionButton(onClick = { }) { Icon(Icons.Filled.Add, contentDescription = null) } },');
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(')');
        break;
      case 'top-bar':
      case 'top-bar-center':
      case 'top-bar-medium':
      case 'top-bar-large':
        var tmp11_elvis_lhs = firstOrNull(k.texts_1);
        var tmp_7;
        if (tmp11_elvis_lhs == null) {
          return false;
        } else {
          tmp_7 = tmp11_elvis_lhs;
        }

        var title = tmp_7;
        var fn_3;
        switch (k.id_1) {
          case 'top-bar-center':
            fn_3 = 'CenterAlignedTopAppBar';
            break;
          case 'top-bar-medium':
            fn_3 = 'MediumTopAppBar';
            break;
          case 'top-bar-large':
            fn_3 = 'LargeTopAppBar';
            break;
          default:
            fn_3 = 'TopAppBar';
            break;
        }

        var bg = ensureNotNull(k.first_1);
        // Inline function 'kotlin.collections.filter' call

        var tmp0 = k.icons_1;
        // Inline function 'kotlin.collections.filterTo' call

        var destination = ArrayList_init_$Create$();
        var _iterator__ex2g4s_0 = tmp0.iterator_jk1svi_k$();
        while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
          var element_1 = _iterator__ex2g4s_0.next_20eer_k$();
          if (element_1.get_cx_knto1u_k$() < k.box_1.get_cx_knto1u_k$()) {
            destination.add_utx5q5_k$(element_1);
          }
        }

        var left = destination;
        // Inline function 'kotlin.collections.filter' call

        var tmp0_0 = k.icons_1;
        // Inline function 'kotlin.collections.filterTo' call

        var destination_0 = ArrayList_init_$Create$();
        var _iterator__ex2g4s_1 = tmp0_0.iterator_jk1svi_k$();
        while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
          var element_2 = _iterator__ex2g4s_1.next_20eer_k$();
          if (element_2.get_cx_knto1u_k$() >= k.box_1.get_cx_knto1u_k$()) {
            destination_0.add_utx5q5_k$(element_2);
          }
        }

        var right = destination_0;
        s.a_p9d5m1_k$(fn_3 + '(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('title = { ' + k.text_chy86p_k$(0, title.text_1) + ' },');
        s.a_p9d5m1_k$('modifier = ' + k.sized_1t5ytf_k$() + ',');
        s.slot_1821w1_k$('navigationIcon', ComposeCode$emitMaterial$lambda_5(left, c));
        // Inline function 'kotlin.collections.isNotEmpty' call

        if (!right.isEmpty_y1axqb_k$()) {
          s.slot_1821w1_k$('actions', ComposeCode$emitMaterial$lambda_6(right, c));
        }

        s.a_p9d5m1_k$('windowInsets = WindowInsets(0, 0, 0, 0),');
        s.a_p9d5m1_k$('colors = TopAppBarDefaults.topAppBarColors(containerColor = ' + colorExpr($this, bg.fill_1, bg.fillToken_1) + '),');
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(')');
        break;
      case 'list-item':
      case 'list-3line':
      case 'list-switch':
      case 'list-checkbox':
        if (k.texts_1.isEmpty_y1axqb_k$())
          return false;
        var tmp9 = k.nodes_1;
        var tmp$ret$15;
        $l$block: {
          // Inline function 'kotlin.collections.firstOrNull' call
          var _iterator__ex2g4s_2 = tmp9.iterator_jk1svi_k$();
          while (_iterator__ex2g4s_2.hasNext_bitz1p_k$()) {
            var element_3 = _iterator__ex2g4s_2.next_20eer_k$();
            var tmp_8;
            if (element_3.kind_1.equals(NodeKind_ELLIPSE_getInstance())) {
              // Inline function 'kotlin.text.isEmpty' call
              var this_0 = element_3.widget_1;
              tmp_8 = charSequenceLength(this_0) === 0;
            } else {
              tmp_8 = false;
            }
            if (tmp_8) {
              tmp$ret$15 = element_3;
              break $l$block;
            }
          }
          tmp$ret$15 = null;
        }

        var avatar = tmp$ret$15;
        var sw = k.role_wr68n8_k$('switch:track');
        var cb = k.role_wr68n8_k$('check:box');
        s.a_p9d5m1_k$('ListItem(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('headlineContent = { ' + k.text$default_p2kv6r_k$(0) + ' },');
        if (k.texts_1.get_size_woubt6_k$() > 1) {
          if (k.texts_1.get_size_woubt6_k$() === 2) {
            s.a_p9d5m1_k$('supportingContent = { ' + k.text$default_p2kv6r_k$(1) + ' },');
          } else {
            s.slot_1821w1_k$('supportingContent', ComposeCode$emitMaterial$lambda_7(k));
          }
        }

        if (!(avatar == null)) {
          s.slot_1821w1_k$('leadingContent', ComposeCode$emitMaterial$lambda_8(avatar));
        }

        if (!(cb == null)) {
          var st_11 = c.state_xyteun_k$('checked', (!((cb.fill_1 >>> 24 | 0) === 0)).toString());
          s.slot_1821w1_k$('leadingContent', ComposeCode$emitMaterial$lambda_9(st_11));
        }

        if (!(sw == null)) {
          var thumb_1 = k.role_wr68n8_k$('switch:thumb');
          var st_12 = c.state_xyteun_k$('checked', (!(thumb_1 == null) && thumb_1.get_cx_knto1u_k$() > sw.get_cx_knto1u_k$()).toString());
          s.slot_1821w1_k$('trailingContent', ComposeCode$emitMaterial$lambda_10(st_12));
        }

        s.a_p9d5m1_k$('modifier = ' + k.wide_267rn_k$() + ',');
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(')');
        break;
      case 'snackbar':
        if (k.texts_1.isEmpty_y1axqb_k$())
          return false;
        s.a_p9d5m1_k$('Snackbar(');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$('modifier = ' + k.wide_267rn_k$() + ',');
        if (k.texts_1.get_size_woubt6_k$() > 1) {
          s.slot_1821w1_k$('action', ComposeCode$emitMaterial$lambda_11(k));
        }

        s.dec_msx87i_k$();
        s.a_p9d5m1_k$(') {');
        s.inc_ry5d6a_k$();
        s.a_p9d5m1_k$(k.text$default_p2kv6r_k$(0));
        s.dec_msx87i_k$();
        s.a_p9d5m1_k$('}');
        break;
      default:
        return false;
    }
    return true;
  }
  function emitChipLabel($this, k, s, st) {
    var text = s.sb_1.toString();
    var cut = lastIndexOf(text, 'FilterChip(');
    var lineStart = lastIndexOf_0(text, _Char___init__impl__6a9atx(10), cut) + 1 | 0;
    s.sb_1.setLength_oy0ork_k$(lineStart);
    s.a_p9d5m1_k$('FilterChip(');
    s.inc_ry5d6a_k$();
    s.a_p9d5m1_k$('selected = ' + st + ',');
    s.a_p9d5m1_k$('onClick = { ' + st + ' = !' + st + ' },');
    s.a_p9d5m1_k$('label = { ' + k.text_chy86p_k$(0, 'Filter') + ' },');
    s.a_p9d5m1_k$('modifier = ' + k.at_2er_k$() + ',');
    s.dec_msx87i_k$();
    s.a_p9d5m1_k$(')');
    return true;
  }
  function emitFilterChip($this, k, s, st) {
    s.a_p9d5m1_k$('FilterChip(');
    s.inc_ry5d6a_k$();
    s.a_p9d5m1_k$('selected = ' + st + ',');
    s.a_p9d5m1_k$('onClick = { ' + st + ' = !' + st + ' },');
    s.a_p9d5m1_k$('label = { ' + k.text_chy86p_k$(0, 'Filter') + ' },');
    s.a_p9d5m1_k$('leadingIcon = if (' + st + ') {');
    s.inc_ry5d6a_k$();
    s.a_p9d5m1_k$('{ Icon(Icons.Filled.Check, contentDescription = null, modifier = Modifier.size(FilterChipDefaults.IconSize)) }');
    s.dec_msx87i_k$();
    s.a_p9d5m1_k$('} else null,');
    s.a_p9d5m1_k$('modifier = ' + k.at_2er_k$() + ',');
    s.dec_msx87i_k$();
    s.a_p9d5m1_k$(')');
  }
  function innerLayers($this, k, c, s, container) {
    s.a_p9d5m1_k$('Box(Modifier.fillMaxSize()) {');
    s.inc_ry5d6a_k$();
    var _iterator__ex2g4s = k.nodes_1.iterator_jk1svi_k$();
    $l$loop: while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var n = _iterator__ex2g4s.next_20eer_k$();
      if (n === container || !n.visible_1)
        continue $l$loop;
      s.raw_h13x4y_k$(layer$default($this, n, c, repeat('    ', s.depth_1), container.x_1, container.y_1));
    }
    s.dec_msx87i_k$();
    s.a_p9d5m1_k$('}');
  }
  function emitCard($this, k, c, s) {
    var tmp0_safe_receiver = k.first_1;
    var tmp;
    if (tmp0_safe_receiver == null) {
      tmp = null;
    } else {
      // Inline function 'kotlin.takeIf' call
      var tmp_0;
      if (tmp0_safe_receiver.kind_1.equals(NodeKind_RECT_getInstance()) && !tmp0_safe_receiver.get_hasGradient_845ojj_k$()) {
        tmp_0 = tmp0_safe_receiver;
      } else {
        tmp_0 = null;
      }
      tmp = tmp_0;
    }
    var tmp1_elvis_lhs = tmp;
    var tmp_1;
    if (tmp1_elvis_lhs == null) {
      return false;
    } else {
      tmp_1 = tmp1_elvis_lhs;
    }
    var box = tmp_1;
    var fn;
    switch (k.id_1) {
      case 'card-elevated':
        fn = 'ElevatedCard';
        break;
      case 'card-outlined':
        fn = 'OutlinedCard';
        break;
      default:
        fn = 'Card';
        break;
    }
    var colors;
    switch (fn) {
      case 'ElevatedCard':
        colors = 'elevatedCardColors';
        break;
      case 'OutlinedCard':
        colors = 'outlinedCardColors';
        break;
      default:
        colors = 'cardColors';
        break;
    }
    var tmp4 = box.corner_1;
    var tmp2 = box.w_1;
    // Inline function 'kotlin.math.min' call
    var b = box.h_1;
    // Inline function 'kotlin.math.min' call
    var b_0 = Math.min(tmp2, b) / 2.0;
    var tmp$ret$3 = Math.min(tmp4, b_0);
    var shape = 'RoundedCornerShape(' + dp($this, tmp$ret$3) + ')';
    var args = arrayListOf(['modifier = ' + k.sized_1t5ytf_k$(), 'shape = ' + shape, 'colors = CardDefaults.' + colors + '(containerColor = ' + colorExpr($this, box.fill_1, box.fillToken_1) + ')']);
    if (fn === 'OutlinedCard' && !((box.stroke_1 >>> 24 | 0) === 0) && box.strokeWidth_1 > 0.0) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element = 'border = BorderStroke(' + dp($this, box.strokeWidth_1) + ', ' + colorExpr($this, box.stroke_1, box.strokeToken_1) + ')';
      args.add_utx5q5_k$(element);
    }
    s.call_xunhn6_k$(fn, args, ComposeCode$emitCard$lambda(k, c, box));
    return true;
  }
  function emitSurface($this, k, c, s) {
    var tmp0_safe_receiver = k.first_1;
    var tmp;
    if (tmp0_safe_receiver == null) {
      tmp = null;
    } else {
      // Inline function 'kotlin.takeIf' call
      var tmp_0;
      if (tmp0_safe_receiver.kind_1.equals(NodeKind_RECT_getInstance()) && !tmp0_safe_receiver.get_hasGradient_845ojj_k$()) {
        tmp_0 = tmp0_safe_receiver;
      } else {
        tmp_0 = null;
      }
      tmp = tmp_0;
    }
    var tmp1_elvis_lhs = tmp;
    var tmp_1;
    if (tmp1_elvis_lhs == null) {
      return false;
    } else {
      tmp_1 = tmp1_elvis_lhs;
    }
    var box = tmp_1;
    var tmp_2 = 'modifier = ' + k.sized_1t5ytf_k$();
    var tmp4 = box.corner_1;
    var tmp2 = box.w_1;
    // Inline function 'kotlin.math.min' call
    var b = box.h_1;
    // Inline function 'kotlin.math.min' call
    var b_0 = Math.min(tmp2, b) / 2.0;
    var tmp$ret$3 = Math.min(tmp4, b_0);
    var args = arrayListOf([tmp_2, 'shape = RoundedCornerShape(' + dp($this, tmp$ret$3) + ')', 'color = ' + colorExpr($this, box.fill_1, box.fillToken_1)]);
    if (box.get_hasShadow_3tjd81_k$()) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element = 'shadowElevation = ' + dp($this, box.shadowBlur_1 / 2.0);
      args.add_utx5q5_k$(element);
    }
    if (!((box.stroke_1 >>> 24 | 0) === 0) && box.strokeWidth_1 > 0.0) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_0 = 'border = BorderStroke(' + dp($this, box.strokeWidth_1) + ', ' + colorExpr($this, box.stroke_1, box.strokeToken_1) + ')';
      args.add_utx5q5_k$(element_0);
    }
    s.call_xunhn6_k$('Surface', args, ComposeCode$emitSurface$lambda(k, c, box));
    return true;
  }
  function recognise($this, group, members, ox, oy) {
    var id = substringAfter_0(group, '~', '');
    // Inline function 'kotlin.text.isEmpty' call
    if (charSequenceLength(id) === 0)
      return null;
    var tmp1 = Components_getInstance().all_1;
    var tmp$ret$2;
    $l$block: {
      // Inline function 'kotlin.collections.firstOrNull' call
      var _iterator__ex2g4s = tmp1.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s.next_20eer_k$();
        if (element.id_1 === id) {
          tmp$ret$2 = element;
          break $l$block;
        }
      }
      tmp$ret$2 = null;
    }
    var tmp0_elvis_lhs = tmp$ret$2;
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return null;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var def = tmp;
    var tpl = def.build_gglqo9_k$(0.0, 0.0, 'x', Companion_getInstance_11().Baseline_1);
    if (!(tpl.get_size_woubt6_k$() === members.get_size_woubt6_k$()))
      return null;
    var inductionVariable = 0;
    var last = tpl.get_size_woubt6_k$() - 1 | 0;
    if (inductionVariable <= last)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var a = tpl.get_c1px32_k$(i);
        var b = members.get_c1px32_k$(i);
        if (!a.kind_1.equals(b.kind_1) || !(a.fillToken_1 === b.fillToken_1) || !(a.strokeToken_1 === b.strokeToken_1))
          return null;
        var tmp_0;
        if (!b.visible_1 || b.mask_1 || b.get_hasGradient_845ojj_k$() || b.blur_1 > 0.5) {
          tmp_0 = true;
        } else {
          var tmp_1;
          // Inline function 'kotlin.math.abs' call
          var x = b.rotation_1 - a.rotation_1;
          if (Math.abs(x) > 0.5) {
            tmp_1 = b.kind_1.equals(NodeKind_TEXT_getInstance());
          } else {
            tmp_1 = false;
          }
          tmp_0 = tmp_1;
        }
        if (tmp_0)
          return null;
      }
       while (inductionVariable <= last);
    return new Comp(id, members, tpl, ox, oy);
  }
  function importsFor($this, code) {
    // Inline function 'kotlin.text.replace' call
    var tmp3 = Regex_init_$Create$('"(\\\\.|[^"\\\\])*"').replace_1ix0wf_k$(code, '""');
    // Inline function 'kotlin.text.replace' call
    var bare = Regex_init_$Create$('//[^\n]*').replace_1ix0wf_k$(tmp3, '');
    var out = sortedSetOf();
    var _iterator__ex2g4s = $this.simpleImports_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var _destruct__k2r9zo = _iterator__ex2g4s.next_20eer_k$();
      var re = _destruct__k2r9zo.component1_7eebsc_k$();
      var imp = _destruct__k2r9zo.component2_7eebsb_k$();
      var tmp;
      // Inline function 'kotlin.text.isNotEmpty' call
      if (charSequenceLength(imp) > 0) {
        tmp = re.containsMatchIn_gpzk5u_k$(bare);
      } else {
        tmp = false;
      }
      if (tmp) {
        // Inline function 'kotlin.collections.plusAssign' call
        out.add_utx5q5_k$(imp);
      }
    }
    if (Regex_init_$Create$('\\bcos\\(').containsMatchIn_gpzk5u_k$(bare)) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element = 'kotlin.math.cos';
      out.add_utx5q5_k$(element);
    }
    if (Regex_init_$Create$('\\bsin\\(').containsMatchIn_gpzk5u_k$(bare)) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_0 = 'kotlin.math.sin';
      out.add_utx5q5_k$(element_0);
    }
    if (Regex_init_$Create$('\\babs\\(').containsMatchIn_gpzk5u_k$(bare)) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_1 = 'kotlin.math.abs';
      out.add_utx5q5_k$(element_1);
    }
    var _iterator__ex2g4s_0 = $this.material3Names_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
      var n = _iterator__ex2g4s_0.next_20eer_k$();
      if (Regex_init_$Create$('\\b' + n + '\\b').containsMatchIn_gpzk5u_k$(bare)) {
        // Inline function 'kotlin.collections.plusAssign' call
        var element_2 = 'androidx.compose.material3.' + n;
        out.add_utx5q5_k$(element_2);
      }
    }
    if (Regex_init_$Create$('\\bExperimentalMaterial3Api\\b').containsMatchIn_gpzk5u_k$(bare)) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_3 = 'androidx.compose.material3.ExperimentalMaterial3Api';
      out.add_utx5q5_k$(element_3);
    }
    if (Regex_init_$Create$('\\bExperimentalMaterial3ExpressiveApi\\b').containsMatchIn_gpzk5u_k$(bare)) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_4 = 'androidx.compose.material3.ExperimentalMaterial3ExpressiveApi';
      out.add_utx5q5_k$(element_4);
    }
    var _iterator__ex2g4s_1 = Regex_init_$Create$('Icons\\.Filled\\.(\\w+)').findAll$default_xha0o9_k$(bare).iterator_jk1svi_k$();
    while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
      var m = _iterator__ex2g4s_1.next_20eer_k$();
      // Inline function 'kotlin.collections.plusAssign' call
      var element_5 = 'androidx.compose.material.icons.Icons';
      out.add_utx5q5_k$(element_5);
      // Inline function 'kotlin.collections.plusAssign' call
      var element_6 = 'androidx.compose.material.icons.filled.' + m.get_groupValues_rkv314_k$().get_c1px32_k$(1);
      out.add_utx5q5_k$(element_6);
    }
    return toList_0(out);
  }
  function optIn($this, code) {
    // Inline function 'kotlin.text.replace' call
    var tmp3 = Regex_init_$Create$('"(\\\\.|[^"\\\\])*"').replace_1ix0wf_k$(code, '""');
    // Inline function 'kotlin.text.replace' call
    var bare = Regex_init_$Create$('//[^\n]*').replace_1ix0wf_k$(tmp3, '');
    var list = ArrayList_init_$Create$();
    var tmp6 = $this.experimentalNames_1;
    var tmp$ret$2;
    $l$block_0: {
      // Inline function 'kotlin.collections.any' call
      var tmp;
      if (isInterface(tmp6, Collection)) {
        tmp = tmp6.isEmpty_y1axqb_k$();
      } else {
        tmp = false;
      }
      if (tmp) {
        tmp$ret$2 = false;
        break $l$block_0;
      }
      var _iterator__ex2g4s = tmp6.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s.next_20eer_k$();
        if (Regex_init_$Create$('\\b' + element + '\\b').containsMatchIn_gpzk5u_k$(bare)) {
          tmp$ret$2 = true;
          break $l$block_0;
        }
      }
      tmp$ret$2 = false;
    }
    if (tmp$ret$2) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_0 = 'ExperimentalMaterial3Api::class';
      list.add_utx5q5_k$(element_0);
    }
    if (Regex_init_$Create$('\\bMaterialShapes\\b|\\.toShape\\(').containsMatchIn_gpzk5u_k$(bare)) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_1 = 'ExperimentalMaterial3ExpressiveApi::class';
      list.add_utx5q5_k$(element_1);
    }
    return list.isEmpty_y1axqb_k$() ? '' : '@OptIn(' + joinToString_0(list, ', ') + ')\n';
  }
  function emitComponent($this, k, c, body) {
    body.a_p9d5m1_k$('// ' + k.id_1);
    var probe = new Src(body.depth_1);
    var stateMark = c.states_1.get_size_woubt6_k$();
    var ok = emitMaterial($this, k, c, probe);
    if (ok) {
      var text = probe.sb_1.toString();
      var tmp0 = k.nodes_1;
      var tmp$ret$2;
      $l$block: {
        // Inline function 'kotlin.collections.firstOrNull' call
        var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
        while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
          var element = _iterator__ex2g4s.next_20eer_k$();
          // Inline function 'kotlin.text.isNotEmpty' call
          var this_0 = element.action_1;
          if (charSequenceLength(this_0) > 0) {
            tmp$ret$2 = element;
            break $l$block;
          }
        }
        tmp$ret$2 = null;
      }
      var tmp0_safe_receiver = tmp$ret$2;
      if (tmp0_safe_receiver == null)
        null;
      else {
        // Inline function 'kotlin.let' call
        var tmp0_safe_receiver_0 = actionExpr(ComposeCode_getInstance(), tmp0_safe_receiver, c);
        var tmp;
        if (tmp0_safe_receiver_0 == null) {
          tmp = null;
        } else {
          // Inline function 'kotlin.let' call
          text = replaceFirst(text, 'onClick = { }', 'onClick = { ' + tmp0_safe_receiver_0 + ' }');
          tmp = Unit_instance;
        }
      }
      body.raw_h13x4y_k$(text);
      return Unit_instance;
    }
    while (c.states_1.get_size_woubt6_k$() > stateMark) {
      c.states_1.removeAt_6niowx_k$(c.states_1.get_size_woubt6_k$() - 1 | 0);
    }
    var name = 'Vexel' + pascal($this, k.id_1) + removePrefix(c.next_bw7zqf_k$('_'), '_');
    var fb = StringBuilder_init_$Create$_0();
    fb.append_22ad7x_k$('/** ' + k.id_1 + ': no direct Material 3 widget, so the layers are placed by coordinates. */\n');
    fb.append_22ad7x_k$('@Composable\nprivate fun ' + name + '(modifier: Modifier = Modifier) {\n');
    fb.append_22ad7x_k$('    Box(modifier.size(' + dp($this, k.get_w_1mhr66_k$()) + ', ' + dp($this, k.get_h_1mhr5r_k$()) + ')) {\n');
    var _iterator__ex2g4s_0 = k.nodes_1.iterator_jk1svi_k$();
    $l$loop: while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
      var n = _iterator__ex2g4s_0.next_20eer_k$();
      if (!n.visible_1)
        continue $l$loop;
      fb.append_22ad7x_k$(layer$default($this, n, c, '        ', k.box_1.l_1, k.box_1.t_1));
    }
    fb.append_22ad7x_k$('    }\n}\n');
    var tmp4 = c.fallbacks_1;
    // Inline function 'kotlin.collections.plusAssign' call
    var element_0 = fb.toString();
    tmp4.add_utx5q5_k$(element_0);
    body.a_p9d5m1_k$(name + '(' + k.at_2er_k$() + ')');
  }
  function layer$body(pre, $n, $ind, modifier, $c) {
    var b = new StringBuilder(pre._v);
    switch ($n.kind_1.ordinal_1) {
      case 3:
        b.append_22ad7x_k$($ind).append_22ad7x_k$('Text(\n').append_22ad7x_k$($ind).append_22ad7x_k$('    text = "').append_22ad7x_k$(esc(ComposeCode_getInstance(), $n.text_1)).append_22ad7x_k$('",\n').append_22ad7x_k$($ind).append_22ad7x_k$('    modifier = ').append_22ad7x_k$(modifier).append_22ad7x_k$(',\n').append_22ad7x_k$($ind).append_22ad7x_k$('    color = ').append_22ad7x_k$(colorExpr(ComposeCode_getInstance(), $n.fill_1, $n.fillToken_1)).append_22ad7x_k$(',\n').append_22ad7x_k$($ind).append_22ad7x_k$('    fontSize = ').append_22ad7x_k$(num(ComposeCode_getInstance(), $n.fontSize_1)).append_22ad7x_k$('.sp,\n').append_22ad7x_k$($ind).append_22ad7x_k$('    fontWeight = FontWeight.W').append_uppzia_k$($n.weight_1).append_22ad7x_k$(',\n').append_22ad7x_k$($ind).append_22ad7x_k$('    softWrap = false,\n');
        var tmp1_safe_receiver = $c.opts_1;
        var tmp2_safe_receiver = tmp1_safe_receiver == null ? null : tmp1_safe_receiver.fonts_1;
        var fam = tmp2_safe_receiver == null ? null : tmp2_safe_receiver.get_wei43m_k$($n.font_1);
        if (!(fam == null)) {
          b.append_22ad7x_k$($ind).append_22ad7x_k$('    fontFamily = VexelFonts.').append_22ad7x_k$(fam).append_22ad7x_k$(',\n');
        } else {
          // Inline function 'kotlin.text.isNotEmpty' call
          var this_0 = $n.font_1;
          if (charSequenceLength(this_0) > 0) {
            b.append_22ad7x_k$($ind).append_22ad7x_k$('    // font "').append_22ad7x_k$(esc(ComposeCode_getInstance(), $n.font_1)).append_22ad7x_k$('": plug in your own FontFamily\n');
          }
        }

        b.append_22ad7x_k$($ind).append_22ad7x_k$(')\n');
        break;
      case 5:
        $c.usesImage_1 = true;
        var res = ComposeCode_getInstance().imageResName_9jbftv_k$($n.asset_1);
        b.append_22ad7x_k$($ind).append_22ad7x_k$('// copy the picture into res/drawable as ').append_22ad7x_k$(res).append_22ad7x_k$(' (original file: ').append_22ad7x_k$(esc(ComposeCode_getInstance(), $n.asset_1)).append_22ad7x_k$(')\n');
        b.append_22ad7x_k$($ind).append_22ad7x_k$('Image(\n').append_22ad7x_k$($ind).append_22ad7x_k$('    painter = painterResource(R.drawable.').append_22ad7x_k$(res).append_22ad7x_k$('),\n').append_22ad7x_k$($ind).append_22ad7x_k$('    contentDescription = null,\n').append_22ad7x_k$($ind).append_22ad7x_k$('    contentScale = ContentScale.Crop,\n').append_22ad7x_k$($ind).append_22ad7x_k$('    modifier = ').append_22ad7x_k$(modifier).append_22ad7x_k$(',\n').append_22ad7x_k$($ind).append_22ad7x_k$(')\n');
        break;
      default:
        b.append_22ad7x_k$($ind).append_22ad7x_k$('Box(\n').append_22ad7x_k$($ind).append_22ad7x_k$('    ').append_22ad7x_k$(modifier).append_22ad7x_k$(',\n').append_22ad7x_k$($ind).append_22ad7x_k$(')\n');
        break;
    }
    return b.toString();
  }
  function ComposeCode$functionName$lambda(it) {
    // Inline function 'kotlin.text.replaceFirstChar' call
    var tmp;
    // Inline function 'kotlin.text.isNotEmpty' call
    if (charSequenceLength(it) > 0) {
      // Inline function 'kotlin.text.uppercase' call
      var this_0 = charSequenceGet(it, 0);
      // Inline function 'kotlin.js.asDynamic' call
      // Inline function 'kotlin.js.unsafeCast' call
      var tmp$ret$4 = toString(this_0).toUpperCase();
      var tmp_0 = toString_1(tmp$ret$4);
      // Inline function 'kotlin.text.substring' call
      // Inline function 'kotlin.js.asDynamic' call
      tmp = tmp_0 + it.substring(1);
    } else {
      tmp = it;
    }
    return tmp;
  }
  function ComposeCode$pascal$lambda(it) {
    // Inline function 'kotlin.text.replaceFirstChar' call
    var tmp;
    // Inline function 'kotlin.text.isNotEmpty' call
    if (charSequenceLength(it) > 0) {
      // Inline function 'kotlin.text.uppercase' call
      var this_0 = charSequenceGet(it, 0);
      // Inline function 'kotlin.js.asDynamic' call
      // Inline function 'kotlin.js.unsafeCast' call
      var tmp$ret$4 = toString(this_0).toUpperCase();
      var tmp_0 = toString_1(tmp$ret$4);
      // Inline function 'kotlin.text.substring' call
      // Inline function 'kotlin.js.asDynamic' call
      tmp = tmp_0 + it.substring(1);
    } else {
      tmp = it;
    }
    return tmp;
  }
  function ComposeCode$emitMaterial$lambda($k) {
    return function ($this$call) {
      $this$call.a_p9d5m1_k$($k.text_chy86p_k$(0, 'Button'));
      return Unit_instance;
    };
  }
  function ComposeCode$emitMaterial$lambda_0($k, $c) {
    return function ($this$call) {
      $this$call.a_p9d5m1_k$(iconCall$default(ComposeCode_getInstance(), firstOrNull($k.icons_1), $c, 'Icons.Filled.Add'));
      return Unit_instance;
    };
  }
  function ComposeCode$emitMaterial$lambda_1($k, $c) {
    return function ($this$call) {
      $this$call.a_p9d5m1_k$(iconCall$default(ComposeCode_getInstance(), firstOrNull($k.icons_1), $c, 'Icons.Filled.Add'));
      return Unit_instance;
    };
  }
  function ComposeCode$emitMaterial$lambda_2($k) {
    return function ($this$call) {
      $this$call.a_p9d5m1_k$($k.text_chy86p_k$(0, 'Create'));
      return Unit_instance;
    };
  }
  function ComposeCode$emitMaterial$lambda_3($this$call) {
    return Unit_instance;
  }
  function ComposeCode$emitMaterial$lambda_4($k) {
    return function ($this$call) {
      $this$call.a_p9d5m1_k$($k.text_chy86p_k$(0, '3'));
      return Unit_instance;
    };
  }
  function ComposeCode$emitMaterial$lambda_5($left, $c) {
    return function ($this$slot) {
      $this$slot.a_p9d5m1_k$('IconButton(onClick = { }) { ' + iconCall$default(ComposeCode_getInstance(), firstOrNull($left), $c, 'Icons.Filled.Menu') + ' }');
      return Unit_instance;
    };
  }
  function ComposeCode$emitMaterial$lambda_6($right, $c) {
    return function ($this$slot) {
      var _iterator__ex2g4s = $right.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var ic = _iterator__ex2g4s.next_20eer_k$();
        $this$slot.a_p9d5m1_k$('IconButton(onClick = { }) { ' + iconCall$default(ComposeCode_getInstance(), ic, $c, 'Icons.Filled.Check') + ' }');
      }
      return Unit_instance;
    };
  }
  function ComposeCode$emitMaterial$lambda_7($k) {
    return function ($this$slot) {
      $this$slot.a_p9d5m1_k$('Column {');
      $this$slot.inc_ry5d6a_k$();
      var inductionVariable = 1;
      var last = $k.texts_1.get_size_woubt6_k$();
      var tmp;
      if (inductionVariable < last) {
        do {
          var i = inductionVariable;
          inductionVariable = inductionVariable + 1 | 0;
          $this$slot.a_p9d5m1_k$($k.text$default_p2kv6r_k$(i));
        }
         while (inductionVariable < last);
        tmp = Unit_instance;
      }
      $this$slot.dec_msx87i_k$();
      $this$slot.a_p9d5m1_k$('}');
      return Unit_instance;
    };
  }
  function ComposeCode$emitMaterial$lambda_8($avatar) {
    return function ($this$slot) {
      $this$slot.a_p9d5m1_k$('Box(Modifier.size(' + dp(ComposeCode_getInstance(), $avatar.w_1) + ', ' + dp(ComposeCode_getInstance(), $avatar.h_1) + ').background(' + colorExpr(ComposeCode_getInstance(), $avatar.fill_1, $avatar.fillToken_1) + ', CircleShape))');
      return Unit_instance;
    };
  }
  function ComposeCode$emitMaterial$lambda_9($st) {
    return function ($this$slot) {
      $this$slot.a_p9d5m1_k$('Checkbox(checked = ' + $st + ', onCheckedChange = { ' + $st + ' = it })');
      return Unit_instance;
    };
  }
  function ComposeCode$emitMaterial$lambda_10($st) {
    return function ($this$slot) {
      $this$slot.a_p9d5m1_k$('Switch(checked = ' + $st + ', onCheckedChange = { ' + $st + ' = it })');
      return Unit_instance;
    };
  }
  function ComposeCode$emitMaterial$lambda_11($k) {
    return function ($this$slot) {
      $this$slot.a_p9d5m1_k$('TextButton(onClick = { }) { ' + $k.text$default_p2kv6r_k$(1) + ' }');
      return Unit_instance;
    };
  }
  function ComposeCode$emitCard$lambda($k, $c, $box) {
    return function ($this$call) {
      innerLayers(ComposeCode_getInstance(), $k, $c, $this$call, $box);
      return Unit_instance;
    };
  }
  function ComposeCode$emitSurface$lambda($k, $c, $box) {
    return function ($this$call) {
      innerLayers(ComposeCode_getInstance(), $k, $c, $this$call, $box);
      return Unit_instance;
    };
  }
  function ComposeCode() {
    ComposeCode_instance = this;
    this.tokenNames_1 = listOf_0(['primary', 'onPrimary', 'primaryContainer', 'onPrimaryContainer', 'secondary', 'secondaryContainer', 'onSecondaryContainer', 'tertiary', 'tertiaryContainer', 'onTertiaryContainer', 'error', 'errorContainer', 'surface', 'surfaceContainerLow', 'surfaceContainer', 'surfaceContainerHigh', 'surfaceContainerHighest', 'onSurface', 'onSurfaceVariant', 'outline', 'outlineVariant', 'inverseSurface']);
    this.materialShapes_1 = mapOf([to('circle', 'Circle'), to('square', 'Square'), to('slanted', 'Slanted'), to('arch', 'Arch'), to('fan', 'Fan'), to('arrow', 'Arrow'), to('semicircle', 'SemiCircle'), to('oval', 'Oval'), to('pill', 'Pill'), to('triangle', 'Triangle'), to('diamond', 'Diamond'), to('clamshell', 'ClamShell'), to('pentagon', 'Pentagon'), to('gem', 'Gem'), to('cookie-4', 'Cookie4Sided'), to('cookie-6', 'Cookie6Sided'), to('cookie-7', 'Cookie7Sided'), to('cookie-9', 'Cookie9Sided'), to('cookie-12', 'Cookie12Sided'), to('sunny', 'Sunny'), to('very-sunny', 'VerySunny'), to('burst', 'Burst'), to('soft-burst', 'SoftBurst'), to('boom', 'Boom'), to('soft-boom', 'SoftBoom'), to('clover-4', 'Clover4Leaf'), to('clover-8', 'Clover8Leaf'), to('flower', 'Flower'), to('puffy', 'Puffy'), to('puffy-diamond', 'PuffyDiamond'), to('ghostish', 'Ghostish'), to('bun', 'Bun'), to('heart', 'Heart'), to('pixel-circle', 'PixelCircle'), to('pixel-triangle', 'PixelTriangle')]);
    this.material3Names_1 = listOf_0(['Button', 'FilledTonalButton', 'OutlinedButton', 'ElevatedButton', 'TextButton', 'IconButton', 'FilledIconButton', 'FilledTonalIconButton', 'OutlinedIconButton', 'FloatingActionButton', 'SmallFloatingActionButton', 'LargeFloatingActionButton', 'ExtendedFloatingActionButton', 'Card', 'ElevatedCard', 'OutlinedCard', 'CardDefaults', 'Surface', 'Text', 'Icon', 'FilterChip', 'FilterChipDefaults', 'AssistChip', 'AssistChipDefaults', 'InputChip', 'InputChipDefaults', 'Switch', 'SwitchDefaults', 'Checkbox', 'RadioButton', 'Slider', 'LinearProgressIndicator', 'CircularProgressIndicator', 'OutlinedTextField', 'TextField', 'TextFieldDefaults', 'HorizontalDivider', 'Badge', 'TabRow', 'Tab', 'SingleChoiceSegmentedButtonRow', 'SegmentedButton', 'SegmentedButtonDefaults', 'NavigationBar', 'NavigationBarItem', 'NavigationRail', 'NavigationRailItem', 'BottomAppBar', 'TopAppBar', 'CenterAlignedTopAppBar', 'MediumTopAppBar', 'LargeTopAppBar', 'TopAppBarDefaults', 'ListItem', 'Snackbar', 'MaterialTheme', 'MaterialShapes']);
    this.experimentalNames_1 = listOf_0(['TopAppBar', 'CenterAlignedTopAppBar', 'MediumTopAppBar', 'LargeTopAppBar', 'TopAppBarDefaults', 'SingleChoiceSegmentedButtonRow', 'SegmentedButton', 'SegmentedButtonDefaults']);
    this.simpleImports_1 = listOf_0([to(Regex_init_$Create$('\\bModifier\\b'), 'androidx.compose.ui.Modifier'), to(Regex_init_$Create$('\\.offset\\('), 'androidx.compose.foundation.layout.offset'), to(Regex_init_$Create$('\\.size\\('), 'androidx.compose.foundation.layout.size'), to(Regex_init_$Create$('\\.width\\('), 'androidx.compose.foundation.layout.width'), to(Regex_init_$Create$('\\bfillMaxSize\\('), 'androidx.compose.foundation.layout.fillMaxSize'), to(Regex_init_$Create$('\\bBox\\('), 'androidx.compose.foundation.layout.Box'), to(Regex_init_$Create$('\\bColumn\\b'), 'androidx.compose.foundation.layout.Column'), to(Regex_init_$Create$('\\bWindowInsets\\('), 'androidx.compose.foundation.layout.WindowInsets'), to(Regex_init_$Create$('\\.background\\('), 'androidx.compose.foundation.background'), to(Regex_init_$Create$('\\.border\\('), 'androidx.compose.foundation.border'), to(Regex_init_$Create$('\\bBorderStroke\\('), 'androidx.compose.foundation.BorderStroke'), to(Regex_init_$Create$('\\.clip\\('), 'androidx.compose.ui.draw.clip'), to(Regex_init_$Create$('\\.rotate\\('), 'androidx.compose.ui.draw.rotate'), to(Regex_init_$Create$('\\.alpha\\('), 'androidx.compose.ui.draw.alpha'), to(Regex_init_$Create$('\\.shadow\\('), 'androidx.compose.ui.draw.shadow'), to(Regex_init_$Create$('\\bColor[.(]'), 'androidx.compose.ui.graphics.Color'), to(Regex_init_$Create$('\\bRectangleShape\\b'), 'androidx.compose.ui.graphics.RectangleShape'), to(Regex_init_$Create$('\\bRoundedCornerShape\\('), 'androidx.compose.foundation.shape.RoundedCornerShape'), to(Regex_init_$Create$('\\bCircleShape\\b'), 'androidx.compose.foundation.shape.CircleShape'), to(Regex_init_$Create$('\\bGenericShape\\b'), 'androidx.compose.foundation.shape.GenericShape'), to(Regex_init_$Create$('\\bRect\\('), 'androidx.compose.ui.geometry.Rect'), to(Regex_init_$Create$('\\bOffset\\b'), 'androidx.compose.ui.geometry.Offset'), to(Regex_init_$Create$('\\bSize\\b'), 'androidx.compose.ui.geometry.Size'), to(Regex_init_$Create$('\\bBrush\\b'), 'androidx.compose.ui.graphics.Brush'), to(Regex_init_$Create$('\\bShaderBrush\\b'), 'androidx.compose.ui.graphics.ShaderBrush'), to(Regex_init_$Create$('\\bShader\\b'), 'androidx.compose.ui.graphics.Shader'), to(Regex_init_$Create$('\\bLinearGradientShader\\b'), 'androidx.compose.ui.graphics.LinearGradientShader'), to(Regex_init_$Create$('\\bSolidColor\\b'), 'androidx.compose.ui.graphics.SolidColor'), to(Regex_init_$Create$('\\bPath\\b'), 'androidx.compose.ui.graphics.Path'), to(Regex_init_$Create$('\\bPathFillType\\b'), 'androidx.compose.ui.graphics.PathFillType'), to(Regex_init_$Create$('\\bImageVector\\b'), 'androidx.compose.ui.graphics.vector.ImageVector'), to(Regex_init_$Create$('\\bPathParser\\b'), 'androidx.compose.ui.graphics.vector.PathParser'), to(Regex_init_$Create$('\\.dp\\b'), 'androidx.compose.ui.unit.dp'), to(Regex_init_$Create$('\\.sp\\b'), 'androidx.compose.ui.unit.sp'), to(Regex_init_$Create$('\\bFontWeight\\b'), 'androidx.compose.ui.text.font.FontWeight'), to(Regex_init_$Create$('\\bImage\\('), 'androidx.compose.foundation.Image'), to(Regex_init_$Create$('\\bpainterResource\\('), 'androidx.compose.ui.res.painterResource'), to(Regex_init_$Create$('\\bContentScale\\b'), 'androidx.compose.ui.layout.ContentScale'), to(Regex_init_$Create$('\\bComposable\\b'), 'androidx.compose.runtime.Composable'), to(Regex_init_$Create$('\\bremember\\b'), 'androidx.compose.runtime.remember'), to(Regex_init_$Create$('\\bmutableStateOf\\b'), 'androidx.compose.runtime.mutableStateOf'), to(Regex_init_$Create$('\\b(val|var) \\w+ by '), 'androidx.compose.runtime.getValue'), to(Regex_init_$Create$('\\.blur\\('), 'androidx.compose.ui.draw.blur'), to(Regex_init_$Create$('\\bBlurredEdgeTreatment\\b'), 'androidx.compose.ui.draw.BlurredEdgeTreatment'), to(Regex_init_$Create$('\\.clickable\\('), 'androidx.compose.foundation.clickable'), to(Regex_init_$Create$('\\bLocalUriHandler\\b'), 'androidx.compose.ui.platform.LocalUriHandler'), to(Regex_init_$Create$('\\bMutableInteractionSource\\b'), 'androidx.compose.foundation.interaction.MutableInteractionSource'), to(Regex_init_$Create$('\\bcollectIsPressedAsState\\b'), 'androidx.compose.foundation.interaction.collectIsPressedAsState'), to(Regex_init_$Create$('\\banimateDpAsState\\b'), 'androidx.compose.animation.core.animateDpAsState'), to(Regex_init_$Create$('\\bSpring\\.'), 'androidx.compose.animation.core.Spring'), to(Regex_init_$Create$('\\bspring\\('), 'androidx.compose.animation.core.spring'), to(Regex_init_$Create$('\\bvar \\w+ by remember'), 'androidx.compose.runtime.setValue'), to(Regex_init_$Create$('\\.toShape\\('), 'androidx.compose.material3.toShape'), to(Regex_init_$Create$('\\bRoundedPolygon\\b'), 'androidx.graphics.shapes.RoundedPolygon'), to(Regex_init_$Create$('\\.star\\('), 'androidx.graphics.shapes.star'), to(Regex_init_$Create$('\\b(cos|sin|abs)\\('), '')]);
    this.PATH_HELPER_1 = '/** \u041A\u043E\u043D\u0442\u0443\u0440 \u0432 \u0435\u0434\u0438\u043D\u0438\u0447\u043D\u043E\u043C \u043A\u0432\u0430\u0434\u0440\u0430\u0442\u0435 ("M x y L x y C ... Z") -> Path \u0440\u0430\u0437\u043C\u0435\u0440\u0430 w x h. */\nprivate fun vexelPath(data: String, w: Float, h: Float): Path {\n    val p = Path()\n    val t = data.split(\' \').filter { it.isNotEmpty() }\n    var i = 0\n    while (i < t.size) {\n        when (t[i]) {\n            "M" -> { p.moveTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h); i += 3 }\n            "L" -> { p.lineTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h); i += 3 }\n            "Q" -> { p.quadraticTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h, t[i + 3].toFloat() * w, t[i + 4].toFloat() * h); i += 5 }\n            "C" -> { p.cubicTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h, t[i + 3].toFloat() * w, t[i + 4].toFloat() * h, t[i + 5].toFloat() * w, t[i + 6].toFloat() * h); i += 7 }\n            "Z" -> { p.close(); i += 1 }\n            else -> i += 1\n        }\n    }\n    return p\n}\n';
    this.ANGLE_HELPER_1 = '/** \u041B\u0438\u043D\u0435\u0439\u043D\u044B\u0439 \u0433\u0440\u0430\u0434\u0438\u0435\u043D\u0442 \u043F\u043E\u0434 \u043B\u044E\u0431\u044B\u043C \u0443\u0433\u043B\u043E\u043C (0 - \u0441\u043B\u0435\u0432\u0430 \u043D\u0430\u043F\u0440\u0430\u0432\u043E, 90 - \u0441\u0432\u0435\u0440\u0445\u0443 \u0432\u043D\u0438\u0437) \u043D\u0430 \u0432\u0441\u044E \u043F\u043B\u043E\u0449\u0430\u0434\u044C \u0441\u043B\u043E\u044F. */\nprivate fun angledGradient(angle: Float, vararg colors: Color): Brush = object : ShaderBrush() {\n    override fun createShader(size: Size): Shader {\n        val r = Math.toRadians(angle.toDouble())\n        val dx = cos(r).toFloat()\n        val dy = sin(r).toFloat()\n        val half = (abs(size.width * dx) + abs(size.height * dy)) / 2f\n        val cx = size.width / 2f\n        val cy = size.height / 2f\n        return LinearGradientShader(Offset(cx - dx * half, cy - dy * half), Offset(cx + dx * half, cy + dy * half), colors.toList())\n    }\n}\n';
  }
  protoOf(ComposeCode).functionName_64af4n_k$ = function (title) {
    // Inline function 'kotlin.text.split' call
    // Inline function 'kotlin.collections.filter' call
    var tmp0 = Regex_init_$Create$('[^A-Za-z0-9]+').split_p7ck23_k$(title, 0);
    // Inline function 'kotlin.collections.filterTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      // Inline function 'kotlin.text.isNotEmpty' call
      if (charSequenceLength(element) > 0) {
        destination.add_utx5q5_k$(element);
      }
    }
    var words = destination;
    var name = joinToString_0(words, '', VOID, VOID, VOID, VOID, ComposeCode$functionName$lambda);
    var tmp;
    var tmp_0;
    // Inline function 'kotlin.text.isEmpty' call
    if (charSequenceLength(name) === 0) {
      tmp_0 = true;
    } else {
      tmp_0 = isDigit(charSequenceGet(name, 0));
    }
    if (tmp_0) {
      tmp = 'Screen' + name;
    } else {
      tmp = name;
    }
    return tmp;
  };
  protoOf(ComposeCode).imageResName_9jbftv_k$ = function (asset) {
    // Inline function 'kotlin.text.lowercase' call
    // Inline function 'kotlin.js.asDynamic' call
    var tmp1 = substringBeforeLast(asset, _Char___init__impl__6a9atx(46)).toLowerCase();
    // Inline function 'kotlin.text.replace' call
    var base = Regex_init_$Create$('[^a-z0-9_]').replace_1ix0wf_k$(tmp1, '_');
    var tmp;
    var tmp_0;
    // Inline function 'kotlin.text.isEmpty' call
    if (charSequenceLength(base) === 0) {
      tmp_0 = true;
    } else {
      tmp_0 = isDigit(charSequenceGet(base, 0));
    }
    if (tmp_0) {
      tmp = 'img_' + base;
    } else {
      tmp = base;
    }
    return tmp;
  };
  protoOf(ComposeCode).generate_juvjz2_k$ = function (p, nodes, title, crop, opts) {
    var c = new Ctx();
    c.opts_1 = opts;
    var _iterator__ex2g4s = nodes.iterator_jk1svi_k$();
    $l$loop_0: while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var a = _iterator__ex2g4s.next_20eer_k$();
      if (!startsWith(a.action_1, 'toggle:'))
        continue $l$loop_0;
      var tmp$ret$2;
      $l$block: {
        // Inline function 'kotlin.collections.firstOrNull' call
        var _iterator__ex2g4s_0 = nodes.iterator_jk1svi_k$();
        while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
          var element = _iterator__ex2g4s_0.next_20eer_k$();
          var tmp;
          if (element.id_1 === substringAfter(a.action_1, _Char___init__impl__6a9atx(58))) {
            // Inline function 'kotlin.text.isEmpty' call
            var this_0 = element.group_1;
            tmp = charSequenceLength(this_0) === 0;
          } else {
            tmp = false;
          }
          if (tmp) {
            tmp$ret$2 = element;
            break $l$block;
          }
        }
        tmp$ret$2 = null;
      }
      var tmp0_elvis_lhs = tmp$ret$2;
      var tmp_0;
      if (tmp0_elvis_lhs == null) {
        continue $l$loop_0;
      } else {
        tmp_0 = tmp0_elvis_lhs;
      }
      var t = tmp_0;
      var tmp2 = c.toggles_1;
      // Inline function 'kotlin.collections.contains' call
      // Inline function 'kotlin.collections.containsKey' call
      var key = t.id_1;
      if (!(isInterface(tmp2, KtMap) ? tmp2 : THROW_CCE()).containsKey_aw81wo_k$(key)) {
        var tmp4 = c.toggles_1;
        var tmp5 = t.id_1;
        // Inline function 'kotlin.collections.set' call
        var value = c.state_xyteun_k$('show', t.visible_1.toString());
        tmp4.put_4fpzoq_k$(tmp5, value);
      }
    }
    var tmp2_elvis_lhs = crop == null ? null : crop.l_1;
    var ox = tmp2_elvis_lhs == null ? 0.0 : tmp2_elvis_lhs;
    var tmp4_elvis_lhs = crop == null ? null : crop.t_1;
    var oy = tmp4_elvis_lhs == null ? 0.0 : tmp4_elvis_lhs;
    var tmp6_elvis_lhs = crop == null ? null : crop.get_w_1mhr66_k$();
    var rootW = tmp6_elvis_lhs == null ? p.width_1 : tmp6_elvis_lhs;
    var tmp8_elvis_lhs = crop == null ? null : crop.get_h_1mhr5r_k$();
    var rootH = tmp8_elvis_lhs == null ? p.height_1 : tmp8_elvis_lhs;
    var body = new Src(2);
    // Inline function 'kotlin.collections.filter' call
    // Inline function 'kotlin.collections.filterTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s_1 = nodes.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
      var element_0 = _iterator__ex2g4s_1.next_20eer_k$();
      // Inline function 'kotlin.text.isNotEmpty' call
      var this_1 = element_0.group_1;
      if (charSequenceLength(this_1) > 0) {
        destination.add_utx5q5_k$(element_0);
      }
    }
    // Inline function 'kotlin.collections.groupBy' call
    // Inline function 'kotlin.collections.groupByTo' call
    var destination_0 = LinkedHashMap_init_$Create$();
    var _iterator__ex2g4s_2 = destination.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_2.hasNext_bitz1p_k$()) {
      var element_1 = _iterator__ex2g4s_2.next_20eer_k$();
      var key_0 = element_1.group_1;
      // Inline function 'kotlin.collections.getOrPut' call
      var value_0 = destination_0.get_wei43m_k$(key_0);
      var tmp_1;
      if (value_0 == null) {
        var answer = ArrayList_init_$Create$();
        destination_0.put_4fpzoq_k$(key_0, answer);
        tmp_1 = answer;
      } else {
        tmp_1 = value_0;
      }
      var list = tmp_1;
      list.add_utx5q5_k$(element_1);
    }
    var byGroup = destination_0;
    var recognised = HashMap_init_$Create$();
    var done = HashSet_init_$Create$();
    var iterator = nodes.iterator_jk1svi_k$();
    var index = 0;
    $l$loop_3: while (iterator.hasNext_bitz1p_k$()) {
      var idx = index;
      index = index + 1 | 0;
      var n = iterator.next_20eer_k$();
      // Inline function 'kotlin.text.isNotEmpty' call
      var this_2 = n.group_1;
      if (charSequenceLength(this_2) > 0) {
        // Inline function 'kotlin.collections.getOrPut' call
        var key_1 = n.group_1;
        var value_1 = recognised.get_wei43m_k$(key_1);
        var tmp_2;
        if (value_1 == null) {
          var tmp_3 = ComposeCode_getInstance();
          // Inline function 'kotlin.collections.orEmpty' call
          var tmp0_elvis_lhs_0 = byGroup.get_wei43m_k$(n.group_1);
          var tmp$ret$16 = tmp0_elvis_lhs_0 == null ? emptyList() : tmp0_elvis_lhs_0;
          var answer_0 = recognise(tmp_3, n.group_1, tmp$ret$16, ox, oy);
          recognised.put_4fpzoq_k$(key_1, answer_0);
          tmp_2 = answer_0;
        } else {
          tmp_2 = value_1;
        }
        var comp = tmp_2;
        if (!(comp == null)) {
          if (!done.add_utx5q5_k$(n.group_1))
            continue $l$loop_3;
          emitComponent(this, comp, c, body);
          continue $l$loop_3;
        }
      }
      var tog = c.toggles_1.get_wei43m_k$(n.id_1);
      if (n.get_isMask_ew1zy7_k$() || (!n.visible_1 && tog == null))
        continue $l$loop_3;
      var tmp9_safe_receiver = getOrNull(nodes, idx + 1 | 0);
      var tmp_4;
      if (tmp9_safe_receiver == null) {
        tmp_4 = null;
      } else {
        // Inline function 'kotlin.takeIf' call
        var tmp_5;
        if (tmp9_safe_receiver.get_isMask_ew1zy7_k$() && tmp9_safe_receiver.visible_1) {
          tmp_5 = tmp9_safe_receiver;
        } else {
          tmp_5 = null;
        }
        tmp_4 = tmp_5;
      }
      var mask = tmp_4;
      if (!(tog == null)) {
        var inner = layer(this, n, c, '            ', ox, oy, mask);
        body.raw_h13x4y_k$('        if (' + tog + ') {\n' + inner + '        }\n');
      } else {
        body.raw_h13x4y_k$(layer(this, n, c, '        ', ox, oy, mask));
      }
    }
    var rootBg = !(crop == null) ? null : colorExpr(this, p.background_1, p.bgToken_1);
    var tmp11_elvis_lhs = opts == null ? null : opts.fnName_1;
    var fnName = tmp11_elvis_lhs == null ? this.functionName_64af4n_k$(title) : tmp11_elvis_lhs;
    var main = StringBuilder_init_$Create$_0();
    main.append_22ad7x_k$('@Composable\nfun ').append_22ad7x_k$(fnName).append_22ad7x_k$('(modifier: Modifier = Modifier');
    if (!(opts == null)) {
      main.append_22ad7x_k$(', onGoTo: (Int) -> Unit = {}, onBack: () -> Unit = {}');
    }
    main.append_22ad7x_k$(') {\n');
    var _iterator__ex2g4s_3 = c.states_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_3.hasNext_bitz1p_k$()) {
      var st = _iterator__ex2g4s_3.next_20eer_k$();
      main.append_22ad7x_k$('    ').append_22ad7x_k$(st).append_58al37_k$(_Char___init__impl__6a9atx(10));
    }
    // Inline function 'kotlin.collections.isNotEmpty' call
    if (!c.states_1.isEmpty_y1axqb_k$()) {
      main.append_58al37_k$(_Char___init__impl__6a9atx(10));
    }
    main.append_22ad7x_k$('    Box(\n        modifier\n            .size(' + dp(this, rootW) + ', ' + dp(this, rootH) + ')');
    if (!(rootBg == null)) {
      main.append_22ad7x_k$('\n            .background(' + rootBg + ')');
    }
    main.append_22ad7x_k$('\n    ) {\n');
    main.append_jgojdo_k$(body.sb_1);
    main.append_22ad7x_k$('    }\n}\n');
    var parts = ArrayList_init_$Create$();
    // Inline function 'kotlin.collections.plusAssign' call
    var element_2 = optIn(this, main.toString()) + main.toString();
    parts.add_utx5q5_k$(element_2);
    var _iterator__ex2g4s_4 = c.fallbacks_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_4.hasNext_bitz1p_k$()) {
      var fb = _iterator__ex2g4s_4.next_20eer_k$();
      // Inline function 'kotlin.collections.plusAssign' call
      var element_3 = optIn(this, fb) + fb;
      parts.add_utx5q5_k$(element_3);
    }
    var tail = StringBuilder_init_$Create$_0();
    var tmp_6;
    // Inline function 'kotlin.collections.isNotEmpty' call
    if (!c.pathSrc_1.isEmpty_y1axqb_k$()) {
      tmp_6 = true;
    } else {
      // Inline function 'kotlin.collections.isNotEmpty' call
      tmp_6 = !c.vectorSrc_1.isEmpty_y1axqb_k$();
    }
    if (tmp_6) {
      tail.append_22ad7x_k$('// ---- shapes and icons used above\n\n');
    }
    var _iterator__ex2g4s_5 = c.pathSrc_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_5.hasNext_bitz1p_k$()) {
      var x = _iterator__ex2g4s_5.next_20eer_k$();
      tail.append_22ad7x_k$(x).append_58al37_k$(_Char___init__impl__6a9atx(10));
    }
    var _iterator__ex2g4s_6 = c.vectorSrc_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_6.hasNext_bitz1p_k$()) {
      var x_0 = _iterator__ex2g4s_6.next_20eer_k$();
      tail.append_22ad7x_k$(x_0).append_58al37_k$(_Char___init__impl__6a9atx(10));
    }
    if (c.needPathHelper_1) {
      tail.append_22ad7x_k$('/** \u041A\u043E\u043D\u0442\u0443\u0440 \u0432 \u0435\u0434\u0438\u043D\u0438\u0447\u043D\u043E\u043C \u043A\u0432\u0430\u0434\u0440\u0430\u0442\u0435 ("M x y L x y C ... Z") -> Path \u0440\u0430\u0437\u043C\u0435\u0440\u0430 w x h. */\nprivate fun vexelPath(data: String, w: Float, h: Float): Path {\n    val p = Path()\n    val t = data.split(\' \').filter { it.isNotEmpty() }\n    var i = 0\n    while (i < t.size) {\n        when (t[i]) {\n            "M" -> { p.moveTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h); i += 3 }\n            "L" -> { p.lineTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h); i += 3 }\n            "Q" -> { p.quadraticTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h, t[i + 3].toFloat() * w, t[i + 4].toFloat() * h); i += 5 }\n            "C" -> { p.cubicTo(t[i + 1].toFloat() * w, t[i + 2].toFloat() * h, t[i + 3].toFloat() * w, t[i + 4].toFloat() * h, t[i + 5].toFloat() * w, t[i + 6].toFloat() * h); i += 7 }\n            "Z" -> { p.close(); i += 1 }\n            else -> i += 1\n        }\n    }\n    return p\n}\n').append_58al37_k$(_Char___init__impl__6a9atx(10));
    }
    if (c.needAngle_1) {
      tail.append_22ad7x_k$('/** \u041B\u0438\u043D\u0435\u0439\u043D\u044B\u0439 \u0433\u0440\u0430\u0434\u0438\u0435\u043D\u0442 \u043F\u043E\u0434 \u043B\u044E\u0431\u044B\u043C \u0443\u0433\u043B\u043E\u043C (0 - \u0441\u043B\u0435\u0432\u0430 \u043D\u0430\u043F\u0440\u0430\u0432\u043E, 90 - \u0441\u0432\u0435\u0440\u0445\u0443 \u0432\u043D\u0438\u0437) \u043D\u0430 \u0432\u0441\u044E \u043F\u043B\u043E\u0449\u0430\u0434\u044C \u0441\u043B\u043E\u044F. */\nprivate fun angledGradient(angle: Float, vararg colors: Color): Brush = object : ShaderBrush() {\n    override fun createShader(size: Size): Shader {\n        val r = Math.toRadians(angle.toDouble())\n        val dx = cos(r).toFloat()\n        val dy = sin(r).toFloat()\n        val half = (abs(size.width * dx) + abs(size.height * dy)) / 2f\n        val cx = size.width / 2f\n        val cy = size.height / 2f\n        return LinearGradientShader(Offset(cx - dx * half, cy - dy * half), Offset(cx + dx * half, cy + dy * half), colors.toList())\n    }\n}\n').append_58al37_k$(_Char___init__impl__6a9atx(10));
    }
    var tmp_7 = joinToString_0(parts, '\n');
    var tmp_8;
    // Inline function 'kotlin.text.isNotEmpty' call
    if (charSequenceLength(tail) > 0) {
      tmp_8 = '\n' + tail.toString();
    } else {
      tmp_8 = '';
    }
    var code = tmp_7 + tmp_8;
    var out = StringBuilder_init_$Create$_0();
    out.append_22ad7x_k$('// Generated by Vexel. Components from the Components tab are real Material 3 widgets (state is kept with remember);\n');
    out.append_22ad7x_k$('// other layers are placed by coordinates like on the canvas. Colors go through MaterialTheme.colorScheme.\n');
    if (c.usesImage_1 && opts == null) {
      out.append_22ad7x_k$('// Pictures use R.drawable: add `import your.app.package.R` and copy the files into res/drawable.\n');
    }
    out.append_58al37_k$(_Char___init__impl__6a9atx(10));
    if (!(opts == null)) {
      out.append_22ad7x_k$('package ').append_22ad7x_k$(opts.pkg_1).append_22ad7x_k$('\n\n');
    }
    var imps = toMutableList_0(importsFor(this, code));
    if (!(opts == null) && c.usesImage_1) {
      // Inline function 'kotlin.collections.plusAssign' call
      var element_4 = opts.rPkg_1 + '.R';
      imps.add_utx5q5_k$(element_4);
    }
    var _iterator__ex2g4s_7 = sorted(imps).iterator_jk1svi_k$();
    while (_iterator__ex2g4s_7.hasNext_bitz1p_k$()) {
      var i = _iterator__ex2g4s_7.next_20eer_k$();
      out.append_22ad7x_k$('import ').append_22ad7x_k$(i).append_58al37_k$(_Char___init__impl__6a9atx(10));
    }
    out.append_58al37_k$(_Char___init__impl__6a9atx(10));
    out.append_22ad7x_k$(code);
    return out.toString();
  };
  protoOf(ComposeCode).generate$default_i4fm48_k$ = function (p, nodes, title, crop, opts, $super) {
    nodes = nodes === VOID ? p.nodes_1 : nodes;
    title = title === VOID ? p.name_1 : title;
    crop = crop === VOID ? null : crop;
    opts = opts === VOID ? null : opts;
    return $super === VOID ? this.generate_juvjz2_k$(p, nodes, title, crop, opts) : $super.generate_juvjz2_k$.call(this, p, nodes, title, crop, opts);
  };
  var ComposeCode_instance;
  function ComposeCode_getInstance() {
    if (ComposeCode_instance == null)
      new ComposeCode();
    return ComposeCode_instance;
  }
  function EchoParams(count, scaleStep, rotateStep, fade, contour, spread, jitter, seed) {
    count = count === VOID ? 4 : count;
    scaleStep = scaleStep === VOID ? 5.0 : scaleStep;
    rotateStep = rotateStep === VOID ? 3.0 : rotateStep;
    fade = fade === VOID ? 0.85 : fade;
    contour = contour === VOID ? true : contour;
    spread = spread === VOID ? 0.0 : spread;
    jitter = jitter === VOID ? 0.2 : jitter;
    seed = seed === VOID ? 7 : seed;
    this.count_1 = count;
    this.scaleStep_1 = scaleStep;
    this.rotateStep_1 = rotateStep;
    this.fade_1 = fade;
    this.contour_1 = contour;
    this.spread_1 = spread;
    this.jitter_1 = jitter;
    this.seed_1 = seed;
  }
  protoOf(EchoParams).toString = function () {
    return 'EchoParams(count=' + this.count_1 + ', scaleStep=' + this.scaleStep_1 + ', rotateStep=' + this.rotateStep_1 + ', fade=' + this.fade_1 + ', contour=' + this.contour_1 + ', spread=' + this.spread_1 + ', jitter=' + this.jitter_1 + ', seed=' + this.seed_1 + ')';
  };
  protoOf(EchoParams).hashCode = function () {
    var result = this.count_1;
    result = imul(result, 31) + getNumberHashCode(this.scaleStep_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.rotateStep_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.fade_1) | 0;
    result = imul(result, 31) + getBooleanHashCode(this.contour_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.spread_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.jitter_1) | 0;
    result = imul(result, 31) + this.seed_1 | 0;
    return result;
  };
  protoOf(EchoParams).equals = function (other) {
    if (this === other)
      return true;
    if (!(other instanceof EchoParams))
      return false;
    var tmp0_other_with_cast = other instanceof EchoParams ? other : THROW_CCE();
    if (!(this.count_1 === tmp0_other_with_cast.count_1))
      return false;
    if (!equals(this.scaleStep_1, tmp0_other_with_cast.scaleStep_1))
      return false;
    if (!equals(this.rotateStep_1, tmp0_other_with_cast.rotateStep_1))
      return false;
    if (!equals(this.fade_1, tmp0_other_with_cast.fade_1))
      return false;
    if (!(this.contour_1 === tmp0_other_with_cast.contour_1))
      return false;
    if (!equals(this.spread_1, tmp0_other_with_cast.spread_1))
      return false;
    if (!equals(this.jitter_1, tmp0_other_with_cast.jitter_1))
      return false;
    if (!(this.seed_1 === tmp0_other_with_cast.seed_1))
      return false;
    return true;
  };
  function copies$j(rnd, $p) {
    return (rnd.nextFloat_jqti5l_k$() * 2.0 - 1.0) * $p.jitter_1;
  }
  function Echo() {
  }
  protoOf(Echo).copies_ne07ek_k$ = function (src, p) {
    var rnd = new Random(toLong(p.seed_1));
    var n = coerceIn_0(p.count_1, 1, 40);
    var hasLine = src.strokeWidth_1 > 0.0 && !((src.stroke_1 >>> 24 | 0) === 0);
    var lineColor = hasLine ? src.stroke_1 : src.fill_1;
    var lineToken = hasLine ? src.strokeToken_1 : src.fillToken_1;
    var out = ArrayList_init_$Create$_0(n);
    var inductionVariable = 1;
    if (inductionVariable <= n)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var t = i / n;
        var f = coerceAtLeast(1.0 + p.scaleStep_1 / 100.0 * i + copies$j(rnd, p) * 0.25, 0.05);
        var w = src.w_1 * f;
        var h = src.h_1 * f;
        var dx = p.spread_1 * i * (1.0 + copies$j(rnd, p) * 0.5);
        var dy = p.spread_1 * i * copies$j(rnd, p) * 0.5;
        var tmp = src.rotation_1 + p.rotateStep_1 * i;
        var tmp_0 = copies$j(rnd, p);
        // Inline function 'kotlin.math.abs' call
        var x = p.rotateStep_1;
        var rot = tmp + tmp_0 * Math.abs(x) * 0.5;
        var op = coerceIn(src.opacity_1 * (1.0 - p.fade_1 * t) * (1.0 + copies$j(rnd, p) * 0.3), 0.04, 1.0);
        var line = (src.strokeWidth_1 > 0.0 ? src.strokeWidth_1 : 1.2) * (0.6 + rnd.nextFloat_jqti5l_k$() * 1.2);
        var tmp0_id = newId();
        var tmp1_name = src.name_1 + ' ' + i;
        var tmp2_x = src.get_cx_knto1u_k$() - w / 2.0 + dx;
        var tmp3_y = src.get_cy_knto1t_k$() - h / 2.0 + dy;
        var tmp4_corner = src.corner_1 * f;
        var tmp5_pressCorner = -1.0;
        var c = src.copy$default_q375vp_k$(tmp0_id, VOID, tmp1_name, tmp2_x, tmp3_y, w, h, rot, VOID, VOID, VOID, op, tmp4_corner, VOID, VOID, VOID, VOID, VOID, VOID, false, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 0.0, 0.0, tmp5_pressCorner, VOID, VOID, VOID, 0.0, VOID, VOID, VOID, false, '');
        if (p.contour_1) {
          c = c.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 0, lineColor, line, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, -1, lineToken, VOID, VOID, VOID, 0);
        }
        out.add_utx5q5_k$(c);
      }
       while (!(i === n));
    reverse(out);
    return out;
  };
  var Echo_instance;
  function Echo_getInstance() {
    return Echo_instance;
  }
  function rect($this, t, name, g, x, y, w, h, corner, fillTok, strokeTok, sw) {
    return Components_getInstance().rect_l2nxf2_k$(t, name, g, x, y, w, h, corner, fillTok, strokeTok, sw);
  }
  function rect$default($this, t, name, g, x, y, w, h, corner, fillTok, strokeTok, sw, $super) {
    strokeTok = strokeTok === VOID ? -1 : strokeTok;
    sw = sw === VOID ? 0.0 : sw;
    return rect($this, t, name, g, x, y, w, h, corner, fillTok, strokeTok, sw);
  }
  function oval($this, t, name, g, x, y, w, h, fillTok) {
    return Components_getInstance().oval_w4fudg_k$(t, name, g, x, y, w, h, fillTok);
  }
  function ring($this, t, name, g, x, y, d, strokeTok, sw) {
    return Components_getInstance().ring_233v8i_k$(t, name, g, x, y, d, strokeTok, sw);
  }
  function label($this, t, g, text, cx, cy, size, weight, tok) {
    return Components_getInstance().label_uq5396_k$(t, g, text, cx, cy, size, weight, tok);
  }
  function labelLeft($this, t, g, text, x, cy, size, weight, tok) {
    return Components_getInstance().labelLeft_4kh12r_k$(t, g, text, x, cy, size, weight, tok);
  }
  function shadowed($this, _this__u8e3s4, blur, dy) {
    return _this__u8e3s4.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, blur, VOID, dy, 855638016);
  }
  function plus_1($this, t, g, cx, cy, size, thick, tok) {
    return listOf_0([rect$default($this, t, tr('plus_h', []), g, cx - size / 2.0, cy - thick / 2.0, size, thick, thick / 2.0, tok), rect$default($this, t, tr('plus_v', []), g, cx - thick / 2.0, cy - size / 2.0, thick, size, thick / 2.0, tok)]);
  }
  function cross($this, t, g, cx, cy, size, tok) {
    return listOf_0([rect$default($this, t, tr('check_1', []), g, cx - size / 2.0, cy - 1.0, size, 2.0, 1.0, tok).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, 45.0), rect$default($this, t, tr('check_2', []), g, cx - size / 2.0, cy - 1.0, size, 2.0, 1.0, tok).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, -45.0)]);
  }
  function check($this, t, g, x, y, tok) {
    return listOf_0([rect$default($this, t, tr('check_1', []), g, x + 7.0, y + 12.0, 6.0, 2.0, 1.0, tok).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, 45.0), rect$default($this, t, tr('check_2', []), g, x + 9.5, y + 11.0, 9.0, 2.0, 1.0, tok).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, -50.0)]);
  }
  function chevronDown($this, t, g, cx, cy, tok) {
    return listOf_0([rect$default($this, t, tr('check_1', []), g, cx - 6.8, cy - 1.5, 8.0, 2.0, 1.0, tok).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, 45.0), rect$default($this, t, tr('check_2', []), g, cx - 1.2, cy - 1.5, 8.0, 2.0, 1.0, tok).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, -45.0)]);
  }
  function bars($this, t, g, x, cy, tok) {
    return IconNodes_instance.menu_8qjpfe_k$(t, g, x + 12.0, cy, tok);
  }
  function icon($this, t, g, name, cx, cy, tok, d) {
    return IconNodes_instance.icon$default_pzaq2z_k$(t, name, g, cx, cy, d, tok);
  }
  function icon$default($this, t, g, name, cx, cy, tok, d, $super) {
    d = d === VOID ? 24.0 : d;
    return icon($this, t, g, name, cx, cy, tok, d);
  }
  function strokePath($this, t, name, g, x, y, w, h, path, tok, sw) {
    var tmp0_id = newId();
    var tmp1_kind = NodeKind_PATH_getInstance();
    var tmp2_stroke = t.color$default_xk5c97_k$(tok);
    return new Node(tmp0_id, tmp1_kind, name, x, y, w, h, VOID, 0, tmp2_stroke, sw, VOID, VOID, VOID, VOID, VOID, VOID, g, VOID, VOID, VOID, path, VOID, VOID, VOID, VOID, tok);
  }
  function shape($this, t, name, g, shapeId, x, y, d, tok) {
    var tmp0_id = newId();
    var tmp1_kind = NodeKind_SHAPE_getInstance();
    var tmp2_fill = t.color$default_xk5c97_k$(tok);
    return new Node(tmp0_id, tmp1_kind, name, x, y, d, d, VOID, tmp2_fill, VOID, VOID, VOID, VOID, shapeId, VOID, VOID, VOID, g, VOID, VOID, true, VOID, VOID, VOID, VOID, tok);
  }
  function def($this, id, name, w, h, b) {
    return new ComponentDef(id, name, w, h, b);
  }
  function sizedButton($this, id, title, w, h, text, corner) {
    return def($this, id, title, w, h, ExpressiveComponents$sizedButton$lambda(w, h, corner, text));
  }
  function sizedButton$default($this, id, title, w, h, text, corner, $super) {
    corner = corner === VOID ? 9999.0 : corner;
    return sizedButton($this, id, title, w, h, text, corner);
  }
  function iconButton($this, id, title, fillTok, glyphTok, outline, corner) {
    return def($this, id, title, 40.0, 40.0, ExpressiveComponents$iconButton$lambda(corner, outline, fillTok, glyphTok));
  }
  function iconButton$default($this, id, title, fillTok, glyphTok, outline, corner, $super) {
    outline = outline === VOID ? false : outline;
    corner = corner === VOID ? 9999.0 : corner;
    return iconButton($this, id, title, fillTok, glyphTok, outline, corner);
  }
  function listRow($this, t, g, x, y, w, h, corner, bgTok, title, sub) {
    return listOf_0([rect$default($this, t, tr('container', []), g, x, y, w, h, corner, bgTok), oval($this, t, tr('avatar', []), g, x + 16.0, y + (h - 40.0) / 2.0, 40.0, 40.0, 2), labelLeft($this, t, g, title, x + 72.0, y + h / 2.0 - 10.0, 16.0, 500, 17), labelLeft($this, t, g, sub, x + 72.0, y + h / 2.0 + 12.0, 14.0, 400, 18)]);
  }
  function ExpressiveComponents$sizedButton$lambda($w, $h, $corner, $text) {
    return function (ox, oy, g, t) {
      return listOf_0([rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, $w, $h, $corner, 0), label(ExpressiveComponents_getInstance(), t, g, 'Button', ox + $w / 2.0, oy + $h / 2.0, $text, 600, 1)]);
    };
  }
  function ExpressiveComponents$iconButton$lambda($corner, $outline, $fillTok, $glyphTok) {
    return function (ox, oy, g, t) {
      // Inline function 'kotlin.collections.buildList' call
      // Inline function 'kotlin.collections.buildListInternal' call
      // Inline function 'kotlin.apply' call
      var this_0 = ArrayList_init_$Create$();
      this_0.add_utx5q5_k$(rect(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 40.0, 40.0, $corner, $outline ? -1 : $fillTok, $outline ? 19 : -1, $outline ? 1.0 : 0.0));
      this_0.addAll_h3ej1q_k$(plus_1(ExpressiveComponents_getInstance(), t, g, ox + 20.0, oy + 20.0, 16.0, 2.0, $glyphTok));
      return this_0.build_nmwvly_k$();
    };
  }
  function ExpressiveComponents$list$lambda(ox, oy, g, t) {
    return listOf_0([shadowed(ExpressiveComponents_getInstance(), rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 120.0, 40.0, 9999.0, 13), 6.0, 2.0), label(ExpressiveComponents_getInstance(), t, g, 'Button', ox + 60.0, oy + 20.0, 14.0, 500, 0)]);
  }
  function ExpressiveComponents$list$lambda_0(ox, oy, g, t) {
    return listOf_0([rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 100.0, 40.0, 9999.0, -1), label(ExpressiveComponents_getInstance(), t, g, 'Button', ox + 50.0, oy + 20.0, 14.0, 500, 0)]);
  }
  function ExpressiveComponents$list$lambda_1(ox, oy, g, t) {
    return listOf_0([rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 160.0, 56.0, 9999.0, 0).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 12.0), label(ExpressiveComponents_getInstance(), t, g, 'Button', ox + 80.0, oy + 28.0, 16.0, 600, 1)]);
  }
  function ExpressiveComponents$list$lambda_2(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 72.0, 72.0, 16.0, 0).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 36.0));
    this_0.addAll_h3ej1q_k$(plus_1(ExpressiveComponents_getInstance(), t, g, ox + 36.0, oy + 36.0, 24.0, 3.0, 1));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_3(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 72.0, 72.0, 36.0, 5).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 16.0));
    this_0.addAll_h3ej1q_k$(plus_1(ExpressiveComponents_getInstance(), t, g, ox + 36.0, oy + 36.0, 24.0, 3.0, 6));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_4(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, 'FAB', g, ox, oy, 40.0, 40.0, 12.0, 2));
    this_0.addAll_h3ej1q_k$(plus_1(ExpressiveComponents_getInstance(), t, g, ox + 20.0, oy + 20.0, 16.0, 2.0, 3));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_5(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(shadowed(ExpressiveComponents_getInstance(), rect$default(ExpressiveComponents_getInstance(), t, 'FAB', g, ox, oy, 96.0, 96.0, 28.0, 2), 10.0, 3.0));
    this_0.addAll_h3ej1q_k$(plus_1(ExpressiveComponents_getInstance(), t, g, ox + 48.0, oy + 48.0, 36.0, 4.0, 3));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_6(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    var inductionVariable = 0;
    if (inductionVariable < 3)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var y = oy + i * 64.0;
        this_0.add_utx5q5_k$(w(rect$default(ExpressiveComponents_getInstance(), t, tr('menu_item', []), g, ox, y, 200.0, 56.0, 9999.0, 2), 'reveal:item'));
        // Inline function 'kotlin.collections.map' call
        var this_1 = icon$default(ExpressiveComponents_getInstance(), t, g, listOf_0(['edit', 'share', 'bookmark']).get_c1px32_k$(i), ox + 32.0, y + 28.0, 3);
        // Inline function 'kotlin.collections.mapTo' call
        var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_1, 10));
        var _iterator__ex2g4s = this_1.iterator_jk1svi_k$();
        while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
          var item = _iterator__ex2g4s.next_20eer_k$();
          var tmp$ret$0 = w(item, 'reveal:item');
          destination.add_utx5q5_k$(tmp$ret$0);
        }
        this_0.addAll_h3ej1q_k$(destination);
        this_0.add_utx5q5_k$(w(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('menu_item', []), ox + 60.0, y + 28.0, 16.0, 500, 3), 'reveal:item'));
      }
       while (inductionVariable < 3);
    this_0.add_utx5q5_k$(shadowed(ExpressiveComponents_getInstance(), rect$default(ExpressiveComponents_getInstance(), t, 'FAB', g, ox + 144.0, oy + 192.0, 56.0, 56.0, 9999.0, 0), 8.0, 2.0));
    this_0.addAll_h3ej1q_k$(cross(ExpressiveComponents_getInstance(), t, g, ox + 172.0, oy + 220.0, 22.0, 1));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_7(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 102.0, 40.0, 9999.0, 0));
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox + 62.0, oy, 40.0, 40.0, 4.0, 0));
    this_0.add_utx5q5_k$(label(ExpressiveComponents_getInstance(), t, g, 'Save', ox + 48.0, oy + 20.0, 14.0, 500, 1));
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox + 104.0, oy, 48.0, 40.0, 9999.0, 0));
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox + 104.0, oy, 24.0, 40.0, 4.0, 0));
    this_0.addAll_h3ej1q_k$(chevronDown(ExpressiveComponents_getInstance(), t, g, ox + 128.0, oy + 21.0, 1));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_8(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 304.0, 40.0, 9999.0, 5));
    this_0.add_utx5q5_k$(w(rect$default(ExpressiveComponents_getInstance(), t, tr('selected', []), g, ox + 102.0, oy, 100.0, 40.0, 9999.0, 0), 'pick:fit'));
    this_0.add_utx5q5_k$(pick(label(ExpressiveComponents_getInstance(), t, g, tr('day', []), ox + 50.0, oy + 20.0, 14.0, 500, 6), 0, 1, 6));
    this_0.add_utx5q5_k$(pick(label(ExpressiveComponents_getInstance(), t, g, tr('week', []), ox + 152.0, oy + 20.0, 14.0, 600, 1), 1, 1, 6));
    this_0.add_utx5q5_k$(pick(label(ExpressiveComponents_getInstance(), t, g, tr('month', []), ox + 254.0, oy + 20.0, 14.0, 500, 6), 2, 1, 6));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_9(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(shadowed(ExpressiveComponents_getInstance(), rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 232.0, 64.0, 9999.0, 15), 10.0, 3.0));
    var inductionVariable = 0;
    if (inductionVariable < 4)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        this_0.addAll_h3ej1q_k$(pick_0(icon$default(ExpressiveComponents_getInstance(), t, g, listOf_0(['edit', 'share', 'bookmark', 'more_vert']).get_c1px32_k$(i), ox + 40.0 + i * 51.0, oy + 32.0, i === 0 ? 0 : 18), i, 0, 18));
      }
       while (inductionVariable < 4);
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, 'FAB', g, ox + 244.0, oy + 4.0, 56.0, 56.0, 16.0, 2));
    this_0.addAll_h3ej1q_k$(plus_1(ExpressiveComponents_getInstance(), t, g, ox + 272.0, oy + 32.0, 22.0, 2.0, 3));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_10(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('background', []), g, ox, oy, 360.0, 64.0, 0.0, 12));
    this_0.addAll_h3ej1q_k$(bars(ExpressiveComponents_getInstance(), t, g, ox + 16.0, oy + 32.0, 17));
    this_0.add_utx5q5_k$(label(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 180.0, oy + 32.0, 22.0, 500, 17));
    this_0.addAll_h3ej1q_k$(icon$default(ExpressiveComponents_getInstance(), t, g, 'more_vert', ox + 332.0, oy + 32.0, 18));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_11(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('background', []), g, ox, oy, 360.0, 112.0, 0.0, 14));
    this_0.addAll_h3ej1q_k$(bars(ExpressiveComponents_getInstance(), t, g, ox + 16.0, oy + 32.0, 17));
    this_0.addAll_h3ej1q_k$(icon$default(ExpressiveComponents_getInstance(), t, g, 'more_vert', ox + 332.0, oy + 32.0, 18));
    this_0.add_utx5q5_k$(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 16.0, oy + 84.0, 24.0, 600, 17));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_12(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('background', []), g, ox, oy, 360.0, 152.0, 0.0, 14));
    this_0.addAll_h3ej1q_k$(bars(ExpressiveComponents_getInstance(), t, g, ox + 16.0, oy + 32.0, 17));
    this_0.addAll_h3ej1q_k$(icon$default(ExpressiveComponents_getInstance(), t, g, 'more_vert', ox + 332.0, oy + 32.0, 18));
    this_0.add_utx5q5_k$(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 16.0, oy + 118.0, 32.0, 600, 17));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_13(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('background', []), g, ox, oy, 360.0, 64.0, 0.0, 14));
    var tmp = rect$default(ExpressiveComponents_getInstance(), t, tr('indicator', []), g, ox + invoke$_anonymous_$slot_plopj5(0, 0) + 4.0, oy + 12.0, 128.0, 40.0, 9999.0, 5);
    var tmp_0 = until(0, 3);
    this_0.add_utx5q5_k$(w(tmp, 'pick:ind/' + joinToString_0(tmp_0, ';', VOID, VOID, VOID, VOID, ExpressiveComponents$list$lambda$lambda)));
    var names = listOf_0([tr('home', []), tr('search', []), tr('profile', [])]);
    var icons = listOf_0(['home', 'search', 'person']);
    var inductionVariable = 0;
    if (inductionVariable < 3)
      do {
        var j = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var ic = icon$default(ExpressiveComponents_getInstance(), t, g, icons.get_c1px32_k$(j), ox + invoke$_anonymous_$iconC_c6douf(j, 0), oy + 32.0, j === 0 ? 6 : 18);
        var _iterator__ex2g4s = ic.iterator_jk1svi_k$();
        while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
          var n = _iterator__ex2g4s.next_20eer_k$();
          var tmp_1 = 'pick:i' + j + '/6/18/';
          var tmp_2 = until(0, 3);
          this_0.add_utx5q5_k$(n.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, tmp_1 + joinToString_0(tmp_2, ';', VOID, VOID, VOID, VOID, ExpressiveComponents$list$lambda$lambda_0(n, ox, j))));
        }
        var lb = labelLeft(ExpressiveComponents_getInstance(), t, g, names.get_c1px32_k$(j), ox + invoke$_anonymous_$slot_plopj5(j, 0) + 4.0 + 56.0, oy + 32.0, 13.0, 700, 6);
        var tmp_3 = j === 0 ? 1.0 : 0.0;
        var tmp_4 = 'pick:i' + j + '/6/18/';
        var tmp_5 = until(0, 3);
        this_0.add_utx5q5_k$(lb.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, tmp_3, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, tmp_4 + joinToString_0(tmp_5, ';', VOID, VOID, VOID, VOID, ExpressiveComponents$list$lambda$lambda_1(j)) + '/f'));
      }
       while (inductionVariable < 3);
    return this_0.build_nmwvly_k$();
  }
  function invoke$_anonymous_$slot_plopj5(j, sel) {
    // Inline function 'kotlin.collections.sumOf' call
    var sum = 0;
    var progression = until(0, j);
    var inductionVariable = progression.first_1;
    var last = progression.last_1;
    if (inductionVariable <= last)
      do {
        var element = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var tmp = sum;
        sum = tmp + (element === sel ? 136 : 72);
      }
       while (!(element === last));
    return 40.0 + sum;
  }
  function invoke$_anonymous_$fmt_j5mh9m(v) {
    return formatNumber('%.2f', [v]);
  }
  function invoke$_anonymous_$iconC_c6douf(j, k) {
    return j === k ? invoke$_anonymous_$slot_plopj5(j, k) + 4.0 + 32.0 : invoke$_anonymous_$slot_plopj5(j, k) + 36.0;
  }
  function ExpressiveComponents$list$lambda$lambda(it) {
    return invoke$_anonymous_$fmt_j5mh9m(invoke$_anonymous_$slot_plopj5(it, it) + 4.0);
  }
  function ExpressiveComponents$list$lambda$lambda_0($n, $ox, $j) {
    return function (k) {
      return invoke$_anonymous_$fmt_j5mh9m($n.x_1 - $ox + invoke$_anonymous_$iconC_c6douf($j, k) - invoke$_anonymous_$iconC_c6douf($j, 0));
    };
  }
  function ExpressiveComponents$list$lambda$lambda_1($j) {
    return function (k) {
      return invoke$_anonymous_$fmt_j5mh9m(invoke$_anonymous_$slot_plopj5($j, k) + 4.0 + 56.0);
    };
  }
  function ExpressiveComponents$list$lambda_14(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('background', []), g, ox, oy, 360.0, 80.0, 0.0, 14));
    var inductionVariable = 0;
    if (inductionVariable < 3)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        this_0.addAll_h3ej1q_k$(pick_0(icon$default(ExpressiveComponents_getInstance(), t, g, listOf_0(['menu', 'search', 'favorite']).get_c1px32_k$(i), ox + 40.0 + i * 56.0, oy + 40.0, i === 0 ? 0 : 18), i, 0, 18));
      }
       while (inductionVariable < 3);
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, 'FAB', g, ox + 284.0, oy + 12.0, 56.0, 56.0, 16.0, 2));
    this_0.addAll_h3ej1q_k$(plus_1(ExpressiveComponents_getInstance(), t, g, ox + 312.0, oy + 40.0, 22.0, 2.0, 3));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_15(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('background', []), g, ox, oy, 80.0, 360.0, 0.0, 12));
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, 'FAB', g, ox + 12.0, oy + 16.0, 56.0, 56.0, 16.0, 2));
    this_0.addAll_h3ej1q_k$(plus_1(ExpressiveComponents_getInstance(), t, g, ox + 40.0, oy + 44.0, 22.0, 2.0, 3));
    var names = listOf_0([tr('home', []), tr('search', []), tr('profile', [])]);
    var inductionVariable = 0;
    if (inductionVariable < 3)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var top = oy + 104.0 + i * 84.0;
        if (i === 0) {
          this_0.add_utx5q5_k$(w(rect$default(ExpressiveComponents_getInstance(), t, tr('indicator', []), g, ox + 12.0, top, 56.0, 32.0, 9999.0, 5), 'pick:ind'));
        }
        this_0.addAll_h3ej1q_k$(pick_0(icon$default(ExpressiveComponents_getInstance(), t, g, listOf_0(['home', 'search', 'person']).get_c1px32_k$(i), ox + 40.0, top + 16.0, i === 0 ? 6 : 18), i, 6, 18));
        this_0.add_utx5q5_k$(pick(label(ExpressiveComponents_getInstance(), t, g, names.get_c1px32_k$(i), ox + 40.0, top + 44.0, 12.0, i === 0 ? 700 : 500, i === 0 ? 17 : 18), i, 17, 18));
      }
       while (inductionVariable < 3);
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_16(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 360.0, 300.0, 16.0, 13));
    this_0.add_utx5q5_k$(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 28.0, oy + 40.0, 14.0, 500, 18));
    var names = listOf_0([tr('home', []), tr('search', []), tr('profile', [])]);
    var inductionVariable = 0;
    if (inductionVariable < 3)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var y = oy + 68.0 + i * 60.0;
        if (i === 0) {
          this_0.add_utx5q5_k$(w(rect$default(ExpressiveComponents_getInstance(), t, tr('indicator', []), g, ox + 12.0, y, 336.0, 56.0, 9999.0, 5), 'pick:ind'));
        }
        this_0.addAll_h3ej1q_k$(pick_0(icon$default(ExpressiveComponents_getInstance(), t, g, listOf_0(['home', 'search', 'person']).get_c1px32_k$(i), ox + 40.0, y + 28.0, i === 0 ? 6 : 18), i, 6, 18));
        this_0.add_utx5q5_k$(pick(labelLeft(ExpressiveComponents_getInstance(), t, g, names.get_c1px32_k$(i), ox + 68.0, y + 28.0, 14.0, 500, i === 0 ? 6 : 18), i, 6, 18));
      }
       while (inductionVariable < 3);
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_17(ox, oy, g, t) {
    return listOf_0([shadowed(ExpressiveComponents_getInstance(), rect$default(ExpressiveComponents_getInstance(), t, tr('card', []), g, ox, oy, 328.0, 120.0, 12.0, 13), 8.0, 2.0), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 16.0, oy + 28.0, 16.0, 500, 17), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('supporting_text', []), ox + 16.0, oy + 52.0, 14.0, 400, 18)]);
  }
  function ExpressiveComponents$list$lambda_18(ox, oy, g, t) {
    return listOf_0([rect(ExpressiveComponents_getInstance(), t, tr('card', []), g, ox, oy, 328.0, 120.0, 12.0, 12, 20, 1.0), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 16.0, oy + 28.0, 16.0, 500, 17), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('supporting_text', []), ox + 16.0, oy + 52.0, 14.0, 400, 18)]);
  }
  function ExpressiveComponents$list$lambda_19(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('card', []), g, ox, oy, 328.0, 300.0, 28.0, 13));
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('media', []), g, ox + 8.0, oy + 8.0, 312.0, 170.0, 20.0, 8));
    this_0.add_utx5q5_k$(shape(ExpressiveComponents_getInstance(), t, tr('media', []), g, 'cookie-9', ox + 116.0, oy + 41.0, 96.0, 9));
    this_0.add_utx5q5_k$(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 20.0, oy + 208.0, 22.0, 600, 17));
    this_0.add_utx5q5_k$(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('supporting_text', []), ox + 20.0, oy + 236.0, 14.0, 400, 18));
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox + 20.0, oy + 254.0, 96.0, 36.0, 9999.0, 0));
    this_0.add_utx5q5_k$(label(ExpressiveComponents_getInstance(), t, g, 'Button', ox + 68.0, oy + 272.0, 14.0, 500, 1));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_20(ox, oy, g, t) {
    return listOf_0([rect$default(ExpressiveComponents_getInstance(), t, tr('card', []), g, ox, oy, 328.0, 160.0, 48.0, 2), shape(ExpressiveComponents_getInstance(), t, tr('media', []), g, 'flower', ox + 220.0, oy + 20.0, 96.0, 8), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 28.0, oy + 100.0, 28.0, 700, 3), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('supporting_text', []), ox + 28.0, oy + 130.0, 14.0, 400, 3)]);
  }
  function ExpressiveComponents$list$lambda_21(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(shadowed(ExpressiveComponents_getInstance(), rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 360.0, 240.0, 28.0, 13), 12.0, -2.0));
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('handle', []), g, ox + 164.0, oy + 12.0, 32.0, 4.0, 2.0, 18));
    this_0.add_utx5q5_k$(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 24.0, oy + 48.0, 22.0, 500, 17));
    var inductionVariable = 0;
    if (inductionVariable < 2)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        this_0.addAll_h3ej1q_k$(icon$default(ExpressiveComponents_getInstance(), t, g, listOf_0(['share', 'delete']).get_c1px32_k$(i), ox + 36.0, oy + 100.0 + i * 56.0, 18));
        this_0.add_utx5q5_k$(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('menu_item', []), ox + 68.0, oy + 100.0 + i * 56.0, 16.0, 400, 17));
      }
       while (inductionVariable < 2);
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_22(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    var tokens = listOf_0([2, 5, 8, 16, 2]);
    var onTokens = listOf_0([3, 6, 9, 17, 3]);
    var inductionVariable = 0;
    if (inductionVariable < 5)
      do {
        var j = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var tmp = 'pick:i' + j + '/' + tokens.get_c1px32_k$(j) + '/' + tokens.get_c1px32_k$(j) + '/';
        var tmp_0 = until(0, 5);
        var tmp_1 = tmp + joinToString_0(tmp_0, ';', VOID, VOID, VOID, VOID, ExpressiveComponents$list$lambda$lambda_2(j)) + '/w=';
        var tmp_2 = until(0, 5);
        var role = tmp_1 + joinToString_0(tmp_2, ';', VOID, VOID, VOID, VOID, ExpressiveComponents$list$lambda$lambda_3(j));
        this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('card', []), g, ox + invoke$_anonymous_$cardX_c31pb9(j, 0), oy, invoke$_anonymous_$cardW_c31pb8(j, 0), 160.0, 28.0, tokens.get_c1px32_k$(j)).copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, role));
        var lb = label(ExpressiveComponents_getInstance(), t, g, tr('title', []), 0.0, oy + 80.0, 22.0, 600, onTokens.get_c1px32_k$(j));
        var tmp_3 = ox + invoke$_anonymous_$lx_iy59cf(j, lb, 0);
        var tmp_4 = j === 0 ? 1.0 : 0.0;
        var tmp_5 = 'pick:i' + j + '/' + onTokens.get_c1px32_k$(j) + '/' + onTokens.get_c1px32_k$(j) + '/';
        var tmp_6 = until(0, 5);
        this_0.add_utx5q5_k$(lb.copy$default_q375vp_k$(VOID, VOID, VOID, tmp_3, VOID, VOID, VOID, VOID, VOID, VOID, VOID, tmp_4, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, tmp_5 + joinToString_0(tmp_6, ';', VOID, VOID, VOID, VOID, ExpressiveComponents$list$lambda$lambda_4(j, lb)) + '/f'));
      }
       while (inductionVariable < 5);
    return this_0.build_nmwvly_k$();
  }
  function invoke$_anonymous_$cardX_c31pb9(j, k) {
    return j <= k ? 0.0 : (j - k | 0) <= 2 ? 232.0 + ((j - k | 0) - 1 | 0) * 64.0 : 360.0;
  }
  function invoke$_anonymous_$cardW_c31pb8(j, k) {
    return j < k ? 0.0 : j === k ? 224.0 : (j - k | 0) <= 2 ? 56.0 : 0.0;
  }
  function invoke$_anonymous_$fmt$0_c4wquu(v) {
    return formatNumber('%.2f', [v]);
  }
  function invoke$_anonymous_$lx_iy59cf(j, lb, k) {
    var tmp0 = invoke$_anonymous_$cardX_c31pb9(j, k) + 112.0 - lb.w_1 / 2.0;
    // Inline function 'kotlin.comparisons.minOf' call
    var b = 360.0 - lb.w_1;
    return Math.min(tmp0, b);
  }
  function ExpressiveComponents$list$lambda$lambda_2($j) {
    return function (it) {
      return invoke$_anonymous_$fmt$0_c4wquu(invoke$_anonymous_$cardX_c31pb9($j, it));
    };
  }
  function ExpressiveComponents$list$lambda$lambda_3($j) {
    return function (it) {
      return invoke$_anonymous_$fmt$0_c4wquu(invoke$_anonymous_$cardW_c31pb8($j, it));
    };
  }
  function ExpressiveComponents$list$lambda$lambda_4($j, $lb) {
    return function (it) {
      return invoke$_anonymous_$fmt$0_c4wquu(invoke$_anonymous_$lx_iy59cf($j, $lb, it));
    };
  }
  function ExpressiveComponents$list$lambda_23(ox, oy, g, t) {
    return listOf_0([rect$default(ExpressiveComponents_getInstance(), t, tr('background', []), g, ox, oy, 360.0, 88.0, 0.0, 12), oval(ExpressiveComponents_getInstance(), t, tr('avatar', []), g, ox + 16.0, oy + 16.0, 40.0, 40.0, 2), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 72.0, oy + 24.0, 16.0, 500, 17), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('supporting_text', []), ox + 72.0, oy + 46.0, 14.0, 400, 18), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('supporting_text', []), ox + 72.0, oy + 64.0, 14.0, 400, 18)]);
  }
  function ExpressiveComponents$list$lambda_24(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    var inductionVariable = 0;
    if (inductionVariable < 3)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        this_0.addAll_h3ej1q_k$(listRow(ExpressiveComponents_getInstance(), t, g, ox, oy + i * 74.0, 360.0, 72.0, i === 1 ? 8.0 : 24.0, 14, tr('title', []), tr('supporting_text', [])));
      }
       while (inductionVariable < 3);
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_25(ox, oy, g, t) {
    return listOf_0([rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 120.0, 32.0, 8.0, 21), label(ExpressiveComponents_getInstance(), t, g, tr('message', []), ox + 60.0, oy + 16.0, 12.0, 500, 12)]);
  }
  function ExpressiveComponents$list$lambda_26(ox, oy, g, t) {
    return listOf_0([rect$default(ExpressiveComponents_getInstance(), t, tr('badge', []), g, ox, oy, 28.0, 16.0, 9999.0, 10), label(ExpressiveComponents_getInstance(), t, g, '99+', ox + 14.0, oy + 8.0, 10.0, 600, 1)]);
  }
  function ExpressiveComponents$list$lambda_27(ox, oy, g, t) {
    return listOf_0([oval(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 48.0, 48.0, 5), w(shape(ExpressiveComponents_getInstance(), t, tr('indicator', []), g, 'cookie-9', ox + 8.0, oy + 8.0, 32.0, 0), 'spin:rot')]);
  }
  function ExpressiveComponents$list$lambda_28(ox, oy, g, t) {
    return listOf_0([ring(ExpressiveComponents_getInstance(), t, tr('track', []), g, ox + 4.0, oy + 4.0, 40.0, 5, 4.0), w(strokePath(ExpressiveComponents_getInstance(), t, tr('arc', []), g, ox + 4.0, oy + 4.0, 40.0, 40.0, PlayMode_getInstance().arcPath_w946m9_k$(0.75), 0, 4.0), 'progress:arc')]);
  }
  function ExpressiveComponents$list$lambda_29(ox, oy, g, t) {
    return listOf_0([w(rect$default(ExpressiveComponents_getInstance(), t, tr('track', []), g, ox + 176.0, oy + 6.0, 104.0, 4.0, 2.0, 5), 'progress:track'), w(strokePath(ExpressiveComponents_getInstance(), t, tr('wave', []), g, ox, oy + 2.0, 168.0, 12.0, PlayMode_getInstance().wavePath_dm4l52_k$(168.0), 0, 4.0), 'progress:active'), oval(ExpressiveComponents_getInstance(), t, tr('dot', []), g, ox + 274.0, oy + 6.0, 4.0, 4.0, 0)]);
  }
  function ExpressiveComponents$list$lambda_30(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(w(rect$default(ExpressiveComponents_getInstance(), t, tr('chip', []), g, ox, oy, 104.0, 32.0, 8.0, 5), 'chip:bg'));
    // Inline function 'kotlin.collections.map' call
    var this_1 = check(ExpressiveComponents_getInstance(), t, g, ox + 4.0, oy + 4.0, 6);
    // Inline function 'kotlin.collections.mapTo' call
    var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_1, 10));
    var _iterator__ex2g4s = this_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s.next_20eer_k$();
      var tmp$ret$0 = w(item, 'chip:mark');
      destination.add_utx5q5_k$(tmp$ret$0);
    }
    this_0.addAll_h3ej1q_k$(destination);
    this_0.add_utx5q5_k$(w(label(ExpressiveComponents_getInstance(), t, g, 'Filter', ox + 62.0, oy + 16.0, 14.0, 500, 6), 'chip:label'));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_31(ox, oy, g, t) {
    var tmp = [rect(ExpressiveComponents_getInstance(), t, tr('chip', []), g, ox, oy, 104.0, 32.0, 8.0, -1, 20, 1.0)];
    // Inline function 'kotlin.collections.toTypedArray' call
    var this_0 = icon(ExpressiveComponents_getInstance(), t, g, 'event', ox + 18.0, oy + 16.0, 0, 18.0);
    var tmp$ret$0 = copyToArray(this_0);
    return listOf_0(arrayConcat([tmp, tmp$ret$0, [label(ExpressiveComponents_getInstance(), t, g, 'Assist', ox + 62.0, oy + 16.0, 14.0, 500, 17)]]));
  }
  function ExpressiveComponents$list$lambda_32(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect(ExpressiveComponents_getInstance(), t, tr('chip', []), g, ox, oy, 112.0, 32.0, 8.0, -1, 20, 1.0));
    this_0.add_utx5q5_k$(label(ExpressiveComponents_getInstance(), t, g, 'Input', ox + 42.0, oy + 16.0, 14.0, 500, 18));
    this_0.addAll_h3ej1q_k$(cross(ExpressiveComponents_getInstance(), t, g, ox + 92.0, oy + 16.0, 12.0, 18));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_33(ox, oy, g, t) {
    return listOf_0([w(rect(ExpressiveComponents_getInstance(), t, tr('track', []), g, ox + 1.0, oy + 1.0, 50.0, 30.0, 9999.0, 16, 19, 2.0), 'switch:track'), w(oval(ExpressiveComponents_getInstance(), t, tr('thumb', []), g, ox + 8.0, oy + 8.0, 16.0, 16.0, 19), 'switch:thumb')]);
  }
  function ExpressiveComponents$list$lambda_34(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(w(rect$default(ExpressiveComponents_getInstance(), t, tr('track', []), g, ox, oy, 52.0, 32.0, 9999.0, 0), 'switch:track'));
    this_0.add_utx5q5_k$(w(oval(ExpressiveComponents_getInstance(), t, tr('thumb', []), g, ox + 24.0, oy + 4.0, 24.0, 24.0, 1), 'switch:thumb'));
    // Inline function 'kotlin.collections.map' call
    var this_1 = check(ExpressiveComponents_getInstance(), t, g, ox + 24.0, oy + 4.0, 0);
    // Inline function 'kotlin.collections.mapTo' call
    var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_1, 10));
    var _iterator__ex2g4s = this_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s.next_20eer_k$();
      var tmp$ret$0 = w(item, 'switch:icon');
      destination.add_utx5q5_k$(tmp$ret$0);
    }
    this_0.addAll_h3ej1q_k$(destination);
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_35(ox, oy, g, t) {
    return listOf(w(rect(ExpressiveComponents_getInstance(), t, tr('box', []), g, ox + 3.0, oy + 3.0, 18.0, 18.0, 2.0, -1, 18, 2.0), 'check:box'));
  }
  function ExpressiveComponents$list$lambda_36(ox, oy, g, t) {
    return listOf(w(ring(ExpressiveComponents_getInstance(), t, tr('ring', []), g, ox + 2.0, oy + 2.0, 20.0, 18, 2.0), 'radio:ring'));
  }
  function ExpressiveComponents$list$lambda_37(ox, oy, g, t) {
    return listOf_0([w(rect$default(ExpressiveComponents_getInstance(), t, tr('track', []), g, ox + 180.0, oy + 2.0, 120.0, 40.0, 12.0, 5), 'slider:track'), w(rect$default(ExpressiveComponents_getInstance(), t, tr('active_part', []), g, ox, oy + 2.0, 168.0, 40.0, 12.0, 0), 'slider:active'), w(rect$default(ExpressiveComponents_getInstance(), t, tr('handle', []), g, ox + 172.0, oy, 4.0, 44.0, 2.0, 0), 'slider:thumb')]);
  }
  function ExpressiveComponents$list$lambda_38(ox, oy, g, t) {
    return listOf_0([w(rect$default(ExpressiveComponents_getInstance(), t, tr('track', []), g, ox + 182.0, oy + 20.0, 118.0, 4.0, 2.0, 5), 'slider:track'), w(strokePath(ExpressiveComponents_getInstance(), t, tr('wave', []), g, ox, oy + 14.0, 164.0, 16.0, PlayMode_getInstance().wavePath_dm4l52_k$(164.0), 0, 4.0), 'slider:active'), w(rect$default(ExpressiveComponents_getInstance(), t, tr('handle', []), g, ox + 172.0, oy + 6.0, 4.0, 32.0, 2.0, 0), 'slider:thumb')]);
  }
  function ExpressiveComponents$list$lambda_39(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(shadowed(ExpressiveComponents_getInstance(), rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 200.0, 160.0, 12.0, 14), 12.0, 4.0));
    this_0.add_utx5q5_k$(w(rect$default(ExpressiveComponents_getInstance(), t, tr('selected', []), g, ox + 8.0, oy + 8.0, 184.0, 48.0, 8.0, 5), 'pick:ind'));
    var inductionVariable = 0;
    if (inductionVariable < 3)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var y = oy + 32.0 + i * 48.0;
        var on = i === 0;
        this_0.addAll_h3ej1q_k$(pick_0(icon(ExpressiveComponents_getInstance(), t, g, listOf_0(['edit', 'share', 'delete']).get_c1px32_k$(i), ox + 32.0, y, on ? 6 : 18, 20.0), i, 6, 18));
        this_0.add_utx5q5_k$(pick(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('menu_item', []), ox + 56.0, y, 16.0, 400, on ? 6 : 17), i, 6, 17));
      }
       while (inductionVariable < 3);
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_40(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 328.0, 384.0, 28.0, 15));
    this_0.add_utx5q5_k$(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('cal_month', []), ox + 24.0, oy + 32.0, 16.0, 500, 17));
    var inductionVariable = 0;
    if (inductionVariable < 7)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        this_0.add_utx5q5_k$(label(ExpressiveComponents_getInstance(), t, g, tr('wd_' + (i + 1 | 0), []), ox + 32.0 + i * 44.0, oy + 76.0, 12.0, 500, 18));
      }
       while (inductionVariable < 7);
    var selected = 13;
    this_0.add_utx5q5_k$(w(oval(ExpressiveComponents_getInstance(), t, tr('selected', []), g, ox + 32.0 + ((6 + selected | 0) % 7 | 0) * 44.0 - 20.0, oy + 114.0 + ((6 + selected | 0) / 7 | 0) * 44.0 - 20.0, 40.0, 40.0, 0), 'pick:ind'));
    var inductionVariable_0 = 0;
    if (inductionVariable_0 < 30)
      do {
        var d = inductionVariable_0;
        inductionVariable_0 = inductionVariable_0 + 1 | 0;
        var cell = 6 + d | 0;
        this_0.add_utx5q5_k$(pick(label(ExpressiveComponents_getInstance(), t, g, '' + (d + 1 | 0), ox + 32.0 + (cell % 7 | 0) * 44.0, oy + 114.0 + (cell / 7 | 0) * 44.0, 14.0, 400, d === selected ? 1 : 17), d, 1, 17));
      }
       while (inductionVariable_0 < 30);
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_41(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 360.0, 104.0, 0.0, 13));
    this_0.add_utx5q5_k$(oval(ExpressiveComponents_getInstance(), t, tr('avatar', []), g, ox + 16.0, oy + 16.0, 40.0, 40.0, 2));
    this_0.addAll_h3ej1q_k$(icon$default(ExpressiveComponents_getInstance(), t, g, 'info', ox + 36.0, oy + 36.0, 3));
    this_0.add_utx5q5_k$(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('banner_title', []), ox + 72.0, oy + 28.0, 16.0, 500, 17));
    this_0.add_utx5q5_k$(labelLeft(ExpressiveComponents_getInstance(), t, g, tr('banner_body', []), ox + 72.0, oy + 52.0, 14.0, 400, 18));
    this_0.add_utx5q5_k$(label(ExpressiveComponents_getInstance(), t, g, tr('cancel', []), ox + 262.0, oy + 84.0, 14.0, 500, 0));
    this_0.add_utx5q5_k$(label(ExpressiveComponents_getInstance(), t, g, tr('more', []), ox + 326.0, oy + 84.0, 14.0, 500, 0));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_42(ox, oy, g, t) {
    // Inline function 'kotlin.collections.buildList' call
    // Inline function 'kotlin.collections.buildListInternal' call
    // Inline function 'kotlin.apply' call
    var this_0 = ArrayList_init_$Create$();
    this_0.add_utx5q5_k$(rect(ExpressiveComponents_getInstance(), t, tr('container', []), g, ox, oy, 120.0, 40.0, 9999.0, -1, 19, 1.0));
    this_0.add_utx5q5_k$(rect$default(ExpressiveComponents_getInstance(), t, tr('minus', []), g, ox + 14.0, oy + 19.0, 12.0, 2.0, 1.0, 17));
    this_0.add_utx5q5_k$(w(label(ExpressiveComponents_getInstance(), t, g, '1', ox + 60.0, oy + 20.0, 16.0, 500, 17), 'counter:label'));
    this_0.addAll_h3ej1q_k$(plus_1(ExpressiveComponents_getInstance(), t, g, ox + 100.0, oy + 20.0, 12.0, 2.0, 17));
    return this_0.build_nmwvly_k$();
  }
  function ExpressiveComponents$list$lambda_43(ox, oy, g, t) {
    return listOf_0([rect$default(ExpressiveComponents_getInstance(), t, tr('background', []), g, ox, oy, 360.0, 72.0, 0.0, 12), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 16.0, oy + 28.0, 16.0, 400, 17), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('supporting_text', []), ox + 16.0, oy + 49.0, 14.0, 400, 18), w(rect$default(ExpressiveComponents_getInstance(), t, tr('track', []), g, ox + 292.0, oy + 20.0, 52.0, 32.0, 9999.0, 0), 'switch:track'), w(oval(ExpressiveComponents_getInstance(), t, tr('thumb', []), g, ox + 316.0, oy + 24.0, 24.0, 24.0, 1), 'switch:thumb')]);
  }
  function ExpressiveComponents$list$lambda_44(ox, oy, g, t) {
    return listOf_0([rect$default(ExpressiveComponents_getInstance(), t, tr('background', []), g, ox, oy, 360.0, 56.0, 0.0, 12), w(rect(ExpressiveComponents_getInstance(), t, tr('box', []), g, ox + 19.0, oy + 19.0, 18.0, 18.0, 2.0, -1, 18, 2.0), 'check:box'), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('title', []), ox + 60.0, oy + 28.0, 16.0, 400, 17)]);
  }
  function ExpressiveComponents$list$lambda_45(ox, oy, g, t) {
    return listOf_0([w(rect(ExpressiveComponents_getInstance(), t, tr('field', []), g, ox, oy, 280.0, 56.0, 4.0, -1, 10, 2.0), 'focus:box/err'), labelLeft(ExpressiveComponents_getInstance(), t, g, 'Email', ox + 16.0, oy + 28.0, 16.0, 400, 10), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('field_error', []), ox + 16.0, oy + 70.0, 12.0, 400, 10)]);
  }
  function ExpressiveComponents$list$lambda_46(ox, oy, g, t) {
    return listOf_0([oval(ExpressiveComponents_getInstance(), t, tr('avatar', []), g, ox, oy, 40.0, 40.0, 2), oval(ExpressiveComponents_getInstance(), t, tr('avatar', []), g, ox + 28.0, oy, 40.0, 40.0, 8), oval(ExpressiveComponents_getInstance(), t, tr('avatar', []), g, ox + 56.0, oy, 40.0, 40.0, 5), oval(ExpressiveComponents_getInstance(), t, tr('avatar', []), g, ox + 84.0, oy, 40.0, 40.0, 16), label(ExpressiveComponents_getInstance(), t, g, '+5', ox + 104.0, oy + 20.0, 13.0, 600, 17)]);
  }
  function ExpressiveComponents$list$lambda_47(ox, oy, g, t) {
    return listOf_0([rect$default(ExpressiveComponents_getInstance(), t, tr('card', []), g, ox, oy, 160.0, 120.0, 28.0, 15), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('revenue', []), ox + 20.0, oy + 32.0, 14.0, 400, 18), labelLeft(ExpressiveComponents_getInstance(), t, g, tr('revenue_value', []), ox + 20.0, oy + 68.0, 28.0, 600, 17), rect$default(ExpressiveComponents_getInstance(), t, tr('chip', []), g, ox + 20.0, oy + 84.0, 56.0, 24.0, 9999.0, 2), label(ExpressiveComponents_getInstance(), t, g, '+12%', ox + 48.0, oy + 96.0, 12.0, 600, 3)]);
  }
  function ExpressiveComponents$list$lambda_48(ox, oy, g, t) {
    return listOf_0([rect$default(ExpressiveComponents_getInstance(), t, tr('field', []), g, ox, oy, 280.0, 56.0, 4.0, 16), w(rect$default(ExpressiveComponents_getInstance(), t, tr('line', []), g, ox, oy + 54.0, 280.0, 2.0, 0.0, 18), 'focus:line'), w(labelLeft(ExpressiveComponents_getInstance(), t, g, 'Label', ox + 16.0, oy + 28.0, 16.0, 400, 18), 'focus:label')]);
  }
  function ExpressiveComponents() {
    ExpressiveComponents_instance = this;
    var tmp = this;
    var tmp_0 = def(this, 'btn-elevated', 'Elevated button', 120.0, 40.0, ExpressiveComponents$list$lambda);
    var tmp_1 = def(this, 'btn-text', 'Text button', 100.0, 40.0, ExpressiveComponents$list$lambda_0);
    var tmp_2 = sizedButton$default(this, 'btn-m', 'Button M (56)', 160.0, 56.0, 16.0);
    var tmp_3 = sizedButton$default(this, 'btn-l', 'Button L (96)', 220.0, 96.0, 24.0);
    var tmp_4 = sizedButton$default(this, 'btn-xl', 'Button XL (136)', 300.0, 136.0, 32.0);
    var tmp_5 = sizedButton(this, 'btn-square', 'Button M (square)', 160.0, 56.0, 16.0, 16.0);
    var tmp_6 = def(this, 'btn-morph', 'Button (pill to square on press)', 160.0, 56.0, ExpressiveComponents$list$lambda_1);
    var tmp_7 = def(this, 'btn-morph-square', 'Button (square to circle on press)', 72.0, 72.0, ExpressiveComponents$list$lambda_2);
    var tmp_8 = def(this, 'btn-morph-tonal', 'Button (circle to square on press)', 72.0, 72.0, ExpressiveComponents$list$lambda_3);
    var tmp_9 = iconButton$default(this, 'icon-btn', 'Icon button', 0, 1);
    var tmp_10 = iconButton$default(this, 'icon-btn-tonal', 'Icon button (tonal)', 5, 6);
    var tmp_11 = iconButton$default(this, 'icon-btn-outlined', 'Icon button (outlined)', -1, 18, true);
    var tmp_12 = iconButton$default(this, 'icon-btn-square', 'Icon button (square)', 0, 1, VOID, 12.0);
    var tmp_13 = def(this, 'fab-small', 'Small FAB', 40.0, 40.0, ExpressiveComponents$list$lambda_4);
    var tmp_14 = def(this, 'fab-large', 'Large FAB', 96.0, 96.0, ExpressiveComponents$list$lambda_5);
    var tmp_15 = def(this, 'fab-menu', 'FAB menu', 200.0, 248.0, ExpressiveComponents$list$lambda_6);
    var tmp_16 = def(this, 'split-button', 'Split button', 152.0, 40.0, ExpressiveComponents$list$lambda_7);
    var tmp_17 = def(this, 'button-group', 'Button group (connected)', 304.0, 40.0, ExpressiveComponents$list$lambda_8);
    var tmp_18 = def(this, 'toolbar-floating', 'Floating toolbar', 300.0, 64.0, ExpressiveComponents$list$lambda_9);
    var tmp_19 = def(this, 'top-bar-center', 'Top app bar (centered)', 360.0, 64.0, ExpressiveComponents$list$lambda_10);
    var tmp_20 = def(this, 'top-bar-medium', 'Top app bar (medium)', 360.0, 112.0, ExpressiveComponents$list$lambda_11);
    var tmp_21 = def(this, 'top-bar-large', 'Top app bar (large)', 360.0, 152.0, ExpressiveComponents$list$lambda_12);
    var tmp_22 = def(this, 'nav-bar-flex', 'Navigation bar (flexible)', 360.0, 64.0, ExpressiveComponents$list$lambda_13);
    var tmp_23 = def(this, 'bottom-bar', 'Bottom app bar', 360.0, 80.0, ExpressiveComponents$list$lambda_14);
    var tmp_24 = def(this, 'nav-rail', 'Navigation rail', 80.0, 360.0, ExpressiveComponents$list$lambda_15);
    var tmp_25 = def(this, 'nav-drawer', 'Navigation drawer', 360.0, 300.0, ExpressiveComponents$list$lambda_16);
    var tmp_26 = def(this, 'card-elevated', 'Card (elevated)', 328.0, 120.0, ExpressiveComponents$list$lambda_17);
    var tmp_27 = def(this, 'card-outlined', 'Card (outlined)', 328.0, 120.0, ExpressiveComponents$list$lambda_18);
    var tmp_28 = def(this, 'card-media', 'Card (media)', 328.0, 300.0, ExpressiveComponents$list$lambda_19);
    var tmp_29 = def(this, 'card-expressive', 'Card (expressive)', 328.0, 160.0, ExpressiveComponents$list$lambda_20);
    var tmp_30 = def(this, 'bottom-sheet', 'Bottom sheet', 360.0, 240.0, ExpressiveComponents$list$lambda_21);
    var tmp_31 = def(this, 'carousel', 'Carousel', 360.0, 160.0, ExpressiveComponents$list$lambda_22);
    var tmp_32 = def(this, 'list-3line', 'List item (3 lines)', 360.0, 88.0, ExpressiveComponents$list$lambda_23);
    var tmp_33 = def(this, 'list-segmented', 'List (segmented)', 360.0, 220.0, ExpressiveComponents$list$lambda_24);
    var tmp_34 = def(this, 'tooltip', 'Tooltip', 120.0, 32.0, ExpressiveComponents$list$lambda_25);
    var tmp_35 = def(this, 'badge-large', 'Badge (large)', 28.0, 16.0, ExpressiveComponents$list$lambda_26);
    var tmp_36 = def(this, 'loading', 'Loading indicator', 48.0, 48.0, ExpressiveComponents$list$lambda_27);
    var tmp_37 = def(this, 'progress-circular', 'Circular progress', 48.0, 48.0, ExpressiveComponents$list$lambda_28);
    var tmp_38 = def(this, 'progress-wavy', 'Wavy progress', 280.0, 16.0, ExpressiveComponents$list$lambda_29);
    var tmp_39 = def(this, 'chip-filter', 'Filter chip (selected)', 104.0, 32.0, ExpressiveComponents$list$lambda_30);
    var tmp_40 = def(this, 'chip-assist', 'Assist chip', 104.0, 32.0, ExpressiveComponents$list$lambda_31);
    var tmp_41 = def(this, 'chip-input', 'Input chip', 112.0, 32.0, ExpressiveComponents$list$lambda_32);
    var tmp_42 = def(this, 'switch-off', 'Switch (off)', 52.0, 32.0, ExpressiveComponents$list$lambda_33);
    var tmp_43 = def(this, 'switch-icon', 'Switch (with icon)', 52.0, 32.0, ExpressiveComponents$list$lambda_34);
    var tmp_44 = def(this, 'checkbox-off', 'Checkbox (off)', 24.0, 24.0, ExpressiveComponents$list$lambda_35);
    var tmp_45 = def(this, 'radio-off', 'Radio button (off)', 24.0, 24.0, ExpressiveComponents$list$lambda_36);
    var tmp_46 = def(this, 'slider-expressive', 'Slider (expressive)', 300.0, 44.0, ExpressiveComponents$list$lambda_37);
    var tmp_47 = def(this, 'slider-wavy', 'Slider (wavy)', 300.0, 44.0, ExpressiveComponents$list$lambda_38);
    var tmp_48 = def(this, 'menu', 'Menu', 200.0, 160.0, ExpressiveComponents$list$lambda_39);
    var tmp_49 = def(this, 'date-picker', 'Date picker', 328.0, 384.0, ExpressiveComponents$list$lambda_40);
    var tmp_50 = def(this, 'banner', 'Banner', 360.0, 104.0, ExpressiveComponents$list$lambda_41);
    var tmp_51 = def(this, 'quantity', 'Quantity stepper', 120.0, 40.0, ExpressiveComponents$list$lambda_42);
    var tmp_52 = def(this, 'list-switch', 'List item (switch)', 360.0, 72.0, ExpressiveComponents$list$lambda_43);
    var tmp_53 = def(this, 'list-checkbox', 'List item (checkbox)', 360.0, 56.0, ExpressiveComponents$list$lambda_44);
    var tmp_54 = def(this, 'textfield-error', 'Text field (error)', 280.0, 80.0, ExpressiveComponents$list$lambda_45);
    var tmp_55 = def(this, 'avatar-stack', 'Avatar stack', 124.0, 40.0, ExpressiveComponents$list$lambda_46);
    var tmp_56 = def(this, 'stat-card', 'Stat card', 160.0, 120.0, ExpressiveComponents$list$lambda_47);
    tmp.list_1 = listOf_0([tmp_0, tmp_1, tmp_2, tmp_3, tmp_4, tmp_5, tmp_6, tmp_7, tmp_8, tmp_9, tmp_10, tmp_11, tmp_12, tmp_13, tmp_14, tmp_15, tmp_16, tmp_17, tmp_18, tmp_19, tmp_20, tmp_21, tmp_22, tmp_23, tmp_24, tmp_25, tmp_26, tmp_27, tmp_28, tmp_29, tmp_30, tmp_31, tmp_32, tmp_33, tmp_34, tmp_35, tmp_36, tmp_37, tmp_38, tmp_39, tmp_40, tmp_41, tmp_42, tmp_43, tmp_44, tmp_45, tmp_46, tmp_47, tmp_48, tmp_49, tmp_50, tmp_51, tmp_52, tmp_53, tmp_54, tmp_55, tmp_56, def(this, 'textfield-filled', 'Filled text field', 280.0, 56.0, ExpressiveComponents$list$lambda_48)]);
  }
  var ExpressiveComponents_instance;
  function ExpressiveComponents_getInstance() {
    if (ExpressiveComponents_instance == null)
      new ExpressiveComponents();
    return ExpressiveComponents_instance;
  }
  function IconNodes() {
  }
  protoOf(IconNodes).make_7gle7u_k$ = function (t, name, g, cx, cy, size, tok, fill) {
    var tmp;
    try {
      // Inline function 'kotlin.let' call
      var s = IconLibrary_getInstance().styles_1;
      var style = s.contains_aljjnj_k$('outlined') ? 'outlined' : firstOrNull(s);
      var tmp_0;
      if (style == null) {
        tmp_0 = null;
      } else {
        // Inline function 'kotlin.let' call
        tmp_0 = IconLibrary_getInstance().bytes_k928ey_k$(style, name, fill);
      }
      var bytes = tmp_0;
      var tmp_1;
      if (bytes == null) {
        tmp_1 = null;
      } else {
        // Inline function 'kotlin.let' call
        tmp_1 = SvgImport_instance.parseOwnSize_8kecem_k$(bytes, size / 960.0);
      }
      var res = tmp_1;
      var tmp_2;
      if (res == null || res.nodes_1.isEmpty_y1axqb_k$()) {
        tmp_2 = null;
      } else {
        var dx = cx - res.width_1 / 2.0;
        var dy = cy - res.height_1 / 2.0;
        var color = t.color_kvkafx_k$(tok, -14869728);
        // Inline function 'kotlin.collections.map' call
        var this_0 = res.nodes_1;
        // Inline function 'kotlin.collections.mapTo' call
        var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_0, 10));
        var _iterator__ex2g4s = this_0.iterator_jk1svi_k$();
        while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
          var item = _iterator__ex2g4s.next_20eer_k$();
          var tmp0_id = newId();
          var tmp1_x = item.x_1 + dx;
          var tmp2_y = item.y_1 + dy;
          var tmp3_name = IconLibrary_getInstance().label_9g3ls6_k$(name);
          var tmp4_fill = item.kind_1.equals(NodeKind_PATH_getInstance()) ? color : item.fill_1;
          var tmp5_fillToken = item.kind_1.equals(NodeKind_PATH_getInstance()) ? tok : item.fillToken_1;
          var tmp$ret$6 = item.copy$default_q375vp_k$(tmp0_id, VOID, tmp3_name, tmp1_x, tmp2_y, VOID, VOID, VOID, tmp4_fill, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, g, VOID, VOID, true, VOID, VOID, VOID, VOID, tmp5_fillToken);
          destination.add_utx5q5_k$(tmp$ret$6);
        }
        tmp_2 = destination;
      }
      tmp = tmp_2;
    } catch ($p) {
      var tmp_3;
      if ($p instanceof Error) {
        var e = $p;
        tmp_3 = null;
      } else {
        throw $p;
      }
      tmp = tmp_3;
    }
    return tmp;
  };
  protoOf(IconNodes).make$default_d3mja_k$ = function (t, name, g, cx, cy, size, tok, fill, $super) {
    fill = fill === VOID ? false : fill;
    return $super === VOID ? this.make_7gle7u_k$(t, name, g, cx, cy, size, tok, fill) : $super.make_7gle7u_k$.call(this, t, name, g, cx, cy, size, tok, fill);
  };
  protoOf(IconNodes).icon_xdq47j_k$ = function (t, name, g, cx, cy, size, tok, fill) {
    var tmp0_elvis_lhs = this.make_7gle7u_k$(t, name, g, cx, cy, size, tok, fill);
    return tmp0_elvis_lhs == null ? listOf(new Node(newId(), NodeKind_ELLIPSE_getInstance(), 'icon', cx - size * 0.375, cy - size * 0.375, size * 0.75, size * 0.75, VOID, t.color$default_xk5c97_k$(tok), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, g, VOID, VOID, VOID, VOID, VOID, VOID, VOID, tok)) : tmp0_elvis_lhs;
  };
  protoOf(IconNodes).icon$default_pzaq2z_k$ = function (t, name, g, cx, cy, size, tok, fill, $super) {
    fill = fill === VOID ? false : fill;
    return $super === VOID ? this.icon_xdq47j_k$(t, name, g, cx, cy, size, tok, fill) : $super.icon_xdq47j_k$.call(this, t, name, g, cx, cy, size, tok, fill);
  };
  protoOf(IconNodes).menu_8qjpfe_k$ = function (t, g, cx, cy, tok) {
    var tmp0_elvis_lhs = this.make$default_d3mja_k$(t, 'menu', g, cx, cy, 24.0, tok);
    var tmp;
    if (tmp0_elvis_lhs == null) {
      // Inline function 'kotlin.collections.map' call
      var this_0 = listOf_0([-7.0, 0.0, 7.0]);
      // Inline function 'kotlin.collections.mapTo' call
      var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_0, 10));
      var _iterator__ex2g4s = this_0.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var item = _iterator__ex2g4s.next_20eer_k$();
        var tmp$ret$0 = new Node(newId(), NodeKind_RECT_getInstance(), 'menu', cx - 9.0, cy + item - 1.0, 18.0, 2.0, VOID, t.color$default_xk5c97_k$(tok), VOID, VOID, VOID, 1.0, VOID, VOID, VOID, VOID, g, VOID, VOID, VOID, VOID, VOID, VOID, VOID, tok);
        destination.add_utx5q5_k$(tmp$ret$0);
      }
      tmp = destination;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    return tmp;
  };
  var IconNodes_instance;
  function IconNodes_getInstance() {
    return IconNodes_instance;
  }
  function pick(_this__u8e3s4, i, sel, un) {
    return _this__u8e3s4.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 'pick:i' + i + '/' + sel + '/' + un);
  }
  function pick_0(_this__u8e3s4, i, sel, un) {
    // Inline function 'kotlin.collections.map' call
    // Inline function 'kotlin.collections.mapTo' call
    var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(_this__u8e3s4, 10));
    var _iterator__ex2g4s = _this__u8e3s4.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s.next_20eer_k$();
      var tmp$ret$0 = pick(item, i, sel, un);
      destination.add_utx5q5_k$(tmp$ret$0);
    }
    return destination;
  }
  var NodeKind_RECT_instance;
  var NodeKind_ELLIPSE_instance;
  var NodeKind_SHAPE_instance;
  var NodeKind_TEXT_instance;
  var NodeKind_PATH_instance;
  var NodeKind_IMAGE_instance;
  function valueOf(value) {
    switch (value) {
      case 'RECT':
        return NodeKind_RECT_getInstance();
      case 'ELLIPSE':
        return NodeKind_ELLIPSE_getInstance();
      case 'SHAPE':
        return NodeKind_SHAPE_getInstance();
      case 'TEXT':
        return NodeKind_TEXT_getInstance();
      case 'PATH':
        return NodeKind_PATH_getInstance();
      case 'IMAGE':
        return NodeKind_IMAGE_getInstance();
      default:
        NodeKind_initEntries();
        THROW_IAE('No enum constant value.');
        break;
    }
  }
  var NodeKind_entriesInitialized;
  function NodeKind_initEntries() {
    if (NodeKind_entriesInitialized)
      return Unit_instance;
    NodeKind_entriesInitialized = true;
    NodeKind_RECT_instance = new NodeKind('RECT', 0);
    NodeKind_ELLIPSE_instance = new NodeKind('ELLIPSE', 1);
    NodeKind_SHAPE_instance = new NodeKind('SHAPE', 2);
    NodeKind_TEXT_instance = new NodeKind('TEXT', 3);
    NodeKind_PATH_instance = new NodeKind('PATH', 4);
    NodeKind_IMAGE_instance = new NodeKind('IMAGE', 5);
  }
  function NodeKind(name, ordinal) {
    Enum.call(this, name, ordinal);
  }
  function Node(id, kind, name, x, y, w, h, rotation, fill, stroke, strokeWidth, opacity, corner, shapeId, text, fontSize, weight, group, visible, locked, ratioLock, path, evenOdd, asset, font, fillToken, strokeToken, blur, softBlur, pressCorner, gradKind, fill2, gradAngle, shadowBlur, shadowDx, shadowDy, shadowColor, mask, widget, action) {
    rotation = rotation === VOID ? 0.0 : rotation;
    fill = fill === VOID ? -16749974 : fill;
    stroke = stroke === VOID ? 0 : stroke;
    strokeWidth = strokeWidth === VOID ? 0.0 : strokeWidth;
    opacity = opacity === VOID ? 1.0 : opacity;
    corner = corner === VOID ? 0.0 : corner;
    shapeId = shapeId === VOID ? '' : shapeId;
    text = text === VOID ? '' : text;
    fontSize = fontSize === VOID ? 16.0 : fontSize;
    weight = weight === VOID ? 400 : weight;
    group = group === VOID ? '' : group;
    visible = visible === VOID ? true : visible;
    locked = locked === VOID ? false : locked;
    ratioLock = ratioLock === VOID ? false : ratioLock;
    path = path === VOID ? '' : path;
    evenOdd = evenOdd === VOID ? false : evenOdd;
    asset = asset === VOID ? '' : asset;
    font = font === VOID ? '' : font;
    fillToken = fillToken === VOID ? -1 : fillToken;
    strokeToken = strokeToken === VOID ? -1 : strokeToken;
    blur = blur === VOID ? 0.0 : blur;
    softBlur = softBlur === VOID ? 0.0 : softBlur;
    pressCorner = pressCorner === VOID ? -1.0 : pressCorner;
    gradKind = gradKind === VOID ? 0 : gradKind;
    fill2 = fill2 === VOID ? -16777216 : fill2;
    gradAngle = gradAngle === VOID ? 90.0 : gradAngle;
    shadowBlur = shadowBlur === VOID ? 0.0 : shadowBlur;
    shadowDx = shadowDx === VOID ? 0.0 : shadowDx;
    shadowDy = shadowDy === VOID ? 4.0 : shadowDy;
    shadowColor = shadowColor === VOID ? 1493172224 : shadowColor;
    mask = mask === VOID ? false : mask;
    widget = widget === VOID ? '' : widget;
    action = action === VOID ? '' : action;
    this.id_1 = id;
    this.kind_1 = kind;
    this.name_1 = name;
    this.x_1 = x;
    this.y_1 = y;
    this.w_1 = w;
    this.h_1 = h;
    this.rotation_1 = rotation;
    this.fill_1 = fill;
    this.stroke_1 = stroke;
    this.strokeWidth_1 = strokeWidth;
    this.opacity_1 = opacity;
    this.corner_1 = corner;
    this.shapeId_1 = shapeId;
    this.text_1 = text;
    this.fontSize_1 = fontSize;
    this.weight_1 = weight;
    this.group_1 = group;
    this.visible_1 = visible;
    this.locked_1 = locked;
    this.ratioLock_1 = ratioLock;
    this.path_1 = path;
    this.evenOdd_1 = evenOdd;
    this.asset_1 = asset;
    this.font_1 = font;
    this.fillToken_1 = fillToken;
    this.strokeToken_1 = strokeToken;
    this.blur_1 = blur;
    this.softBlur_1 = softBlur;
    this.pressCorner_1 = pressCorner;
    this.gradKind_1 = gradKind;
    this.fill2__1 = fill2;
    this.gradAngle_1 = gradAngle;
    this.shadowBlur_1 = shadowBlur;
    this.shadowDx_1 = shadowDx;
    this.shadowDy_1 = shadowDy;
    this.shadowColor_1 = shadowColor;
    this.mask_1 = mask;
    this.widget_1 = widget;
    this.action_1 = action;
  }
  protoOf(Node).get_canMask_acquwj_k$ = function () {
    return this.kind_1.equals(NodeKind_RECT_getInstance()) || this.kind_1.equals(NodeKind_ELLIPSE_getInstance()) || this.kind_1.equals(NodeKind_SHAPE_getInstance()) || this.kind_1.equals(NodeKind_PATH_getInstance());
  };
  protoOf(Node).get_isMask_ew1zy7_k$ = function () {
    return this.mask_1 && this.get_canMask_acquwj_k$();
  };
  protoOf(Node).get_hasShadow_3tjd81_k$ = function () {
    return this.shadowBlur_1 > 0.5 && (this.kind_1.equals(NodeKind_RECT_getInstance()) || this.kind_1.equals(NodeKind_ELLIPSE_getInstance()) || this.kind_1.equals(NodeKind_SHAPE_getInstance()) || this.kind_1.equals(NodeKind_PATH_getInstance()));
  };
  protoOf(Node).get_hasGradient_845ojj_k$ = function () {
    return !(this.gradKind_1 === 0) && (this.kind_1.equals(NodeKind_RECT_getInstance()) || this.kind_1.equals(NodeKind_ELLIPSE_getInstance()) || this.kind_1.equals(NodeKind_SHAPE_getInstance()) || this.kind_1.equals(NodeKind_PATH_getInstance()));
  };
  protoOf(Node).get_cx_knto1u_k$ = function () {
    return this.x_1 + this.w_1 / 2.0;
  };
  protoOf(Node).get_cy_knto1t_k$ = function () {
    return this.y_1 + this.h_1 / 2.0;
  };
  protoOf(Node).bounds_mvivyj_k$ = function () {
    if (this.rotation_1 === 0.0)
      return new Box(this.x_1, this.y_1, this.x_1 + this.w_1, this.y_1 + this.h_1);
    var pts = this.corners_fsly9q_k$();
    var l = 3.4028235E38;
    var t = 3.4028235E38;
    var r = -3.4028235E38;
    var b = -3.4028235E38;
    var inductionVariable = 0;
    if (inductionVariable < 4)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var tmp0 = l;
        // Inline function 'kotlin.math.min' call
        var b_0 = pts[imul(i, 2)];
        l = Math.min(tmp0, b_0);
        var tmp2 = r;
        // Inline function 'kotlin.math.max' call
        var b_1 = pts[imul(i, 2)];
        r = Math.max(tmp2, b_1);
        var tmp4 = t;
        // Inline function 'kotlin.math.min' call
        var b_2 = pts[imul(i, 2) + 1 | 0];
        t = Math.min(tmp4, b_2);
        var tmp6 = b;
        // Inline function 'kotlin.math.max' call
        var b_3 = pts[imul(i, 2) + 1 | 0];
        b = Math.max(tmp6, b_3);
      }
       while (inductionVariable < 4);
    return new Box(l, t, r, b);
  };
  protoOf(Node).corners_fsly9q_k$ = function () {
    var out = new Float32Array(8);
    var hx = this.w_1 / 2.0;
    var hy = this.h_1 / 2.0;
    // Inline function 'kotlin.floatArrayOf' call
    var xs = new Float32Array([-hx, hx, hx, -hx]);
    // Inline function 'kotlin.floatArrayOf' call
    var ys = new Float32Array([-hy, -hy, hy, hy]);
    var inductionVariable = 0;
    if (inductionVariable < 4)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var p = rotate(xs[i], ys[i], this.rotation_1);
        out[imul(i, 2)] = this.get_cx_knto1u_k$() + p.first_1;
        out[imul(i, 2) + 1 | 0] = this.get_cy_knto1t_k$() + p.second_1;
      }
       while (inductionVariable < 4);
    return out;
  };
  protoOf(Node).copy_k318qi_k$ = function (id, kind, name, x, y, w, h, rotation, fill, stroke, strokeWidth, opacity, corner, shapeId, text, fontSize, weight, group, visible, locked, ratioLock, path, evenOdd, asset, font, fillToken, strokeToken, blur, softBlur, pressCorner, gradKind, fill2, gradAngle, shadowBlur, shadowDx, shadowDy, shadowColor, mask, widget, action) {
    return new Node(id, kind, name, x, y, w, h, rotation, fill, stroke, strokeWidth, opacity, corner, shapeId, text, fontSize, weight, group, visible, locked, ratioLock, path, evenOdd, asset, font, fillToken, strokeToken, blur, softBlur, pressCorner, gradKind, fill2, gradAngle, shadowBlur, shadowDx, shadowDy, shadowColor, mask, widget, action);
  };
  protoOf(Node).copy$default_q375vp_k$ = function (id, kind, name, x, y, w, h, rotation, fill, stroke, strokeWidth, opacity, corner, shapeId, text, fontSize, weight, group, visible, locked, ratioLock, path, evenOdd, asset, font, fillToken, strokeToken, blur, softBlur, pressCorner, gradKind, fill2, gradAngle, shadowBlur, shadowDx, shadowDy, shadowColor, mask, widget, action, $super) {
    id = id === VOID ? this.id_1 : id;
    kind = kind === VOID ? this.kind_1 : kind;
    name = name === VOID ? this.name_1 : name;
    x = x === VOID ? this.x_1 : x;
    y = y === VOID ? this.y_1 : y;
    w = w === VOID ? this.w_1 : w;
    h = h === VOID ? this.h_1 : h;
    rotation = rotation === VOID ? this.rotation_1 : rotation;
    fill = fill === VOID ? this.fill_1 : fill;
    stroke = stroke === VOID ? this.stroke_1 : stroke;
    strokeWidth = strokeWidth === VOID ? this.strokeWidth_1 : strokeWidth;
    opacity = opacity === VOID ? this.opacity_1 : opacity;
    corner = corner === VOID ? this.corner_1 : corner;
    shapeId = shapeId === VOID ? this.shapeId_1 : shapeId;
    text = text === VOID ? this.text_1 : text;
    fontSize = fontSize === VOID ? this.fontSize_1 : fontSize;
    weight = weight === VOID ? this.weight_1 : weight;
    group = group === VOID ? this.group_1 : group;
    visible = visible === VOID ? this.visible_1 : visible;
    locked = locked === VOID ? this.locked_1 : locked;
    ratioLock = ratioLock === VOID ? this.ratioLock_1 : ratioLock;
    path = path === VOID ? this.path_1 : path;
    evenOdd = evenOdd === VOID ? this.evenOdd_1 : evenOdd;
    asset = asset === VOID ? this.asset_1 : asset;
    font = font === VOID ? this.font_1 : font;
    fillToken = fillToken === VOID ? this.fillToken_1 : fillToken;
    strokeToken = strokeToken === VOID ? this.strokeToken_1 : strokeToken;
    blur = blur === VOID ? this.blur_1 : blur;
    softBlur = softBlur === VOID ? this.softBlur_1 : softBlur;
    pressCorner = pressCorner === VOID ? this.pressCorner_1 : pressCorner;
    gradKind = gradKind === VOID ? this.gradKind_1 : gradKind;
    fill2 = fill2 === VOID ? this.fill2__1 : fill2;
    gradAngle = gradAngle === VOID ? this.gradAngle_1 : gradAngle;
    shadowBlur = shadowBlur === VOID ? this.shadowBlur_1 : shadowBlur;
    shadowDx = shadowDx === VOID ? this.shadowDx_1 : shadowDx;
    shadowDy = shadowDy === VOID ? this.shadowDy_1 : shadowDy;
    shadowColor = shadowColor === VOID ? this.shadowColor_1 : shadowColor;
    mask = mask === VOID ? this.mask_1 : mask;
    widget = widget === VOID ? this.widget_1 : widget;
    action = action === VOID ? this.action_1 : action;
    return $super === VOID ? this.copy_k318qi_k$(id, kind, name, x, y, w, h, rotation, fill, stroke, strokeWidth, opacity, corner, shapeId, text, fontSize, weight, group, visible, locked, ratioLock, path, evenOdd, asset, font, fillToken, strokeToken, blur, softBlur, pressCorner, gradKind, fill2, gradAngle, shadowBlur, shadowDx, shadowDy, shadowColor, mask, widget, action) : $super.copy_k318qi_k$.call(this, id, kind, name, x, y, w, h, rotation, fill, stroke, strokeWidth, opacity, corner, shapeId, text, fontSize, weight, group, visible, locked, ratioLock, path, evenOdd, asset, font, fillToken, strokeToken, blur, softBlur, pressCorner, gradKind, fill2, gradAngle, shadowBlur, shadowDx, shadowDy, shadowColor, mask, widget, action);
  };
  protoOf(Node).toString = function () {
    return 'Node(id=' + this.id_1 + ', kind=' + this.kind_1.toString() + ', name=' + this.name_1 + ', x=' + this.x_1 + ', y=' + this.y_1 + ', w=' + this.w_1 + ', h=' + this.h_1 + ', rotation=' + this.rotation_1 + ', fill=' + this.fill_1 + ', stroke=' + this.stroke_1 + ', strokeWidth=' + this.strokeWidth_1 + ', opacity=' + this.opacity_1 + ', corner=' + this.corner_1 + ', shapeId=' + this.shapeId_1 + ', text=' + this.text_1 + ', fontSize=' + this.fontSize_1 + ', weight=' + this.weight_1 + ', group=' + this.group_1 + ', visible=' + this.visible_1 + ', locked=' + this.locked_1 + ', ratioLock=' + this.ratioLock_1 + ', path=' + this.path_1 + ', evenOdd=' + this.evenOdd_1 + ', asset=' + this.asset_1 + ', font=' + this.font_1 + ', fillToken=' + this.fillToken_1 + ', strokeToken=' + this.strokeToken_1 + ', blur=' + this.blur_1 + ', softBlur=' + this.softBlur_1 + ', pressCorner=' + this.pressCorner_1 + ', gradKind=' + this.gradKind_1 + ', fill2=' + this.fill2__1 + ', gradAngle=' + this.gradAngle_1 + ', shadowBlur=' + this.shadowBlur_1 + ', shadowDx=' + this.shadowDx_1 + ', shadowDy=' + this.shadowDy_1 + ', shadowColor=' + this.shadowColor_1 + ', mask=' + this.mask_1 + ', widget=' + this.widget_1 + ', action=' + this.action_1 + ')';
  };
  protoOf(Node).hashCode = function () {
    var result = getStringHashCode(this.id_1);
    result = imul(result, 31) + this.kind_1.hashCode() | 0;
    result = imul(result, 31) + getStringHashCode(this.name_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.x_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.y_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.w_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.h_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.rotation_1) | 0;
    result = imul(result, 31) + this.fill_1 | 0;
    result = imul(result, 31) + this.stroke_1 | 0;
    result = imul(result, 31) + getNumberHashCode(this.strokeWidth_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.opacity_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.corner_1) | 0;
    result = imul(result, 31) + getStringHashCode(this.shapeId_1) | 0;
    result = imul(result, 31) + getStringHashCode(this.text_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.fontSize_1) | 0;
    result = imul(result, 31) + this.weight_1 | 0;
    result = imul(result, 31) + getStringHashCode(this.group_1) | 0;
    result = imul(result, 31) + getBooleanHashCode(this.visible_1) | 0;
    result = imul(result, 31) + getBooleanHashCode(this.locked_1) | 0;
    result = imul(result, 31) + getBooleanHashCode(this.ratioLock_1) | 0;
    result = imul(result, 31) + getStringHashCode(this.path_1) | 0;
    result = imul(result, 31) + getBooleanHashCode(this.evenOdd_1) | 0;
    result = imul(result, 31) + getStringHashCode(this.asset_1) | 0;
    result = imul(result, 31) + getStringHashCode(this.font_1) | 0;
    result = imul(result, 31) + this.fillToken_1 | 0;
    result = imul(result, 31) + this.strokeToken_1 | 0;
    result = imul(result, 31) + getNumberHashCode(this.blur_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.softBlur_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.pressCorner_1) | 0;
    result = imul(result, 31) + this.gradKind_1 | 0;
    result = imul(result, 31) + this.fill2__1 | 0;
    result = imul(result, 31) + getNumberHashCode(this.gradAngle_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.shadowBlur_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.shadowDx_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.shadowDy_1) | 0;
    result = imul(result, 31) + this.shadowColor_1 | 0;
    result = imul(result, 31) + getBooleanHashCode(this.mask_1) | 0;
    result = imul(result, 31) + getStringHashCode(this.widget_1) | 0;
    result = imul(result, 31) + getStringHashCode(this.action_1) | 0;
    return result;
  };
  protoOf(Node).equals = function (other) {
    if (this === other)
      return true;
    if (!(other instanceof Node))
      return false;
    var tmp0_other_with_cast = other instanceof Node ? other : THROW_CCE();
    if (!(this.id_1 === tmp0_other_with_cast.id_1))
      return false;
    if (!this.kind_1.equals(tmp0_other_with_cast.kind_1))
      return false;
    if (!(this.name_1 === tmp0_other_with_cast.name_1))
      return false;
    if (!equals(this.x_1, tmp0_other_with_cast.x_1))
      return false;
    if (!equals(this.y_1, tmp0_other_with_cast.y_1))
      return false;
    if (!equals(this.w_1, tmp0_other_with_cast.w_1))
      return false;
    if (!equals(this.h_1, tmp0_other_with_cast.h_1))
      return false;
    if (!equals(this.rotation_1, tmp0_other_with_cast.rotation_1))
      return false;
    if (!(this.fill_1 === tmp0_other_with_cast.fill_1))
      return false;
    if (!(this.stroke_1 === tmp0_other_with_cast.stroke_1))
      return false;
    if (!equals(this.strokeWidth_1, tmp0_other_with_cast.strokeWidth_1))
      return false;
    if (!equals(this.opacity_1, tmp0_other_with_cast.opacity_1))
      return false;
    if (!equals(this.corner_1, tmp0_other_with_cast.corner_1))
      return false;
    if (!(this.shapeId_1 === tmp0_other_with_cast.shapeId_1))
      return false;
    if (!(this.text_1 === tmp0_other_with_cast.text_1))
      return false;
    if (!equals(this.fontSize_1, tmp0_other_with_cast.fontSize_1))
      return false;
    if (!(this.weight_1 === tmp0_other_with_cast.weight_1))
      return false;
    if (!(this.group_1 === tmp0_other_with_cast.group_1))
      return false;
    if (!(this.visible_1 === tmp0_other_with_cast.visible_1))
      return false;
    if (!(this.locked_1 === tmp0_other_with_cast.locked_1))
      return false;
    if (!(this.ratioLock_1 === tmp0_other_with_cast.ratioLock_1))
      return false;
    if (!(this.path_1 === tmp0_other_with_cast.path_1))
      return false;
    if (!(this.evenOdd_1 === tmp0_other_with_cast.evenOdd_1))
      return false;
    if (!(this.asset_1 === tmp0_other_with_cast.asset_1))
      return false;
    if (!(this.font_1 === tmp0_other_with_cast.font_1))
      return false;
    if (!(this.fillToken_1 === tmp0_other_with_cast.fillToken_1))
      return false;
    if (!(this.strokeToken_1 === tmp0_other_with_cast.strokeToken_1))
      return false;
    if (!equals(this.blur_1, tmp0_other_with_cast.blur_1))
      return false;
    if (!equals(this.softBlur_1, tmp0_other_with_cast.softBlur_1))
      return false;
    if (!equals(this.pressCorner_1, tmp0_other_with_cast.pressCorner_1))
      return false;
    if (!(this.gradKind_1 === tmp0_other_with_cast.gradKind_1))
      return false;
    if (!(this.fill2__1 === tmp0_other_with_cast.fill2__1))
      return false;
    if (!equals(this.gradAngle_1, tmp0_other_with_cast.gradAngle_1))
      return false;
    if (!equals(this.shadowBlur_1, tmp0_other_with_cast.shadowBlur_1))
      return false;
    if (!equals(this.shadowDx_1, tmp0_other_with_cast.shadowDx_1))
      return false;
    if (!equals(this.shadowDy_1, tmp0_other_with_cast.shadowDy_1))
      return false;
    if (!(this.shadowColor_1 === tmp0_other_with_cast.shadowColor_1))
      return false;
    if (!(this.mask_1 === tmp0_other_with_cast.mask_1))
      return false;
    if (!(this.widget_1 === tmp0_other_with_cast.widget_1))
      return false;
    if (!(this.action_1 === tmp0_other_with_cast.action_1))
      return false;
    return true;
  };
  function Box(l, t, r, b) {
    this.l_1 = l;
    this.t_1 = t;
    this.r_1 = r;
    this.b_1 = b;
  }
  protoOf(Box).get_w_1mhr66_k$ = function () {
    return this.r_1 - this.l_1;
  };
  protoOf(Box).get_h_1mhr5r_k$ = function () {
    return this.b_1 - this.t_1;
  };
  protoOf(Box).get_cx_knto1u_k$ = function () {
    return (this.l_1 + this.r_1) / 2.0;
  };
  protoOf(Box).get_cy_knto1t_k$ = function () {
    return (this.t_1 + this.b_1) / 2.0;
  };
  protoOf(Box).union_j60epv_k$ = function (o) {
    var tmp0 = this.l_1;
    // Inline function 'kotlin.math.min' call
    var b = o.l_1;
    var tmp = Math.min(tmp0, b);
    var tmp2 = this.t_1;
    // Inline function 'kotlin.math.min' call
    var b_0 = o.t_1;
    var tmp_0 = Math.min(tmp2, b_0);
    var tmp4 = this.r_1;
    // Inline function 'kotlin.math.max' call
    var b_1 = o.r_1;
    var tmp_1 = Math.max(tmp4, b_1);
    var tmp6 = this.b_1;
    // Inline function 'kotlin.math.max' call
    var b_2 = o.b_1;
    var tmp$ret$3 = Math.max(tmp6, b_2);
    return new Box(tmp, tmp_0, tmp_1, tmp$ret$3);
  };
  protoOf(Box).toString = function () {
    return 'Box(l=' + this.l_1 + ', t=' + this.t_1 + ', r=' + this.r_1 + ', b=' + this.b_1 + ')';
  };
  protoOf(Box).hashCode = function () {
    var result = getNumberHashCode(this.l_1);
    result = imul(result, 31) + getNumberHashCode(this.t_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.r_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.b_1) | 0;
    return result;
  };
  protoOf(Box).equals = function (other) {
    if (this === other)
      return true;
    if (!(other instanceof Box))
      return false;
    var tmp0_other_with_cast = other instanceof Box ? other : THROW_CCE();
    if (!equals(this.l_1, tmp0_other_with_cast.l_1))
      return false;
    if (!equals(this.t_1, tmp0_other_with_cast.t_1))
      return false;
    if (!equals(this.r_1, tmp0_other_with_cast.r_1))
      return false;
    if (!equals(this.b_1, tmp0_other_with_cast.b_1))
      return false;
    return true;
  };
  function Project(id, name, width, height, background, nodes, created, updated, tone, bgToken, pages, activePage) {
    tone = tone === VOID ? Companion_getInstance_11().Baseline_1 : tone;
    bgToken = bgToken === VOID ? -1 : bgToken;
    pages = pages === VOID ? emptyList() : pages;
    activePage = activePage === VOID ? 0 : activePage;
    this.id_1 = id;
    this.name_1 = name;
    this.width_1 = width;
    this.height_1 = height;
    this.background_1 = background;
    this.nodes_1 = nodes;
    this.created_1 = created;
    this.updated_1 = updated;
    this.tone_1 = tone;
    this.bgToken_1 = bgToken;
    this.pages_1 = pages;
    this.activePage_1 = activePage;
  }
  protoOf(Project).copy_esogvb_k$ = function (id, name, width, height, background, nodes, created, updated, tone, bgToken, pages, activePage) {
    return new Project(id, name, width, height, background, nodes, created, updated, tone, bgToken, pages, activePage);
  };
  protoOf(Project).copy$default_4q9ge3_k$ = function (id, name, width, height, background, nodes, created, updated, tone, bgToken, pages, activePage, $super) {
    id = id === VOID ? this.id_1 : id;
    name = name === VOID ? this.name_1 : name;
    width = width === VOID ? this.width_1 : width;
    height = height === VOID ? this.height_1 : height;
    background = background === VOID ? this.background_1 : background;
    nodes = nodes === VOID ? this.nodes_1 : nodes;
    created = created === VOID ? this.created_1 : created;
    updated = updated === VOID ? this.updated_1 : updated;
    tone = tone === VOID ? this.tone_1 : tone;
    bgToken = bgToken === VOID ? this.bgToken_1 : bgToken;
    pages = pages === VOID ? this.pages_1 : pages;
    activePage = activePage === VOID ? this.activePage_1 : activePage;
    return $super === VOID ? this.copy_esogvb_k$(id, name, width, height, background, nodes, created, updated, tone, bgToken, pages, activePage) : $super.copy_esogvb_k$.call(this, id, name, width, height, background, nodes, created, updated, tone, bgToken, pages, activePage);
  };
  protoOf(Project).toString = function () {
    return 'Project(id=' + this.id_1 + ', name=' + this.name_1 + ', width=' + this.width_1 + ', height=' + this.height_1 + ', background=' + this.background_1 + ', nodes=' + toString_1(this.nodes_1) + ', created=' + this.created_1.toString() + ', updated=' + this.updated_1.toString() + ', tone=' + this.tone_1.toString() + ', bgToken=' + this.bgToken_1 + ', pages=' + toString_1(this.pages_1) + ', activePage=' + this.activePage_1 + ')';
  };
  protoOf(Project).hashCode = function () {
    var result = getStringHashCode(this.id_1);
    result = imul(result, 31) + getStringHashCode(this.name_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.width_1) | 0;
    result = imul(result, 31) + getNumberHashCode(this.height_1) | 0;
    result = imul(result, 31) + this.background_1 | 0;
    result = imul(result, 31) + hashCode(this.nodes_1) | 0;
    result = imul(result, 31) + this.created_1.hashCode() | 0;
    result = imul(result, 31) + this.updated_1.hashCode() | 0;
    result = imul(result, 31) + this.tone_1.hashCode() | 0;
    result = imul(result, 31) + this.bgToken_1 | 0;
    result = imul(result, 31) + hashCode(this.pages_1) | 0;
    result = imul(result, 31) + this.activePage_1 | 0;
    return result;
  };
  protoOf(Project).equals = function (other) {
    if (this === other)
      return true;
    if (!(other instanceof Project))
      return false;
    var tmp0_other_with_cast = other instanceof Project ? other : THROW_CCE();
    if (!(this.id_1 === tmp0_other_with_cast.id_1))
      return false;
    if (!(this.name_1 === tmp0_other_with_cast.name_1))
      return false;
    if (!equals(this.width_1, tmp0_other_with_cast.width_1))
      return false;
    if (!equals(this.height_1, tmp0_other_with_cast.height_1))
      return false;
    if (!(this.background_1 === tmp0_other_with_cast.background_1))
      return false;
    if (!equals(this.nodes_1, tmp0_other_with_cast.nodes_1))
      return false;
    if (!this.created_1.equals(tmp0_other_with_cast.created_1))
      return false;
    if (!this.updated_1.equals(tmp0_other_with_cast.updated_1))
      return false;
    if (!this.tone_1.equals(tmp0_other_with_cast.tone_1))
      return false;
    if (!(this.bgToken_1 === tmp0_other_with_cast.bgToken_1))
      return false;
    if (!equals(this.pages_1, tmp0_other_with_cast.pages_1))
      return false;
    if (!(this.activePage_1 === tmp0_other_with_cast.activePage_1))
      return false;
    return true;
  };
  function Page(id, name, nodes) {
    this.id_1 = id;
    this.name_1 = name;
    this.nodes_1 = nodes;
  }
  protoOf(Page).toString = function () {
    return 'Page(id=' + this.id_1 + ', name=' + this.name_1 + ', nodes=' + toString_1(this.nodes_1) + ')';
  };
  protoOf(Page).hashCode = function () {
    var result = getStringHashCode(this.id_1);
    result = imul(result, 31) + getStringHashCode(this.name_1) | 0;
    result = imul(result, 31) + hashCode(this.nodes_1) | 0;
    return result;
  };
  protoOf(Page).equals = function (other) {
    if (this === other)
      return true;
    if (!(other instanceof Page))
      return false;
    var tmp0_other_with_cast = other instanceof Page ? other : THROW_CCE();
    if (!(this.id_1 === tmp0_other_with_cast.id_1))
      return false;
    if (!(this.name_1 === tmp0_other_with_cast.name_1))
      return false;
    if (!equals(this.nodes_1, tmp0_other_with_cast.nodes_1))
      return false;
    return true;
  };
  function rotate(x, y, degrees) {
    if (degrees === 0.0)
      return to(x, y);
    var a = Math_instance.toRadians_sjqwz3_k$(degrees);
    // Inline function 'kotlin.math.cos' call
    var c = Math.cos(a);
    // Inline function 'kotlin.math.sin' call
    var s = Math.sin(a);
    return to(x * c - y * s, x * s + y * c);
  }
  function newId() {
    return freshId();
  }
  function TextMetrics$widthOf$lambda(s, size, _unused_var__etf5q3, _unused_var__etf5q3_0) {
    return s.length * size * 0.55;
  }
  function TextMetrics() {
    TextMetrics_instance = this;
    var tmp = this;
    tmp.widthOf_1 = TextMetrics$widthOf$lambda;
  }
  protoOf(TextMetrics).size_oze5wh_k$ = function (text, fontSize, weight, font) {
    var lines = split(text, charArrayOf([_Char___init__impl__6a9atx(10)]));
    // Inline function 'kotlin.collections.maxOf' call
    var iterator = lines.iterator_jk1svi_k$();
    if (!iterator.hasNext_bitz1p_k$())
      throw NoSuchElementException_init_$Create$();
    var it = iterator.next_20eer_k$();
    var maxValue = TextMetrics_getInstance().widthOf_1(it, fontSize, weight, font);
    while (iterator.hasNext_bitz1p_k$()) {
      var it_0 = iterator.next_20eer_k$();
      var v = TextMetrics_getInstance().widthOf_1(it_0, fontSize, weight, font);
      // Inline function 'kotlin.comparisons.maxOf' call
      var a = maxValue;
      maxValue = Math.max(a, v);
    }
    var w = maxValue;
    // Inline function 'kotlin.math.max' call
    var tmp = Math.max(1.0, w);
    // Inline function 'kotlin.math.max' call
    var b = lines.get_size_woubt6_k$() * fontSize * 1.25;
    var tmp$ret$5 = Math.max(1.0, b);
    return to(tmp, tmp$ret$5);
  };
  var TextMetrics_instance;
  function TextMetrics_getInstance() {
    if (TextMetrics_instance == null)
      new TextMetrics();
    return TextMetrics_instance;
  }
  function withTextSize(_this__u8e3s4) {
    if (!_this__u8e3s4.kind_1.equals(NodeKind_TEXT_getInstance()))
      return _this__u8e3s4;
    var _destruct__k2r9zo = TextMetrics_getInstance().size_oze5wh_k$(_this__u8e3s4.text_1, _this__u8e3s4.fontSize_1, _this__u8e3s4.weight_1, _this__u8e3s4.font_1);
    var nw = _destruct__k2r9zo.component1_7eebsc_k$();
    var nh = _destruct__k2r9zo.component2_7eebsb_k$();
    return _this__u8e3s4.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, nw, nh);
  }
  function boundsOf(nodes) {
    var res = null;
    var _iterator__ex2g4s = nodes.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var n = _iterator__ex2g4s.next_20eer_k$();
      var tmp0_safe_receiver = res;
      var tmp1_elvis_lhs = tmp0_safe_receiver == null ? null : tmp0_safe_receiver.union_j60epv_k$(n.bounds_mvivyj_k$());
      res = tmp1_elvis_lhs == null ? n.bounds_mvivyj_k$() : tmp1_elvis_lhs;
    }
    return res;
  }
  function w(_this__u8e3s4, role) {
    return _this__u8e3s4.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, role);
  }
  function NodeKind_RECT_getInstance() {
    NodeKind_initEntries();
    return NodeKind_RECT_instance;
  }
  function NodeKind_ELLIPSE_getInstance() {
    NodeKind_initEntries();
    return NodeKind_ELLIPSE_instance;
  }
  function NodeKind_SHAPE_getInstance() {
    NodeKind_initEntries();
    return NodeKind_SHAPE_instance;
  }
  function NodeKind_TEXT_getInstance() {
    NodeKind_initEntries();
    return NodeKind_TEXT_instance;
  }
  function NodeKind_PATH_getInstance() {
    NodeKind_initEntries();
    return NodeKind_PATH_instance;
  }
  function NodeKind_IMAGE_getInstance() {
    NodeKind_initEntries();
    return NodeKind_IMAGE_instance;
  }
  function Swatch(name, argb) {
    this.name_1 = name;
    this.argb_1 = argb;
  }
  protoOf(Swatch).toString = function () {
    return 'Swatch(name=' + this.name_1 + ', argb=' + this.argb_1 + ')';
  };
  protoOf(Swatch).hashCode = function () {
    var result = getStringHashCode(this.name_1);
    result = imul(result, 31) + this.argb_1 | 0;
    return result;
  };
  protoOf(Swatch).equals = function (other) {
    if (this === other)
      return true;
    if (!(other instanceof Swatch))
      return false;
    var tmp0_other_with_cast = other instanceof Swatch ? other : THROW_CCE();
    if (!(this.name_1 === tmp0_other_with_cast.name_1))
      return false;
    if (!(this.argb_1 === tmp0_other_with_cast.argb_1))
      return false;
    return true;
  };
  function c($this, hex) {
    return (new Long(-16777216, 0)).or_yj0lj3_k$(hex).toInt_1tsl84_k$();
  }
  function DesignPalette$baseline$delegate$lambda() {
    // Inline function 'kotlin.collections.map' call
    var this_0 = zip(DesignPalette_getInstance().baselineNames_1, ToneGen_instance.scheme_n1wg6q_k$(-16749974, false));
    // Inline function 'kotlin.collections.mapTo' call
    var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_0, 10));
    var _iterator__ex2g4s = this_0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s.next_20eer_k$();
      var n = item.component1_7eebsc_k$();
      var argb = item.component2_7eebsb_k$();
      var tmp$ret$0 = new Swatch(n, argb);
      destination.add_utx5q5_k$(tmp$ret$0);
    }
    return destination;
  }
  function DesignPalette$cycle$delegate$lambda() {
    // Inline function 'kotlin.intArrayOf' call
    // Inline function 'kotlin.collections.map' call
    var this_0 = new Int32Array([0, 8, 2, 7, 5, 10]);
    // Inline function 'kotlin.collections.mapTo' call
    var destination = ArrayList_init_$Create$_0(this_0.length);
    var inductionVariable = 0;
    var last = this_0.length;
    while (inductionVariable < last) {
      var item = this_0[inductionVariable];
      inductionVariable = inductionVariable + 1 | 0;
      var tmp$ret$1 = DesignPalette_getInstance().get_baseline_arnwum_k$().get_c1px32_k$(item).argb_1;
      destination.add_utx5q5_k$(tmp$ret$1);
    }
    return toIntArray(destination);
  }
  function DesignPalette() {
    DesignPalette_instance = this;
    this.baselineNames_1 = listOf_0(['primary', 'on-primary', 'primary-container', 'on-primary-container', 'secondary', 'secondary-container', 'on-secondary-container', 'tertiary', 'tertiary-container', 'on-tertiary-container', 'error', 'error-container', 'surface', 'surface-container-low', 'surface-container', 'surface-container-high', 'surface-container-highest', 'on-surface', 'on-surface-variant', 'outline', 'outline-variant', 'inverse-surface']);
    var tmp = this;
    tmp.baseline$delegate_1 = lazy(DesignPalette$baseline$delegate$lambda);
    this.qwel_1 = listOf_0([new Swatch('primary', c(this, new Long(6572734, 0))), new Swatch('primary-container', c(this, new Long(15326719, 0))), new Swatch('secondary', c(this, new Long(6510725, 0))), new Swatch('secondary-container', c(this, new Long(15326719, 0))), new Swatch('tertiary', c(this, new Long(11154723, 0))), new Swatch('tertiary-container', c(this, new Long(16767698, 0))), new Swatch('surface', c(this, new Long(16513279, 0))), new Swatch('surface-container', c(this, new Long(15724020, 0)))]);
    this.neutral_1 = listOf_0([new Swatch('white', c(this, new Long(16777215, 0))), new Swatch('black', c(this, new Long(0, 0))), new Swatch('none', 0)]);
    var tmp_0 = this;
    tmp_0.cycle$delegate_1 = lazy(DesignPalette$cycle$delegate$lambda);
    var tmp_1 = this;
    // Inline function 'kotlin.intArrayOf' call
    tmp_1.cycleTokens_1 = new Int32Array([0, 8, 2, 7, 5, 10]);
  }
  protoOf(DesignPalette).get_baseline_arnwum_k$ = function () {
    var tmp0 = this.baseline$delegate_1;
    // Inline function 'kotlin.getValue' call
    baseline$factory();
    return tmp0.get_value_j01efc_k$();
  };
  var DesignPalette_instance;
  function DesignPalette_getInstance() {
    if (DesignPalette_instance == null)
      new DesignPalette();
    return DesignPalette_instance;
  }
  function baseline$factory() {
    return getPropertyCallableRef('baseline', 1, KProperty1, function (receiver) {
      return receiver.get_baseline_arnwum_k$();
    }, null);
  }
  function Widget(group, kind, nodes, all) {
    all = all === VOID ? nodes : all;
    this.group_1 = group;
    this.kind_1 = kind;
    this.nodes_1 = nodes;
    this.all_1 = all;
  }
  protoOf(Widget).part_s8somf_k$ = function (p) {
    var tmp0 = this.nodes_1;
    var tmp$ret$1;
    $l$block: {
      // Inline function 'kotlin.collections.firstOrNull' call
      var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s.next_20eer_k$();
        if (substringBefore(substringAfter(element.widget_1, _Char___init__impl__6a9atx(58)), _Char___init__impl__6a9atx(47)) === p) {
          tmp$ret$1 = element;
          break $l$block;
        }
      }
      tmp$ret$1 = null;
    }
    return tmp$ret$1;
  };
  protoOf(Widget).parts_9zuly2_k$ = function (p) {
    // Inline function 'kotlin.collections.filter' call
    var tmp0 = this.nodes_1;
    // Inline function 'kotlin.collections.filterTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      if (substringBefore(substringAfter(element.widget_1, _Char___init__impl__6a9atx(58)), _Char___init__impl__6a9atx(47)) === p) {
        destination.add_utx5q5_k$(element);
      }
    }
    return destination;
  };
  protoOf(Widget).get_bounds_bj99ku_k$ = function () {
    return boundsOf(this.all_1);
  };
  function autoPress($this, all) {
    if (all.get_size_woubt6_k$() > 60)
      return false;
    var tmp0_elvis_lhs = boundsOf(all);
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return false;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var b = tmp;
    return b.get_w_1mhr66_k$() * b.get_h_1mhr5r_k$() < 140000.0;
  }
  function PItem(k, nodes) {
    this.k_1 = k;
    this.nodes_1 = nodes;
    var tmp = this;
    // Inline function 'kotlin.collections.filter' call
    var tmp0 = this.nodes_1;
    // Inline function 'kotlin.collections.filterTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      if (element.opacity_1 > 0.05 && element.w_1 > 1.0) {
        destination.add_utx5q5_k$(element);
      }
    }
    // Inline function 'kotlin.collections.ifEmpty' call
    var tmp_0;
    if (destination.isEmpty_y1axqb_k$()) {
      tmp_0 = this.nodes_1;
    } else {
      tmp_0 = destination;
    }
    var tmp$ret$4 = tmp_0;
    tmp.box_1 = ensureNotNull(boundsOf(tmp$ret$4));
  }
  function extras($this, role, from) {
    return drop(split(role, charArrayOf([_Char___init__impl__6a9atx(47)])), from);
  }
  function floats($this, v) {
    // Inline function 'kotlin.collections.mapNotNull' call
    var tmp0 = split(v, charArrayOf([_Char___init__impl__6a9atx(59)]));
    // Inline function 'kotlin.collections.mapNotNullTo' call
    var destination = ArrayList_init_$Create$();
    // Inline function 'kotlin.collections.forEach' call
    var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      // Inline function 'kotlin.text.toFloatOrNull' call
      // Inline function 'kotlin.js.unsafeCast' call
      // Inline function 'kotlin.js.asDynamic' call
      var tmp0_safe_receiver = toDoubleOrNull(element);
      if (tmp0_safe_receiver == null)
        null;
      else {
        // Inline function 'kotlin.let' call
        destination.add_utx5q5_k$(tmp0_safe_receiver);
      }
    }
    // Inline function 'kotlin.takeIf' call
    var tmp;
    // Inline function 'kotlin.collections.isNotEmpty' call
    if (!destination.isEmpty_y1axqb_k$()) {
      tmp = destination;
    } else {
      tmp = null;
    }
    return tmp;
  }
  function xsOfRole($this, role, from) {
    var tmp0 = extras($this, role, from);
    var tmp$ret$1;
    $l$block: {
      // Inline function 'kotlin.collections.firstOrNull' call
      var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s.next_20eer_k$();
        if (!(element === 'f') && !startsWith(element, 'w=')) {
          tmp$ret$1 = element;
          break $l$block;
        }
      }
      tmp$ret$1 = null;
    }
    var tmp0_safe_receiver = tmp$ret$1;
    var tmp;
    if (tmp0_safe_receiver == null) {
      tmp = null;
    } else {
      // Inline function 'kotlin.let' call
      tmp = floats($this, tmp0_safe_receiver);
    }
    return tmp;
  }
  function wsOfRole($this, role, from) {
    var tmp0 = extras($this, role, from);
    var tmp$ret$1;
    $l$block: {
      // Inline function 'kotlin.collections.firstOrNull' call
      var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s.next_20eer_k$();
        if (startsWith(element, 'w=')) {
          tmp$ret$1 = element;
          break $l$block;
        }
      }
      tmp$ret$1 = null;
    }
    var tmp0_safe_receiver = tmp$ret$1;
    var tmp1_safe_receiver = tmp0_safe_receiver == null ? null : removePrefix(tmp0_safe_receiver, 'w=');
    var tmp;
    if (tmp1_safe_receiver == null) {
      tmp = null;
    } else {
      // Inline function 'kotlin.let' call
      tmp = floats($this, tmp1_safe_receiver);
    }
    return tmp;
  }
  function fadeOfRole($this, role, from) {
    return extras($this, role, from).contains_aljjnj_k$('f');
  }
  function pickItems($this, w) {
    // Inline function 'kotlin.collections.filter' call
    var tmp0 = w.nodes_1;
    // Inline function 'kotlin.collections.filterTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      if (startsWith(element.widget_1, 'pick:i')) {
        destination.add_utx5q5_k$(element);
      }
    }
    // Inline function 'kotlin.collections.groupBy' call
    // Inline function 'kotlin.collections.groupByTo' call
    var destination_0 = LinkedHashMap_init_$Create$();
    var _iterator__ex2g4s_0 = destination.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
      var element_0 = _iterator__ex2g4s_0.next_20eer_k$();
      var tmp0_elvis_lhs = toIntOrNull(substringBefore(substringAfter_0(element_0.widget_1, 'pick:i'), _Char___init__impl__6a9atx(47)));
      var key = tmp0_elvis_lhs == null ? -1 : tmp0_elvis_lhs;
      // Inline function 'kotlin.collections.getOrPut' call
      var value = destination_0.get_wei43m_k$(key);
      var tmp;
      if (value == null) {
        var answer = ArrayList_init_$Create$();
        destination_0.put_4fpzoq_k$(key, answer);
        tmp = answer;
      } else {
        tmp = value;
      }
      var list = tmp;
      list.add_utx5q5_k$(element_0);
    }
    // Inline function 'kotlin.collections.filterKeys' call
    var result = LinkedHashMap_init_$Create$();
    // Inline function 'kotlin.collections.iterator' call
    var _iterator__ex2g4s_1 = destination_0.get_entries_p20ztl_k$().iterator_jk1svi_k$();
    while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
      var entry = _iterator__ex2g4s_1.next_20eer_k$();
      if (entry.get_key_18j28a_k$() >= 0) {
        result.put_4fpzoq_k$(entry.get_key_18j28a_k$(), entry.get_value_j01efc_k$());
      }
    }
    // Inline function 'kotlin.collections.map' call
    var this_0 = toSortedMap(result);
    // Inline function 'kotlin.collections.mapTo' call
    var destination_1 = ArrayList_init_$Create$_0(this_0.get_size_woubt6_k$());
    // Inline function 'kotlin.collections.iterator' call
    var _iterator__ex2g4s_2 = this_0.get_entries_p20ztl_k$().iterator_jk1svi_k$();
    while (_iterator__ex2g4s_2.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s_2.next_20eer_k$();
      // Inline function 'kotlin.collections.component1' call
      var k = item.get_key_18j28a_k$();
      // Inline function 'kotlin.collections.component2' call
      var l = item.get_value_j01efc_k$();
      var tmp$ret$14 = new PItem(k, l);
      destination_1.add_utx5q5_k$(tmp$ret$14);
    }
    return destination_1;
  }
  function initialPick($this, w) {
    var items = pickItems($this, w);
    if (items.isEmpty_y1axqb_k$())
      return 0.0;
    // Inline function 'kotlin.collections.map' call
    // Inline function 'kotlin.collections.mapTo' call
    var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(items, 10));
    var _iterator__ex2g4s = items.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s.next_20eer_k$();
      var tmp$ret$0 = first(item.nodes_1);
      destination.add_utx5q5_k$(tmp$ret$0);
    }
    var sizes = destination;
    var tmp$ret$3;
    $l$block_0: {
      // Inline function 'kotlin.collections.any' call
      var tmp;
      if (isInterface(sizes, Collection)) {
        tmp = sizes.isEmpty_y1axqb_k$();
      } else {
        tmp = false;
      }
      if (tmp) {
        tmp$ret$3 = false;
        break $l$block_0;
      }
      var _iterator__ex2g4s_0 = sizes.iterator_jk1svi_k$();
      while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
        var element = _iterator__ex2g4s_0.next_20eer_k$();
        if (!(wsOfRole(PlayMode_getInstance(), element.widget_1, 3) == null)) {
          tmp$ret$3 = true;
          break $l$block_0;
        }
      }
      tmp$ret$3 = false;
    }
    if (tmp$ret$3) {
      var tmp4 = withIndex(sizes);
      var tmp$ret$5;
      $l$block_2: {
        // Inline function 'kotlin.collections.maxByOrNull' call
        var iterator = tmp4.iterator_jk1svi_k$();
        if (!iterator.hasNext_bitz1p_k$()) {
          tmp$ret$5 = null;
          break $l$block_2;
        }
        var maxElem = iterator.next_20eer_k$();
        if (!iterator.hasNext_bitz1p_k$()) {
          tmp$ret$5 = maxElem;
          break $l$block_2;
        }
        var maxValue = maxElem.value_1.w_1;
        do {
          var e = iterator.next_20eer_k$();
          var v = e.value_1.w_1;
          if (compareTo(maxValue, v) < 0) {
            maxElem = e;
            maxValue = v;
          }
        }
         while (iterator.hasNext_bitz1p_k$());
        tmp$ret$5 = maxElem;
      }
      return ensureNotNull(tmp$ret$5).index_1;
    }
    var tmp0_elvis_lhs = w.part_s8somf_k$('ind');
    var ind = tmp0_elvis_lhs == null ? w.part_s8somf_k$('fit') : tmp0_elvis_lhs;
    if (!(ind == null)) {
      var tmp7 = withIndex(items);
      var tmp$ret$8;
      $l$block_4: {
        // Inline function 'kotlin.collections.minByOrNull' call
        var iterator_0 = tmp7.iterator_jk1svi_k$();
        if (!iterator_0.hasNext_bitz1p_k$()) {
          tmp$ret$8 = null;
          break $l$block_4;
        }
        var minElem = iterator_0.next_20eer_k$();
        if (!iterator_0.hasNext_bitz1p_k$()) {
          tmp$ret$8 = minElem;
          break $l$block_4;
        }
        var it = minElem.component2_7eebsb_k$();
        var dx = it.box_1.get_cx_knto1u_k$() - ind.get_cx_knto1u_k$();
        var dy = it.box_1.get_cy_knto1t_k$() - ind.get_cy_knto1t_k$();
        var minValue = dx * dx + dy * dy;
        do {
          var e_0 = iterator_0.next_20eer_k$();
          var it_0 = e_0.component2_7eebsb_k$();
          var dx_0 = it_0.box_1.get_cx_knto1u_k$() - ind.get_cx_knto1u_k$();
          var dy_0 = it_0.box_1.get_cy_knto1t_k$() - ind.get_cy_knto1t_k$();
          var v_0 = dx_0 * dx_0 + dy_0 * dy_0;
          if (compareTo(minValue, v_0) > 0) {
            minElem = e_0;
            minValue = v_0;
          }
        }
         while (iterator_0.hasNext_bitz1p_k$());
        tmp$ret$8 = minElem;
      }
      return ensureNotNull(tmp$ret$8).index_1;
    }
    var tmp$ret$14;
    $l$block_7: {
      // Inline function 'kotlin.collections.indexOfFirst' call
      var index = 0;
      var _iterator__ex2g4s_1 = items.iterator_jk1svi_k$();
      while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
        var item_0 = _iterator__ex2g4s_1.next_20eer_k$();
        var tmp0 = item_0.nodes_1;
        var tmp$ret$11;
        $l$block_6: {
          // Inline function 'kotlin.collections.any' call
          var tmp_0;
          if (isInterface(tmp0, Collection)) {
            tmp_0 = tmp0.isEmpty_y1axqb_k$();
          } else {
            tmp_0 = false;
          }
          if (tmp_0) {
            tmp$ret$11 = false;
            break $l$block_6;
          }
          var _iterator__ex2g4s_2 = tmp0.iterator_jk1svi_k$();
          while (_iterator__ex2g4s_2.hasNext_bitz1p_k$()) {
            var element_0 = _iterator__ex2g4s_2.next_20eer_k$();
            var tmp0_safe_receiver = getOrNull(split(element_0.widget_1, charArrayOf([_Char___init__impl__6a9atx(47)])), 1);
            if (element_0.fillToken_1 === (tmp0_safe_receiver == null ? null : toIntOrNull(tmp0_safe_receiver))) {
              tmp$ret$11 = true;
              break $l$block_6;
            }
          }
          tmp$ret$11 = false;
        }
        if (tmp$ret$11) {
          tmp$ret$14 = index;
          break $l$block_7;
        }
        index = index + 1 | 0;
      }
      tmp$ret$14 = -1;
    }
    var sel = tmp$ret$14;
    // Inline function 'kotlin.math.max' call
    return Math.max(sel, 0);
  }
  function patchPick($this, w, v, tone, out) {
    var items = pickItems($this, w);
    if (items.isEmpty_y1axqb_k$())
      return Unit_instance;
    var n = items.get_size_woubt6_k$();
    var vv = coerceIn(v, 0.0, n - 1 | 0);
    // Inline function 'kotlin.math.floor' call
    var tmp$ret$0 = Math.floor(vv);
    var k0 = numberToInt(tmp$ret$0);
    var tmp1 = k0 + 1 | 0;
    // Inline function 'kotlin.math.min' call
    var b = n - 1 | 0;
    var k1 = Math.min(tmp1, b);
    var f = vv - k0;
    // Inline function 'kotlin.math.roundToInt' call
    var chosen = roundToInt(vv);
    // Inline function 'kotlin.collections.filter' call
    var tmp0 = w.all_1;
    // Inline function 'kotlin.collections.filterTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      if (!startsWith(element.widget_1, 'pick:i')) {
        destination.add_utx5q5_k$(element);
      }
    }
    var tmp0_elvis_lhs = boundsOf(destination);
    var base = tmp0_elvis_lhs == null ? ensureNotNull(boundsOf(w.nodes_1)) : tmp0_elvis_lhs;
    var iterator = items.iterator_jk1svi_k$();
    var index = 0;
    while (iterator.hasNext_bitz1p_k$()) {
      var idx = index;
      index = index + 1 | 0;
      var it = iterator.next_20eer_k$();
      // Inline function 'kotlin.math.abs' call
      var x = vv - idx;
      var tmp$ret$6 = Math.abs(x);
      var weight = coerceIn(1.0 - tmp$ret$6, 0.0, 1.0);
      var _iterator__ex2g4s_0 = it.nodes_1.iterator_jk1svi_k$();
      $l$loop_0: while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
        var nd = _iterator__ex2g4s_0.next_20eer_k$();
        var p = split(nd.widget_1, charArrayOf([_Char___init__impl__6a9atx(47)]));
        var tmp1_safe_receiver = getOrNull(p, 1);
        var tmp2_elvis_lhs = tmp1_safe_receiver == null ? null : toIntOrNull(tmp1_safe_receiver);
        var tmp;
        if (tmp2_elvis_lhs == null) {
          continue $l$loop_0;
        } else {
          tmp = tmp2_elvis_lhs;
        }
        var st = tmp;
        var tmp3_safe_receiver = getOrNull(p, 2);
        var tmp4_elvis_lhs = tmp3_safe_receiver == null ? null : toIntOrNull(tmp3_safe_receiver);
        var tmp_0;
        if (tmp4_elvis_lhs == null) {
          continue $l$loop_0;
        } else {
          tmp_0 = tmp4_elvis_lhs;
        }
        var un = tmp_0;
        var res = nd.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, mix($this, tone.color$default_xk5c97_k$(un), tone.color$default_xk5c97_k$(st), weight), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, idx === chosen ? st : un);
        var tmp5_safe_receiver = xsOfRole($this, nd.widget_1, 3);
        if (tmp5_safe_receiver == null)
          null;
        else {
          // Inline function 'kotlin.let' call
          res = res.copy$default_q375vp_k$(VOID, VOID, VOID, patchPick$at(base, k0, k1, f, tmp5_safe_receiver));
        }
        var tmp6_safe_receiver = wsOfRole($this, nd.widget_1, 3);
        if (tmp6_safe_receiver == null)
          null;
        else {
          // Inline function 'kotlin.let' call
          var tmp_1 = res;
          // Inline function 'kotlin.math.min' call
          var b_0 = tmp6_safe_receiver.get_size_woubt6_k$() - 1 | 0;
          var tmp$ret$9 = Math.min(k0, b_0);
          var tmp_2 = tmp6_safe_receiver.get_c1px32_k$(tmp$ret$9);
          // Inline function 'kotlin.math.min' call
          var b_1 = tmp6_safe_receiver.get_size_woubt6_k$() - 1 | 0;
          var tmp$ret$10 = Math.min(k1, b_1);
          res = tmp_1.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, coerceAtLeast(patchPick$mixF(f, tmp_2, tmp6_safe_receiver.get_c1px32_k$(tmp$ret$10)), 0.0));
        }
        if (fadeOfRole($this, nd.widget_1, 3))
          res = res.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, weight);
        var tmp12 = nd.id_1;
        // Inline function 'kotlin.collections.set' call
        var value = res;
        out.put_4fpzoq_k$(tmp12, value);
      }
    }
    // Inline function 'kotlin.collections.map' call
    // Inline function 'kotlin.collections.mapTo' call
    var destination_0 = ArrayList_init_$Create$_0(collectionSizeOrDefault(items, 10));
    var _iterator__ex2g4s_1 = items.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s_1.next_20eer_k$();
      var tmp$ret$14 = item.box_1.get_cx_knto1u_k$();
      destination_0.add_utx5q5_k$(tmp$ret$14);
    }
    var cxs = destination_0;
    // Inline function 'kotlin.collections.map' call
    // Inline function 'kotlin.collections.mapTo' call
    var destination_1 = ArrayList_init_$Create$_0(collectionSizeOrDefault(items, 10));
    var _iterator__ex2g4s_2 = items.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_2.hasNext_bitz1p_k$()) {
      var item_0 = _iterator__ex2g4s_2.next_20eer_k$();
      var tmp$ret$17 = item_0.box_1.get_cy_knto1t_k$();
      destination_1.add_utx5q5_k$(tmp$ret$17);
    }
    var cys = destination_1;
    var ind = w.part_s8somf_k$('ind');
    if (!(ind == null)) {
      var cx = patchPick$mixF(f, cxs.get_c1px32_k$(k0), cxs.get_c1px32_k$(k1));
      var cy = patchPick$mixF(f, cys.get_c1px32_k$(k0), cys.get_c1px32_k$(k1));
      var moveX = max(cxs) - min(cxs) > 24.0;
      var moveY = max(cys) - min(cys) > 24.0;
      var xs = xsOfRole($this, ind.widget_1, 1);
      var tmp19 = ind.id_1;
      // Inline function 'kotlin.collections.set' call
      var value_0 = ind.copy$default_q375vp_k$(VOID, VOID, VOID, !(xs == null) ? patchPick$at(base, k0, k1, f, xs) : moveX ? cx - ind.w_1 / 2.0 : ind.x_1, moveY ? cy - ind.h_1 / 2.0 : ind.y_1);
      out.put_4fpzoq_k$(tmp19, value_0);
    }
    var fit = w.part_s8somf_k$('fit');
    if (!(fit == null)) {
      // Inline function 'kotlin.collections.filter' call
      var tmp0_0 = w.all_1;
      // Inline function 'kotlin.collections.filterTo' call
      var destination_2 = ArrayList_init_$Create$();
      var _iterator__ex2g4s_3 = tmp0_0.iterator_jk1svi_k$();
      while (_iterator__ex2g4s_3.hasNext_bitz1p_k$()) {
        var element_0 = _iterator__ex2g4s_3.next_20eer_k$();
        if (!(element_0.id_1 === fit.id_1)) {
          destination_2.add_utx5q5_k$(element_0);
        }
      }
      var tmp7_elvis_lhs = boundsOf(destination_2);
      var tmp_3;
      if (tmp7_elvis_lhs == null) {
        return Unit_instance;
      } else {
        tmp_3 = tmp7_elvis_lhs;
      }
      var gb = tmp_3;
      var a = patchPick$seg(gb, cxs, n, k0);
      var b_2 = patchPick$seg(gb, cxs, n, k1);
      var l = patchPick$mixF(f, a.first_1, b_2.first_1);
      var r = patchPick$mixF(f, a.second_1, b_2.second_1);
      var tmp24 = fit.id_1;
      // Inline function 'kotlin.collections.set' call
      var value_1 = fit.copy$default_q375vp_k$(VOID, VOID, VOID, l + 1.0, VOID, coerceAtLeast(r - l - 2.0, 1.0));
      out.put_4fpzoq_k$(tmp24, value_1);
    }
  }
  function Bar(active, track) {
    this.active_1 = active;
    this.track_1 = track;
    this.left_1 = this.active_1.x_1;
    var tmp = this;
    var tmp0_safe_receiver = this.track_1;
    var tmp_0;
    if (tmp0_safe_receiver == null) {
      tmp_0 = null;
    } else {
      // Inline function 'kotlin.let' call
      tmp_0 = tmp0_safe_receiver.x_1 + tmp0_safe_receiver.w_1;
    }
    var tmp1_elvis_lhs = tmp_0;
    tmp.right_1 = tmp1_elvis_lhs == null ? this.active_1.x_1 + this.active_1.w_1 : tmp1_elvis_lhs;
    var tmp_1 = this;
    var tmp0_safe_receiver_0 = this.track_1;
    var tmp_2;
    if (tmp0_safe_receiver_0 == null) {
      tmp_2 = null;
    } else {
      // Inline function 'kotlin.let' call
      // Inline function 'kotlin.math.max' call
      var a = tmp0_safe_receiver_0.x_1 - (this.active_1.x_1 + this.active_1.w_1);
      tmp_2 = Math.max(a, 0.0);
    }
    var tmp1_elvis_lhs_0 = tmp_2;
    tmp_1.gap_1 = tmp1_elvis_lhs_0 == null ? 0.0 : tmp1_elvis_lhs_0;
    var tmp_3 = this;
    // Inline function 'kotlin.math.max' call
    var a_0 = this.right_1 - this.left_1 - this.gap_1;
    tmp_3.total_1 = Math.max(a_0, 1.0);
  }
  function bar($this, w) {
    var tmp0_safe_receiver = w.part_s8somf_k$('active');
    var tmp;
    if (tmp0_safe_receiver == null) {
      tmp = null;
    } else {
      // Inline function 'kotlin.let' call
      tmp = new Bar(tmp0_safe_receiver, w.part_s8somf_k$('track'));
    }
    return tmp;
  }
  function progressInitial($this, w) {
    var arc = w.part_s8somf_k$('arc');
    if (!(arc == null)) {
      // Inline function 'kotlin.text.count' call
      var count = 0;
      var indexedObject = arc.path_1;
      var inductionVariable = 0;
      while (inductionVariable < charSequenceLength(indexedObject)) {
        var element = charSequenceGet(indexedObject, inductionVariable);
        inductionVariable = inductionVariable + 1 | 0;
        if (element === _Char___init__impl__6a9atx(76)) {
          count = count + 1 | 0;
        }
      }
      var tmp$ret$1 = count;
      return coerceIn(tmp$ret$1 / 40, 0.0, 1.0);
    }
    var tmp0_elvis_lhs = bar($this, w);
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return 0.0;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var b = tmp;
    return coerceIn(b.active_1.w_1 / b.total_1, 0.0, 1.0);
  }
  function patchProgress($this, w, v, out) {
    var arc = w.part_s8somf_k$('arc');
    if (!(arc == null)) {
      var tmp1 = arc.id_1;
      // Inline function 'kotlin.collections.set' call
      var value = arc.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, $this.arcPath_w946m9_k$(v));
      out.put_4fpzoq_k$(tmp1, value);
      return Unit_instance;
    }
    var tmp0_elvis_lhs = bar($this, w);
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return Unit_instance;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var b = tmp;
    // Inline function 'kotlin.math.max' call
    var a = v * b.total_1;
    var aw = Math.max(a, 0.5);
    var tmp6 = b.active_1.id_1;
    // Inline function 'kotlin.collections.set' call
    var value_0 = b.active_1.kind_1.equals(NodeKind_PATH_getInstance()) ? b.active_1.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, aw, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, $this.wavePath_dm4l52_k$(aw)) : b.active_1.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, aw);
    out.put_4fpzoq_k$(tmp6, value_0);
    var tmp1_safe_receiver = b.track_1;
    if (tmp1_safe_receiver == null)
      null;
    else {
      // Inline function 'kotlin.let' call
      var tmp0 = b.left_1 + aw + b.gap_1;
      // Inline function 'kotlin.math.min' call
      var b_0 = b.right_1;
      var kx = Math.min(tmp0, b_0);
      var tmp5 = tmp1_safe_receiver.id_1;
      // Inline function 'kotlin.math.max' call
      var a_0 = b.right_1 - kx;
      var tmp$ret$4 = Math.max(a_0, 0.0);
      // Inline function 'kotlin.collections.set' call
      var value_1 = tmp1_safe_receiver.copy$default_q375vp_k$(VOID, VOID, VOID, kx, VOID, tmp$ret$4);
      out.put_4fpzoq_k$(tmp5, value_1);
    }
  }
  function patchFocus($this, w, t, tone, out) {
    var on = t >= 0.5;
    var tmp0_safe_receiver = w.part_s8somf_k$('box');
    var tmp1_safe_receiver = tmp0_safe_receiver == null ? null : tmp0_safe_receiver.widget_1;
    var err = (tmp1_safe_receiver == null ? null : endsWith(tmp1_safe_receiver, '/err')) === true;
    var tmp2_safe_receiver = w.part_s8somf_k$('box');
    if (tmp2_safe_receiver == null)
      null;
    else {
      // Inline function 'kotlin.let' call
      var tmp1 = tmp2_safe_receiver.id_1;
      // Inline function 'kotlin.collections.set' call
      var value = err ? tmp2_safe_receiver.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 2.0 + t) : tmp2_safe_receiver.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, mix(PlayMode_getInstance(), tone.color$default_xk5c97_k$(19), tone.color$default_xk5c97_k$(0), t), 1.0 + t, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, on ? 0 : 19);
      out.put_4fpzoq_k$(tmp1, value);
    }
    var tmp3_safe_receiver = w.part_s8somf_k$('line');
    if (tmp3_safe_receiver == null)
      null;
    else {
      // Inline function 'kotlin.let' call
      var bottom = tmp3_safe_receiver.y_1 + tmp3_safe_receiver.h_1;
      var h = 2.0 + t;
      var tmp1_0 = tmp3_safe_receiver.id_1;
      // Inline function 'kotlin.collections.set' call
      var value_0 = tmp3_safe_receiver.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, bottom - h, VOID, h, VOID, mix(PlayMode_getInstance(), tone.color$default_xk5c97_k$(18), tone.color$default_xk5c97_k$(0), t), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, on ? 0 : 18);
      out.put_4fpzoq_k$(tmp1_0, value_0);
    }
    if (!err) {
      var tmp4_safe_receiver = w.part_s8somf_k$('label');
      if (tmp4_safe_receiver == null)
        null;
      else {
        // Inline function 'kotlin.let' call
        var tmp1_1 = tmp4_safe_receiver.id_1;
        // Inline function 'kotlin.collections.set' call
        var value_1 = tmp4_safe_receiver.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, mix(PlayMode_getInstance(), tone.color$default_xk5c97_k$(18), tone.color$default_xk5c97_k$(0), t), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, on ? 0 : 18);
        out.put_4fpzoq_k$(tmp1_1, value_1);
      }
    }
  }
  function patchCounter($this, w, v, out) {
    var tmp0_elvis_lhs = w.part_s8somf_k$('label');
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return Unit_instance;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var l = tmp;
    // Inline function 'kotlin.math.roundToInt' call
    var tmp$ret$0 = roundToInt(v);
    var txt = coerceIn_0(tmp$ret$0, 0, 99).toString();
    if (txt === l.text_1)
      return Unit_instance;
    var tmp_0;
    // Inline function 'kotlin.text.isNotEmpty' call
    var this_0 = l.text_1;
    if (charSequenceLength(this_0) > 0) {
      tmp_0 = l.w_1 * txt.length / l.text_1.length;
    } else {
      tmp_0 = l.w_1;
    }
    var nw = tmp_0;
    var tmp3 = l.id_1;
    var tmp1_x = l.x_1 + (l.w_1 - nw) / 2.0;
    // Inline function 'kotlin.collections.set' call
    var value = l.copy$default_q375vp_k$(VOID, VOID, txt, tmp1_x, VOID, nw, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, txt);
    out.put_4fpzoq_k$(tmp3, value);
  }
  function lum($this, c) {
    var r = (c >> 16 & 255) / 255.0;
    var g = (c >> 8 & 255) / 255.0;
    var b = (c & 255) / 255.0;
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }
  function patchPress($this, w, t, out) {
    if (t <= 0.001)
      return Unit_instance;
    var tmp0_elvis_lhs = w.get_bounds_bj99ku_k$();
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return Unit_instance;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var b = tmp;
    var s = 1.0 - 0.05 * t;
    // Inline function 'kotlin.collections.filter' call
    var tmp0 = w.all_1;
    // Inline function 'kotlin.collections.filterTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      if (!element.kind_1.equals(NodeKind_TEXT_getInstance()) && !((element.fill_1 >>> 24 | 0) === 0)) {
        destination.add_utx5q5_k$(element);
      }
    }
    var tmp$ret$3;
    $l$block_0: {
      // Inline function 'kotlin.collections.maxByOrNull' call
      var iterator = destination.iterator_jk1svi_k$();
      if (!iterator.hasNext_bitz1p_k$()) {
        tmp$ret$3 = null;
        break $l$block_0;
      }
      var maxElem = iterator.next_20eer_k$();
      if (!iterator.hasNext_bitz1p_k$()) {
        tmp$ret$3 = maxElem;
        break $l$block_0;
      }
      var it = maxElem;
      var maxValue = it.w_1 * it.h_1;
      do {
        var e = iterator.next_20eer_k$();
        var v = e.w_1 * e.h_1;
        if (compareTo(maxValue, v) < 0) {
          maxElem = e;
          maxValue = v;
        }
      }
       while (iterator.hasNext_bitz1p_k$());
      tmp$ret$3 = maxElem;
    }
    var big = tmp$ret$3;
    var _iterator__ex2g4s_0 = w.all_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
      var n = _iterator__ex2g4s_0.next_20eer_k$();
      var r = n.copy$default_q375vp_k$(VOID, VOID, VOID, b.get_cx_knto1u_k$() + (n.x_1 - b.get_cx_knto1u_k$()) * s, b.get_cy_knto1t_k$() + (n.y_1 - b.get_cy_knto1t_k$()) * s, n.w_1 * s, n.h_1 * s, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, n.kind_1.equals(NodeKind_TEXT_getInstance()) ? n.fontSize_1 * s : n.fontSize_1);
      if (n.kind_1.equals(NodeKind_RECT_getInstance()) && n.pressCorner_1 >= 0.0) {
        var tmp5 = n.w_1;
        // Inline function 'kotlin.math.min' call
        var b_0 = n.h_1;
        var half = Math.min(tmp5, b_0) / 2.0;
        // Inline function 'kotlin.math.min' call
        var a = n.corner_1;
        var from = Math.min(a, half);
        // Inline function 'kotlin.math.min' call
        var a_0 = n.pressCorner_1;
        var to = Math.min(a_0, half);
        r = r.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, (from + (to - from) * t) * s);
      }
      if (n.id_1 === (big == null ? null : big.id_1)) {
        var over = lum($this, n.fill_1) > 0.55 ? -16777216 : -1;
        r = r.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, mix($this, n.fill_1, n.fill_1 & -16777216 | over & 16777215, 0.14 * t));
      }
      var tmp12 = n.id_1;
      // Inline function 'kotlin.collections.set' call
      var value = r;
      out.put_4fpzoq_k$(tmp12, value);
    }
  }
  function Slider(thumb, active, track) {
    this.thumb_1 = thumb;
    this.active_1 = active;
    this.track_1 = track;
    this.left_1 = this.active_1.x_1;
    var tmp = this;
    var tmp0 = this.track_1.x_1 + this.track_1.w_1;
    // Inline function 'kotlin.math.max' call
    var b = this.thumb_1.x_1 + this.thumb_1.w_1;
    tmp.right_1 = Math.max(tmp0, b);
    this.span_1 = coerceAtLeast(this.right_1 - this.left_1 - this.thumb_1.w_1, 1.0);
  }
  protoOf(Slider).value_cpglt3_k$ = function (x) {
    return coerceIn((x - this.left_1 - this.thumb_1.w_1 / 2.0) / this.span_1, 0.0, 1.0);
  };
  function slider($this, w) {
    var tmp0_elvis_lhs = w.part_s8somf_k$('thumb');
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return null;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var t = tmp;
    var tmp1_elvis_lhs = w.part_s8somf_k$('active');
    var tmp_0;
    if (tmp1_elvis_lhs == null) {
      return null;
    } else {
      tmp_0 = tmp1_elvis_lhs;
    }
    var a = tmp_0;
    var tmp2_elvis_lhs = w.part_s8somf_k$('track');
    var tmp_1;
    if (tmp2_elvis_lhs == null) {
      return null;
    } else {
      tmp_1 = tmp2_elvis_lhs;
    }
    var k = tmp_1;
    return new Slider(t, a, k);
  }
  function mix($this, a, b, t) {
    var k = coerceIn(t, 0.0, 1.0);
    return mix$ch(a, b, k, 24) | mix$ch(a, b, k, 16) | mix$ch(a, b, k, 8) | mix$ch(a, b, k, 0);
  }
  function clear($this, c) {
    return c & 16777215;
  }
  function patchSlider($this, w, v, out) {
    var tmp0_elvis_lhs = slider($this, w);
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return Unit_instance;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var s = tmp;
    var c0 = s.thumb_1.get_cx_knto1u_k$();
    var aOff = c0 - (s.active_1.x_1 + s.active_1.w_1);
    var c = s.left_1 + s.thumb_1.w_1 / 2.0 + v * s.span_1;
    var tmp1 = s.thumb_1.id_1;
    // Inline function 'kotlin.collections.set' call
    var value = s.thumb_1.copy$default_q375vp_k$(VOID, VOID, VOID, c - s.thumb_1.w_1 / 2.0);
    out.put_4fpzoq_k$(tmp1, value);
    // Inline function 'kotlin.math.max' call
    var a = c - aOff - s.left_1;
    var aw = Math.max(a, 1.0);
    var tmp6 = s.active_1.id_1;
    // Inline function 'kotlin.collections.set' call
    var value_0 = s.active_1.kind_1.equals(NodeKind_PATH_getInstance()) ? s.active_1.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, aw, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, $this.wavePath_dm4l52_k$(aw)) : s.active_1.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, aw);
    out.put_4fpzoq_k$(tmp6, value_0);
    if (s.track_1.x_1 > s.active_1.x_1 + 1.0) {
      var tmp8 = c + (s.track_1.x_1 - c0);
      // Inline function 'kotlin.comparisons.minOf' call
      var b = s.right_1;
      var kx = Math.min(tmp8, b);
      var tmp13 = s.track_1.id_1;
      // Inline function 'kotlin.math.max' call
      var a_0 = s.right_1 - kx;
      var tmp$ret$4 = Math.max(a_0, 0.0);
      // Inline function 'kotlin.collections.set' call
      var value_1 = s.track_1.copy$default_q375vp_k$(VOID, VOID, VOID, kx, VOID, tmp$ret$4);
      out.put_4fpzoq_k$(tmp13, value_1);
    }
  }
  function patchSwitch($this, w, t, tone, out) {
    var tmp0_elvis_lhs = w.part_s8somf_k$('track');
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return Unit_instance;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var tr = tmp;
    var tmp1_elvis_lhs = w.part_s8somf_k$('thumb');
    var tmp_0;
    if (tmp1_elvis_lhs == null) {
      return Unit_instance;
    } else {
      tmp_0 = tmp1_elvis_lhs;
    }
    var th = tmp_0;
    var baseOn = tr.fillToken_1 === 0;
    var e = baseOn ? 0.0 : 1.0;
    var tb = new Box(tr.x_1 - e, tr.y_1 - e, tr.x_1 + tr.w_1 + e, tr.y_1 + tr.h_1 + e);
    var inset = 1.0 - t;
    var on = t >= 0.5;
    var tmp1 = tr.id_1;
    var tmp2_fillToken = on ? 0 : 16;
    var tmp3_strokeToken = on ? -1 : 19;
    var tmp4_x = tb.l_1 + inset;
    var tmp5_y = tb.t_1 + inset;
    var tmp6_w = tb.get_w_1mhr66_k$() - 2.0 * inset;
    var tmp7_h = tb.get_h_1mhr5r_k$() - 2.0 * inset;
    var tmp8_fill = mix($this, tone.color$default_xk5c97_k$(16), tone.color$default_xk5c97_k$(0), t);
    var tmp9_stroke = tone.color$default_xk5c97_k$(19);
    var tmp10_strokeWidth = 2.0 * (1.0 - t);
    // Inline function 'kotlin.collections.set' call
    var value = tr.copy$default_q375vp_k$(VOID, VOID, VOID, tmp4_x, tmp5_y, tmp6_w, tmp7_h, VOID, tmp8_fill, tmp9_stroke, tmp10_strokeWidth, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, tmp2_fillToken, tmp3_strokeToken);
    out.put_4fpzoq_k$(tmp1, value);
    var size = 16.0 + 8.0 * t;
    var offC = tb.l_1 + tb.get_h_1mhr5r_k$() / 2.0;
    var onC = tb.r_1 - tb.get_h_1mhr5r_k$() / 2.0;
    var cx = offC + (onC - offC) * t;
    var tmp4 = th.id_1;
    // Inline function 'kotlin.collections.set' call
    var value_0 = th.copy$default_q375vp_k$(VOID, VOID, VOID, cx - size / 2.0, tb.get_cy_knto1t_k$() - size / 2.0, size, size, VOID, mix($this, tone.color$default_xk5c97_k$(19), tone.color$default_xk5c97_k$(1), t), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, on ? 1 : 19);
    out.put_4fpzoq_k$(tmp4, value_0);
    var _iterator__ex2g4s = w.parts_9zuly2_k$('bg').iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var b = _iterator__ex2g4s.next_20eer_k$();
      var tmp7 = b.id_1;
      // Inline function 'kotlin.collections.set' call
      var value_1 = b.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, mix($this, tone.color$default_xk5c97_k$(15), tone.color$default_xk5c97_k$(2), t), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, on ? 2 : 15);
      out.put_4fpzoq_k$(tmp7, value_1);
    }
    var _iterator__ex2g4s_0 = w.parts_9zuly2_k$('title').iterator_jk1svi_k$();
    while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
      var b_0 = _iterator__ex2g4s_0.next_20eer_k$();
      var tmp10 = b_0.id_1;
      // Inline function 'kotlin.collections.set' call
      var value_2 = b_0.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, mix($this, tone.color$default_xk5c97_k$(17), tone.color$default_xk5c97_k$(3), t), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, on ? 3 : 17);
      out.put_4fpzoq_k$(tmp10, value_2);
    }
    var dx = cx - th.get_cx_knto1u_k$();
    var _iterator__ex2g4s_1 = w.parts_9zuly2_k$('icon').iterator_jk1svi_k$();
    while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
      var ic = _iterator__ex2g4s_1.next_20eer_k$();
      var tmp13 = ic.id_1;
      // Inline function 'kotlin.collections.set' call
      var value_3 = ic.copy$default_q375vp_k$(VOID, VOID, VOID, ic.x_1 + dx, VOID, VOID, VOID, VOID, VOID, VOID, VOID, t);
      out.put_4fpzoq_k$(tmp13, value_3);
    }
  }
  function patchCheck($this, w, t, tone, out, extra) {
    var tmp0_elvis_lhs = w.part_s8somf_k$('box');
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return Unit_instance;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var box = tmp;
    var on = tone.color$default_xk5c97_k$(0);
    var isOn = t >= 0.5;
    var tmp1 = box.id_1;
    // Inline function 'kotlin.collections.set' call
    var value = box.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, mix($this, clear($this, on), on, t), tone.color$default_xk5c97_k$(18), 2.0 * (1.0 - t), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, isOn ? 0 : -1, isOn ? -1 : 18);
    out.put_4fpzoq_k$(tmp1, value);
    var marks = w.parts_9zuly2_k$('mark');
    // Inline function 'kotlin.collections.isNotEmpty' call
    if (!marks.isEmpty_y1axqb_k$()) {
      var _iterator__ex2g4s = marks.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var m = _iterator__ex2g4s.next_20eer_k$();
        var tmp5 = m.id_1;
        // Inline function 'kotlin.collections.set' call
        var value_0 = m.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, t);
        out.put_4fpzoq_k$(tmp5, value_0);
      }
      return Unit_instance;
    }
    if (t <= 0.001)
      return Unit_instance;
    var k = box.w_1 / 18.0;
    var c = tone.color$default_xk5c97_k$(1);
    var tmp8 = box.id_1;
    var tmp1_id = 'play-' + box.id_1 + '-1';
    var tmp2_kind = NodeKind_RECT_getInstance();
    var tmp3_name = tr('check_1', []);
    var tmp4_x = box.x_1 + 4.0 * k;
    var tmp5_y = box.y_1 + 9.0 * k;
    var tmp6_w = 6.0 * k;
    var tmp7_h = 2.0 * k;
    var tmp8_group = box.group_1;
    var tmp_0 = new Node(tmp1_id, tmp2_kind, tmp3_name, tmp4_x, tmp5_y, tmp6_w, tmp7_h, 45.0, c, VOID, VOID, t, k, VOID, VOID, VOID, VOID, tmp8_group, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 1, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 'check:mark');
    var tmp10_id = 'play-' + box.id_1 + '-2';
    var tmp11_kind = NodeKind_RECT_getInstance();
    var tmp12_name = tr('check_2', []);
    var tmp13_x = box.x_1 + 6.5 * k;
    var tmp14_y = box.y_1 + 8.0 * k;
    var tmp15_w = 9.0 * k;
    var tmp16_h = 2.0 * k;
    var tmp17_rotation = -50.0;
    var tmp18_group = box.group_1;
    // Inline function 'kotlin.collections.set' call
    var value_1 = listOf_0([tmp_0, new Node(tmp10_id, tmp11_kind, tmp12_name, tmp13_x, tmp14_y, tmp15_w, tmp16_h, tmp17_rotation, c, VOID, VOID, t, k, VOID, VOID, VOID, VOID, tmp18_group, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 1, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 'check:mark')]);
    extra.put_4fpzoq_k$(tmp8, value_1);
  }
  function patchRadio($this, w, t, tone, out, extra) {
    var tmp0_elvis_lhs = w.part_s8somf_k$('ring');
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return Unit_instance;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var ring = tmp;
    var on = tone.color$default_xk5c97_k$(0);
    var tmp1 = ring.id_1;
    // Inline function 'kotlin.collections.set' call
    var value = ring.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, mix($this, tone.color$default_xk5c97_k$(18), on, t), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, t >= 0.5 ? 0 : 18);
    out.put_4fpzoq_k$(tmp1, value);
    var d = ring.w_1 * 0.5 * t;
    var dot = w.part_s8somf_k$('dot');
    if (!(dot == null)) {
      var tmp4 = dot.id_1;
      // Inline function 'kotlin.collections.set' call
      var value_0 = dot.copy$default_q375vp_k$(VOID, VOID, VOID, ring.get_cx_knto1u_k$() - d / 2.0, ring.get_cy_knto1t_k$() - d / 2.0, d, d);
      out.put_4fpzoq_k$(tmp4, value_0);
      return Unit_instance;
    }
    if (t <= 0.001)
      return Unit_instance;
    var tmp7 = ring.id_1;
    var tmp1_id = 'play-' + ring.id_1 + '-dot';
    var tmp2_kind = NodeKind_ELLIPSE_getInstance();
    var tmp3_name = tr('dot', []);
    var tmp4_x = ring.get_cx_knto1u_k$() - d / 2.0;
    var tmp5_y = ring.get_cy_knto1t_k$() - d / 2.0;
    var tmp6_group = ring.group_1;
    // Inline function 'kotlin.collections.set' call
    var value_1 = listOf(new Node(tmp1_id, tmp2_kind, tmp3_name, tmp4_x, tmp5_y, d, d, VOID, on, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, tmp6_group, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 0, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, 'radio:dot'));
    extra.put_4fpzoq_k$(tmp7, value_1);
  }
  function patchChip($this, w, t, tone, out) {
    var tmp0_elvis_lhs = w.part_s8somf_k$('bg');
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return Unit_instance;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var bg = tmp;
    var sec = tone.color$default_xk5c97_k$(5);
    var on = t >= 0.5;
    var tmp1 = bg.id_1;
    // Inline function 'kotlin.collections.set' call
    var value = bg.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, mix($this, clear($this, sec), sec, t), tone.color$default_xk5c97_k$(20), 1.0 * (1.0 - t), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, on ? 5 : -1, on ? -1 : 20);
    out.put_4fpzoq_k$(tmp1, value);
    var marks = w.parts_9zuly2_k$('mark');
    var label = w.part_s8somf_k$('label');
    if (!(label == null)) {
      var b0 = $this.initial_8bu8p4_k$(w);
      var tmp_0;
      // Inline function 'kotlin.collections.isNotEmpty' call
      if (!marks.isEmpty_y1axqb_k$()) {
        tmp_0 = 10.0 * (b0 - t);
      } else {
        tmp_0 = 0.0;
      }
      var shift = tmp_0;
      var tmp5 = label.id_1;
      // Inline function 'kotlin.collections.set' call
      var value_0 = label.copy$default_q375vp_k$(VOID, VOID, VOID, label.x_1 + shift, VOID, VOID, VOID, VOID, mix($this, tone.color$default_xk5c97_k$(18), tone.color$default_xk5c97_k$(6), t), VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, on ? 6 : 18);
      out.put_4fpzoq_k$(tmp5, value_0);
    }
    var _iterator__ex2g4s = marks.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var m = _iterator__ex2g4s.next_20eer_k$();
      var tmp8 = m.id_1;
      // Inline function 'kotlin.collections.set' call
      var value_1 = m.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, t);
      out.put_4fpzoq_k$(tmp8, value_1);
    }
  }
  function sam$kotlin_Comparator$0(function_0) {
    this.function_1 = function_0;
  }
  protoOf(sam$kotlin_Comparator$0).compare_bczr_k$ = function (a, b) {
    return this.function_1(a, b);
  };
  protoOf(sam$kotlin_Comparator$0).compare = function (a, b) {
    return this.compare_bczr_k$(a, b);
  };
  protoOf(sam$kotlin_Comparator$0).getFunctionDelegate_jtodtf_k$ = function () {
    return this.function_1;
  };
  protoOf(sam$kotlin_Comparator$0).equals = function (other) {
    var tmp;
    if (!(other == null) ? isInterface(other, Comparator) : false) {
      var tmp_0;
      if (!(other == null) ? isInterface(other, FunctionAdapter) : false) {
        tmp_0 = equals(this.getFunctionDelegate_jtodtf_k$(), other.getFunctionDelegate_jtodtf_k$());
      } else {
        tmp_0 = false;
      }
      tmp = tmp_0;
    } else {
      tmp = false;
    }
    return tmp;
  };
  protoOf(sam$kotlin_Comparator$0).hashCode = function () {
    return hashCode(this.getFunctionDelegate_jtodtf_k$());
  };
  function patchPick$mixF(f, a, b) {
    return a + (b - a) * f;
  }
  function patchPick$at(base, k0, k1, f, xs) {
    // Inline function 'kotlin.math.min' call
    var b = xs.get_size_woubt6_k$() - 1 | 0;
    var tmp$ret$0 = Math.min(k0, b);
    var tmp = xs.get_c1px32_k$(tmp$ret$0);
    // Inline function 'kotlin.math.min' call
    var b_0 = xs.get_size_woubt6_k$() - 1 | 0;
    var tmp$ret$1 = Math.min(k1, b_0);
    return base.l_1 + patchPick$mixF(f, tmp, xs.get_c1px32_k$(tmp$ret$1));
  }
  function patchPick$seg(gb, cxs, n, k) {
    return new Pair(k === 0 ? gb.l_1 : (cxs.get_c1px32_k$(k - 1 | 0) + cxs.get_c1px32_k$(k)) / 2.0, k === (n - 1 | 0) ? gb.r_1 : (cxs.get_c1px32_k$(k) + cxs.get_c1px32_k$(k + 1 | 0)) / 2.0);
  }
  function mix$ch($a, $b, k, shift) {
    var x = ($a >>> shift | 0) & 255;
    var y = ($b >>> shift | 0) & 255;
    return coerceIn_0(numberToInt(x + (y - x | 0) * k), 0, 255) << shift;
  }
  function PlayMode$widgets$lambda($first) {
    return function (a, b) {
      // Inline function 'kotlin.comparisons.compareValuesBy' call
      var tmp0_elvis_lhs = $first.get_wei43m_k$(a.group_1);
      var tmp = tmp0_elvis_lhs == null ? 0 : tmp0_elvis_lhs;
      var tmp0_elvis_lhs_0 = $first.get_wei43m_k$(b.group_1);
      var tmp$ret$1 = tmp0_elvis_lhs_0 == null ? 0 : tmp0_elvis_lhs_0;
      return compareValues(tmp, tmp$ret$1);
    };
  }
  function PlayMode() {
    PlayMode_instance = this;
    this.kinds_1 = setOf_0(['slider', 'switch', 'check', 'radio', 'chip', 'pick', 'progress', 'spin', 'focus', 'reveal', 'counter']);
    this.ARC_STEPS_1 = 40;
  }
  protoOf(PlayMode).widgets_hajxma_k$ = function (nodes) {
    // Inline function 'kotlin.collections.filter' call
    // Inline function 'kotlin.collections.filterTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s = nodes.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      var tmp;
      // Inline function 'kotlin.text.isNotEmpty' call
      var this_0 = element.group_1;
      if (charSequenceLength(this_0) > 0) {
        tmp = element.visible_1;
      } else {
        tmp = false;
      }
      if (tmp) {
        destination.add_utx5q5_k$(element);
      }
    }
    // Inline function 'kotlin.collections.groupBy' call
    // Inline function 'kotlin.collections.groupByTo' call
    var destination_0 = LinkedHashMap_init_$Create$();
    var _iterator__ex2g4s_0 = destination.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
      var element_0 = _iterator__ex2g4s_0.next_20eer_k$();
      var key = element_0.group_1;
      // Inline function 'kotlin.collections.getOrPut' call
      var value = destination_0.get_wei43m_k$(key);
      var tmp_0;
      if (value == null) {
        var answer = ArrayList_init_$Create$();
        destination_0.put_4fpzoq_k$(key, answer);
        tmp_0 = answer;
      } else {
        tmp_0 = value;
      }
      var list = tmp_0;
      list.add_utx5q5_k$(element_0);
    }
    var byGroup = destination_0;
    var first_0 = HashMap_init_$Create$();
    // Inline function 'kotlin.collections.forEachIndexed' call
    var index = 0;
    var _iterator__ex2g4s_1 = nodes.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s_1.next_20eer_k$();
      var _unary__edvuaz = index;
      index = _unary__edvuaz + 1 | 0;
      var i = checkIndexOverflow(_unary__edvuaz);
      // Inline function 'kotlin.text.isNotEmpty' call
      var this_1 = item.group_1;
      if (charSequenceLength(this_1) > 0) {
        putIfAbsent(first_0, item.group_1, i);
      }
    }
    var out = ArrayList_init_$Create$();
    // Inline function 'kotlin.collections.iterator' call
    var _iterator__ex2g4s_2 = byGroup.get_entries_p20ztl_k$().iterator_jk1svi_k$();
    $l$loop: while (_iterator__ex2g4s_2.hasNext_bitz1p_k$()) {
      var _destruct__k2r9zo = _iterator__ex2g4s_2.next_20eer_k$();
      // Inline function 'kotlin.collections.component1' call
      var g = _destruct__k2r9zo.get_key_18j28a_k$();
      // Inline function 'kotlin.collections.component2' call
      var all = _destruct__k2r9zo.get_value_j01efc_k$();
      // Inline function 'kotlin.collections.filter' call
      // Inline function 'kotlin.collections.filterTo' call
      var destination_1 = ArrayList_init_$Create$();
      var _iterator__ex2g4s_3 = all.iterator_jk1svi_k$();
      while (_iterator__ex2g4s_3.hasNext_bitz1p_k$()) {
        var element_1 = _iterator__ex2g4s_3.next_20eer_k$();
        // Inline function 'kotlin.text.isNotEmpty' call
        var this_2 = element_1.widget_1;
        if (charSequenceLength(this_2) > 0) {
          destination_1.add_utx5q5_k$(element_1);
        }
      }
      var tagged = destination_1;
      if (tagged.isEmpty_y1axqb_k$()) {
        if (autoPress(this, all)) {
          // Inline function 'kotlin.collections.plusAssign' call
          var element_2 = new Widget(g, 'press', all, all);
          out.add_utx5q5_k$(element_2);
        }
        continue $l$loop;
      }
      var k = substringBefore(first(tagged).widget_1, _Char___init__impl__6a9atx(58));
      var tmp_1;
      if (this.kinds_1.contains_aljjnj_k$(k)) {
        var tmp$ret$20;
        $l$block_0: {
          // Inline function 'kotlin.collections.all' call
          var tmp_2;
          if (isInterface(tagged, Collection)) {
            tmp_2 = tagged.isEmpty_y1axqb_k$();
          } else {
            tmp_2 = false;
          }
          if (tmp_2) {
            tmp$ret$20 = true;
            break $l$block_0;
          }
          var _iterator__ex2g4s_4 = tagged.iterator_jk1svi_k$();
          while (_iterator__ex2g4s_4.hasNext_bitz1p_k$()) {
            var element_3 = _iterator__ex2g4s_4.next_20eer_k$();
            if (!(substringBefore(element_3.widget_1, _Char___init__impl__6a9atx(58)) === k)) {
              tmp$ret$20 = false;
              break $l$block_0;
            }
          }
          tmp$ret$20 = true;
        }
        tmp_1 = tmp$ret$20;
      } else {
        tmp_1 = false;
      }
      if (tmp_1) {
        // Inline function 'kotlin.collections.plusAssign' call
        var element_4 = new Widget(g, k, tagged, all);
        out.add_utx5q5_k$(element_4);
      }
    }
    // Inline function 'kotlin.collections.forEachIndexed' call
    var index_0 = 0;
    var _iterator__ex2g4s_5 = nodes.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_5.hasNext_bitz1p_k$()) {
      var item_0 = _iterator__ex2g4s_5.next_20eer_k$();
      var _unary__edvuaz_0 = index_0;
      index_0 = _unary__edvuaz_0 + 1 | 0;
      var i_0 = checkIndexOverflow(_unary__edvuaz_0);
      var tmp_3;
      var tmp_4;
      var tmp_5;
      // Inline function 'kotlin.text.isEmpty' call
      var this_3 = item_0.group_1;
      if (charSequenceLength(this_3) === 0) {
        tmp_5 = item_0.visible_1;
      } else {
        tmp_5 = false;
      }
      if (tmp_5) {
        tmp_4 = item_0.kind_1.equals(NodeKind_RECT_getInstance());
      } else {
        tmp_4 = false;
      }
      if (tmp_4) {
        tmp_3 = item_0.pressCorner_1 >= 0.0;
      } else {
        tmp_3 = false;
      }
      if (tmp_3) {
        // Inline function 'kotlin.collections.plusAssign' call
        var element_5 = new Widget('n:' + item_0.id_1, 'press', listOf(item_0), listOf(item_0));
        out.add_utx5q5_k$(element_5);
        // Inline function 'kotlin.collections.set' call
        var key_0 = 'n:' + item_0.id_1;
        first_0.put_4fpzoq_k$(key_0, i_0);
      }
    }
    // Inline function 'kotlin.collections.sortedBy' call
    // Inline function 'kotlin.comparisons.compareBy' call
    var tmp_6 = PlayMode$widgets$lambda(first_0);
    var tmp$ret$28 = new sam$kotlin_Comparator$0(tmp_6);
    return sortedWith(out, tmp$ret$28);
  };
  protoOf(PlayMode).widgetAt_cyoaem_k$ = function (nodes, x, y, pad) {
    var _iterator__ex2g4s = asReversed(this.widgets_hajxma_k$(nodes)).iterator_jk1svi_k$();
    $l$loop: while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var w = _iterator__ex2g4s.next_20eer_k$();
      var tmp0_elvis_lhs = w.get_bounds_bj99ku_k$();
      var tmp;
      if (tmp0_elvis_lhs == null) {
        continue $l$loop;
      } else {
        tmp = tmp0_elvis_lhs;
      }
      var b = tmp;
      // Inline function 'kotlin.math.max' call
      var b_0 = (44.0 - b.get_h_1mhr5r_k$()) / 2.0;
      var ph = Math.max(pad, b_0);
      if (x >= b.l_1 - pad && x <= b.r_1 + pad && y >= b.t_1 - ph && y <= b.b_1 + ph)
        return w;
    }
    return null;
  };
  protoOf(PlayMode).wavePath_dm4l52_k$ = function (w) {
    // Inline function 'kotlin.math.max' call
    var a = w / 28.0;
    var periods = Math.max(a, 0.5);
    // Inline function 'kotlin.math.max' call
    var b = numberToInt(w / 2.0);
    var steps = Math.max(8, b);
    var sb = StringBuilder_init_$Create$_0();
    var inductionVariable = 0;
    if (inductionVariable <= steps)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var x = i / steps;
        // Inline function 'kotlin.math.sin' call
        var x_0 = 2.0 * 3.141592653589793 * periods * x;
        var y = 0.5 + 0.34 * Math.sin(x_0);
        sb.append_22ad7x_k$(i === 0 ? 'M ' : 'L ').append_22ad7x_k$(formatNumber('%.4f %.4f ', [x, y]));
      }
       while (!(i === steps));
    // Inline function 'kotlin.text.trim' call
    var this_0 = sb.toString();
    return toString_1(trim(isCharSequence(this_0) ? this_0 : THROW_CCE()));
  };
  protoOf(PlayMode).pickCount_5xun7y_k$ = function (w) {
    return pickItems(this, w).get_size_woubt6_k$();
  };
  protoOf(PlayMode).pickIndexAt_3el5rs_k$ = function (w, x, y) {
    var items = pickItems(this, w);
    var tmp0 = withIndex(items);
    var tmp$ret$0;
    $l$block_0: {
      // Inline function 'kotlin.collections.minByOrNull' call
      var iterator = tmp0.iterator_jk1svi_k$();
      if (!iterator.hasNext_bitz1p_k$()) {
        tmp$ret$0 = null;
        break $l$block_0;
      }
      var minElem = iterator.next_20eer_k$();
      if (!iterator.hasNext_bitz1p_k$()) {
        tmp$ret$0 = minElem;
        break $l$block_0;
      }
      var it = minElem.component2_7eebsb_k$();
      var dx = it.box_1.get_cx_knto1u_k$() - x;
      var dy = it.box_1.get_cy_knto1t_k$() - y;
      var minValue = dx * dx + dy * dy;
      do {
        var e = iterator.next_20eer_k$();
        var it_0 = e.component2_7eebsb_k$();
        var dx_0 = it_0.box_1.get_cx_knto1u_k$() - x;
        var dy_0 = it_0.box_1.get_cy_knto1t_k$() - y;
        var v = dx_0 * dx_0 + dy_0 * dy_0;
        if (compareTo(minValue, v) > 0) {
          minElem = e;
          minValue = v;
        }
      }
       while (iterator.hasNext_bitz1p_k$());
      tmp$ret$0 = minElem;
    }
    var tmp0_elvis_lhs = tmp$ret$0;
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return 0;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var best = tmp;
    return best.index_1;
  };
  protoOf(PlayMode).pickHit_po30ei_k$ = function (w, x, y) {
    var items = pickItems(this, w);
    // Inline function 'kotlin.collections.flatMap' call
    // Inline function 'kotlin.collections.flatMapTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s = items.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      var list = element.nodes_1;
      addAll(destination, list);
    }
    var tmp0_elvis_lhs = boundsOf(destination);
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return null;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var box = tmp;
    if (x < box.l_1 - 32.0 || x > box.r_1 + 32.0 || y < box.t_1 - 32.0 || y > box.b_1 + 32.0)
      return null;
    return this.pickIndexAt_3el5rs_k$(w, x, y);
  };
  protoOf(PlayMode).arcPath_w946m9_k$ = function (v) {
    // Inline function 'kotlin.math.roundToInt' call
    var this_0 = coerceIn(v, 0.0, 1.0) * 40;
    var n = roundToInt(this_0);
    var sb = StringBuilder_init_$Create$_0();
    var inductionVariable = 0;
    if (inductionVariable <= n)
      do {
        var i = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var a = (-90.0 + 360.0 * i / 40) * 3.141592653589793 / 180.0;
        var tmp = sb.append_22ad7x_k$(i === 0 ? 'M ' : 'L ');
        // Inline function 'kotlin.math.cos' call
        var tmp_0 = 0.5 + 0.5 * Math.cos(a);
        // Inline function 'kotlin.math.sin' call
        var tmp$ret$2 = Math.sin(a);
        tmp.append_22ad7x_k$(formatNumber('%.4f %.4f ', [tmp_0, 0.5 + 0.5 * tmp$ret$2]));
      }
       while (!(i === n));
    // Inline function 'kotlin.text.trim' call
    var this_1 = sb.toString();
    return toString_1(trim(isCharSequence(this_1) ? this_1 : THROW_CCE()));
  };
  protoOf(PlayMode).scrubValue_p128sm_k$ = function (w, x, y) {
    if (w.kind_1 === 'slider')
      return this.sliderValue_3e3kr0_k$(w, x);
    var arc = w.part_s8somf_k$('arc');
    if (!(arc == null)) {
      var tmp0 = x - arc.get_cx_knto1u_k$();
      // Inline function 'kotlin.math.atan2' call
      var x_0 = -(y - arc.get_cy_knto1t_k$());
      var a = Math.atan2(tmp0, x_0);
      return (a / (2.0 * 3.141592653589793) + 1.0) % 1.0;
    }
    var tmp0_elvis_lhs = bar(this, w);
    var tmp;
    if (tmp0_elvis_lhs == null) {
      return 0.0;
    } else {
      tmp = tmp0_elvis_lhs;
    }
    var b = tmp;
    return coerceIn((x - b.left_1) / b.total_1, 0.0, 1.0);
  };
  protoOf(PlayMode).sliderValue_3e3kr0_k$ = function (w, docX) {
    var tmp0_safe_receiver = slider(this, w);
    var tmp1_elvis_lhs = tmp0_safe_receiver == null ? null : tmp0_safe_receiver.value_cpglt3_k$(docX);
    return tmp1_elvis_lhs == null ? 0.0 : tmp1_elvis_lhs;
  };
  protoOf(PlayMode).initial_8bu8p4_k$ = function (w) {
    var tmp;
    switch (w.kind_1) {
      case 'slider':
        var tmp1_safe_receiver = slider(this, w);
        var tmp_0;
        if (tmp1_safe_receiver == null) {
          tmp_0 = null;
        } else {
          // Inline function 'kotlin.let' call
          tmp_0 = tmp1_safe_receiver.value_cpglt3_k$(tmp1_safe_receiver.thumb_1.get_cx_knto1u_k$());
        }

        var tmp2_elvis_lhs = tmp_0;
        tmp = tmp2_elvis_lhs == null ? 0.0 : tmp2_elvis_lhs;
        break;
      case 'switch':
        var tmp_1;
        var tmp3_safe_receiver = w.part_s8somf_k$('track');
        if ((tmp3_safe_receiver == null ? null : tmp3_safe_receiver.fillToken_1) === 0) {
          tmp_1 = 1.0;
        } else {
          tmp_1 = 0.0;
        }

        tmp = tmp_1;
        break;
      case 'check':
        var tmp_2;
        var tmp4_safe_receiver = w.part_s8somf_k$('box');
        var tmp5_safe_receiver = tmp4_safe_receiver == null ? null : tmp4_safe_receiver.fillToken_1;
        var tmp_3;
        if (tmp5_safe_receiver == null) {
          tmp_3 = null;
        } else {
          // Inline function 'kotlin.let' call
          tmp_3 = tmp5_safe_receiver >= 0;
        }

        if (tmp_3 === true) {
          tmp_2 = 1.0;
        } else {
          tmp_2 = 0.0;
        }

        tmp = tmp_2;
        break;
      case 'radio':
        var tmp_4;
        var tmp6_safe_receiver = w.part_s8somf_k$('dot');
        var tmp7_elvis_lhs = tmp6_safe_receiver == null ? null : tmp6_safe_receiver.w_1;
        if ((tmp7_elvis_lhs == null ? 0.0 : tmp7_elvis_lhs) > 1.0) {
          tmp_4 = 1.0;
        } else {
          tmp_4 = 0.0;
        }

        tmp = tmp_4;
        break;
      case 'chip':
        var tmp_5;
        var tmp8_safe_receiver = w.part_s8somf_k$('bg');
        var tmp9_safe_receiver = tmp8_safe_receiver == null ? null : tmp8_safe_receiver.fillToken_1;
        var tmp_6;
        if (tmp9_safe_receiver == null) {
          tmp_6 = null;
        } else {
          // Inline function 'kotlin.let' call
          tmp_6 = tmp9_safe_receiver >= 0;
        }

        if (tmp_6 === true) {
          tmp_5 = 1.0;
        } else {
          tmp_5 = 0.0;
        }

        tmp = tmp_5;
        break;
      case 'pick':
        tmp = initialPick(this, w);
        break;
      case 'progress':
        tmp = progressInitial(this, w);
        break;
      case 'focus':
        var tmp_7;
        var tmp_8;
        var tmp10_safe_receiver = w.part_s8somf_k$('box');
        var tmp_9;
        if (tmp10_safe_receiver == null) {
          tmp_9 = null;
        } else {
          // Inline function 'kotlin.let' call
          tmp_9 = tmp10_safe_receiver.strokeWidth_1 > (endsWith(tmp10_safe_receiver.widget_1, '/err') ? 2.5 : 1.5);
        }

        if (tmp_9 === true) {
          tmp_8 = true;
        } else {
          var tmp11_safe_receiver = w.part_s8somf_k$('line');
          tmp_8 = (tmp11_safe_receiver == null ? null : tmp11_safe_receiver.fillToken_1) === 0;
        }

        if (tmp_8) {
          tmp_7 = 1.0;
        } else {
          tmp_7 = 0.0;
        }

        tmp = tmp_7;
        break;
      case 'reveal':
        var tmp_10;
        var tmp12_safe_receiver = firstOrNull(w.parts_9zuly2_k$('item'));
        var tmp13_elvis_lhs = tmp12_safe_receiver == null ? null : tmp12_safe_receiver.opacity_1;
        if ((tmp13_elvis_lhs == null ? 1.0 : tmp13_elvis_lhs) > 0.5) {
          tmp_10 = 1.0;
        } else {
          tmp_10 = 0.0;
        }

        tmp = tmp_10;
        break;
      case 'counter':
        var tmp14_safe_receiver = w.part_s8somf_k$('label');
        var tmp15_safe_receiver = tmp14_safe_receiver == null ? null : tmp14_safe_receiver.text_1;
        var tmp_11;
        if (tmp15_safe_receiver == null) {
          tmp_11 = null;
        } else {
          // Inline function 'kotlin.text.trim' call
          tmp_11 = toString_1(trim(isCharSequence(tmp15_safe_receiver) ? tmp15_safe_receiver : THROW_CCE()));
        }

        var tmp16_safe_receiver = tmp_11;
        var tmp17_safe_receiver = tmp16_safe_receiver == null ? null : toIntOrNull(tmp16_safe_receiver);
        var tmp18_elvis_lhs = tmp17_safe_receiver == null ? null : tmp17_safe_receiver;
        tmp = tmp18_elvis_lhs == null ? 0.0 : tmp18_elvis_lhs;
        break;
      case 'press':
      case 'spin':
        tmp = 0.0;
        break;
      default:
        tmp = 0.0;
        break;
    }
    return tmp;
  };
  protoOf(PlayMode).persistent_it5osl_k$ = function (w) {
    return !(w.kind_1 === 'press') && !(w.kind_1 === 'spin');
  };
  protoOf(PlayMode).apply_5lvb2b_k$ = function (nodes, shown, tone, time) {
    if (shown.isEmpty_y1axqb_k$())
      return nodes;
    // Inline function 'kotlin.collections.filter' call
    var tmp0 = this.widgets_hajxma_k$(nodes);
    // Inline function 'kotlin.collections.filterTo' call
    var destination = ArrayList_init_$Create$();
    var _iterator__ex2g4s = tmp0.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      // Inline function 'kotlin.collections.contains' call
      // Inline function 'kotlin.collections.containsKey' call
      var key = element.group_1;
      if ((isInterface(shown, KtMap) ? shown : THROW_CCE()).containsKey_aw81wo_k$(key)) {
        destination.add_utx5q5_k$(element);
      }
    }
    var ws = destination;
    if (ws.isEmpty_y1axqb_k$())
      return nodes;
    var patched = HashMap_init_$Create$();
    var extra = HashMap_init_$Create$();
    var _iterator__ex2g4s_0 = ws.iterator_jk1svi_k$();
    $l$loop: while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
      var w = _iterator__ex2g4s_0.next_20eer_k$();
      var tmp0_elvis_lhs = shown.get_wei43m_k$(w.group_1);
      var tmp;
      if (tmp0_elvis_lhs == null) {
        continue $l$loop;
      } else {
        tmp = tmp0_elvis_lhs;
      }
      var v = tmp;
      switch (w.kind_1) {
        case 'slider':
          patchSlider(this, w, v, patched);
          break;
        case 'switch':
          patchSwitch(this, w, v, tone, patched);
          break;
        case 'check':
          patchCheck(this, w, v, tone, patched, extra);
          break;
        case 'radio':
          patchRadio(this, w, v, tone, patched, extra);
          break;
        case 'chip':
          patchChip(this, w, v, tone, patched);
          break;
        case 'pick':
          patchPick(this, w, v, tone, patched);
          break;
        case 'progress':
          patchProgress(this, w, v, patched);
          break;
        case 'focus':
          patchFocus(this, w, v, tone, patched);
          break;
        case 'reveal':
          var _iterator__ex2g4s_1 = w.parts_9zuly2_k$('item').iterator_jk1svi_k$();
          while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
            var n = _iterator__ex2g4s_1.next_20eer_k$();
            var tmp3 = n.id_1;
            // Inline function 'kotlin.collections.set' call
            var value = n.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, v);
            patched.put_4fpzoq_k$(tmp3, value);
          }

          break;
        case 'counter':
          patchCounter(this, w, v, patched);
          break;
        case 'spin':
          var _iterator__ex2g4s_2 = w.parts_9zuly2_k$('rot').iterator_jk1svi_k$();
          while (_iterator__ex2g4s_2.hasNext_bitz1p_k$()) {
            var n_0 = _iterator__ex2g4s_2.next_20eer_k$();
            var tmp6 = n_0.id_1;
            // Inline function 'kotlin.collections.set' call
            var value_0 = n_0.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, time * 220.0 % 360.0);
            patched.put_4fpzoq_k$(tmp6, value_0);
          }

          break;
        case 'press':
          patchPress(this, w, v, patched);
          break;
      }
    }
    var out = ArrayList_init_$Create$_0(nodes.get_size_woubt6_k$() + imul(extra.get_size_woubt6_k$(), 2) | 0);
    var _iterator__ex2g4s_3 = nodes.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_3.hasNext_bitz1p_k$()) {
      var n_1 = _iterator__ex2g4s_3.next_20eer_k$();
      var tmp2_elvis_lhs = patched.get_wei43m_k$(n_1.id_1);
      // Inline function 'kotlin.collections.plusAssign' call
      var element_0 = tmp2_elvis_lhs == null ? n_1 : tmp2_elvis_lhs;
      out.add_utx5q5_k$(element_0);
      var tmp3_safe_receiver = extra.get_wei43m_k$(n_1.id_1);
      if (tmp3_safe_receiver == null)
        null;
      else {
        // Inline function 'kotlin.let' call
        // Inline function 'kotlin.collections.plusAssign' call
        addAll(out, tmp3_safe_receiver);
      }
    }
    return out;
  };
  protoOf(PlayMode).apply$default_voeuy2_k$ = function (nodes, shown, tone, time, $super) {
    time = time === VOID ? 0.0 : time;
    return $super === VOID ? this.apply_5lvb2b_k$(nodes, shown, tone, time) : $super.apply_5lvb2b_k$.call(this, nodes, shown, tone, time);
  };
  var PlayMode_instance;
  function PlayMode_getInstance() {
    if (PlayMode_instance == null)
      new PlayMode();
    return PlayMode_instance;
  }
  function decodeTone($this, o) {
    var arr = o.optJSONArray_9s960s_k$('colors');
    var tmp;
    if (!(arr == null) && arr.length_iap7oa_k$() === 22) {
      // Inline function 'kotlin.collections.map' call
      var this_0 = until(0, arr.length_iap7oa_k$());
      // Inline function 'kotlin.collections.mapTo' call
      var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_0, 10));
      var inductionVariable = this_0.first_1;
      var last = this_0.last_1;
      if (inductionVariable <= last)
        do {
          var item = inductionVariable;
          inductionVariable = inductionVariable + 1 | 0;
          var it = item;
          var tmp$ret$0 = arr.getInt_s8uc8x_k$(it);
          destination.add_utx5q5_k$(tmp$ret$0);
        }
         while (!(item === last));
      tmp = destination;
    } else {
      tmp = Companion_getInstance_11().Baseline_1.colors_1;
    }
    var colors = tmp;
    return new Tone(o.optInt_piuztm_k$('mode', 0), o.optInt_piuztm_k$('seed', -16749974), o.optBoolean_n0bbhc_k$('dark', false), colors);
  }
  function encodeNode($this, n) {
    // Inline function 'kotlin.apply' call
    var this_0 = new JSONObject();
    this_0.put_9oxj04_k$('id', n.id_1);
    this_0.put_9oxj04_k$('kind', n.kind_1.name_1);
    this_0.put_9oxj04_k$('name', n.name_1);
    this_0.put_9oxj04_k$('x', n.x_1);
    this_0.put_9oxj04_k$('y', n.y_1);
    this_0.put_9oxj04_k$('w', n.w_1);
    this_0.put_9oxj04_k$('h', n.h_1);
    this_0.put_9oxj04_k$('rot', n.rotation_1);
    this_0.put_9oxj04_k$('fill', n.fill_1);
    this_0.put_9oxj04_k$('stroke', n.stroke_1);
    this_0.put_9oxj04_k$('sw', n.strokeWidth_1);
    this_0.put_9oxj04_k$('op', n.opacity_1);
    this_0.put_9oxj04_k$('corner', n.corner_1);
    this_0.put_9oxj04_k$('shape', n.shapeId_1);
    this_0.put_9oxj04_k$('text', n.text_1);
    this_0.put_9oxj04_k$('fs', n.fontSize_1);
    this_0.put_9oxj04_k$('fw', n.weight_1);
    this_0.put_9oxj04_k$('group', n.group_1);
    this_0.put_9oxj04_k$('vis', n.visible_1);
    this_0.put_9oxj04_k$('lock', n.locked_1);
    this_0.put_9oxj04_k$('ratio', n.ratioLock_1);
    // Inline function 'kotlin.text.isNotEmpty' call
    var this_1 = n.path_1;
    if (charSequenceLength(this_1) > 0) {
      this_0.put_9oxj04_k$('path', n.path_1);
    }
    if (n.evenOdd_1) {
      this_0.put_9oxj04_k$('eo', true);
    }
    // Inline function 'kotlin.text.isNotEmpty' call
    var this_2 = n.asset_1;
    if (charSequenceLength(this_2) > 0) {
      this_0.put_9oxj04_k$('asset', n.asset_1);
    }
    // Inline function 'kotlin.text.isNotEmpty' call
    var this_3 = n.font_1;
    if (charSequenceLength(this_3) > 0) {
      this_0.put_9oxj04_k$('font', n.font_1);
    }
    if (n.fillToken_1 >= 0) {
      this_0.put_9oxj04_k$('ft', n.fillToken_1);
    }
    if (n.strokeToken_1 >= 0) {
      this_0.put_9oxj04_k$('st', n.strokeToken_1);
    }
    if (n.blur_1 > 0.0) {
      this_0.put_9oxj04_k$('blur', n.blur_1);
    }
    if (n.softBlur_1 > 0.0) {
      this_0.put_9oxj04_k$('sb', n.softBlur_1);
    }
    if (n.pressCorner_1 >= 0.0) {
      this_0.put_9oxj04_k$('pc', n.pressCorner_1);
    }
    // Inline function 'kotlin.text.isNotEmpty' call
    var this_4 = n.action_1;
    if (charSequenceLength(this_4) > 0) {
      this_0.put_9oxj04_k$('ac', n.action_1);
    }
    if (n.mask_1) {
      this_0.put_9oxj04_k$('mask', true);
    }
    // Inline function 'kotlin.text.isNotEmpty' call
    var this_5 = n.widget_1;
    if (charSequenceLength(this_5) > 0) {
      this_0.put_9oxj04_k$('wd', n.widget_1);
    }
    if (!(n.gradKind_1 === 0)) {
      this_0.put_9oxj04_k$('gk', n.gradKind_1);
      this_0.put_9oxj04_k$('f2', n.fill2__1);
      this_0.put_9oxj04_k$('ga', n.gradAngle_1);
    }
    if (n.shadowBlur_1 > 0.0) {
      this_0.put_9oxj04_k$('shb', n.shadowBlur_1);
      this_0.put_9oxj04_k$('shx', n.shadowDx_1);
      this_0.put_9oxj04_k$('shy', n.shadowDy_1);
      this_0.put_9oxj04_k$('shc', n.shadowColor_1);
    }
    return this_0;
  }
  function decodeNode($this, o) {
    var tmp0_id = o.getString_gb1pt9_k$('id');
    // Inline function 'kotlin.runCatching' call
    var tmp;
    try {
      // Inline function 'kotlin.Companion.success' call
      var value = valueOf(o.getString_gb1pt9_k$('kind'));
      tmp = _Result___init__impl__xyqfz8(value);
    } catch ($p) {
      var tmp_0;
      if ($p instanceof Error) {
        var e = $p;
        // Inline function 'kotlin.Companion.failure' call
        tmp_0 = _Result___init__impl__xyqfz8(createFailure(e));
      } else {
        throw $p;
      }
      tmp = tmp_0;
    }
    var tmp2 = tmp;
    var tmp3 = NodeKind_RECT_getInstance();
    var tmp$ret$4;
    $l$block: {
      // Inline function 'kotlin.getOrDefault' call
      if (_Result___get_isFailure__impl__jpiriv(tmp2)) {
        tmp$ret$4 = tmp3;
        break $l$block;
      }
      var tmp_1 = _Result___get_value__impl__bjfvqg(tmp2);
      tmp$ret$4 = (tmp_1 == null ? true : !(tmp_1 == null)) ? tmp_1 : THROW_CCE();
    }
    var tmp1_kind = tmp$ret$4;
    var tmp2_name = o.optString$default_a8gqg6_k$('name');
    var tmp3_x = o.getDouble_v37ict_k$('x');
    var tmp4_y = o.getDouble_v37ict_k$('y');
    var tmp5_w = o.getDouble_v37ict_k$('w');
    var tmp6_h = o.getDouble_v37ict_k$('h');
    var tmp7_rotation = o.optDouble_pwajio_k$('rot', 0.0);
    var tmp8_fill = o.optInt$default_5j5ewg_k$('fill');
    var tmp9_stroke = o.optInt$default_5j5ewg_k$('stroke');
    var tmp10_strokeWidth = o.optDouble_pwajio_k$('sw', 0.0);
    var tmp11_opacity = o.optDouble_pwajio_k$('op', 1.0);
    var tmp12_corner = o.optDouble_pwajio_k$('corner', 0.0);
    var tmp13_shapeId = o.optString$default_a8gqg6_k$('shape');
    var tmp14_text = o.optString$default_a8gqg6_k$('text');
    var tmp15_fontSize = o.optDouble_pwajio_k$('fs', 16.0);
    var tmp16_weight = o.optInt_piuztm_k$('fw', 400);
    var tmp17_group = o.optString$default_a8gqg6_k$('group');
    var tmp18_visible = o.optBoolean_n0bbhc_k$('vis', true);
    var tmp19_locked = o.optBoolean_n0bbhc_k$('lock', false);
    var tmp20_ratioLock = o.optBoolean_n0bbhc_k$('ratio', false);
    var tmp21_path = o.optString$default_a8gqg6_k$('path');
    var tmp22_evenOdd = o.optBoolean_n0bbhc_k$('eo', false);
    var tmp23_asset = o.optString$default_a8gqg6_k$('asset');
    var tmp24_font = o.optString$default_a8gqg6_k$('font');
    var tmp25_fillToken = o.optInt_piuztm_k$('ft', -1);
    var tmp26_strokeToken = o.optInt_piuztm_k$('st', -1);
    var tmp27_blur = o.optDouble_pwajio_k$('blur', 0.0);
    var tmp28_softBlur = o.optDouble_pwajio_k$('sb', 0.0);
    var tmp29_pressCorner = o.optDouble_pwajio_k$('pc', -1.0);
    var tmp30_action = o.optString_gse350_k$('ac', '');
    var tmp31_mask = o.optBoolean_n0bbhc_k$('mask', false);
    var tmp32_widget = o.optString_gse350_k$('wd', '');
    var tmp33_gradKind = o.optInt_piuztm_k$('gk', 0);
    var tmp34_fill2 = o.optInt_piuztm_k$('f2', -16777216);
    var tmp35_gradAngle = o.optDouble_pwajio_k$('ga', 90.0);
    var tmp36_shadowBlur = o.optDouble_pwajio_k$('shb', 0.0);
    var tmp37_shadowDx = o.optDouble_pwajio_k$('shx', 0.0);
    var tmp38_shadowDy = o.optDouble_pwajio_k$('shy', 4.0);
    var tmp39_shadowColor = o.optInt_piuztm_k$('shc', 1493172224);
    return new Node(tmp0_id, tmp1_kind, tmp2_name, tmp3_x, tmp4_y, tmp5_w, tmp6_h, tmp7_rotation, tmp8_fill, tmp9_stroke, tmp10_strokeWidth, tmp11_opacity, tmp12_corner, tmp13_shapeId, tmp14_text, tmp15_fontSize, tmp16_weight, tmp17_group, tmp18_visible, tmp19_locked, tmp20_ratioLock, tmp21_path, tmp22_evenOdd, tmp23_asset, tmp24_font, tmp25_fillToken, tmp26_strokeToken, tmp27_blur, tmp28_softBlur, tmp29_pressCorner, tmp33_gradKind, tmp34_fill2, tmp35_gradAngle, tmp36_shadowBlur, tmp37_shadowDx, tmp38_shadowDy, tmp39_shadowColor, tmp31_mask, tmp32_widget, tmp30_action);
  }
  function ProjectStore() {
  }
  protoOf(ProjectStore).encode_mh4nqw_k$ = function (p) {
    // Inline function 'kotlin.apply' call
    var this_0 = new JSONObject();
    this_0.put_9oxj04_k$('v', 1);
    this_0.put_9oxj04_k$('id', p.id_1);
    this_0.put_9oxj04_k$('name', p.name_1);
    this_0.put_9oxj04_k$('w', p.width_1);
    this_0.put_9oxj04_k$('h', p.height_1);
    this_0.put_9oxj04_k$('bg', p.background_1);
    this_0.put_9oxj04_k$('created', p.created_1);
    this_0.put_9oxj04_k$('updated', p.updated_1);
    this_0.put_9oxj04_k$('bgToken', p.bgToken_1);
    // Inline function 'kotlin.apply' call
    var this_1 = new JSONObject();
    this_1.put_9oxj04_k$('mode', p.tone_1.mode_1);
    this_1.put_9oxj04_k$('seed', p.tone_1.seed_1);
    this_1.put_9oxj04_k$('dark', p.tone_1.dark_1);
    // Inline function 'kotlin.also' call
    var this_2 = new JSONArray();
    // Inline function 'kotlin.collections.forEach' call
    var _iterator__ex2g4s = p.tone_1.colors_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      this_2.put_58ltao_k$(element);
    }
    this_1.put_9oxj04_k$('colors', this_2);
    this_0.put_9oxj04_k$('tone', this_1);
    // Inline function 'kotlin.also' call
    var this_3 = new JSONArray();
    // Inline function 'kotlin.collections.forEach' call
    var _iterator__ex2g4s_0 = p.nodes_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
      var element_0 = _iterator__ex2g4s_0.next_20eer_k$();
      this_3.put_58ltao_k$(encodeNode(ProjectStore_instance, element_0));
    }
    this_0.put_9oxj04_k$('nodes', this_3);
    if (p.pages_1.get_size_woubt6_k$() > 1) {
      this_0.put_9oxj04_k$('active', p.activePage_1);
      // Inline function 'kotlin.also' call
      var this_4 = new JSONArray();
      // Inline function 'kotlin.collections.forEach' call
      var _iterator__ex2g4s_1 = p.pages_1.iterator_jk1svi_k$();
      while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
        var element_1 = _iterator__ex2g4s_1.next_20eer_k$();
        // Inline function 'kotlin.apply' call
        var this_5 = new JSONObject();
        this_5.put_9oxj04_k$('id', element_1.id_1);
        this_5.put_9oxj04_k$('name', element_1.name_1);
        // Inline function 'kotlin.also' call
        var this_6 = new JSONArray();
        // Inline function 'kotlin.collections.forEach' call
        var _iterator__ex2g4s_2 = element_1.nodes_1.iterator_jk1svi_k$();
        while (_iterator__ex2g4s_2.hasNext_bitz1p_k$()) {
          var element_2 = _iterator__ex2g4s_2.next_20eer_k$();
          this_6.put_58ltao_k$(encodeNode(ProjectStore_instance, element_2));
        }
        this_5.put_9oxj04_k$('nodes', this_6);
        this_4.put_58ltao_k$(this_5);
      }
      this_0.put_9oxj04_k$('pages', this_4);
    }
    return this_0;
  };
  protoOf(ProjectStore).decode_rg9bht_k$ = function (o) {
    var arr = o.getJSONArray_be86jl_k$('nodes');
    // Inline function 'kotlin.collections.map' call
    var this_0 = until(0, arr.length_iap7oa_k$());
    // Inline function 'kotlin.collections.mapTo' call
    var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_0, 10));
    var inductionVariable = this_0.first_1;
    var last = this_0.last_1;
    if (inductionVariable <= last)
      do {
        var item = inductionVariable;
        inductionVariable = inductionVariable + 1 | 0;
        var it = item;
        var tmp$ret$0 = decodeNode(ProjectStore_instance, arr.getJSONObject_j6v1id_k$(it));
        destination.add_utx5q5_k$(tmp$ret$0);
      }
       while (!(item === last));
    var nodes = destination;
    var pagesArr = o.optJSONArray_9s960s_k$('pages');
    var tmp;
    if (pagesArr == null) {
      tmp = emptyList();
    } else {
      // Inline function 'kotlin.collections.map' call
      var this_1 = until(0, pagesArr.length_iap7oa_k$());
      // Inline function 'kotlin.collections.mapTo' call
      var destination_0 = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_1, 10));
      var inductionVariable_0 = this_1.first_1;
      var last_0 = this_1.last_1;
      if (inductionVariable_0 <= last_0)
        do {
          var item_0 = inductionVariable_0;
          inductionVariable_0 = inductionVariable_0 + 1 | 0;
          var i = item_0;
          var po = pagesArr.getJSONObject_j6v1id_k$(i);
          var na = po.getJSONArray_be86jl_k$('nodes');
          var tmp_0 = po.optString_gse350_k$('id', newId());
          var tmp_1 = po.optString$default_a8gqg6_k$('name');
          // Inline function 'kotlin.collections.map' call
          var this_2 = until(0, na.length_iap7oa_k$());
          // Inline function 'kotlin.collections.mapTo' call
          var destination_1 = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_2, 10));
          var inductionVariable_1 = this_2.first_1;
          var last_1 = this_2.last_1;
          if (inductionVariable_1 <= last_1)
            do {
              var item_1 = inductionVariable_1;
              inductionVariable_1 = inductionVariable_1 + 1 | 0;
              var it_0 = item_1;
              var tmp$ret$3 = decodeNode(ProjectStore_instance, na.getJSONObject_j6v1id_k$(it_0));
              destination_1.add_utx5q5_k$(tmp$ret$3);
            }
             while (!(item_1 === last_1));
          var tmp$ret$6 = new Page(tmp_0, tmp_1, destination_1);
          destination_0.add_utx5q5_k$(tmp$ret$6);
        }
         while (!(item_0 === last_0));
      tmp = destination_0;
    }
    var pages = tmp;
    var active = coerceIn_0(o.optInt_piuztm_k$('active', 0), 0, coerceAtLeast_0(pages.get_size_woubt6_k$() - 1 | 0, 0));
    var tmp_2 = o.getString_gb1pt9_k$('id');
    var tmp_3 = o.getString_gb1pt9_k$('name');
    var tmp_4 = o.getDouble_v37ict_k$('w');
    var tmp_5 = o.getDouble_v37ict_k$('h');
    var tmp_6 = o.getInt_npc9pd_k$('bg');
    var tmp_7 = o.optLong$default_wkurpt_k$('created');
    var tmp_8 = o.optLong$default_wkurpt_k$('updated');
    var tmp0_safe_receiver = o.optJSONObject_yq7aww_k$('tone');
    var tmp_9;
    if (tmp0_safe_receiver == null) {
      tmp_9 = null;
    } else {
      // Inline function 'kotlin.let' call
      tmp_9 = decodeTone(ProjectStore_instance, tmp0_safe_receiver);
    }
    var tmp1_elvis_lhs = tmp_9;
    return new Project(tmp_2, tmp_3, tmp_4, tmp_5, tmp_6, nodes, tmp_7, tmp_8, tmp1_elvis_lhs == null ? Companion_getInstance_11().Baseline_1 : tmp1_elvis_lhs, o.optInt_piuztm_k$('bgToken', -1), pages, active);
  };
  var ProjectStore_instance;
  function ProjectStore_getInstance() {
    return ProjectStore_instance;
  }
  function Companion_11() {
    Companion_instance_11 = this;
    this.MODE_BASELINE_1 = 0;
    this.MODE_SEED_1 = 1;
    this.MODE_DYNAMIC_1 = 2;
    this.BASE_SEED_1 = -16749974;
    this.Baseline_1 = new Tone();
  }
  protoOf(Companion_11).fromSeed_gjco7c_k$ = function (seed, dark) {
    return new Tone(1, seed | -16777216, dark, ToneGen_instance.scheme_n1wg6q_k$(seed, dark));
  };
  var Companion_instance_11;
  function Companion_getInstance_11() {
    if (Companion_instance_11 == null)
      new Companion_11();
    return Companion_instance_11;
  }
  function Tone(mode, seed, dark, colors) {
    Companion_getInstance_11();
    mode = mode === VOID ? 0 : mode;
    seed = seed === VOID ? -16749974 : seed;
    dark = dark === VOID ? false : dark;
    var tmp;
    if (colors === VOID) {
      // Inline function 'kotlin.collections.map' call
      var this_0 = DesignPalette_getInstance().get_baseline_arnwum_k$();
      // Inline function 'kotlin.collections.mapTo' call
      var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(this_0, 10));
      var _iterator__ex2g4s = this_0.iterator_jk1svi_k$();
      while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
        var item = _iterator__ex2g4s.next_20eer_k$();
        var tmp$ret$0 = item.argb_1;
        destination.add_utx5q5_k$(tmp$ret$0);
      }
      tmp = destination;
    } else {
      tmp = colors;
    }
    colors = tmp;
    this.mode_1 = mode;
    this.seed_1 = seed;
    this.dark_1 = dark;
    this.colors_1 = colors;
  }
  protoOf(Tone).color_kvkafx_k$ = function (token, fallback) {
    var tmp0_elvis_lhs = getOrNull(this.colors_1, token);
    return tmp0_elvis_lhs == null ? fallback : tmp0_elvis_lhs;
  };
  protoOf(Tone).color$default_xk5c97_k$ = function (token, fallback, $super) {
    fallback = fallback === VOID ? 0 : fallback;
    return $super === VOID ? this.color_kvkafx_k$(token, fallback) : $super.color_kvkafx_k$.call(this, token, fallback);
  };
  protoOf(Tone).toString = function () {
    return 'Tone(mode=' + this.mode_1 + ', seed=' + this.seed_1 + ', dark=' + this.dark_1 + ', colors=' + toString_1(this.colors_1) + ')';
  };
  protoOf(Tone).hashCode = function () {
    var result = this.mode_1;
    result = imul(result, 31) + this.seed_1 | 0;
    result = imul(result, 31) + getBooleanHashCode(this.dark_1) | 0;
    result = imul(result, 31) + hashCode(this.colors_1) | 0;
    return result;
  };
  protoOf(Tone).equals = function (other) {
    if (this === other)
      return true;
    if (!(other instanceof Tone))
      return false;
    var tmp0_other_with_cast = other instanceof Tone ? other : THROW_CCE();
    if (!(this.mode_1 === tmp0_other_with_cast.mode_1))
      return false;
    if (!(this.seed_1 === tmp0_other_with_cast.seed_1))
      return false;
    if (!(this.dark_1 === tmp0_other_with_cast.dark_1))
      return false;
    if (!equals(this.colors_1, tmp0_other_with_cast.colors_1))
      return false;
    return true;
  };
  function toLinear($this, c) {
    var tmp;
    if (c <= 0.04045) {
      tmp = c / 12.92;
    } else {
      // Inline function 'kotlin.math.pow' call
      var this_0 = (c + 0.055) / 1.055;
      tmp = Math.pow(this_0, 2.4);
    }
    return tmp;
  }
  function fromLinear($this, c) {
    var tmp;
    if (c <= 0.0031308) {
      tmp = 12.92 * c;
    } else {
      // Inline function 'kotlin.math.pow' call
      var x = 1.0 / 2.4;
      tmp = 1.055 * Math.pow(c, x) - 0.055;
    }
    return tmp;
  }
  function linearRgb($this, L, C, hue) {
    var hr = Math_instance.toRadians_sjqwz3_k$(hue);
    // Inline function 'kotlin.math.cos' call
    var a = C * Math.cos(hr);
    // Inline function 'kotlin.math.sin' call
    var b = C * Math.sin(hr);
    // Inline function 'kotlin.let' call
    var it = L + 0.39633778 * a + 0.21580376 * b;
    var l = it * it * it;
    // Inline function 'kotlin.let' call
    var it_0 = L - 0.105561346 * a - 0.06385417 * b;
    var m = it_0 * it_0 * it_0;
    // Inline function 'kotlin.let' call
    var it_1 = L - 0.08948418 * a - 1.2914855 * b;
    var s = it_1 * it_1 * it_1;
    // Inline function 'kotlin.floatArrayOf' call
    return new Float32Array([4.0767417 * l - 3.3077116 * m + 0.23096994 * s, -1.268438 * l + 2.6097574 * m - 0.34131938 * s, -0.0041960864 * l - 0.7034186 * m + 1.7076147 * s]);
  }
  function fromOklch$ch(v) {
    // Inline function 'kotlin.math.roundToInt' call
    var this_0 = fromLinear(ToneGen_instance, coerceIn(v, 0.0, 1.0)) * 255.0;
    var tmp$ret$0 = roundToInt(this_0);
    return coerceIn_0(tmp$ret$0, 0, 255);
  }
  function scheme$p(hs, cp, t) {
    return ToneGen_instance.tone_vb5dx6_k$(hs, cp, t);
  }
  function scheme$s(hs, cp, t) {
    return ToneGen_instance.tone_vb5dx6_k$(hs, cp / 3.0, t);
  }
  function scheme$t(ht, cp, tn) {
    return ToneGen_instance.tone_vb5dx6_k$(ht, cp * 0.55, tn);
  }
  function scheme$e(tn) {
    return ToneGen_instance.tone_vb5dx6_k$(29.0, 0.19, tn);
  }
  function scheme$n(hs, cn, tn) {
    return ToneGen_instance.tone_vb5dx6_k$(hs, cn, tn);
  }
  function scheme$nv(hs, cnv, tn) {
    return ToneGen_instance.tone_vb5dx6_k$(hs, cnv, tn);
  }
  function ToneGen() {
  }
  protoOf(ToneGen).toOklch_6nb526_k$ = function (argb) {
    var r = toLinear(this, (argb >> 16 & 255) / 255.0);
    var g = toLinear(this, (argb >> 8 & 255) / 255.0);
    var b = toLinear(this, (argb & 255) / 255.0);
    // Inline function 'kotlin.math.cbrt' call
    var x = 0.41222146 * r + 0.53633255 * g + 0.051445995 * b;
    var l = Math.cbrt(x);
    // Inline function 'kotlin.math.cbrt' call
    var x_0 = 0.2119035 * r + 0.6806995 * g + 0.10739696 * b;
    var m = Math.cbrt(x_0);
    // Inline function 'kotlin.math.cbrt' call
    var x_1 = 0.08830246 * r + 0.28171885 * g + 0.6299787 * b;
    var s = Math.cbrt(x_1);
    var ll = 0.21045426 * l + 0.7936178 * m - 0.004072047 * s;
    var a = 1.9779985 * l - 2.4285922 * m + 0.4505937 * s;
    var bb = 0.025904037 * l + 0.78277177 * m - 0.80867577 * s;
    var tmp = Math_instance;
    // Inline function 'kotlin.math.atan2' call
    var tmp$ret$3 = Math.atan2(bb, a);
    var h = tmp.toDegrees_negxly_k$(tmp$ret$3);
    if (h < 0.0)
      h = h + 360.0;
    // Inline function 'kotlin.math.sqrt' call
    var x_2 = a * a + bb * bb;
    var tmp$ret$4 = Math.sqrt(x_2);
    return new Triple(ll, tmp$ret$4, h);
  };
  protoOf(ToneGen).fromOklch_o6gs8d_k$ = function (L, C, hue) {
    var c = C;
    var rgb = linearRgb(this, L, c, hue);
    var guard = 0;
    $l$loop: while (true) {
      var tmp;
      var _unary__edvuaz = guard;
      guard = _unary__edvuaz + 1 | 0;
      if (_unary__edvuaz < 40) {
        var tmp0 = rgb;
        var tmp$ret$1;
        $l$block: {
          // Inline function 'kotlin.collections.any' call
          var inductionVariable = 0;
          var last = tmp0.length;
          while (inductionVariable < last) {
            var element = tmp0[inductionVariable];
            inductionVariable = inductionVariable + 1 | 0;
            if (element < -5.0E-4 || element > 1.0005) {
              tmp$ret$1 = true;
              break $l$block;
            }
          }
          tmp$ret$1 = false;
        }
        tmp = tmp$ret$1;
      } else {
        tmp = false;
      }
      if (!tmp) {
        break $l$loop;
      }
      c = c * 0.92;
      rgb = linearRgb(this, L, c, hue);
    }
    return -16777216 | fromOklch$ch(rgb[0]) << 16 | fromOklch$ch(rgb[1]) << 8 | fromOklch$ch(rgb[2]);
  };
  protoOf(ToneGen).tone_vb5dx6_k$ = function (hue, chroma, tone) {
    var tmp;
    if (tone > 8.0) {
      // Inline function 'kotlin.math.pow' call
      var this_0 = (tone + 16.0) / 116.0;
      tmp = Math.pow(this_0, 3);
    } else {
      tmp = tone / 903.3;
    }
    var y = tmp;
    // Inline function 'kotlin.math.cbrt' call
    var tmp$ret$1 = Math.cbrt(y);
    return this.fromOklch_o6gs8d_k$(tmp$ret$1, chroma, hue);
  };
  protoOf(ToneGen).scheme_n1wg6q_k$ = function (seed, dark) {
    var _destruct__k2r9zo = this.toOklch_6nb526_k$(seed);
    var c = _destruct__k2r9zo.component2_7eebsb_k$();
    var h = _destruct__k2r9zo.component3_7eebsa_k$();
    var gray = c < 0.02;
    var cp = gray ? c : coerceIn(c, 0.11, 0.2);
    var hs = h;
    var ht = (h + 60.0) % 360.0;
    var cn = gray ? 0.0 : 0.012;
    var cnv = gray ? 0.0 : 0.022;
    return !dark ? listOf_0([scheme$p(hs, cp, 40.0), scheme$p(hs, cp, 100.0), scheme$p(hs, cp, 90.0), scheme$p(hs, cp, 10.0), scheme$s(hs, cp, 40.0), scheme$s(hs, cp, 90.0), scheme$s(hs, cp, 10.0), scheme$t(ht, cp, 40.0), scheme$t(ht, cp, 90.0), scheme$t(ht, cp, 10.0), scheme$e(40.0), scheme$e(90.0), scheme$n(hs, cn, 98.0), scheme$n(hs, cn, 96.0), scheme$n(hs, cn, 94.0), scheme$n(hs, cn, 92.0), scheme$n(hs, cn, 90.0), scheme$n(hs, cn, 10.0), scheme$nv(hs, cnv, 30.0), scheme$nv(hs, cnv, 50.0), scheme$nv(hs, cnv, 80.0), scheme$n(hs, cn, 20.0)]) : listOf_0([scheme$p(hs, cp, 80.0), scheme$p(hs, cp, 20.0), scheme$p(hs, cp, 30.0), scheme$p(hs, cp, 90.0), scheme$s(hs, cp, 80.0), scheme$s(hs, cp, 30.0), scheme$s(hs, cp, 90.0), scheme$t(ht, cp, 80.0), scheme$t(ht, cp, 30.0), scheme$t(ht, cp, 90.0), scheme$e(80.0), scheme$e(30.0), scheme$n(hs, cn, 6.0), scheme$n(hs, cn, 10.0), scheme$n(hs, cn, 12.0), scheme$n(hs, cn, 17.0), scheme$n(hs, cn, 22.0), scheme$n(hs, cn, 90.0), scheme$nv(hs, cnv, 80.0), scheme$nv(hs, cnv, 60.0), scheme$nv(hs, cnv, 30.0), scheme$n(hs, cn, 90.0)]);
  };
  var ToneGen_instance;
  function ToneGen_getInstance() {
    return ToneGen_instance;
  }
  function withTone(_this__u8e3s4, tone) {
    // Inline function 'kotlin.collections.map' call
    // Inline function 'kotlin.collections.mapTo' call
    var destination = ArrayList_init_$Create$_0(collectionSizeOrDefault(_this__u8e3s4, 10));
    var _iterator__ex2g4s = _this__u8e3s4.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var item = _iterator__ex2g4s.next_20eer_k$();
      var tmp$ret$0 = item.fillToken_1 < 0 && item.strokeToken_1 < 0 ? item : item.copy$default_q375vp_k$(VOID, VOID, VOID, VOID, VOID, VOID, VOID, VOID, item.fillToken_1 >= 0 ? tone.color_kvkafx_k$(item.fillToken_1, item.fill_1) : item.fill_1, item.strokeToken_1 >= 0 ? tone.color_kvkafx_k$(item.strokeToken_1, item.stroke_1) : item.stroke_1);
      destination.add_utx5q5_k$(tmp$ret$0);
    }
    return destination;
  }
  function IconLibrary() {
    IconLibrary_instance = this;
    this.styles_1 = emptyList();
  }
  protoOf(IconLibrary).bytes_k928ey_k$ = function (style, name, fill) {
    return null;
  };
  protoOf(IconLibrary).label_9g3ls6_k$ = function (name) {
    return name;
  };
  var IconLibrary_instance;
  function IconLibrary_getInstance() {
    if (IconLibrary_instance == null)
      new IconLibrary();
    return IconLibrary_instance;
  }
  function SvgImport() {
  }
  protoOf(SvgImport).parseOwnSize_8kecem_k$ = function (b, s) {
    return null;
  };
  var SvgImport_instance;
  function SvgImport_getInstance() {
    return SvgImport_instance;
  }
  var cached;
  function qwelCore(input) {
    var request = JSONObject_init_$Create$(input);
    if (request.optString$default_a8gqg6_k$('op') === 'language') {
      set_words(JSON.parse(request.getString_gb1pt9_k$('strings')));
      return '{}';
    }
    var supplied = request.optJSONObject_yq7aww_k$('project');
    var tmp;
    if (!(supplied == null)) {
      // Inline function 'kotlin.also' call
      var this_0 = ProjectStore_instance.decode_rg9bht_k$(supplied);
      cached = this_0;
      tmp = this_0;
    } else {
      var tmp0_elvis_lhs = cached;
      var tmp_0;
      if (tmp0_elvis_lhs == null) {
        throw IllegalStateException_init_$Create$_0('No project');
      } else {
        tmp_0 = tmp0_elvis_lhs;
      }
      tmp = tmp_0;
    }
    var p = tmp;
    var op = request.getString_gb1pt9_k$('op');
    var pm = PlayMode_getInstance();
    var tmp1_elvis_lhs = request.optJSONObject_yq7aww_k$('shown');
    var shown = tmp1_elvis_lhs == null ? new JSONObject() : tmp1_elvis_lhs;
    // Inline function 'kotlin.collections.associateWith' call
    var this_1 = shown.keys_1yhh0_k$();
    var result = LinkedHashMap_init_$Create$_0(coerceAtLeast_0(mapCapacity(collectionSizeOrDefault(this_1, 10)), 16));
    // Inline function 'kotlin.collections.associateWithTo' call
    var _iterator__ex2g4s = this_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      var tmp$ret$2 = shown.optDouble$default_xipa5i_k$(element);
      result.put_4fpzoq_k$(element, tmp$ret$2);
    }
    var values = toMutableMap(result);
    var tmp_1;
    switch (op) {
      case 'set':
      case 'init':
        var tmp_2 = new JSONObject();
        // Inline function 'kotlin.also' call

        var this_2 = new JSONArray();
        // Inline function 'kotlin.collections.forEach' call

        var _iterator__ex2g4s_0 = pm.widgets_hajxma_k$(p.nodes_1).iterator_jk1svi_k$();
        while (_iterator__ex2g4s_0.hasNext_bitz1p_k$()) {
          var element_0 = _iterator__ex2g4s_0.next_20eer_k$();
          this_2.put_58ltao_k$(qwelCore$widgetObject(pm, element_0));
        }

        tmp_1 = tmp_2.put_9oxj04_k$('widgets', this_2).toString();
        break;
      case 'hit':
        var x = request.optDouble$default_xipa5i_k$('x');
        var y = request.optDouble$default_xipa5i_k$('y');
        var w = pm.widgetAt_cyoaem_k$(p.nodes_1, x, y, request.optDouble_pwajio_k$('pad', 8.0));
        tmp_1 = w == null ? '{}' : qwelCore$widgetObject(pm, w).put_9oxj04_k$('value', w.kind_1 === 'slider' ? pm.sliderValue_3e3kr0_k$(w, x) : w.kind_1 === 'progress' ? pm.scrubValue_p128sm_k$(w, x, y) : pm.initial_8bu8p4_k$(w)).toString();
        break;
      case 'tap':
      case 'swipe':
        var tmp6 = pm.widgets_hajxma_k$(p.nodes_1);
        var tmp$ret$10;
        $l$block: {
          // Inline function 'kotlin.collections.firstOrNull' call
          var _iterator__ex2g4s_1 = tmp6.iterator_jk1svi_k$();
          while (_iterator__ex2g4s_1.hasNext_bitz1p_k$()) {
            var element_1 = _iterator__ex2g4s_1.next_20eer_k$();
            if (element_1.group_1 === request.getString_gb1pt9_k$('group')) {
              tmp$ret$10 = element_1;
              break $l$block;
            }
          }
          tmp$ret$10 = null;
        }

        var w_0 = tmp$ret$10;
        if (!(w_0 == null)) {
          if (op === 'swipe' && w_0.kind_1 === 'pick') {
            var tmp9 = w_0.group_1;
            var tmp3_elvis_lhs = values.get_wei43m_k$(w_0.group_1);
            // Inline function 'kotlin.collections.set' call
            var value = coerceIn_0(numberToInt(tmp3_elvis_lhs == null ? 0.0 : tmp3_elvis_lhs) + request.optInt$default_5j5ewg_k$('direction') | 0, 0, coerceAtLeast_0(pm.pickCount_5xun7y_k$(w_0) - 1 | 0, 0));
            values.put_4fpzoq_k$(tmp9, value);
          } else {
            (new TapState(p.nodes_1, values)).playTap_eyfrwd_k$(w_0, request.optDouble$default_xipa5i_k$('x'), request.optDouble$default_xipa5i_k$('y'));
          }
        }

        // Inline function 'kotlin.also' call

        var this_3 = new JSONObject();
        // Inline function 'kotlin.collections.forEach' call

        // Inline function 'kotlin.collections.iterator' call

        var _iterator__ex2g4s_2 = values.get_entries_p20ztl_k$().iterator_jk1svi_k$();
        while (_iterator__ex2g4s_2.hasNext_bitz1p_k$()) {
          var element_2 = _iterator__ex2g4s_2.next_20eer_k$();
          // Inline function 'kotlin.collections.component1' call
          var k = element_2.get_key_18j28a_k$();
          // Inline function 'kotlin.collections.component2' call
          var v = element_2.get_value_j01efc_k$();
          this_3.put_9oxj04_k$(k, v);
        }

        tmp_1 = this_3.toString();
        break;
      case 'apply':
        tmp_1 = qwelCore$output(p, pm.apply_5lvb2b_k$(p.nodes_1, values, p.tone_1, request.optDouble$default_xipa5i_k$('time')));
        break;
      case 'stop':
        // Inline function 'kotlin.collections.associateBy' call

        var this_4 = pm.widgets_hajxma_k$(p.nodes_1);
        var capacity = coerceAtLeast_0(mapCapacity(collectionSizeOrDefault(this_4, 10)), 16);
        // Inline function 'kotlin.collections.associateByTo' call

        var destination = LinkedHashMap_init_$Create$_0(capacity);
        var _iterator__ex2g4s_3 = this_4.iterator_jk1svi_k$();
        while (_iterator__ex2g4s_3.hasNext_bitz1p_k$()) {
          var element_3 = _iterator__ex2g4s_3.next_20eer_k$();
          var tmp$ret$19 = element_3.group_1;
          destination.put_4fpzoq_k$(tmp$ret$19, element_3);
        }

        var ws = destination;
        // Inline function 'kotlin.collections.filter' call

        // Inline function 'kotlin.collections.filterTo' call

        var destination_0 = LinkedHashMap_init_$Create$();
        // Inline function 'kotlin.collections.iterator' call

        var _iterator__ex2g4s_4 = values.get_entries_p20ztl_k$().iterator_jk1svi_k$();
        while (_iterator__ex2g4s_4.hasNext_bitz1p_k$()) {
          var element_4 = _iterator__ex2g4s_4.next_20eer_k$();
          // Inline function 'kotlin.collections.component1' call
          var g = element_4.get_key_18j28a_k$();
          // Inline function 'kotlin.collections.component2' call
          var v_0 = element_4.get_value_j01efc_k$();
          var tmp0_safe_receiver = ws.get_wei43m_k$(g);
          var tmp_3;
          if (tmp0_safe_receiver == null) {
            tmp_3 = null;
          } else {
            // Inline function 'kotlin.let' call
            var tmp_4;
            if (pm.persistent_it5osl_k$(tmp0_safe_receiver)) {
              // Inline function 'kotlin.math.abs' call
              var x_0 = pm.initial_8bu8p4_k$(tmp0_safe_receiver) - v_0;
              tmp_4 = Math.abs(x_0) > 0.001;
            } else {
              tmp_4 = false;
            }
            tmp_3 = tmp_4;
          }
          if (tmp_3 === true) {
            destination_0.put_4fpzoq_k$(element_4.get_key_18j28a_k$(), element_4.get_value_j01efc_k$());
          }
        }

        var touched = destination_0;
        tmp_1 = qwelCore$output(p, pm.apply$default_voeuy2_k$(p.nodes_1, touched, p.tone_1));
        break;
      case 'echo':
        var tmp17 = p.nodes_1;
        var tmp$ret$32;
        $l$block_0: {
          // Inline function 'kotlin.collections.first' call
          var _iterator__ex2g4s_5 = tmp17.iterator_jk1svi_k$();
          while (_iterator__ex2g4s_5.hasNext_bitz1p_k$()) {
            var element_5 = _iterator__ex2g4s_5.next_20eer_k$();
            if (element_5.id_1 === request.getString_gb1pt9_k$('id')) {
              tmp$ret$32 = element_5;
              break $l$block_0;
            }
          }
          throw NoSuchElementException_init_$Create$_0('Collection contains no element matching the predicate.');
        }

        var source = tmp$ret$32;
        var params = new EchoParams(request.optInt_piuztm_k$('count', 4), request.optDouble_pwajio_k$('scale', 5.0), request.optDouble_pwajio_k$('rotation', 3.0), request.optDouble_pwajio_k$('fade', 0.85), request.optBoolean_n0bbhc_k$('contour', true), request.optDouble$default_xipa5i_k$('spread'), request.optDouble_pwajio_k$('jitter', 0.2), request.optInt_piuztm_k$('seed', 7));
        tmp_1 = qwelCore$output(p, Echo_instance.copies_ne07ek_k$(source, params));
        break;
      case 'compose':
        tmp_1 = (new JSONObject()).put_9oxj04_k$('code', ComposeCode_getInstance().generate$default_i4fm48_k$(p)).toString();
        break;
      case 'tone':
        tmp_1 = qwelCore$output(p, withTone(p.nodes_1, Companion_getInstance_11().fromSeed_gjco7c_k$(request.optInt$default_5j5ewg_k$('seed'), request.optBoolean$default_dxma8m_k$('dark'))));
        break;
      default:
        throw IllegalArgumentException_init_$Create$_0('Unknown operation');
    }
    return tmp_1;
  }
  function qwelCore$output(p, nodes) {
    return ProjectStore_instance.encode_mh4nqw_k$(p.copy$default_4q9ge3_k$(VOID, VOID, VOID, VOID, VOID, nodes)).toString();
  }
  function qwelCore$widgetObject(pm, w) {
    // Inline function 'kotlin.also' call
    var this_0 = (new JSONObject()).put_9oxj04_k$('group', w.group_1).put_9oxj04_k$('kind', w.kind_1).put_9oxj04_k$('value', pm.initial_8bu8p4_k$(w)).put_9oxj04_k$('persistent', pm.persistent_it5osl_k$(w));
    var tmp0_safe_receiver = w.get_bounds_bj99ku_k$();
    if (tmp0_safe_receiver == null)
      null;
    else {
      // Inline function 'kotlin.let' call
      this_0.put_9oxj04_k$('x', tmp0_safe_receiver.l_1).put_9oxj04_k$('y', tmp0_safe_receiver.t_1).put_9oxj04_k$('w', tmp0_safe_receiver.get_w_1mhr66_k$()).put_9oxj04_k$('h', tmp0_safe_receiver.get_h_1mhr5r_k$());
    }
    return this_0;
  }
  function Math_0() {
  }
  protoOf(Math_0).toRadians_sjqwz3_k$ = function (x) {
    return x * 3.141592653589793 / 180;
  };
  protoOf(Math_0).toDegrees_negxly_k$ = function (x) {
    return x * 180 / 3.141592653589793;
  };
  var Math_instance;
  function Math_getInstance() {
    return Math_instance;
  }
  function freshId() {
    var tmp = 'xxxxxxxxxx'.replace(/x/g, function () {
      return (Math.random() * 16 | 0).toString(16);
    });
    return (!(tmp == null) ? typeof tmp === 'string' : false) ? tmp : THROW_CCE();
  }
  function formatNumber(pattern, values) {
    var i = {_v: 0};
    var tmp = Regex_init_$Create$('%([0-9]*)(?:\\.([0-9]+))?([fXd])');
    return tmp.replace_dbivij_k$(pattern, formatNumber$lambda(values, i));
  }
  function Random(seed) {
    var tmp = this;
    var tmp_0 = seed.xor_eoldvb_k$(new Long(-554899859, 5));
    // Inline function 'kotlin.Long.minus' call
    var tmp$ret$0 = (new Long(0, 65536)).minus_eruey4_k$(toLong(1));
    tmp.value_1 = tmp_0.and_5hkqyb_k$(tmp$ret$0);
  }
  protoOf(Random).nextFloat_jqti5l_k$ = function () {
    var tmp = this;
    var tmp_0 = this.value_1.times_99rz9a_k$(new Long(-554899859, 5)).plus_gdf42y_k$(new Long(11, 0));
    // Inline function 'kotlin.Long.minus' call
    var tmp$ret$0 = (new Long(0, 65536)).minus_eruey4_k$(toLong(1));
    tmp.value_1 = tmp_0.and_5hkqyb_k$(tmp$ret$0);
    return this.value_1.ushr_z7nmq8_k$(24).toInt_1tsl84_k$() / 1.6777216E7;
  };
  function putIfAbsent(_this__u8e3s4, k, v) {
    var old = _this__u8e3s4.get_wei43m_k$(k);
    if (!_this__u8e3s4.containsKey_aw81wo_k$(k)) {
      // Inline function 'kotlin.collections.set' call
      _this__u8e3s4.put_4fpzoq_k$(k, v);
    }
    return old;
  }
  function toSortedMap(_this__u8e3s4) {
    // Inline function 'kotlin.collections.sortedBy' call
    var this_0 = _this__u8e3s4.get_entries_p20ztl_k$();
    // Inline function 'kotlin.comparisons.compareBy' call
    var tmp = toSortedMap$lambda;
    var tmp$ret$0 = new sam$kotlin_Comparator$0_0(tmp);
    // Inline function 'kotlin.collections.associate' call
    var this_1 = sortedWith(this_0, tmp$ret$0);
    var capacity = coerceAtLeast_0(mapCapacity(collectionSizeOrDefault(this_1, 10)), 16);
    // Inline function 'kotlin.collections.associateTo' call
    var destination = LinkedHashMap_init_$Create$_0(capacity);
    var _iterator__ex2g4s = this_1.iterator_jk1svi_k$();
    while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
      var element = _iterator__ex2g4s.next_20eer_k$();
      // Inline function 'kotlin.collections.plusAssign' call
      var pair = to(element.get_key_18j28a_k$(), element.get_value_j01efc_k$());
      destination.put_4fpzoq_k$(pair.first_1, pair.second_1);
    }
    return destination;
  }
  function sortedSetOf() {
    // Inline function 'kotlin.collections.linkedSetOf' call
    return LinkedHashSet_init_$Create$();
  }
  function sam$kotlin_Comparator$0_0(function_0) {
    this.function_1 = function_0;
  }
  protoOf(sam$kotlin_Comparator$0_0).compare_bczr_k$ = function (a, b) {
    return this.function_1(a, b);
  };
  protoOf(sam$kotlin_Comparator$0_0).compare = function (a, b) {
    return this.compare_bczr_k$(a, b);
  };
  protoOf(sam$kotlin_Comparator$0_0).getFunctionDelegate_jtodtf_k$ = function () {
    return this.function_1;
  };
  protoOf(sam$kotlin_Comparator$0_0).equals = function (other) {
    var tmp;
    if (!(other == null) ? isInterface(other, Comparator) : false) {
      var tmp_0;
      if (!(other == null) ? isInterface(other, FunctionAdapter) : false) {
        tmp_0 = equals(this.getFunctionDelegate_jtodtf_k$(), other.getFunctionDelegate_jtodtf_k$());
      } else {
        tmp_0 = false;
      }
      tmp = tmp_0;
    } else {
      tmp = false;
    }
    return tmp;
  };
  protoOf(sam$kotlin_Comparator$0_0).hashCode = function () {
    return hashCode(this.getFunctionDelegate_jtodtf_k$());
  };
  function formatNumber$lambda($values, $i) {
    return function (m) {
      var _unary__edvuaz = $i._v;
      $i._v = _unary__edvuaz + 1 | 0;
      var v = $values[_unary__edvuaz];
      var tmp;
      switch (m.get_groupValues_rkv314_k$().get_c1px32_k$(3)) {
        case 'X':
          // Inline function 'kotlin.toUInt' call

          var this_0 = numberToInt(isNumber(v) ? v : THROW_CCE());
          var tmp$ret$0 = _UInt___init__impl__l7qpdl(this_0);
          // Inline function 'kotlin.text.uppercase' call

          // Inline function 'kotlin.js.asDynamic' call

          var tmp_0 = toString_5(tmp$ret$0, 16).toUpperCase();
          var tmp1_elvis_lhs = toIntOrNull(m.get_groupValues_rkv314_k$().get_c1px32_k$(1));
          tmp = padStart(tmp_0, tmp1_elvis_lhs == null ? 0 : tmp1_elvis_lhs, _Char___init__impl__6a9atx(48));
          break;
        case 'd':
          tmp = toString_1(v);
          break;
        default:
          var d = numberToDouble(isNumber(v) ? v : THROW_CCE());
          // Inline function 'kotlin.js.asDynamic' call

          var tmp2_elvis_lhs = toIntOrNull(m.get_groupValues_rkv314_k$().get_c1px32_k$(2));
          var tmp_1 = d.toFixed(tmp2_elvis_lhs == null ? 6 : tmp2_elvis_lhs);
          tmp = (!(tmp_1 == null) ? typeof tmp_1 === 'string' : false) ? tmp_1 : THROW_CCE();
          break;
      }
      return tmp;
    };
  }
  function toSortedMap$lambda(a, b) {
    // Inline function 'kotlin.comparisons.compareValuesBy' call
    var tmp = a.get_key_18j28a_k$();
    var tmp$ret$1 = b.get_key_18j28a_k$();
    return compareValues(tmp, tmp$ret$1);
  }
  function set_words(_set____db54di) {
    words = _set____db54di;
  }
  var words;
  function tr(key, args) {
    var value = words != null && words[key] != null ? toString_1(words[key]) : key;
    // Inline function 'kotlin.collections.forEachIndexed' call
    var index = 0;
    var inductionVariable = 0;
    var last = args.length;
    while (inductionVariable < last) {
      var item = args[inductionVariable];
      inductionVariable = inductionVariable + 1 | 0;
      var _unary__edvuaz = index;
      index = _unary__edvuaz + 1 | 0;
      value = replace(value, '{' + _unary__edvuaz + '}', toString_1(item));
    }
    return value;
  }
  function JSONObject_init_$Init$(s, $this) {
    JSONObject.call($this, JSON.parse(s), true);
    return $this;
  }
  function JSONObject_init_$Create$(s) {
    return JSONObject_init_$Init$(s, objectCreate(protoOf(JSONObject)));
  }
  function JSONObject(obj, marker) {
    obj = obj === VOID ? {} : obj;
    marker = marker === VOID ? true : marker;
    this.obj_1 = obj;
    this.marker_1 = marker;
  }
  protoOf(JSONObject).put_9oxj04_k$ = function (k, v) {
    var tmp;
    if (v instanceof JSONObject) {
      tmp = v.obj_1;
    } else {
      if (v instanceof JSONArray) {
        tmp = v.obj_1;
      } else {
        if (v instanceof Long) {
          tmp = v.toDouble_ygsx0s_k$();
        } else {
          tmp = v;
        }
      }
    }
    this.obj_1[k] = tmp;
    return this;
  };
  protoOf(JSONObject).getString_gb1pt9_k$ = function (k) {
    // Inline function 'kotlin.require' call
    // Inline function 'kotlin.require' call
    if (!(this.obj_1[k] != null)) {
      var message = 'Failed requirement.';
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    return toString_1(this.obj_1[k]);
  };
  protoOf(JSONObject).optString_gse350_k$ = function (k, fallback) {
    return this.obj_1[k] == null ? fallback : toString_1(this.obj_1[k]);
  };
  protoOf(JSONObject).optString$default_a8gqg6_k$ = function (k, fallback, $super) {
    fallback = fallback === VOID ? '' : fallback;
    return $super === VOID ? this.optString_gse350_k$(k, fallback) : $super.optString_gse350_k$.call(this, k, fallback);
  };
  protoOf(JSONObject).getDouble_v37ict_k$ = function (k) {
    // Inline function 'kotlin.require' call
    // Inline function 'kotlin.require' call
    if (!(this.obj_1[k] != null)) {
      var message = 'Failed requirement.';
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    var tmp = this.obj_1[k];
    return numberToDouble(isNumber(tmp) ? tmp : THROW_CCE());
  };
  protoOf(JSONObject).optDouble_pwajio_k$ = function (k, fallback) {
    var tmp;
    if (this.obj_1[k] == null) {
      tmp = fallback;
    } else {
      var tmp_0 = this.obj_1[k];
      tmp = numberToDouble(isNumber(tmp_0) ? tmp_0 : THROW_CCE());
    }
    return tmp;
  };
  protoOf(JSONObject).optDouble$default_xipa5i_k$ = function (k, fallback, $super) {
    fallback = fallback === VOID ? 0.0 : fallback;
    return $super === VOID ? this.optDouble_pwajio_k$(k, fallback) : $super.optDouble_pwajio_k$.call(this, k, fallback);
  };
  protoOf(JSONObject).getInt_npc9pd_k$ = function (k) {
    return numberToInt(this.getDouble_v37ict_k$(k));
  };
  protoOf(JSONObject).optInt_piuztm_k$ = function (k, fallback) {
    return numberToInt(this.optDouble_pwajio_k$(k, fallback));
  };
  protoOf(JSONObject).optInt$default_5j5ewg_k$ = function (k, fallback, $super) {
    fallback = fallback === VOID ? 0 : fallback;
    return $super === VOID ? this.optInt_piuztm_k$(k, fallback) : $super.optInt_piuztm_k$.call(this, k, fallback);
  };
  protoOf(JSONObject).optLong_jmrogp_k$ = function (k, fallback) {
    return numberToLong(this.optDouble_pwajio_k$(k, fallback.toDouble_ygsx0s_k$()));
  };
  protoOf(JSONObject).optLong$default_wkurpt_k$ = function (k, fallback, $super) {
    fallback = fallback === VOID ? new Long(0, 0) : fallback;
    return $super === VOID ? this.optLong_jmrogp_k$(k, fallback) : $super.optLong_jmrogp_k$.call(this, k, fallback);
  };
  protoOf(JSONObject).optBoolean_n0bbhc_k$ = function (k, fallback) {
    var tmp;
    if (this.obj_1[k] == null) {
      tmp = fallback;
    } else {
      var tmp_0 = this.obj_1[k];
      tmp = (!(tmp_0 == null) ? typeof tmp_0 === 'boolean' : false) ? tmp_0 : THROW_CCE();
    }
    return tmp;
  };
  protoOf(JSONObject).optBoolean$default_dxma8m_k$ = function (k, fallback, $super) {
    fallback = fallback === VOID ? false : fallback;
    return $super === VOID ? this.optBoolean_n0bbhc_k$(k, fallback) : $super.optBoolean_n0bbhc_k$.call(this, k, fallback);
  };
  protoOf(JSONObject).getJSONArray_be86jl_k$ = function (k) {
    // Inline function 'kotlin.require' call
    // Inline function 'kotlin.require' call
    if (!(this.obj_1[k] != null)) {
      var message = 'Failed requirement.';
      throw IllegalArgumentException_init_$Create$_0(toString_1(message));
    }
    return new JSONArray(this.obj_1[k]);
  };
  protoOf(JSONObject).optJSONArray_9s960s_k$ = function (k) {
    return this.obj_1[k] == null ? null : new JSONArray(this.obj_1[k]);
  };
  protoOf(JSONObject).optJSONObject_yq7aww_k$ = function (k) {
    return this.obj_1[k] == null ? null : new JSONObject(this.obj_1[k], true);
  };
  protoOf(JSONObject).keys_1yhh0_k$ = function () {
    var tmp = Object.keys(this.obj_1);
    return toList((!(tmp == null) ? isArray(tmp) : false) ? tmp : THROW_CCE());
  };
  protoOf(JSONObject).toString = function () {
    return JSON.stringify(this.obj_1);
  };
  function JSONArray(obj) {
    obj = obj === VOID ? [] : obj;
    this.obj_1 = obj;
  }
  protoOf(JSONArray).put_58ltao_k$ = function (v) {
    var tmp;
    if (v instanceof JSONObject) {
      tmp = v.obj_1;
    } else {
      if (v instanceof JSONArray) {
        tmp = v.obj_1;
      } else {
        if (v instanceof Long) {
          tmp = v.toDouble_ygsx0s_k$();
        } else {
          tmp = v;
        }
      }
    }
    this.obj_1.push(tmp);
    return this;
  };
  protoOf(JSONArray).length_iap7oa_k$ = function () {
    var tmp = this.obj_1.length;
    return (!(tmp == null) ? typeof tmp === 'number' : false) ? tmp : THROW_CCE();
  };
  protoOf(JSONArray).getJSONObject_j6v1id_k$ = function (i) {
    return new JSONObject(this.obj_1[i], true);
  };
  protoOf(JSONArray).getInt_s8uc8x_k$ = function (i) {
    var tmp = this.obj_1[i];
    return numberToInt(isNumber(tmp) ? tmp : THROW_CCE());
  };
  protoOf(JSONArray).toString = function () {
    return JSON.stringify(this.obj_1);
  };
  function TapState(nodes, playTarget) {
    this.nodes_1 = nodes;
    this.playTarget_1 = playTarget;
  }
  protoOf(TapState).playSlide_4hpddh_k$ = function (group, v) {
    // Inline function 'kotlin.collections.set' call
    this.playTarget_1.put_4fpzoq_k$(group, v);
  };
  protoOf(TapState).playTap_eyfrwd_k$ = function (w, x, y) {
    var g = w.group_1;
    switch (w.kind_1) {
      case 'pick':
        var tmp1_safe_receiver = PlayMode_getInstance().pickHit_po30ei_k$(w, x, y);
        if (tmp1_safe_receiver == null)
          null;
        else {
          // Inline function 'kotlin.let' call
          // Inline function 'kotlin.collections.set' call
          this.playTarget_1.put_4fpzoq_k$(g, tmp1_safe_receiver);
        }

        break;
      case 'counter':
        var tmp2_elvis_lhs = w.get_bounds_bj99ku_k$();
        var tmp;
        if (tmp2_elvis_lhs == null) {
          return Unit_instance;
        } else {
          tmp = tmp2_elvis_lhs;
        }

        var b = tmp;
        var d = x < b.get_cx_knto1u_k$() - b.get_w_1mhr66_k$() * 0.2 ? -1 : x > b.get_cx_knto1u_k$() + b.get_w_1mhr66_k$() * 0.2 ? 1 : 0;
        if (!(d === 0)) {
          var tmp3_elvis_lhs = this.playTarget_1.get_wei43m_k$(g);
          this.playSlide_4hpddh_k$(g, coerceIn((tmp3_elvis_lhs == null ? 0.0 : tmp3_elvis_lhs) + d, 0.0, 99.0));
        }

        break;
      case 'press':
        // Inline function 'kotlin.collections.set' call

        this.playTarget_1.put_4fpzoq_k$(g, 1.0);
        break;
      case 'radio':
        var tmp4_elvis_lhs = this.playTarget_1.get_wei43m_k$(g);
        if ((tmp4_elvis_lhs == null ? 0.0 : tmp4_elvis_lhs) > 0.5)
          return Unit_instance;
        // Inline function 'kotlin.collections.set' call

        this.playTarget_1.put_4fpzoq_k$(g, 1.0);
        var tmp5_elvis_lhs = w.get_bounds_bj99ku_k$();
        var tmp_0;
        if (tmp5_elvis_lhs == null) {
          return Unit_instance;
        } else {
          tmp_0 = tmp5_elvis_lhs;
        }

        var mine = tmp_0;
        var _iterator__ex2g4s = PlayMode_getInstance().widgets_hajxma_k$(this.nodes_1).iterator_jk1svi_k$();
        $l$loop_0: while (_iterator__ex2g4s.hasNext_bitz1p_k$()) {
          var o = _iterator__ex2g4s.next_20eer_k$();
          if (!(o.kind_1 === 'radio') || o.group_1 === g)
            continue $l$loop_0;
          var tmp6_elvis_lhs = o.get_bounds_bj99ku_k$();
          var tmp_1;
          if (tmp6_elvis_lhs == null) {
            continue $l$loop_0;
          } else {
            tmp_1 = tmp6_elvis_lhs;
          }
          var ob = tmp_1;
          var tmp_2;
          // Inline function 'kotlin.math.abs' call
          var x_0 = ob.get_cy_knto1t_k$() - mine.get_cy_knto1t_k$();
          if (Math.abs(x_0) < 12.0) {
            // Inline function 'kotlin.math.abs' call
            var x_1 = ob.get_cx_knto1u_k$() - mine.get_cx_knto1u_k$();
            tmp_2 = Math.abs(x_1) < 240.0;
          } else {
            tmp_2 = false;
          }
          var sameRow = tmp_2;
          var tmp_3;
          // Inline function 'kotlin.math.abs' call
          var x_2 = ob.get_cx_knto1u_k$() - mine.get_cx_knto1u_k$();
          if (Math.abs(x_2) < 12.0) {
            // Inline function 'kotlin.math.abs' call
            var x_3 = ob.get_cy_knto1t_k$() - mine.get_cy_knto1t_k$();
            tmp_3 = Math.abs(x_3) < 240.0;
          } else {
            tmp_3 = false;
          }
          var sameCol = tmp_3;
          if (sameRow || sameCol) {
            var tmp12 = this.playTarget_1;
            // Inline function 'kotlin.collections.set' call
            var key = o.group_1;
            tmp12.put_4fpzoq_k$(key, 0.0);
          }
        }

        break;
      default:
        this.playToggle_mjhate_k$(g);
        break;
    }
  };
  protoOf(TapState).playToggle_mjhate_k$ = function (group) {
    var tmp0 = this.playTarget_1;
    var tmp;
    var tmp0_elvis_lhs = this.playTarget_1.get_wei43m_k$(group);
    if ((tmp0_elvis_lhs == null ? 0.0 : tmp0_elvis_lhs) > 0.5) {
      tmp = 0.0;
    } else {
      tmp = 1.0;
    }
    // Inline function 'kotlin.collections.set' call
    var value = tmp;
    tmp0.put_4fpzoq_k$(group, value);
  };
  //region block: post-declaration
  protoOf(InternalHashMap).containsAllEntries_m9iqdx_k$ = containsAllEntries;
  //endregion
  //region block: init
  Companion_instance = new Companion();
  Unit_instance = new Unit();
  _stableSortingIsSupported = null;
  Companion_instance_2 = new Companion_2();
  Companion_instance_4 = new Companion_4();
  Companion_instance_5 = new Companion_5();
  Companion_instance_6 = new Companion_6();
  EmptyIterator_instance = new EmptyIterator();
  EmptySequence_instance = new EmptySequence();
  NaturalOrderComparator_instance = new NaturalOrderComparator();
  Companion_instance_8 = new Companion_8();
  UNINITIALIZED_VALUE_instance = new UNINITIALIZED_VALUE();
  Companion_instance_9 = new Companion_9();
  Companion_instance_10 = new Companion_10();
  Echo_instance = new Echo();
  IconNodes_instance = new IconNodes();
  ProjectStore_instance = new ProjectStore();
  ToneGen_instance = new ToneGen();
  SvgImport_instance = new SvgImport();
  cached = null;
  Math_instance = new Math_0();
  words = null;
  //endregion
  //region block: exports
  function $jsExportAll$(_) {
    _.qwelCore = qwelCore;
  }
  $jsExportAll$(_);
  //endregion
  return _;
}(typeof qwelcore === 'undefined' ? {} : qwelcore);
