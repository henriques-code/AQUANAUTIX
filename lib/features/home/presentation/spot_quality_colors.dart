import 'package:flutter/material.dart';

import '../domain/entities/featured_spot.dart';
import '../../../core/theme/app_colors.dart';

Color qualityColor(SpotQuality q) => switch (q) {
      SpotQuality.excelente => AppColors.qualityExcelente,
      SpotQuality.muitoBom => AppColors.accent,
      SpotQuality.bom => AppColors.qualityBom,
      SpotQuality.razoavel => AppColors.qualityRazoavel,
      SpotQuality.mau => AppColors.qualityMau,
    };

String qualityLabel(SpotQuality q, bool es) => switch (q) {
      SpotQuality.excelente => es ? 'Excelente' : 'Excelente',
      SpotQuality.muitoBom => es ? 'Muy bueno' : 'Muito Bom',
      SpotQuality.bom => es ? 'Bueno' : 'Bom',
      SpotQuality.razoavel => es ? 'Regular' : 'Razoável',
      SpotQuality.mau => es ? 'Malo' : 'Mau',
    };
