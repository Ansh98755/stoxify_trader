import 'package:flutter/material.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/constants/text_style_constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning', style: TextStyleConstants.screenTitle),
              const SizedBox(height: 4),
              Text(
                'Live ideas from analysts you subscribe to',
                style: TextStyleConstants.caption,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Text(
                    'Home screen — build UI here',
                    style: TextStyleConstants.body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
