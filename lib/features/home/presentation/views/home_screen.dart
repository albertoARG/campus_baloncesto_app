import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tablon/presentation/providers/tablon_providers.dart';
import '../../../blog/presentation/providers/blog_providers.dart';
import '../../../../core/services/notification_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh the banner data every time we open/return to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(tablonPostsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final session = Supabase.instance.client.auth.currentSession;
    final String role = session == null
        ? 'visitante'
        : (userProfileAsync.value?.role ?? 'visitante');
    final bool canManageScores = role == 'admin' || role == 'entrenador';
    final bool isAdmin = role == 'admin';
    final String userName = session == null
        ? 'Invitado'
        : (userProfileAsync.value?.nombre ?? '');

    // Subscribe/unsubscribe from staff notifications based on role
    if (session != null && userProfileAsync.value != null) {
      final notifService = ref.read(notificationServiceProvider);
      if (canManageScores) {
        notifService.subscribeToStaffTopic();
      } else {
        notifService.unsubscribeFromStaffTopic();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Toledo'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Mi Perfil',
            onPressed: () =>
                session != null ? context.go('/profile') : context.go('/login'),
          ),
        ],
      ),
      drawer: _AppDrawer(
        role: role,
        userName: userName,
        isAdmin: isAdmin,
        canManageScores: canManageScores,
      ),
      body: _HomeBody(
        canManageScores: canManageScores,
        isAdmin: isAdmin,
        session: session,
      ),
    );
  }
}

// ─── Drawer lateral ─────────────────────────────────────────────────────────

class _AppDrawer extends ConsumerWidget {
  final String role;
  final String userName;
  final bool isAdmin;
  final bool canManageScores;
  const _AppDrawer({
    required this.role,
    required this.userName,
    required this.isAdmin,
    required this.canManageScores,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isLoggedIn =
        Supabase.instance.client.auth.currentSession != null;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userName.isNotEmpty ? userName : 'Invitado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ─── Sección: Todos ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'GENERAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _DrawerItem(
            icon: Icons.leaderboard_outlined,
            label: 'Clasificación',
            onTap: () {
              Navigator.pop(context);
              context.go('/standings');
            },
          ),
          _DrawerItem(
            icon: Icons.photo_library_outlined,
            label: 'Blog',
            onTap: () {
              Navigator.pop(context);
              context.push('/blog');
            },
          ),
          _DrawerItem(
            icon: Icons.sports_tennis,
            label: 'Competiciones Siesta',
            onTap: () {
              Navigator.pop(context);
              context.go('/siesta');
            },
          ),
          _DrawerItem(
            icon: Icons.nightlight_round,
            label: 'Veladas',
            onTap: () {
              Navigator.pop(context);
              context.go('/veladas');
            },
          ),
          _DrawerItem(
            icon: Icons.forum_outlined,
            label: 'Tablón de Anuncios',
            onTap: () {
              Navigator.pop(context);
              context.push('/tablon');
            },
          ),
          _DrawerItem(
            icon: Icons.person_outline,
            label: 'Mi Perfil',
            onTap: () {
              Navigator.pop(context);
              isLoggedIn ? context.go('/profile') : context.go('/login');
            },
          ),

          // ─── Sección: Solo Staff ────────────────────────────
          if (canManageScores) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'SOLO STAFF',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _DrawerItem(
              icon: Icons.sports_score,
              label: 'Puntuar Estación',
              iconColor: Theme.of(context).colorScheme.primary,
              onTap: () {
                Navigator.pop(context);
                context.push('/add-score');
              },
            ),
            _DrawerItem(
              icon: Icons.tune,
              label: 'Gestión Competición',
              iconColor: Theme.of(context).colorScheme.primary,
              onTap: () {
                Navigator.pop(context);
                context.push('/competitions/manage');
              },
            ),
            _DrawerItem(
              icon: Icons.group,
              label: 'Grupos Competición',
              iconColor: Theme.of(context).colorScheme.primary,
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/groups');
              },
            ),
            _DrawerItem(
              icon: Icons.auto_awesome,
              label: 'Gestión Veladas',
              iconColor: Theme.of(context).colorScheme.primary,
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/veladas');
              },
            ),
            if (isAdmin)
              _DrawerItem(
                icon: Icons.manage_accounts_outlined,
                label: 'Gestionar Usuarios',
                iconColor: Theme.of(context).colorScheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin/users');
                },
              ),
          ],

          // ─── Sección: Sesión ────────────────────────────────
          const Divider(),
          if (isLoggedIn)
            _DrawerItem(
              icon: Icons.logout,
              label: 'Cerrar Sesión',
              iconColor: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text(
                      '¿Estás seguro de que quieres cerrar sesión?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/');
                }
              },
            )
          else
            _DrawerItem(
              icon: Icons.login,
              label: 'Iniciar Sesión',
              onTap: () {
                Navigator.pop(context);
                context.go('/login');
              },
            ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label),
      onTap: onTap,
    );
  }
}

