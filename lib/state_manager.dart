import 'dart:collection';
import 'package:flutter/widgets.dart';

abstract class Logic {
  //#1
  Logic() {
    Merge.initLogic(this);
  }

  static void _mLogicMustContain(Type type) {
    assert(
      Merge._typeMLogic.containsKey(type),
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
      Merge.addTypeContextRel<T>(context);
    }
    return Merge.getLogicByGenericType<T>();
  }

  //#4
  @protected
  void rebuild() {
    for (var context in Merge.getContextsByType(runtimeType)) {
      //TODO: make it safer
      print("rebuild");
      (context as StatefulElement).markNeedsBuild();
    }
  }
}

mixin Merge {
  static final _typeMLogic = HashMap<Type, Logic>();
  static final typeContextRel = HashMap<Type, HashSet<BuildContext>>();
  

  static void initLogic(Logic l) {
    typeContextRel[l.runtimeType] = HashSet<BuildContext>();
    _typeMLogic[l.runtimeType] = l;
  }


  static void addTypeContextRel<T extends Logic>(BuildContext context) {
    if (context.widget.runtimeType != MBuilder) {
      _MBuilderState? state = context.findAncestorStateOfType<_MBuilderState>();
      if (state == null) return;
      context = state.context;
    }

    if (!getStateOfContext(context).hasAncestorWithLogicType<T>()) {
      typeContextRel[T]!.add(context);
      getStateOfContext(context).supportedTypes.add(T);
    }
  }

  static T getLogicByGenericType<T extends Logic>() => _typeMLogic[T] as T;

  // ignore: library_private_types_in_public_api
  static _MBuilderState getStateOfContext(BuildContext context) =>
      ((context as StatefulElement).state as _MBuilderState);

  static HashSet<BuildContext> getContextsByType(Type t) => typeContextRel[t]!;



  static void remove(BuildContext context) {
    for (var k in typeContextRel.keys) {
      typeContextRel[k]!.remove(context);
    }
    getParentByChlid.remove(context.widget);
  }
  


  static final getParentByChlid = HashMap<MBuilder, MBuilder?>();
  static final kids = HashSet<MBuilder>();

  static void addToFamily(MBuilder? widget) {
    for (var child in kids) {
      getParentByChlid[child] = widget;
    }
    kids.clear();
  }
}

//#2
class MBuilder extends StatefulWidget {
  final WidgetBuilder builder;
  final List<_MBuilderState?> __state = [null];

  // ignore: library_private_types_in_public_api
  _MBuilderState? get state => __state[0];
  set state(state) => __state[0] = state;

  MBuilder({required this.builder, Key? key}) : super(key: key) {
    Merge.kids.add(this);
  }

  @override
  State<MBuilder> createState() => _MBuilderState();
}

class _MBuilderState extends State<MBuilder> {
  final supportedTypes = HashSet<Type>();
  bool hasAncestorWithLogicType<T extends Logic>(){
    MBuilder? ancestor = Merge.getParentByChlid[widget];
    while (ancestor != null) {
      assert(ancestor.state!=null,"smth went wrong");
      if (ancestor.state!.supportedTypes.contains(T)) return true;
      ancestor = Merge.getParentByChlid[ancestor];
    }
    return false;
  }
  @override
  void initState() {
    super.initState();
    if(!Merge.getParentByChlid.containsKey(widget))
    {Merge.addToFamily(null);}
  }
  @override
  void deactivate() {
    Merge.remove(context);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    widget.state = this;
    final tmp = widget.builder(context);
    Merge.addToFamily(widget);
    return tmp;
  }
}