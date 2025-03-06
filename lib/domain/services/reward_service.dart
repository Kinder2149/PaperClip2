import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'event_service.dart';

enum RewardType {
  MONEY,
  PAPERCLIPS,
  METAL,
  MULTIPLIER,
  SPECIAL_ITEM,
}

class Reward {
  final String id;
  final String title;
  final String description;
  final RewardType type;
  final double amount;
  final DateTime? expiryDate;
  final bool isClaimed;
  final bool isExpired;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.amount,
    this.expiryDate,
    this.isClaimed = false,
    this.isExpired = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.toString(),
        'amount': amount,
        'expiryDate': expiryDate?.toIso8601String(),
        'isClaimed': isClaimed,
        'isExpired': isExpired,
      };

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        type: RewardType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => RewardType.MONEY,
        ),
        amount: json['amount'].toDouble(),
        expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
        isClaimed: json['isClaimed'] ?? false,
        isExpired: json['isExpired'] ?? false,
      );
}

class RewardService {
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  final NotificationService _notifications = NotificationService();
  final EventService _eventService = EventService();
  final List<Reward> _availableRewards = [];
  Timer? _rewardCheckTimer;
  static const String _rewardsKey = 'game_rewards';

  List<Reward> get availableRewards => _availableRewards;

  Future<void> initialize() async {
    await _loadRewards();
    _startRewardCheckTimer();
  }

  void _startRewardCheckTimer() {
    _rewardCheckTimer?.cancel();
    _rewardCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkRewards();
    });
  }

  Future<void> _loadRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rewardsJson = prefs.getStringList(_rewardsKey) ?? [];
      _availableRewards.clear();
      _availableRewards.addAll(
        rewardsJson
            .map((json) => Reward.fromJson(json as Map<String, dynamic>))
            .where((reward) => !reward.isExpired),
      );
    } catch (e) {
      debugPrint('Erreur lors du chargement des récompenses: $e');
    }
  }

  Future<void> _saveRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _rewardsKey,
        _availableRewards.map((reward) => reward.toJson().toString()).toList(),
      );
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des récompenses: $e');
    }
  }

  Future<void> _checkRewards() async {
    final now = DateTime.now();
    for (var reward in _availableRewards) {
      if (reward.expiryDate != null && reward.expiryDate!.isBefore(now)) {
        await _expireReward(reward);
      }
    }
  }

  Future<void> addReward(Reward reward) async {
    _availableRewards.add(reward);
    await _saveRewards();
    await _notifyReward(reward);
  }

  Future<void> claimReward(String rewardId) async {
    final reward = _availableRewards.firstWhere(
      (r) => r.id == rewardId,
      orElse: () => throw Exception('Récompense non trouvée'),
    );
    await _claimReward(reward);
  }

  Future<void> _claimReward(Reward reward) async {
    final index = _availableRewards.indexWhere((r) => r.id == reward.id);
    if (index != -1) {
      _availableRewards[index] = Reward(
        id: reward.id,
        title: reward.title,
        description: reward.description,
        type: reward.type,
        amount: reward.amount,
        expiryDate: reward.expiryDate,
        isClaimed: true,
        isExpired: reward.isExpired,
      );
      await _saveRewards();
    }
  }

  Future<void> _expireReward(Reward reward) async {
    final index = _availableRewards.indexWhere((r) => r.id == reward.id);
    if (index != -1) {
      _availableRewards[index] = Reward(
        id: reward.id,
        title: reward.title,
        description: reward.description,
        type: reward.type,
        amount: reward.amount,
        expiryDate: reward.expiryDate,
        isClaimed: reward.isClaimed,
        isExpired: true,
      );
      await _saveRewards();
    }
  }

  Future<void> _notifyReward(Reward reward) async {
    await _notifications.showNotification(
      title: 'Nouvelle Récompense',
      body: '${reward.title}: ${reward.description}',
      payload: reward.id,
    );
  }

  void dispose() {
    _rewardCheckTimer?.cancel();
  }
} 