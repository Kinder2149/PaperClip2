import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'reward_service.dart';

class DailyRewardService {
  static final DailyRewardService _instance = DailyRewardService._internal();
  factory DailyRewardService() => _instance;
  DailyRewardService._internal();

  final NotificationService _notifications = NotificationService();
  final RewardService _rewardService = RewardService();
  static const String _lastRewardKey = 'last_daily_reward';
  static const String _streakKey = 'daily_reward_streak';

  int _currentStreak = 0;
  DateTime? _lastRewardDate;

  int get currentStreak => _currentStreak;
  DateTime? get lastRewardDate => _lastRewardDate;

  Future<void> initialize() async {
    await _loadDailyRewardState();
    _checkDailyReward();
  }

  Future<void> _loadDailyRewardState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastRewardDate = prefs.getString(_lastRewardKey) != null
          ? DateTime.parse(prefs.getString(_lastRewardKey)!)
          : null;
      _currentStreak = prefs.getInt(_streakKey) ?? 0;
    } catch (e) {
      debugPrint('Erreur lors du chargement de l\'état des récompenses quotidiennes: $e');
    }
  }

  Future<void> _saveDailyRewardState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastRewardDate != null) {
        await prefs.setString(_lastRewardKey, _lastRewardDate!.toIso8601String());
      }
      await prefs.setInt(_streakKey, _currentStreak);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de l\'état des récompenses quotidiennes: $e');
    }
  }

  void _checkDailyReward() {
    final now = DateTime.now();
    if (_lastRewardDate == null) {
      _lastRewardDate = now;
      _currentStreak = 0;
      _saveDailyRewardState();
      return;
    }

    final lastReward = DateTime(
      _lastRewardDate!.year,
      _lastRewardDate!.month,
      _lastRewardDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    if (today.isAfter(lastReward)) {
      if (today.difference(lastReward).inDays == 1) {
        // Récompense quotidienne disponible
        _currentStreak++;
      } else {
        // Streak perdu
        _currentStreak = 0;
      }
      _lastRewardDate = now;
      _saveDailyRewardState();
    }
  }

  bool get isDailyRewardAvailable {
    if (_lastRewardDate == null) return true;

    final now = DateTime.now();
    final lastReward = DateTime(
      _lastRewardDate!.year,
      _lastRewardDate!.month,
      _lastRewardDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    return today.isAfter(lastReward);
  }

  Future<void> claimDailyReward() async {
    if (!isDailyRewardAvailable) return;

    _checkDailyReward();
    _currentStreak++;
    _lastRewardDate = DateTime.now();
    await _saveDailyRewardState();

    // Calculer la récompense en fonction du streak
    final reward = _calculateDailyReward();
    await _rewardService.addReward(reward);

    // Programmer la notification pour le lendemain
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final notificationTime = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      9, // 9h du matin
    );

    await _notifications.scheduleNotification(
      id: 1,
      title: 'Récompense quotidienne disponible !',
      body: 'Venez réclamer votre récompense quotidienne et maintenez votre streak de $_currentStreak jours !',
      scheduledTime: notificationTime,
    );
  }

  Reward _calculateDailyReward() {
    // Augmenter la récompense en fonction du streak
    final baseAmount = 100.0;
    final streakMultiplier = 1.0 + (_currentStreak * 0.1);
    final amount = baseAmount * streakMultiplier;

    return Reward(
      id: 'daily_reward_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Récompense Quotidienne',
      description: 'Récompense pour votre streak de $_currentStreak jours',
      type: RewardType.MONEY,
      amount: amount,
      expiryDate: DateTime.now().add(const Duration(days: 1)),
    );
  }

  String get nextRewardTime {
    if (_lastRewardDate == null) return 'Maintenant';

    final now = DateTime.now();
    final lastReward = DateTime(
      _lastRewardDate!.year,
      _lastRewardDate!.month,
      _lastRewardDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    if (today.isAfter(lastReward)) return 'Maintenant';

    final tomorrow = lastReward.add(const Duration(days: 1));
    final timeUntilReward = tomorrow.difference(now);
    final hours = timeUntilReward.inHours;
    final minutes = timeUntilReward.inMinutes % 60;

    return '$hoursh ${minutes}m';
  }
} 