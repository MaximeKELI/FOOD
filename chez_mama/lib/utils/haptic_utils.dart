import 'package:flutter/services.dart';

/// Light haptic feedback for cart / favorite actions.
void hapticLight() => HapticFeedback.lightImpact();

void hapticMedium() => HapticFeedback.mediumImpact();

void hapticSuccess() => HapticFeedback.mediumImpact();
