part of charts_painter;

/// Default renderer for all chart items. Renderers use different painters to paint themselves.
///
/// This is a [LeafRenderObjectWidget] meaning it cannot have any children.
/// All customization for this list items can be done with [BarItemOptions] or [BubbleItemOptions]
class LeafChartItemRenderer<T> extends LeafRenderObjectWidget {
  LeafChartItemRenderer(this.item, this.state, this.itemOptions,
      {this.listIndex = 0, this.itemIndex = 0, required this.drawDataItem});

  final ChartItem<T?> item;
  final ChartState<T?> state;
  final ItemOptions itemOptions;
  final DrawDataItem drawDataItem;
  final int listIndex;
  final int itemIndex;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLeafChartItem(
      state,
      itemOptions,
      item,
      listIndex: listIndex,
      itemIndex: itemIndex,
      drawDataItem: drawDataItem,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderLeafChartItem<T?> renderObject) {
    renderObject
      ..state = state
      ..itemOptions = itemOptions
      ..listIndex = listIndex
      ..itemIndex = itemIndex
      ..drawDataItem = drawDataItem
      ..item = item;

    renderObject.markNeedsLayout();
  }
}

class _RenderLeafChartItem<T> extends RenderBox {
  _RenderLeafChartItem(
    this._state,
    this._itemOptions,
    this._item, {
    int? listIndex,
    required int itemIndex,
    required DrawDataItem drawDataItem,
  })  : _listIndex = listIndex ?? 0,
        _drawDataItem = drawDataItem,
        _itemIndex = itemIndex;

  int _listIndex;

  int _itemIndex;

  int get itemIndex => _itemIndex;

  set itemIndex(int key) {
    if (key != _itemIndex) {
      _itemIndex = key;
      markNeedsPaint();
    }
  }

  DrawDataItem _drawDataItem;

  DrawDataItem get drawDataItem => _drawDataItem;

  set drawDataItem(DrawDataItem drawDataItem) {
    if (drawDataItem != _drawDataItem) {
      _drawDataItem = drawDataItem;
      markNeedsPaint();
    }
  }

  int get listIndex => _listIndex;

  set listIndex(int key) {
    if (key != _listIndex) {
      _listIndex = key;
      markNeedsPaint();
    }
  }

  ChartItem<T> _item;

  set item(ChartItem<T> item) {
    if (item != _item) {
      _item = item;
      markNeedsPaint();
    }
  }

  ChartItem<T> get item => _item;

  ChartState _state;

  set state(ChartState state) {
    if (state != _state) {
      _state = state;
      markNeedsPaint();
    }
  }

  ItemOptions _itemOptions;

  set itemOptions(ItemOptions itemOptions) {
    if (itemOptions != _itemOptions) {
      _itemOptions = itemOptions;
      markNeedsPaint();
    }
  }

  double get _defaultSize => _itemOptions.minBarWidth ?? 0;

  @override
  double computeMinIntrinsicWidth(double height) => _defaultSize;

  @override
  double computeMaxIntrinsicWidth(double height) => _defaultSize;

  @override
  double computeMinIntrinsicHeight(double width) => _defaultSize;

  @override
  double computeMaxIntrinsicHeight(double width) => _defaultSize;

  @override
  bool get sizedByParent => false;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final _onClick = _state.behaviour.onItemClicked;

    // Leaf render objects should only be hit tested if they have a click handler, else return false.
    if (_onClick == null) {
      return false;
    }

    final _stack = 1 - _state.data.dataStrategy._stackMultipleValuesProgress;
    final _stackSize = max(1, _state.data.stackSize * _stack);

    final _multiPadding = _itemOptions.multiValuePadding.horizontal * _stackSize * _stack;
    final _stackWidth = (size.width - _multiPadding - _itemOptions.padding.horizontal) / _stackSize;

    final _translatedPosition = position.translate(
        _itemOptions.multiValuePadding.left * _stack +
            _itemOptions.padding.left +
            _stackWidth * listIndex * _stack +
            ((_itemOptions.multiValuePadding.horizontal * listIndex * _stack)),
        0.0);

    // Get exact items size for current configuration and check position.
    if (Size(_stackWidth, size.height).contains(_translatedPosition)) {
      // Add hit test entry and call onClick callback
      result.add(BoxHitTestEntry(this, position));
      _onClick(ItemBuilderData<T>(item, itemIndex, listIndex));
      return true;
    }

    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    final _stack = 1 - _state.data.dataStrategy._stackMultipleValuesProgress;
    final _stackSize = max(1, _state.data.stackSize * _stack);

    final _multiPadding = _itemOptions.multiValuePadding.horizontal * _stackSize * _stack;

    final _stackWidth = (size.width - _multiPadding - _itemOptions.padding.horizontal) / _stackSize;

    canvas.translate(
        _itemOptions.multiValuePadding.left * _stack +
            _itemOptions.padding.left +
            _stackWidth * listIndex * _stack +
            ((_itemOptions.multiValuePadding.horizontal * listIndex * _stack)),
        0.0);

    // Use item painter from ItemOptions to draw the item on the chart
    final _itemPainter = _itemOptions.geometryPainter(
      item,
      _state.data,
      _itemOptions,
      drawDataItem,
    );

    // Draw the item on selected position
    _itemPainter.draw(canvas, Size(_stackWidth, size.height), drawDataItem.getPaint(Size(_stackWidth, size.height)));

    canvas.restore();
  }
}
