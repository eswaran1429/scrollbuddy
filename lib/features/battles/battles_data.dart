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

  final bool trackingActive;
  final bool pending;
}

class FriendsController extends GetxController {
  final friends = <Friend>[].obs;

  void addByCode(String code) => friends.add(Friend(name: 'Friend $code', pending: true));
}

const myFriendCode = 'SB7K2Q9X';