// ─── Cuerpo principal (cuadrícula de accesos) ────────────────────────────────

class _HomeBody extends ConsumerWidget {
  final bool canManageScores;
  final bool isAdmin;
  final dynamic session;

  const _HomeBody({
    required this.canManageScores,
    required this.isAdmin,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _buildItems(context);
    final postsAsync = ref.watch(tablonPostsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tablonPostsProvider);
        ref.invalidate(blogPostsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Bienvenido al Campus',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecciona una sección para comenzar',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) return const SizedBox.shrink();
                final latest = posts.first;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: InkWell(
                    onTap: () => context.push('/tablon'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade700,
                            Colors.orange.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.campaign,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  latest.isStaffOnly
                                      ? 'ÚLTIMO AVISO - SOLO STAFF'
                                      : 'ÚLTIMO AVISO',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  latest.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: items,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final all = <_NavCard>[
      _NavCard(
        label: 'Clasificación',
        icon: Icons.leaderboard,
        color: const Color(0xFF1A73E8),
        onTap: () => context.go('/standings'),
      ),
      _NavCard(
        label: 'Blog',
        icon: Icons.photo_library,
        color: const Color(0xFFD81B60),
        onTap: () => context.push('/blog'),
      ),
      _NavCard(
        label: 'Competiciones Siesta',
        icon: Icons.sports_tennis,
        color: const Color(0xFF00BFA5),
        onTap: () => context.go('/siesta'),
      ),
      _NavCard(
        label: 'Clasificación Veladas',
        icon: Icons.nightlight_round,
        color: const Color(0xFF0D47A1),
        onTap: () => context.go('/veladas'),
      ),
      _NavCard(
        label: 'Tablón de Anuncios',
        icon: Icons.forum,
        color: const Color(0xFFF57C00),
        onTap: () => context.push('/tablon'),
      ),
      if (canManageScores)
        _NavCard(
          label: 'Puntuar Estación',
          icon: Icons.sports_score,
          color: const Color(0xFFFF6B9E),
          onTap: () => context.push('/add-score'),
        ),
      if (canManageScores)
        _NavCard(
          label: 'Gestión Competición',
          icon: Icons.tune,
          color: const Color(0xFF00897B),
          onTap: () => context.push('/competitions/manage'),
        ),
      if (canManageScores)
        _NavCard(
          label: 'Grupos Competición',
          icon: Icons.group,
          color: const Color(0xFF8E24AA),
          onTap: () => context.go('/admin/groups'),
        ),
      if (canManageScores)
        _NavCard(
          label: 'Gestión Veladas',
          icon: Icons.auto_awesome,
          color: const Color(0xFF00B0FF),
          onTap: () => context.go('/admin/veladas'),
        ),
      if (isAdmin)
        _NavCard(
          label: 'Gestionar Usuarios',
          icon: Icons.manage_accounts,
          color: const Color(0xFFFB8C00),
          onTap: () => context.go('/admin/users'),
        ),
    ];

    return all.map((c) => _buildCard(context, c)).toList();
  }

  Widget _buildCard(BuildContext context, _NavCard item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: item.color.withOpacity(0.12),
          border: Border.all(color: item.color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color.withOpacity(0.2),
              ),
              child: Icon(item.icon, size: 36, color: item.color),
            ),
            const SizedBox(height: 12),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: item.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _NavCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
