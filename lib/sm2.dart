import 'dart:collection';
import 'package:flutter/widgets.dart';

abstract class Logic {
  //#1
  Logic() {
    _Merge.initLogic(this);
  }

  static void _mLogicMustContain(Type type) {
    assert(
      _Merge.typeMLogic.containsKey(type),
      "$type constructor wasn't initialized.\n"
      "Initialize it in main() function of your app, before runApp",
    );
  }

  //#3
  /// pass [context] to mark that this widget can be rebuilt.
  /// don't pass anything if u just getting data from your logic Insatance.
  static T of<T extends Logic>([BuildContext? context]) {
    _mLogicMustContain(T);
    if (context != null) {
      _Merge.addTypeContextRel<T>(context as StatefulElement);
    }
    return _Merge.typeMLogic[T] as T;
  }

  //#4
  @protected
  void rebuild() {
    for (var context in _Merge.typeContextRel[runtimeType]!) {
      if (_Merge.getContextState(context).mounted) context.markNeedsBuild();
    }
  }
}

mixin _Merge {
  static final typeMLogic = HashMap<Type, Logic>();
  static final typeContextRel = HashMap<Type, HashSet<StatefulElement>>();

  static void initLogic(Logic l) {
    typeContextRel[l.runtimeType] = HashSet<StatefulElement>();
    typeMLogic[l.runtimeType] = l;
  }

  static void addTypeContextRel<T extends Logic>(StatefulElement context) {
    if (context.widget.runtimeType != MBuilder) {
      _MBuilderState? state = context.findAncestorStateOfType<_MBuilderState>();
      if (state == null) return;
    }

    if (!getContextState(context).hasAncestorWithLogicType<T>()) {
      typeContextRel[T]!.add(context);
      getContextState(context).supportedTypes.add(T);
    }
  }

  // ignore: library_private_types_in_public_api
  static _MBuilderState getContextState(StatefulElement context) {
    return context.state as _MBuilderState;
  }

  static void remove(BuildContext context) {
    for (var k in typeContextRel.keys) {
      typeContextRel[k]!.remove(context);
    }
  }
}

//#2
class MBuilder extends StatefulWidget {
  final WidgetBuilder builder;
  const MBuilder({required this.builder, Key? key}) : super(key: key);

  @override
  State<MBuilder> createState() => _MBuilderState();
}

class _MBuilderState extends State<MBuilder> {
  final supportedTypes = HashSet<Type>();
  bool hasAncestorWithLogicType<T extends Logic>() {
    var ancestor = context.findAncestorStateOfType<_MBuilderState>();
    while (ancestor != null) {
      if (ancestor.supportedTypes.contains(T)) return true;
      ancestor = ancestor.context.findAncestorStateOfType<_MBuilderState>();
    }
    return false;
  }

  @override
  void deactivate() {
    _Merge.remove(context);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
