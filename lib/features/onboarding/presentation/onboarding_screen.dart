import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'widgets/onboarding_page.dart';
import 'package:whats_your_mood/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  late List<OnboardingPageData> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _onStartGame();
    }
  }

  void _onStartGame() {
    context.go('/lobby');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _pages = [
      OnboardingPageData(
        emoji: '🎲',
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
      ),
      OnboardingPageData(
        emoji: '📸',
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
      ),
      OnboardingPageData(
        emoji: '🎉',
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
      ),
    ];
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final pageData = _pages[index];
                    return OnboardingPage(
                      emoji: pageData.emoji,
                      title: pageData.title,
                      description: pageData.description,
                      pageIndex: index,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildPageIndicators(),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _onNextPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.accentOrange,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ).copyWith(
                      elevation: MaterialStateProperty.all(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastPage ? l10n.start : l10n.continueBtn,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (!isLastPage) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 32 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
            boxShadow: _currentPage == index
                ? [
                    BoxShadow(
                      color: AppColors.white.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String emoji;
  final String title;
  final String description;

  const OnboardingPageData({
    required this.emoji,
    required this.title,
    required this.description,
  });
}
