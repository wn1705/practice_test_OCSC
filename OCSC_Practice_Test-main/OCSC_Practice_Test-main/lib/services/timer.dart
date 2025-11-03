import 'dart:async';

class TimerService {
  late bool isTimed;
  late Timer _timer;
  Duration _duration = Duration.zero;
  Duration _initialDuration = Duration(hours: 3); // 3 hours
  String timerDisplay = '00:00:00';

  TimerService({this.isTimed = true}) {
    if (isTimed) {
      _duration = _initialDuration;
    } else {
      _duration = Duration.zero;
    }
    timerDisplay = formatDuration(_duration);
  }
  String getFormattedDuration() {
    return formatDuration(_duration);
  }

  void startTimer(Function(String) updateTimerDisplay) {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isTimed) {
        // Timed mode: Countdown
        if (_duration.inSeconds > 0) {
          _duration = _duration - Duration(seconds: 1);
          updateTimerDisplay(formatDuration(_duration));
        } else {
          _timer.cancel();
        }
      } else {
        // Non-timed mode: Count up
        _duration = _duration + Duration(seconds: 1);
        updateTimerDisplay(formatDuration(_duration));
      }
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void stopTimer() {
    _timer.cancel();
  }
}
