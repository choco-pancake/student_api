import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/student.dart';
import '../services/student_api.dart';
import '../widgets/student_form_dialog.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = StudentApi.getStudents();
  }

  void _loadStudents() {
    setState(() {
      _studentsFuture = StudentApi.getStudents();
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? AppColors.danger : AppColors.ink,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(message),
        ),
      );
  }

  Future<void> _addStudent() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const StudentFormDialog(),
    );
    if (result == null) return;

    try {
      await StudentApi.addStudent(result['name']!, result['course']!);
      if (!mounted) return;
      _loadStudents();
      _showMessage('Added ${result['name']}');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not add student. $e', isError: true);
    }
  }

  Future<void> _editStudent(Student student) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => StudentFormDialog(student: student),
    );
    if (result == null) return;

    try {
      await StudentApi.updateStudent(
          student.id, result['name']!, result['course']!);
      if (!mounted) return;
      _loadStudents();
      _showMessage('Updated ${result['name']}');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not update student. $e', isError: true);
    }
  }

  Future<void> _deleteStudent(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE9E7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.danger),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete this student?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${student.name} will be removed from the records. '
                  'This cannot be undone.',
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Builder(
                      builder: (ctx) => TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.muted,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (ctx) => FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      await StudentApi.deleteStudent(student.id);
      if (!mounted) return;
      _loadStudents();
      _showMessage('Deleted ${student.name}');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not delete student. $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadStudents,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                Expanded(child: _buildList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Records',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Add, update, and remove students enrolled in your courses.',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: _addStudent,
          icon: const Icon(Icons.add),
          label: const Text('Add Student'),
        ),
      ],
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<Student>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          );
        }

        // Error + retry
        if (snapshot.hasError) {
          return _StateMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Can\'t reach the server',
            message:
                'Check that Laravel is running at 127.0.0.1:8000, then try again.\n${snapshot.error}',
            actionLabel: 'Retry',
            onAction: _loadStudents,
          );
        }

        final all = snapshot.data ?? [];

        // No records at all
        if (all.isEmpty) {
          return _StateMessage(
            icon: Icons.school_outlined,
            title: 'No student records yet',
            message: 'Add your first student to start the list.',
            actionLabel: 'Add Student',
            onAction: _addStudent,
          );
        }

        final students = all;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${all.length} ${all.length == 1 ? 'student' : 'students'}',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return _StudentCard(
                          number: index + 1,
                          student: student,
                          onEdit: () => _editStudent(student),
                          onDelete: () => _deleteStudent(student),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// One row in the list: avatar, name, course tag, Edit and Delete buttons.
class _StudentCard extends StatelessWidget {
  final int number;
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.number,
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  static const _tagColors = [
    [Color(0xFFE0F2F1), Color(0xFF0E7C7B)],
    [Color(0xFFE3EAFB), Color(0xFF2F4EA2)],
    [Color(0xFFFFF1DB), Color(0xFF9A5B00)],
    [Color(0xFFF3E5F5), Color(0xFF7B2D8E)],
    [Color(0xFFE8F5E9), Color(0xFF2E7D32)],
  ];

  String get _initials {
    final parts =
        student.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final list = parts.toList();
    final first = list.first[0];
    final last = list.length > 1 ? list.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tag = _tagColors[student.course.hashCode.abs() % _tagColors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          return Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  number.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: tag[0],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        student.course,
                        style: TextStyle(
                          color: tag[1],
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (compact) ...[
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, color: AppColors.teal),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Used for the error, empty, and no-match states.
class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: Icon(icon, size: 30, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 14, height: 1.4),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}