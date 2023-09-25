enum LoadState { loading, buffering, success, failure }

enum Direction { up, down, left, right }

class LoadStateEvent {
  final LoadState? loadState;
  final Function? retry;

  LoadStateEvent([this.loadState, this.retry]);
}

class VerticalDragInfo {
  bool cancel = false;

  Direction? direction;

  void update(double primaryDelta) {
    Direction tmpDirection;

    if (primaryDelta > 0) {
      tmpDirection = Direction.down;
    } else {
      tmpDirection = Direction.up;
    }

    if (direction != null && tmpDirection != direction) {
      cancel = true;
    }

    direction = tmpDirection;
  }
}
