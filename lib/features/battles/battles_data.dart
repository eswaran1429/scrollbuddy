import 'package:get/get.dart';

class Friend {
  const Friend({
    required this.name,
    this.today = 0,
    this.yesterday = 0,
    this.trackingActive = true,
    this.pending = false,
  });

  final String name;
  final int today;
  final int yesterday;

  /// False when the friend's service is off or heartbeat is stale (D-14).
  final bool trackingActive;
  final bool pending;
}

/// Friends list. Empty until Scroll Battles has a backend (plan.md Phase 9).
class FriendsController extends GetxController {
  final friends = <Friend>[].obs;

  void addByCode(String code) => friends.add(Friend(name: 'Friend $code', pending: true));
}

/// Placeholder until accounts exist (Phase 9). The Battles tab is hidden.
const myFriendCode = 'SB7K2Q9X';
