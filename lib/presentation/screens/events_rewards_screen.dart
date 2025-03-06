import 'package:flutter/material.dart';
import '../widgets/events/events_list.dart';
import '../widgets/rewards/rewards_list.dart';
import '../widgets/rewards/daily_reward_card.dart';

class EventsRewardsScreen extends StatelessWidget {
  const EventsRewardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Événements et Récompenses'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.event),
                text: 'Événements',
              ),
              Tab(
                icon: Icon(Icons.card_giftcard),
                text: 'Récompenses',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Événements en cours',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const EventsList(),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Récompenses disponibles',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const DailyRewardCard(),
                  const RewardsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 