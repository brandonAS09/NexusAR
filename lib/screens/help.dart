import 'package:flutter/material.dart';
import 'package:nexus_ar/core/app_colors.dart';
import 'package:nexus_ar/components/custom_app_bar.dart';
import 'package:nexus_ar/components/bottom_nav_bar.dart';

class HelpScreen extends StatelessWidget {
  final int selectedIndex;

  const HelpScreen({super.key, required this.selectedIndex});

  void _onItemTapped(BuildContext context, int index) {
    Navigator.pop(context, index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: CustomAppBar(
          backButton: true,
          onHelpPressed: null,
        ),
      ),
      
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 50.0,
            right: 50.0,
          ),
          child: const Text(
            'CONSEJOS Y AYUDA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
      ),
      
      bottomNavigationBar: SizedBox(
        height: 160.0,
        child: CustomBottomNavBar(
          selectedIndex: selectedIndex,
          onItemSelected: (index) => _onItemTapped(context, index),
        ),
      ),
    );
  }
}
