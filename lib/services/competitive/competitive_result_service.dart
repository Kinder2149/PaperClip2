import 'package:paperclip2/services/ui/game_ui_port.dart';

class CompetitiveResultService {
  static CompetitiveResultData compute({
    required int paperclips,
    required double money,
    required int level,
    required Duration playTime,
  }) {
    final int timeSeconds = playTime.inSeconds;
    final double efficiency = timeSeconds > 0
        ? paperclips / timeSeconds
        : paperclips.toDouble();

    final double score =
        paperclips.toDouble() + money + level * 100 + efficiency * 50;

    return CompetitiveResultData(
      score: score.round(),
      paperclips: paperclips,
      money: money,
      playTime: playTime,
      level: level,
      efficiency: timeSeconds == 0 ? paperclips.toDouble() : efficiency,
    );
  }

  static void showResult({
    required GameNavigationPort? navigationPort,
    required CompetitiveResultData data,
  }) {
    navigationPort?.showCompetitiveResult(data);
  }
}
