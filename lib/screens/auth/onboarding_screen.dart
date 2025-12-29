import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Travel Light with Medpass',
      description: 'Your Medical Passport in your pocket.\nEasy, quick and secure access to all your medical records.',
    ),
    OnboardingPage(
      title: 'Secure & Private',
      description: 'Your health data is encrypted and protected.\nOnly you control who can access your information.',
    ),
    OnboardingPage(
      title: 'Always Accessible',
      description: 'Access your medical records anytime, anywhere.\nPerfect for emergencies and travel.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryLight,
                  AppColors.backgroundLight,
                ],
                stops: [0.0, 0.5],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Logo area - Big centered logo
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingXL),
                      child: Image.asset(
                        'assets/images/medpass_logo.png',
                        width: 280,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms, delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
                ),

                const SizedBox(height: AppSizes.paddingL),

                // Bottom card
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingL,
                      vertical: AppSizes.paddingM,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemCount: _pages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _pages[index].title,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSizes.paddingS),
                                    Flexible(
                                      flex: 2,
                                      child: Text(
                                        _pages[index].description,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? AppColors.textDark
                                      : AppColors.textSecondary.withAlpha((0.3 * 255).round()),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSizes.paddingM),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: AppStrings.login,
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                              ),
                            ),
                            const SizedBox(width: AppSizes.paddingM),
                            Expanded(
                              child: CustomButton(
                                text: AppStrings.signUp,
                                onPressed: () {
                                  Navigator.pushNamed(context, '/signup');
                                },
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 600.ms, delay: 500.ms).slideY(begin: 0.3),

                        const SizedBox(height: AppSizes.paddingS),
                      ],
                    ),
                  ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 400.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;

  OnboardingPage({
    required this.title,
    required this.description,
  });
}
