import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const OnlineToggle({
    super.key,
    required this.isOnline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 180,
        height: 64,
        decoration: BoxDecoration(
          color: isOnline ? AppColors.primaryEmerald : AppColors.primaryNavy,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: (isOnline ? AppColors.primaryEmerald : Colors.black).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isOnline ? Colors.white.withValues(alpha: 0.2) : AppColors.primaryEmerald,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: isOnline ? 116 : 4,
              top: 4,
              child: Container(
                width: 56,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOnline ? Icons.power_settings_new_rounded : Icons.offline_bolt_rounded,
                  color: isOnline ? AppColors.primaryEmerald : AppColors.primaryNavy,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(left: isOnline ? 0 : 40, right: isOnline ? 40 : 0),
                child: Text(
                  isOnline ? 'ONLINE' : 'GO ONLINE',
                  style: TextStyle(
                    color: isOnline ? Colors.white : AppColors.primaryEmerald,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
