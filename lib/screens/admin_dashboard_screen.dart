import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../logic/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../services/firestore_progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_colors_extension.dart';
import '../utils/responsive.dart';
import '../utils/web_download.dart' as web_download;
import '../widgets/responsive_container.dart';
import '../widgets/responsive_snack_bar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<UserSummary> _users = [];
  List<UserSummary> _filteredUsers = [];
  GlobalStats _stats = const GlobalStats();
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await FirestoreProgressService().getAllUsers();
    final stats = await FirestoreProgressService().getGlobalStats();
    if (mounted) {
      setState(() {
        _users = users;
        _filteredUsers = users;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((u) {
          return u.email.toLowerCase().contains(query.toLowerCase()) ||
              (u.nickname?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _exportCsv() async {
    try {
      final csvContent = await FirestoreProgressService().exportUsersCsv();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'users_export_$timestamp.csv';

      if (kIsWeb) {
        await _downloadCsvWeb(csvContent, fileName);
      } else {
        await _downloadCsvMobile(csvContent, fileName);
      }

      if (mounted) {
        ResponsiveSnackBar.showSuccess(
          context,
          message: '✅ CSV exportado correctamente',
        );
      }
    } catch (e) {
      if (mounted) {
        ResponsiveSnackBar.showError(
          context,
          message: 'Error al exportar: $e',
        );
      }
    }
  }

  Future<void> _downloadCsvWeb(String content, String fileName) async {
    if (!kIsWeb) return;

    try {
      web_download.triggerWebDownload(content, fileName);
    } catch (_) {
      if (mounted) {
        ResponsiveSnackBar.showInfo(
          context,
          message: 'Descarga web no disponible. Contenido CSV generado para $fileName',
        );
      }
    }
  }

  Future<void> _downloadCsvMobile(String content, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);

    if (mounted) {
      ResponsiveSnackBar.showSuccess(
        context,
        message: '📁 Guardado en: ${file.path}',
        duration: const Duration(seconds: 5),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Nunca';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: const Text('Panel de Admin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text(
                    '¿Estás seguro de que quieres cerrar sesión?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                try {
                  await context.read<AuthProvider>().signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ResponsiveSnackBar.showError(
                      context,
                      message: 'Error al cerrar sesión: $e',
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveContainer(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 14),
                    _buildSessionsChart(),
                    const SizedBox(height: 14),
                    _buildSearchBar(),
                    const SizedBox(height: 8),
                    _buildUsersList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    final cards = [
      _StatCard(
        icon: Icons.people,
        label: 'Usuarios',
        value: _stats.totalUsers.toString(),
        color: AppColors.primary,
        trend: _stats.newUsersThisWeek > 0
            ? '+${_stats.newUsersThisWeek} esta semana'
            : null,
      ),
      _StatCard(
        icon: Icons.play_circle,
        label: 'Sesiones',
        value: _stats.totalSessions.toString(),
        color: AppColors.info,
      ),
      _StatCard(
        icon: Icons.check_circle,
        label: 'Completadas',
        value: _stats.totalCompletedLessons.toString(),
        color: AppColors.success,
      ),
      _StatCard(
        icon: Icons.local_fire_department,
        label: 'Activos hoy',
        value: _stats.activeToday.toString(),
        color: AppColors.warningDark,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Responsive.isMobile(context)
            ? 1
            : Responsive.isTablet(context)
                ? 2
                : 4;
        const spacing = 10.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth,
                  height: 96,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSessionsChart() {
    final data = _stats.sessionsLast7Days;
    final hasData = data.any((d) => d.count > 0);

     return Card(
       color: context.appColors.cardBackground,
       elevation: 0,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(12),
         side: BorderSide(color: context.appColors.border),
       ),
       child: Padding(
         padding: const EdgeInsets.all(14),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               children: [
                 const Icon(Icons.show_chart, size: 18, color: AppColors.primary),
                 const SizedBox(width: 6),
                 Text(
                   'Sesiones · últimos 7 días',
                   style: TextStyle(
                     fontSize: 14,
                     fontWeight: FontWeight.w600,
                     color: context.appColors.textPrimary,
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 12),
             SizedBox(
               height: 140,
               width: double.infinity,
               child: hasData
                   ? CustomPaint(
                       painter: _SessionsChartPainter(data),
                     )
                   : Center(
                       child: Text(
                         'Aún no hay sesiones registradas por día',
                         style: TextStyle(
                           fontSize: 13,
                           color: context.appColors.textTertiary,
                         ),
                       ),
                     ),
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(fontSize: 15),
       decoration: InputDecoration(
         hintText: 'Buscar usuario...',
         hintStyle: const TextStyle(fontSize: 15),
         prefixIcon: Icon(Icons.search, size: 18, color: context.appColors.textSecondary),
         suffixIcon: _searchController.text.isNotEmpty
             ? IconButton(
                 icon: Icon(Icons.clear, size: 16, color: context.appColors.textSecondary),
                 onPressed: () {
                   _searchController.clear();
                   _filterUsers('');
                 },
               )
             : null,
         filled: true,
         fillColor: context.appColors.cardBackground,
         isDense: true,
         border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(10),
           borderSide: BorderSide(color: context.appColors.border),
         ),
         enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(10),
           borderSide: BorderSide(color: context.appColors.border),
         ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: _filterUsers,
    );
  }

  Widget _buildUsersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
           child: Text(
             'Usuarios (${_filteredUsers.length})',
             style: TextStyle(
               fontSize: 15,
               fontWeight: FontWeight.w600,
               color: context.appColors.textPrimary,
             ),
           ),
        ),
        if (_filteredUsers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                 children: [
                   Icon(Icons.person_off, size: 36, color: context.appColors.textTertiary),
                   const SizedBox(height: 8),
                   Text(
                     _searchController.text.isNotEmpty
                         ? 'Sin resultados'
                         : 'Sin usuarios registrados',
                     style: TextStyle(fontSize: 14, color: context.appColors.textSecondary),
                   ),
                 ],
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _filteredUsers.map((user) {
                return _UserTile(
                  user: user,
                  formatDate: _formatDate,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailScreen(
                          uid: user.uid,
                          email: user.email,
                          nickname: user.nickname,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class UserDetailScreen extends StatefulWidget {
  final String uid;
  final String email;
  final String? nickname;

  const UserDetailScreen({
    super.key,
    required this.uid,
    required this.email,
    this.nickname,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  UserMetrics? _metrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);
    final metrics = await FirestoreProgressService().getUserMetricsByUid(
      widget.uid,
    );
    if (mounted) {
      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Nunca';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nickname ?? widget.email),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetrics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _metrics == null
              ? const Center(
                  child: Text('No se pudieron cargar las métricas.'),
                )
              : RefreshIndicator(
                  onRefresh: _loadMetrics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildUserHeader(),
                      const SizedBox(height: 20),
                      _buildSessionCard(),
                      const SizedBox(height: 20),
                      _buildLessonProgressList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nickname ?? widget.email,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                       if (widget.nickname != null)
                         Text(
                           widget.email,
                           style: TextStyle(
                             fontSize: 16,
                             color: context.appColors.textSecondary,
                           ),
                         ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
             Text(
               'UID: ${widget.uid}',
               style: TextStyle(
                 fontSize: 13,
                 color: context.appColors.textTertiary,
                 fontFamily: 'monospace',
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               children: [
                 Icon(Icons.analytics, color: context.appColors.textPrimary),
                const SizedBox(width: 8),
                const Text(
                  'Frecuencia de Uso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.play_circle,
                    label: 'Sesiones totales',
                    value: _metrics!.totalSessions.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    icon: Icons.schedule,
                    label: 'Última actividad',
                    value: _formatDate(_metrics!.lastActive),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.local_fire_department,
                    label: 'Racha de login',
                    value: '${_metrics!.loginStreak} días',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    icon: Icons.calendar_today,
                    label: 'Último login',
                    value: _metrics!.lastLoginDate != null
                        ? '${_metrics!.lastLoginDate!.day}/${_metrics!.lastLoginDate!.month}/${_metrics!.lastLoginDate!.year}'
                        : 'Nunca',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonProgressList() {
    final lessons = _metrics!.progress.entries.toList();

    if (lessons.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
             children: [
               Icon(Icons.school_outlined, size: 48, color: context.appColors.textTertiary),
               const SizedBox(height: 12),
               Text(
                 'Aún no hay progreso de lecciones',
                 style: TextStyle(color: context.appColors.textSecondary),
               ),
             ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Progreso por Lección (${lessons.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          child: Column(
            children: lessons.map((entry) {
              final lessonId = entry.key;
              final progress = entry.value;
              return _LessonProgressTile(
                lessonId: lessonId,
                progress: progress,
                formatDate: _formatDate,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? trend;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
     return Container(
       decoration: BoxDecoration(
         color: context.appColors.cardBackground,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: context.appColors.border),
         boxShadow: [
           BoxShadow(
             color: context.appColors.shadow,
             blurRadius: 16,
             offset: const Offset(0, 4),
             spreadRadius: -4,
           ),
         ],
       ),
       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Flexible(
                 child: Text(
                   label,
                   style: TextStyle(
                     fontSize: 13,
                     color: context.appColors.textSecondary,
                     fontWeight: FontWeight.w500,
                   ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
               Icon(icon, color: color, size: 16),
             ],
           ),
           const SizedBox(height: 4),
           Text(
             value,
             style: TextStyle(
               fontSize: 24,
               fontWeight: FontWeight.w500,
               color: context.appColors.textPrimary,
               height: 1.1,
             ),
           ),
          if (trend != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.arrow_upward,
                  size: 12,
                  color: AppColors.success,
                ),
                const SizedBox(width: 2),
                Text(
                  trend!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
           Text(
             label,
             style: TextStyle(
               fontSize: 14,
               color: context.appColors.textSecondary,
             ),
           ),
        ],
      ),
    );
  }
}

/// Iniciales (máx. 2 letras) a partir del nickname o, en su defecto, el email.
String avatarInitials(String? nickname, String email) {
  final source = (nickname != null && nickname.trim().isNotEmpty)
      ? nickname.trim()
      : email.trim();
  final parts =
      source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final word = parts.first;
    return word
        .substring(0, word.length >= 2 ? 2 : 1)
        .toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Color de avatar determinístico basado en el hash del uid,
/// usando la paleta de colores de la app.
Color avatarColorFor(String uid) {
  const palette = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.success,
    AppColors.info,
    AppColors.purpleMagic,
    AppColors.orangeSun,
    AppColors.tealOcean,
    AppColors.pinkFun,
  ];
  var hash = 0;
  for (final codeUnit in uid.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0x7FFFFFFF;
  }
  return palette[hash % palette.length];
}

class _UserTile extends StatelessWidget {
  final UserSummary user;
  final String Function(DateTime?) formatDate;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = user.totalLessons > 0
        ? user.completedLessons / user.totalLessons
        : 0.0;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarColorFor(user.uid),
                  child: Text(
                    avatarInitials(user.nickname, user.email),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname ?? user.email,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                       Text(
                          '${user.totalSessions} sesiones · ${formatDate(user.lastActive)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appColors.textTertiary,
                          ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                       if (user.loginStreak > 0) ...[
                         const SizedBox(height: 2),
                         Row(
                           children: [
                             const Icon(
                               Icons.local_fire_department,
                               size: 12,
                               color: Colors.orange,
                             ),
                             const SizedBox(width: 3),
                             Text(
                               'Racha: ${user.loginStreak} días',
                               style: TextStyle(
                                 fontSize: 11,
                                 color: Colors.orange.shade700,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                           ],
                         ),
                       ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                               child: LinearProgressIndicator(
                                 value: progress,
                                 minHeight: 5,
                                 backgroundColor: context.appColors.surfaceVariant,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  AppColors.success,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                           Text(
                             '${user.completedLessons}/${user.totalLessons}',
                             style: TextStyle(
                               fontSize: 12,
                               color: context.appColors.textSecondary,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                        ],
                      ),
                    ],
                  ),
                ),
                 const SizedBox(width: 6),
                 Icon(Icons.chevron_right, size: 16, color: context.appColors.textTertiary),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Painter del gráfico de línea "sesiones por día" (últimos 7 días).
/// Línea simple con relleno suave, sin dependencias externas.
class _SessionsChartPainter extends CustomPainter {
  final List<DailyCount> data;

  const _SessionsChartPainter(this.data);

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const topPadding = 16.0;
    const bottomLabelSpace = 20.0;
    final chartHeight = size.height - topPadding - bottomLabelSpace;
    if (chartHeight <= 0) return;

    final maxCount = data.fold<int>(0, (m, d) => d.count > m ? d.count : m);
    final maxY = (maxCount == 0 ? 1 : maxCount).toDouble();
    final stepX = data.length > 1 ? size.width / (data.length - 1) : 0.0;
    final baselineY = size.height - bottomLabelSpace;

    final points = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(
          data.length > 1 ? i * stepX : size.width / 2,
          topPadding + chartHeight * (1 - data[i].count / maxY),
        ),
    ];

    // Línea base
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      Paint()
        ..color = AppColors.border
        ..strokeWidth = 1,
    );

    // Relleno suave bajo la curva
    final fillPath = Path()..moveTo(points.first.dx, baselineY);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, baselineY)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withAlpha(50),
            AppColors.primary.withAlpha(5),
          ],
        ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight)),
    );

    // Línea
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Puntos
    final dotPaint = Paint()..color = AppColors.primary;
    final dotInnerPaint = Paint()..color = Colors.white;
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
      canvas.drawCircle(point, 1.5, dotInnerPaint);
    }

    // Etiquetas de día (L M X J V S D)
    for (var i = 0; i < data.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: _dayLabels[data[i].date.weekday - 1],
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, baselineY + 5),
      );
    }

    // Valores sobre los puntos con sesiones
    for (var i = 0; i < data.length; i++) {
      if (data[i].count == 0) continue;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${data[i].count}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          points[i].dx - textPainter.width / 2,
          points[i].dy - textPainter.height - 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SessionsChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

class _LessonProgressTile extends StatelessWidget {
  final String lessonId;
  final dynamic progress;
  final String Function(DateTime?) formatDate;

  const _LessonProgressTile({
    required this.lessonId,
    required this.progress,
    required this.formatDate,
  });

  String _formatLessonId(String id) {
    return id
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            progress.completed ? Icons.check_circle : Icons.pending,
            color: progress.completed ? Colors.green : Colors.orange,
          ),
          title: Text(
            _formatLessonId(lessonId),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('${progress.stars} estrellas'),
                  const SizedBox(width: 16),
                  const Icon(Icons.trending_up, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  Text('${progress.bestAccuracy.toStringAsFixed(0)}%'),
                  const SizedBox(width: 16),
                  const Icon(Icons.replay, color: Colors.purple, size: 16),
                  const SizedBox(width: 4),
                  Text('${progress.attempts} intentos'),
                ],
              ),
              const SizedBox(height: 2),
               Text(
                 'Última vez: ${formatDate(progress.lastPlayed)}',
                 style: TextStyle(
                   fontSize: 14,
                   color: context.appColors.textSecondary,
                 ),
               ),
            ],
          ),
          isThreeLine: true,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
