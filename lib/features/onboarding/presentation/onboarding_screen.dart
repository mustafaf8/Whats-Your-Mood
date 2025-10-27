import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'widgets/onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      emoji: '🎲',
      title: 'Eğlence Başlasın!',
      description:
          'Arkadaşlarınla birlikte en komik ve yaratıcı cevapları bul.',
    ),
    OnboardingPageData(
      emoji: '📸',
      title: 'Fotoğrafını Seç',
      description:
          'Her turda bir mood kartı görürsün ve en uygun fotoğrafını seçersin.',
    ),
    OnboardingPageData(
      emoji: '🎉',
      title: 'Anıları Paylaş',
      description: 'Komik ve eğlenceli anları paylaş, eğlence hiç bitmesin!',
    ),
  ];

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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onStartGame();
    }
  }

  void _onStartGame() {
    context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Expanded(
                flex: 3,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final pageData = _pages[index];
                    return OnboardingPage(
                      emoji: pageData.emoji,
                      title: pageData.title,
                      description: pageData.description,
                    );
                  },
                ),
              ),
              // Page Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildPageIndicator(index == _currentPage),
                ),
              ),
              const SizedBox(height: 24),
              // Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onNextPressed,
                    child: Text(isLastPage ? 'Başla' : 'Devam'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.white : AppColors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
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
