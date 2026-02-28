import 'package:flutter/material.dart';
import '../services/api_service.dart';
 
class HomeDashboard extends StatefulWidget {
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}
 
class _HomeDashboardState extends State<HomeDashboard> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  Map<String, dynamic>? _cachedUser;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _overdueKey = GlobalKey();
  final GlobalKey _upcomingKey = GlobalKey();
 
  @override
  void initState() {
    super.initState();
    _loadCachedUser();
    _loadSummary();
  }
 
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
 
  Future<void> _loadCachedUser() async {
    final user = await ApiService.getCachedUser();
    if (!mounted) return;
    setState(() {
      _cachedUser = user;
    });
  }
 
  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
 
    try {
      final summary = await ApiService.getHomeSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load home summary";
        _loading = false;
      });
    }
  }
 
  int _statValue(Map<String, dynamic>? stats, String key) {
    final value = stats?[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
 
  String _greetingName(Map<String, dynamic> summary) {
    final user = summary["user"];
    if (user is Map<String, dynamic>) {
      final display = user["displayName"]?.toString().trim();
      if (display != null && display.isNotEmpty) {
        return display;
      }
      final firstName = user["firstName"]?.toString().trim();
      if (firstName != null && firstName.isNotEmpty) {
        return firstName;
      }
      final lastName = user["lastName"]?.toString().trim();
      if (lastName != null && lastName.isNotEmpty) {
        return lastName;
      }
      final email = user["email"]?.toString().trim();
      if (email != null && email.isNotEmpty) {
        return email;
      }
    }
    final cached = _cachedUser;
    if (cached != null) {
      final display = cached["displayName"]?.toString().trim();
      if (display != null && display.isNotEmpty) {
        return display;
      }
      final first = cached["firstName"]?.toString().trim();
      if (first != null && first.isNotEmpty) return first;
      final last = cached["lastName"]?.toString().trim();
      if (last != null && last.isNotEmpty) return last;
      final email = cached["email"]?.toString().trim();
      if (email != null && email.isNotEmpty) return email;
    }
    return "";
  }
 
  List<Map<String, dynamic>> _taskList(dynamic value) {
    if (value is List) {
      return value.cast<Map<String, dynamic>>();
    }
    return [];
  }
 
  Color _priorityColor(String? value) {
    switch (value) {
      case "high":
        return Colors.red.shade400;
      case "medium":
        return Colors.orange.shade500;
      case "low":
      default:
        return Colors.green.shade500;
    }
  }
 
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return "No deadline";
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return "No deadline";
    return "${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}";
  }
 
  String _formatTodayLabel() {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final now = DateTime.now();
    final month = months[now.month - 1];
    return "$month ${now.day}, ${now.year}";
  }
 
  String _statusLabel(String? value) {
    switch (value) {
      case "in_progress":
        return "In Progress";
      case "completed":
        return "Done";
      case "pending":
      default:
        return "Todo";
    }
  }
 
  Future<void> _scrollToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }
 
  Widget _statCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required double width,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            title: Text(label),
            subtitle: Text("$value"),
          ),
        ),
      ),
    );
  }
 
  Widget _taskSection({
    required String title,
    required List<Map<String, dynamic>> tasks,
    required String emptyLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        if (tasks.isEmpty)
          Text(emptyLabel, style: TextStyle(color: Colors.grey[600]))
        else
          ...tasks.map((task) {
            final title = task["title"]?.toString() ?? "Untitled";
            final status = task["status"]?.toString();
            final priority = task["priority"]?.toString();
            final deadline = task["deadline"]?.toString();
            final color = _priorityColor(priority);
 
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(Icons.task_alt, color: color),
                ),
                title: Text(title),
                subtitle: Text("${_formatDate(deadline)} • ${_statusLabel(status)}"),
              ),
            );
          }).toList(),
      ],
    );
  }
 
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
 
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadSummary,
                child: Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }
 
    final stats = _summary["stats"] as Map<String, dynamic>?;
    final today = _taskList(_summary["today"]);
    final overdue = _taskList(_summary["overdue"]);
    final upcoming = _taskList(_summary["upcoming"]);
 
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width >= 600 ? (width - 48) / 2 : width - 32;
 
    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _greetingName(_summary).isNotEmpty
                    ? "Hello, ${_greetingName(_summary)}"
                    : "Hello",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatTodayLabel(),
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text("Today's Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard(
                label: "Due Today",
                value: _statValue(stats, "dueToday"),
                icon: Icons.today,
                color: Colors.blue,
                width: cardWidth,
              ),
              _statCard(
                label: "Overdue",
                value: _statValue(stats, "overdue"),
                icon: Icons.warning_amber,
                color: Colors.red,
                width: cardWidth,
                onTap: () => _scrollToSection(_overdueKey),
              ),
              _statCard(
                label: "Upcoming (7 days)",
                value: _statValue(stats, "upcoming"),
                icon: Icons.schedule,
                color: Colors.orange,
                width: cardWidth,
                onTap: () => _scrollToSection(_upcomingKey),
              ),
              _statCard(
                label: "Completed",
                value: _statValue(stats, "completed"),
                icon: Icons.check_circle,
                color: Colors.green,
                width: cardWidth,
              ),
            ],
          ),
          SizedBox(height: 20),
          _taskSection(
            title: "Due Today",
            tasks: today,
            emptyLabel: "No tasks due today",
          ),
          SizedBox(height: 16),
          Container(
            key: _overdueKey,
            child: _taskSection(
              title: "Overdue",
              tasks: overdue,
              emptyLabel: "No overdue tasks",
            ),
          ),
          SizedBox(height: 16),
          Container(
            key: _upcomingKey,
            child: _taskSection(
              title: "Upcoming (next 7 days)",
              tasks: upcoming,
              emptyLabel: "No upcoming tasks",
            ),
          ),
        ],
      ),
    );
  }
}
 
 