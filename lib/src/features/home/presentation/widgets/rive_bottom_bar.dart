import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:odyssey/src/features/home/domain/rive_tab_item.dart';

class RiveBottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const RiveBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<RiveBottomBar> createState() => _RiveBottomBarState();
}

class _RiveBottomBarState extends State<RiveBottomBar> {
  late List<RiveTabItem> _icons;

  @override
  void initState() {
    super.initState();
    _icons = RiveTabItem.tabItems;
  }

  void _onRiveIconInit(Artboard artboard, int index) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      _icons[index].stateMachine,
    );
    artboard.addController(controller!);

    _icons[index].status = controller.findInput<bool>("active") as SMIBool;

    // Set initial state based on current index
    if (widget.currentIndex == index && _icons[index].status != null) {
      _icons[index].status!.value = true;
    }
  }

  void onTabPress(int index) {
    if (widget.currentIndex != index) {
      widget.onTap(index);

      // Trigger animation
      if (_icons[index].status != null) {
        _icons[index].status!.value = true;
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _icons[index].status != null) {
            _icons[index].status!.value = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Background color based on theme
    // Background color based on theme
    final bgColor = theme.colorScheme.surface.withOpacity(0.8);

    final shadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : const Color(0xFF17203A).withOpacity(0.1);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_icons.length, (index) {
            final icon = _icons[index];
            final isSelected = widget.currentIndex == index;

            return Expanded(
              key: icon.id,
              child: GestureDetector(
                onTap: () => onTabPress(index),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 2),
                      height: 4,
                      width: isSelected ? 20 : 0,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      width: 36,
                      child: Opacity(
                        opacity: isSelected ? 1 : 0.5,
                        child: RiveAnimation.asset(
                          'assets/rive/icons.riv',
                          stateMachines: [icon.stateMachine],
                          artboard: icon.artboard,
                          onInit: (artboard) {
                            _onRiveIconInit(artboard, index);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
