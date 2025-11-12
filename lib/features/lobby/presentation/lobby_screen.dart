import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../game/data/game_repository.dart';
import '../../game/provider/game_provider.dart';
import '../../game/presentation/widgets/drawer_menu.dart';
import '../../../core/constants/app_colors.dart';
import '../models/lobby_info.dart';
import 'widgets/lobby_card_widget.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final TextEditingController _usernameController = TextEditingController(text: 'Oyuncu');
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';

  late final GameRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = GameRepository(FirebaseDatabase.instance);
    GameRepository.ensureAnonymousSignIn();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _showCreateLobbyDialog() async {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: AppColors.gradientStart),
            const SizedBox(width: 12),
            const Text('Yeni Lobi Oluştur'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Lobi Adı',
                    hintText: 'Örn: Eğlenceli Grup',
                    prefixIcon: const Icon(Icons.group),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lütfen bir lobi adı girin';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Parola (Opsiyonel)',
                    hintText: 'Boş bırakılabilir',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _createGame(
                  nameController.text.trim(),
                  passwordController.text.trim().isEmpty
                      ? null
                      : passwordController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientStart,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGame(String lobbyName, String? password) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('[LobbyScreen] Anonim giriş başlatılıyor...');
      await GameRepository.ensureAnonymousSignIn();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı girişi yapılmamış');
      }
      print('[LobbyScreen] Kullanıcı ID: ${user.uid}');

      print('[LobbyScreen] Lobi oluşturuluyor: $lobbyName');
      final id = await _repo.createGame(
        hostUserId: user.uid,
        username: _usernameController.text.trim().isEmpty 
            ? 'Oyuncu' 
            : _usernameController.text.trim(),
        lobbyName: lobbyName,
        password: password,
      );
      print('[LobbyScreen] Lobi oluşturuldu, ID: $id');
      
      if (!mounted) return;
      context.go('/lobby/$id');
    } catch (e, stackTrace) {
      print('[LobbyScreen] HATA: $e');
      print('[LobbyScreen] StackTrace: $stackTrace');
      if (!mounted) return;
      
      String errorMessage = 'Lobi oluşturulamadı';
      if (e.toString().contains('zaman aşımı') || e.toString().contains('timeout')) {
        errorMessage = 'Firebase bağlantı hatası. Lütfen internet bağlantınızı ve Firebase kurallarını kontrol edin.';
      } else if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Firebase izin hatası. Firebase Console\'da Realtime Database kurallarını kontrol edin.';
      } else {
        errorMessage = 'Hata: ${e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinLobby(LobbyInfo lobby) async {
    if (_isLoading || lobby.isFull) return;

    String? password;
    
    if (lobby.hasPassword) {
      password = await _showPasswordDialog();
      if (password == null) return;
    }

    setState(() => _isLoading = true);
    
    try {
      await GameRepository.ensureAnonymousSignIn();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı girişi yapılmamış');
      }

      await _repo.joinGame(
        gameId: lobby.gameId,
        userId: user.uid,
        username: _usernameController.text.trim().isEmpty 
            ? 'Oyuncu' 
            : _usernameController.text.trim(),
        password: password,
      );
      
      if (!mounted) return;
      context.go('/lobby/${lobby.gameId}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock, color: AppColors.gradientStart),
            const SizedBox(width: 12),
            const Text('Parola Gerekli'),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordController,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Parola',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen parola girin';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, passwordController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientStart,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
    
    passwordController.dispose();
    return result;
  }

  List<LobbyInfo> _filterLobbies(List<LobbyInfo> lobbies) {
    if (_searchQuery.isEmpty) return lobbies;
    
    final query = _searchQuery.toLowerCase();
    return lobbies.where((lobby) {
      return lobby.lobbyName.toLowerCase().contains(query) ||
          lobby.hostUsername.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lobbiesAsync = ref.watch(activeLobbiesProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Oyun Lobisi'),
        elevation: 0,
        backgroundColor: AppColors.gradientStart,
        foregroundColor: Colors.white,
      ),
      drawer: const DrawerMenu(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(),
            Expanded(
              child: _buildLobbiesList(lobbiesAsync),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCreateButton(),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildUsernameField(),
          const SizedBox(height: 12),
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: 'Kullanıcı Adı',
        hintText: 'Oyuncu adınızı girin',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Lobi Ara',
        hintText: 'Lobi adı veya ev sahibi ara...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildLobbiesList(AsyncValue<List<LobbyInfo>> lobbiesAsync) {
    return lobbiesAsync.when(
      data: (lobbies) {
        final filtered = _filterLobbies(lobbies);
        
        if (filtered.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeLobbiesProvider);
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final lobby = filtered[index];
              return LobbyCardWidget(
                lobby: lobby,
                onTap: _isLoading || lobby.isFull 
                    ? null 
                    : () => _joinLobby(lobby),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.games_outlined : Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Aktif lobi bulunamadı'
                : 'Arama sonucu bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'İlk lobiyi oluşturmak için + butonuna basın'
                : 'Farklı bir arama terimi deneyin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bir hata oluştu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(activeLobbiesProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Yeniden Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientStart,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _showCreateLobbyDialog,
      backgroundColor: AppColors.gradientStart,
      foregroundColor: Colors.white,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.add),
      label: Text(_isLoading ? 'Yükleniyor...' : 'Yeni Lobi'),
    );
  }
}

final activeLobbiesProvider = StreamProvider<List<LobbyInfo>>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  return repo.watchActiveLobbies().map((lobbyList) {
    // Sadece oyuncu sayısı 0'dan büyük olan lobileri filtrele (hayalet lobileri gizle)
    return lobbyList.where((lobby) => lobby.playerCount > 0).toList();
  });
});
