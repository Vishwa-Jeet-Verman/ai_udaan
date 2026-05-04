import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/calendar_event_model.dart';
import '../../providers/calendar_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/user_avatar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 12,
      tablet: 20,
      desktop: 24,
    );
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context,
      tablet: 1100,
      desktop: 1280,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.calendar),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: UserAvatar(radius: 16, fontSize: 12),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              12,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useSplitLayout =
                    constraints.maxWidth >= AppResponsive.tabletBreakpoint;

                if (!useSplitLayout) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildCalendarCard(context),
                        const SizedBox(height: 12),
                        _buildAgendaPanel(context),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildCalendarCard(context)),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildAgendaPanel(context),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventSheet(context),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, _) {
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => provider.eventsForDay(day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                leftChevronIcon:
                    Icon(Icons.chevron_left, color: Colors.grey[700]),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: Colors.grey[700]),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                weekendStyle: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(fontSize: 15),
                weekendTextStyle: const TextStyle(fontSize: 15),
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppTheme.primaryColor, width: 1.5),
                ),
                todayTextStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                markerDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgendaPanel(BuildContext context) {
    final selectedDate = _selectedDay ?? _focusedDay;

    return Consumer<CalendarProvider>(
      builder: (context, provider, _) {
        final dayEvents = provider.eventsForDay(selectedDate);

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.agenda,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    if (provider.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event_note_outlined,
                        color: Theme.of(context).colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(selectedDate),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (provider.error != null)
                  _emptyState(context, provider.error!)
                else if (dayEvents.isEmpty)
                  _emptyState(context, AppLocalizations.of(context)!.noEventsForDay)
                else
                  ...dayEvents.map((e) => _eventTile(context, e, provider)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context, String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(msg, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _eventTile(
      BuildContext context, CalendarEvent event, CalendarProvider provider) {
    final timeStr = DateFormat('h:mm a').format(event.startAt);
    final isReminder = event.eventtype == 'user';

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        try {
          await provider.deleteEvent(event.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.eventDeleted)),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.failedToDeleteEvent)),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isReminder
              ? Colors.amber.withValues(alpha: 0.08)
              : AppTheme.softGreenBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isReminder
                ? Colors.amber.withValues(alpha: 0.4)
                : AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isReminder ? Icons.alarm : Icons.event,
              size: 18,
              color: isReminder ? Colors.amber[700] : AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (event.description.isNotEmpty)
                    Text(
                      event.description,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              timeStr,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Add Event / Reminder Bottom Sheet ────────────────────────────────────
  void _showAddEventSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddEventSheet(initialDate: _selectedDay ?? _focusedDay),
    );
  }
}

// ─── Add Event Sheet ──────────────────────────────────────────────────────────
class _AddEventSheet extends StatefulWidget {
  final DateTime initialDate;
  const _AddEventSheet({required this.initialDate});

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isReminder = false;
  bool _hasDuration = false;
  int _durationMinutes = 60;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final startAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Validate that event is not in the past
    final now = DateTime.now();
    if (startAt.isBefore(now)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cannotCreateEventInPast),
          ),
        );
      }
      return;
    }

    setState(() => _loading = true);

    try {
      await context.read<CalendarProvider>().createEvent(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            startAt: startAt,
            duration: _hasDuration
                ? Duration(minutes: _durationMinutes)
                : Duration.zero,
            eventtype: 'user',
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isReminder ? AppLocalizations.of(context)!.reminderSetOnMoodle : AppLocalizations.of(context)!.eventCreatedOnMoodle),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  _isReminder ? AppLocalizations.of(context)!.setReminder : AppLocalizations.of(context)!.addEvent,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // Toggle: Event / Reminder
            Row(
              children: [
                Text(AppLocalizations.of(context)!.reminder),
                const SizedBox(width: 8),
                Switch(
                  value: _isReminder,
                  onChanged: (v) => setState(() => _isReminder = v),
                  activeThumbColor: AppTheme.primaryColor,
                ),
                const SizedBox(width: 4),
                Icon(
                  _isReminder ? Icons.alarm : Icons.event,
                  size: 18,
                  color: _isReminder ? Colors.amber[700] : AppTheme.primaryColor,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Title
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: _isReminder ? AppLocalizations.of(context)!.reminderTitle : AppLocalizations.of(context)!.eventTitle,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.titleRequired : null,
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.descriptionOptional,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Date & Time row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat('MMM d, y').format(_selectedDate)),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(_selectedTime.format(context)),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Duration (only for events)
            if (!_isReminder) ...[
              Row(
                children: [
                  Checkbox(
                    value: _hasDuration,
                    onChanged: (v) => setState(() => _hasDuration = v ?? false),
                    activeColor: AppTheme.primaryColor,
                  ),
                  Text(AppLocalizations.of(context)!.setDuration),
                  if (_hasDuration) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        value: _durationMinutes.toDouble(),
                        min: 15,
                        max: 480,
                        divisions: 31,
                        label: '${_durationMinutes}m',
                        activeColor: AppTheme.primaryColor,
                        onChanged: (v) =>
                            setState(() => _durationMinutes = v.round()),
                      ),
                    ),
                    Text('${_durationMinutes}m'),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isReminder ? AppLocalizations.of(context)!.setReminder : AppLocalizations.of(context)!.createEvent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
