import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {

  // Constructor
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4ECDC4), // Turkuaz
              Color(0xFF44A8E0), // Mavi
              Color(0xFFB06AE8), // Mor
              Color(0xFFFF6B9D), // Pembe
            ],
            stops: [0.0, 0.33, 0.66, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst Sağ Köşe - Dil ve Tema Butonları
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Dil Değiştirme Butonu
                    _buildTopIconButton(
                      icon: Icons.language,
                      onPressed: () => _onLanguagePressed(context),
                    ),
                    const SizedBox(width: 12),
                    // Tema Değiştirme Butonu
                    _buildTopIconButton(
                      icon: Icons.palette,
                      onPressed: () => _onThemePressed(context),
                    ),
                  ],
                ),
              ),

              // Ortada Logo ve Başlık
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Logo Container
                    _buildLogoContainer(),

                    const Spacer(flex: 1),

                    // Oyunu Başlat Butonu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: _buildPlayButton(context),
                    ),

                    const SizedBox(height: 20),

                    // Nasıl Oynanır Butonu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: _buildHowToPlayButton(context),
                    ),

                    const Spacer(flex: 2),
                  ],
                ),
              ),

              // Alt Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // Top Icon Button Widget
  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildLogoContainer() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/app_logo.png'),
          fit: BoxFit.contain, // logolar için genellikle contain daha iyidir
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }



  // Play Button Widget
  Widget _buildPlayButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _onPlayPressed(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD93D),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(35),
        ),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'OYUNU BAŞLAT',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // How to Play Button Widget
  Widget _buildHowToPlayButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _onHowToPlayPressed(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        side: const BorderSide(color: Colors.white, width: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: Colors.white.withOpacity(0.2),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            'NASIL OYNANIR?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Footer Widget
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Created by LifeEase Studio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Button Actions
  void _onLanguagePressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dil değiştirme özelliği'),
        duration: Duration(seconds: 1),
      ),
    );
    // TODO: Navigate to language selection or show language dialog
  }

  void _onThemePressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tema değiştirme özelliği'),
        duration: Duration(seconds: 1),
      ),
    );
    // TODO: Navigate to theme selection or toggle theme
  }

  void _onPlayPressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oyun başlatılıyor...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to game screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const GameScreen()),
    // );
  }

  void _onHowToPlayPressed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oyun kuralları açılıyor...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to how to play screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const HowToPlayScreen()),
    // );
  }
}