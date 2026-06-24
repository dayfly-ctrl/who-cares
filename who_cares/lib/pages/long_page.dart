import 'package:flutter/material.dart';
import '../services/api_service.dart';

const Color _kOrange   = Color(0xFFFF7500);
const Color _kText     = Color(0xFF1A1A1A);
const Color _kGray     = Color(0xFF888888);
const Color _kBorder   = Color(0xFFE0E0E0);
const Color _kRed      = Color(0xFFE53935);
const Color _kOrangeBg = Color(0xFFFFF3E8);

// ─── Models ───────────────────────────────────────────────────────────────────
enum _ScheduleStatus { completed, active, pending }

class _ScheduleItem {
  const _ScheduleItem({
    required this.no,
    required this.time,
    required this.task,
    required this.status,
  });
  final int no;
  final String time, task;
  final _ScheduleStatus status;
}

class _SummaryItem {
  const _SummaryItem({
    required this.category,
    required this.type,
    required this.topic,
    this.reliability,
  });
  final String category, type, topic;
  final String? reliability;
}

class _RecoItem {
  const _RecoItem({
    required this.code,
    required this.name,
    required this.percent,
    required this.type,
  });
  final String code, name, type;
  final double percent;
}

// ─── LongPage ─────────────────────────────────────────────────────────────────
class LongPage extends StatefulWidget {
  const LongPage({super.key});

  @override
  State<LongPage> createState() => _LongPageState();
}

class _LongPageState extends State<LongPage> {
  bool _loading = true;

  // Schedule
  List<_ScheduleItem> _schedule = [];
  String _activeTime = '';
  String _activeTask = '';
  int _total = 0, _completed = 0, _pending = 0;

  // Summary
  List<_SummaryItem> _summary = [];
  String _disclaimer = '';

  // Recommendation
  List<_RecoItem> _recos = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadSchedule(), _loadSummary(), _loadRecos()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadSchedule() async {
    try {
      final data = await fetchSchedule();
      if (!mounted) return;
      setState(() {
        _activeTime = data['active_time'] as String;
        _activeTask = data['active_task'] as String;
        _total     = data['total'] as int;
        _completed = data['completed'] as int;
        _pending   = data['pending'] as int;
        _schedule  = (data['items'] as List).map((i) {
          final status = switch (i['status'] as String) {
            'completed' => _ScheduleStatus.completed,
            'active'    => _ScheduleStatus.active,
            _           => _ScheduleStatus.pending,
          };
          return _ScheduleItem(
            no: i['no'] as int,
            time: i['time'] as String,
            task: i['task'] as String,
            status: status,
          );
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadSummary() async {
    try {
      final data = await fetchSummary();
      if (!mounted) return;
      setState(() {
        _disclaimer = data['disclaimer'] as String;
        _summary = (data['items'] as List).map((i) => _SummaryItem(
              category: i['name'] as String,
              type: i['type'] as String,
              topic: i['topic'] as String,
              reliability: i['reliability'] as String?,
            )).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadRecos() async {
    try {
      final data = await fetchRecommendation();
      if (!mounted) return;
      setState(() {
        _recos = data.map((r) => _RecoItem(
              code: r['code'] as String,
              name: r['name'] as String,
              percent: (r['percent'] as num).toDouble(),
              type: r['type'] as String,
            )).toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kOrange),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('analysis.', style: TextStyle(
                color: _kText, fontSize: 22, fontWeight: FontWeight.w900)),
            const Spacer(),
            GestureDetector(
              onTap: _loadAll,
              child: const Row(children: [
                Icon(Icons.refresh, color: _kGray, size: 16),
                SizedBox(width: 4),
                Text('새로고침', style: TextStyle(color: _kGray, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 20),

          // ─── process ────────────────────────────────────────────────────────
          const _SubHeader('process'),
          const SizedBox(height: 12),
          if (_schedule.isNotEmpty) ...[
            _buildNextScheduleCard(),
            const SizedBox(height: 10),
            for (final item in _schedule) _ScheduleRow(item: item),
          ],

          const SizedBox(height: 28),

          // ─── summary ────────────────────────────────────────────────────────
          const _SubHeader('summary'),
          const SizedBox(height: 12),
          _buildSummaryTable(),

          const SizedBox(height: 28),

          // ─── recommendation ─────────────────────────────────────────────────
          const _SubHeader('recommendation'),
          const SizedBox(height: 12),
          _buildRecoTable(),
        ],
      ),
    );
  }

  Widget _buildNextScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _kOrangeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kOrange, width: 2),
                ),
                child:
                    const Icon(Icons.access_time, color: _kOrange, size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('next schedule.',
                      style: TextStyle(color: _kOrange, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(
                    '$_activeTime  $_activeTask',
                    style: const TextStyle(
                      color: _kOrange,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatBox(Icons.format_list_bulleted, '전체 항목', '$_total'),
              _StatBox(Icons.check_circle_outline, '완료', '$_completed'),
              _StatBox(Icons.timer_outlined, '대기 중', '$_pending'),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSummaryTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(5)),
          ),
          child: const Row(children: [
            _TH('name', flex: 2),
            _TH('type', flex: 1),
            _TH('topic', flex: 6),
            _TH('reliabilit', flex: 2),
          ]),
        ),
        const Divider(color: _kBorder, height: 1),
        if (_summary.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
                child: Text('뉴스 데이터 없음',
                    style: TextStyle(color: _kGray, fontSize: 12))),
          )
        else
          for (int i = 0; i < _summary.length; i++) ...[
            _SummaryRow(item: _summary[i]),
            if (i < _summary.length - 1)
              const Divider(color: _kBorder, height: 1),
          ],
        if (_disclaimer.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(5)),
              border: Border(top: BorderSide(color: _kBorder)),
            ),
            child: Text(
              _disclaimer,
              style:
                  const TextStyle(color: _kGray, fontSize: 9, height: 1.6),
            ),
          ),
      ]),
    );
  }

  Widget _buildRecoTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(5)),
          ),
          child: const Row(children: [
            _TH('code', flex: 2),
            _TH('name', flex: 2),
            _TH('chart', flex: 4),
            _TH('percent', flex: 2),
            _TH('type', flex: 1),
          ]),
        ),
        const Divider(color: _kBorder, height: 1),
        if (_recos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
                child: Text('추천 종목 없음',
                    style: TextStyle(color: _kGray, fontSize: 12))),
          )
        else
          for (int i = 0; i < _recos.length; i++) ...[
            _RecoRow(item: _recos[i]),
            if (i < _recos.length - 1)
              const Divider(color: _kBorder, height: 1),
          ],
        const SizedBox(height: 40),
      ]),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────
class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          text,
          style: const TextStyle(
              color: _kText, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, size: 18, color: _kGray),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: _kGray, fontSize: 9)),
      Text(
        value,
        style: const TextStyle(
            color: _kText, fontSize: 20, fontWeight: FontWeight.w800),
      ),
    ]);
  }
}

