import 'package:flutter/material.dart';

import '../../core/brain_state.dart';

class MascotView extends StatefulWidget {
  const MascotView({
    super.key,
    required this.state,
    required this.size,
    this.reducedMotion = false,
    this.outfit,
    this.forceAsset,
  });

  final BrainState state;
  final double size;
  final bool reducedMotion;

  /// Reward image worn while healthy.
  final String? outfit;

  /// Image shown whatever the mood (sleeping cat on the block screen).
  final String? forceAsset;

  static const happy = 'assets/images/happy.png';
  static const sleeping = 'assets/images/sleeping.png';
  static const bedtime = 'assets/images/bedtime.png';

  /// 11 pm to 6 am.
  static bool get isBedtime {
    final h = DateTime.now().hour;
    return h >= 23 || h < 6;
  }

  static String asset(BrainState s) => switch (s) {
    BrainState.healthy => 'assets/images/healthy.png',
    BrainState.tired => 'assets/images/tired.png',
    BrainState.cracking => 'assets/images/cracking.png',
    BrainState.fried => 'assets/images/fried.png',
  };

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reducedMotion) _breath.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final s in BrainState.values) {
      precacheImage(_provider(s), context);
    }
  }

  @override
  void didUpdateWidget(MascotView old) {
    super.didUpdateWidget(old);
    if (widget.reducedMotion == old.reducedMotion) return;
    if (widget.reducedMotion) {
      _breath
        ..stop()
        ..value = 0;
    } else {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  ImageProvider _provider(BrainState s) => _image(MascotView.asset(s));

  ImageProvider _image(String asset) {
    final px = (widget.size * MediaQuery.devicePixelRatioOf(context)).round();
    return ResizeImage(AssetImage(asset), width: px, allowUpscaling: false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final asset =
        widget.forceAsset ?? (s == BrainState.healthy && widget.outfit != null ? widget.outfit! : MascotView.asset(s));
    return Semantics(
      label: 'Mascot: ${s.label}. ${s.description}.',
      image: true,
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOut)),
        child: AnimatedSwitcher(
          duration: widget.reducedMotion ? Duration.zero : const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(anim), child: child),
          ),
          child: Image(
            key: ValueKey(asset),
            image: _image(asset),
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
