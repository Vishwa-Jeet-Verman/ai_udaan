import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/grade.dart';
import '../../providers/auth_provider.dart';
import '../../services/grade_service.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  List<CourseGrade> _grades = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await GradeService.getGrades();
      setState(() { _grades = data; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.gradesTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.signInToViewGrades,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text(AppLocalizations.of(context)!.signIn),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.gradesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.failedToLoadGrades, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: Text(AppLocalizations.of(context)!.retry)),
          ],
        ),
      );
    }

    if (_grades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grade_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noGradesYet,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.enrollInCoursesForGrades,
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _grades.length,
        itemBuilder: (context, i) => _CourseGradeCard(courseGrade: _grades[i]),
      ),
    );
  }
}

// ─── Course grade card ────────────────────────────────────────────────────────

class _CourseGradeCard extends StatefulWidget {
  final CourseGrade courseGrade;
  const _CourseGradeCard({required this.courseGrade});

  @override
  State<_CourseGradeCard> createState() => _CourseGradeCardState();
}

class _CourseGradeCardState extends State<_CourseGradeCard> {
  bool _expanded = false;

  Color _gradeColor(double? pct) {
    if (pct == null) return Colors.grey;
    if (pct >= 75) return const Color(0xFF1F7A63);
    if (pct >= 50) return Colors.orange;
    return Colors.red;
  }

  String _gradeLabel(double? pct) {
    if (pct == null) return '-';
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B';
    if (pct >= 60) return 'C';
    if (pct >= 50) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    final cg = widget.courseGrade;
    final total = cg.courseTotal;
    final pct = total?.percentage;
    final color = _gradeColor(pct);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasItems = cg.items.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: hasItems ? () => setState(() => _expanded = !_expanded) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Grade circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: total == null
                          ? Icon(Icons.hourglass_empty, color: Colors.grey[400], size: 22)
                          : Text(
                              _gradeLabel(pct),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cg.courseTitle,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (total != null) ...[
                          Row(
                            children: [
                              Text(
                                total.gradeformatted,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: color,
                                ),
                              ),
                              if (total.percentageformatted != null) ...[
                                Text('  ·  ', style: TextStyle(color: Colors.grey[400])),
                                Text(
                                  total.percentageformatted!,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct != null ? (pct / 100).clamp(0.0, 1.0) : 0,
                              minHeight: 5,
                              backgroundColor: color.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ] else
                          Text(
                            AppLocalizations.of(context)!.noGradeRecorded,
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                  if (hasItems)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[500],
                    ),
                ],
              ),
            ),
          ),

          // ── Grade items breakdown ────────────────────────────
          if (_expanded && hasItems) ...[
            const Divider(height: 1),
            ...cg.items.map((item) => _GradeItemRow(item: item)),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

// ─── Individual grade item row ────────────────────────────────────────────────

class _GradeItemRow extends StatelessWidget {
  final GradeItem item;
  const _GradeItemRow({required this.item});

  IconData _moduleIcon(String? module) {
    switch (module) {
      case 'quiz': return Icons.quiz_outlined;
      case 'assign': return Icons.assignment_outlined;
      case 'forum': return Icons.forum_outlined;
      case 'workshop': return Icons.build_outlined;
      case 'lesson': return Icons.menu_book_outlined;
      default: return Icons.grade_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = item.percentage;
    Color color = Colors.grey;
    if (pct != null) {
      if (pct >= 75) {
        color = Colors.green;
      } else if (pct >= 50) {
        color = Colors.orange;
      } else {
        color = Colors.red;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(_moduleIcon(item.itemmodule), size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemname,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (item.feedback != null && item.feedback!.isNotEmpty)
                  Text(item.feedback!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.gradeformatted,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
              ),
              if (item.percentageformatted != null)
                Text(item.percentageformatted!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}
