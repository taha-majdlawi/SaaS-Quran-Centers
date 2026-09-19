import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import 'students_repository.dart';

const kStudentStatusLabels = {
  'active': 'نشط',
  'paused': 'متوقف',
  'graduated': 'تخرّج',
  'withdrawn': 'منسحب',
};

const _statusColors = <String, MaterialColor>{
  'active': Colors.green,
  'paused': Colors.orange,
  'graduated': Colors.blue,
  'withdrawn': Colors.grey,
};

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final _repository = StudentsRepository(AppSupabase.client);
  late Future<List<StudentSummary>> _studentsFuture;
  String? _loadedForOrgId;
  String _query = '';

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _studentsFuture = _repository.fetchStudents(orgId);
  }

  Future<void> _open(String path) async {
    await context.push(path);
    if (_loadedForOrgId != null && mounted) setState(() => _reload(_loadedForOrgId!));
  }

  Future<void> _delete(StudentSummary student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطالب'),
        content: Text('سيتم حذف "${student.fullName}" وكل ملفه (الحضور، السرد، النقاط...). لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text('حذف', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteStudent(student.id);
    if (_loadedForOrgId != null && mounted) setState(() => _reload(_loadedForOrgId!));
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الطلاب')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open('/students/new'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('إضافة طالب'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم أو رقم الطالب',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: AsyncBody<List<StudentSummary>>(
              future: _studentsFuture,
              onRetry: () => setState(() => _reload(orgId!)),
              builder: (context, all) {
                final students = _query.isEmpty
                    ? all
                    : all.where((s) => s.fullName.contains(_query) || s.studentCode.toLowerCase().contains(_query.toLowerCase())).toList();

                if (all.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_alt_outlined,
                    title: 'لا يوجد طلاب بعد',
                    subtitle: 'ابدأ بإضافة أول طالب من الزر بالأسفل',
                  );
                }
                if (students.isEmpty) {
                  return const EmptyState(icon: Icons.search_off_rounded, title: 'لا نتائج مطابقة');
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _reload(orgId!));
                    await _studentsFuture;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: students.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return Card(
                        child: ListTile(
                          onTap: () => _open('/students/${s.id}/file'),
                          leading: InitialAvatar(s.fullName),
                          title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${s.studentCode}  ·  ${s.circleName ?? "بدون حلقة"}'),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusChip(
                                label: kStudentStatusLabels[s.status] ?? s.status,
                                color: _statusColors[s.status] ?? Colors.grey,
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) => v == 'delete' ? _delete(s) : _open('/students/${s.id}'),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'edit', child: Text('تعديل البيانات')),
                                  PopupMenuItem(value: 'delete', child: Text('حذف الطالب وملفه')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