class _TH extends StatelessWidget {
  const _TH(this.text, {required this.flex});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child:
            Text(text, style: const TextStyle(color: _kGray, fontSize: 10)),
      );
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.item});
  final _ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final isCompleted = item.status == _ScheduleStatus.completed;
    final isActive    = item.status == _ScheduleStatus.active;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: Center(
            child: isCompleted
                ? Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 14),
                  )
                : isActive
                    ? Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _kOrange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _kOrange.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: _kBorder, width: 1.5),
                        ),
                      ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? _kOrange : _kBorder,
                width: isActive ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              SizedBox(
                width: 20,
                child: Text(
                  '${item.no}',
                  style: TextStyle(
                    color: isActive ? _kOrange : _kText,
                    fontSize: 13,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 48,
                child: Text(
                  item.time,
                  style: TextStyle(
                    color: isActive ? _kOrange : _kText,
                    fontSize: 13,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                item.task,
                style: TextStyle(
                  color: isActive ? _kOrange : _kText,
                  fontSize: 13,
                  fontWeight: isActive
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.item});
  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    final typeColor = item.type == '호재' ? _kOrange : _kRed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(item.category,
                style: const TextStyle(color: _kText, fontSize: 11)),
          ),
          Expanded(
            flex: 1,
            child: Text(item.type,
                style: TextStyle(
                    color: typeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 6,
            child: Text(item.topic,
                style: const TextStyle(
                    color: _kGray, fontSize: 10, height: 1.5)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.reliability ?? '-',
              style: const TextStyle(color: _kText, fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoRow extends StatelessWidget {
  const _RecoRow({required this.item});
  final _RecoItem item;

  Color get _typeColor => switch (item.type) {
        'buy.'  => _kOrange,
        'sale.' => _kRed,
        _       => _kGray,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Expanded(
            flex: 2,
            child: Text(item.code,
                style: const TextStyle(color: _kText, fontSize: 11))),
        Expanded(
            flex: 2,
            child: Text(item.name,
                style: const TextStyle(color: _kText, fontSize: 11))),
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.percent,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_kOrange),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            '${(item.percent * 100).toInt()}%',
            style: const TextStyle(color: _kText, fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            item.type,
            style: TextStyle(
                color: _typeColor,
                fontSize: 11,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ]),
    );
  }
}
