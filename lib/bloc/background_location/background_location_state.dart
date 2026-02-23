sealed class BackgroundLocationState {
  const BackgroundLocationState();
}

class BackgroundLocationStopped extends BackgroundLocationState {
  const BackgroundLocationStopped();
}

class BackgroundLocationRunning extends BackgroundLocationState {
  const BackgroundLocationRunning();
}

class BackgroundLocationError extends BackgroundLocationState {
  final String message;
  const BackgroundLocationError(this.message);
}
