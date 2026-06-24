import 'package:flutter/material.dart';
import '../services/api_service.dart';

const Color _kOrange = Color(0xFFFF7500);
const Color _kText   = Color(0xFF1A1A1A);
const Color _kGray   = Color(0xFF888888);
const Color _kBorder = Color(0xFFE0E0E0);
const Color _kRed    = Color(0xFFE53935);

// ─── Models ───────────────────────────────────────────────────────────────────
class _MonitorStock {
  const _MonitorStock({
    required this.code,
    required this.name,
    required this.category,
    required this.price,
    required this.change,
    required this.changePos,
    required this.str,
    required this.rsi,
    required this.bid,
    this.score,
    required this.debate,
  });
  final String code, name, category, price, change;
  final bool changePos, debate;
  final int str, rsi;
  final double bid;
  final int? score;
}

class _ConferenceEntry {
  const _ConferenceEntry({
    required this.time,
    required this.field,
    required this.opinion,
    required this.score,
    required this.type,
  });
  final String time, field, opinion, type;
  final int score;
}

class _ConferenceGroup {
  const _ConferenceGroup({
    required this.stockName,
    required this.stockCode,
    required this.entries,
    required this.decision,
  });
  final String stockName, stockCode, decision;
  final List<_ConferenceEntry> entries;
}

// ─── ShortPage ────────────────────────────────────────────────────────────────
class ShortPage extends StatefulWidget {
  const ShortPage({super.key});

  @override
  State<ShortPage> createState() => _ShortPageState();
}

class _ShortPageState extends State<ShortPage> {
  String _filter = 'all';
  bool _loadingMonitor = true;
  bool _loadingConference = true;
  List<_MonitorStock> _monitorData = [];
  List<_ConferenceGroup> _conferenceData = [];

  @override
  void initState() {
    super.initState();
    _loadMonitor();
    _loadConference('all');
  }

  Future<void> _loadMonitor() async {
    setState(() => _loadingMonitor = true);
    try {
      final raw = await fetchMonitoring();
      if (!mounted) return;
      setState(() {
        _monitorData = raw.map((m) => _MonitorStock(
          code: m['code'] as String,
          name: m['name'] as String,
          category: m['category'] as String,
          price: m['price'] as String,
          change: m['change'] as String,
          changePos: m['change_positive'] as bool,
          str: m['str_val'] as int,
          rsi: m['rsi'] as int,
          bid: (m['bid'] as num).toDouble(),
          score: m['score'] as int?,
          debate: m['debate'] as bool,
        )).toList();
        _loadingMonitor = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMonitor = false);
    }
  }

  Future<void> _loadConference(String filter) async {
    setState(() => _loadingConference = true);
    try {
      final raw = await fetchConference(filter);
      if (!mounted) return;
      setState(() {
        _conferenceData = raw.map((g) => _ConferenceGroup(
          stockName: g['stock_name'] as String,
          stockCode: g['stock_code'] as String,
          decision: g['decision'] as String,
          entries: (g['entries'] as List).map((e) => _ConferenceEntry(
            time: e['time'] as String,
            field: e['field'] as String,
            opinion: e['opinion'] as String,
            score: e['score'] as int,
            type: e['type'] as String,
          )).toList(),
        )).toList();
        _loadingConference = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingConference = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonitoringSection(),
          const SizedBox(height: 28),
          _buildConferenceSection(),
        ],
      ),
    );
  }

  // ─── Monitoring ─────────────────────────────────────────────────────────────
  Widget _buildMonitoringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('monitoring.', style: TextStyle(
              color: _kText, fontSize: 22, fontWeight: FontWeight.w900)),
          const Spacer(),
          GestureDetector(
            onTap: _loadMonitor,
            child: const Row(children: [
              Icon(Icons.refresh, color: _kGray, size: 16),
              SizedBox(width: 4),
              Text('새로고침', style: TextStyle(color: _kGray, fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(5)),
              ),
              child: const Row(children: [
                _MH('code', flex: 2),
                _MH('name', flex: 2),
                _MH('category', flex: 2),
                _MH('price(%)', flex: 4),
                _MH('str', flex: 1),
                _MH('rsi', flex: 1),
                _MH('bid', flex: 2),
                _MH('score', flex: 1),
                _MH('debate', flex: 2),
              ]),
            ),
            const Divider(color: _kBorder, height: 1),
            if (_loadingMonitor)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kOrange)),
              )
            else ...[
              for (final stock in _monitorData) ...[
                _MonitorRow(stock: stock),
                const Divider(color: _kBorder, height: 1),
              ],
              if (_monitorData.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('모니터링 종목 없음',
                        style: TextStyle(color: _kGray, fontSize: 12)),
                  ),
                ),
              for (int i = 0; i < 3; i++) const SizedBox(height: 34),
            ],
          ]),
        ),
      ],
    );
  }

  // ─── Conference ──────────────────────────────────────────────────────────────
  Widget _buildConferenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('conference.', style: TextStyle(
              color: _kText, fontSize: 22, fontWeight: FontWeight.w900)),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(7),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['all', 'hold', 'buy', 'sell'].map((f) {
                final selected = _filter == f;
                return GestureDetector(
                  onTap: () {
                    setState(() => _filter = f);
                    _loadConference(f);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: selected ? _kText : _kGray,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        if (_loadingConference)
          const Center(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _kOrange),
          ))
        else if (_conferenceData.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                '해당 조건의 컨퍼런스 결과가 없습니다.',
                style: const TextStyle(color: _kGray, fontSize: 13),
              ),
            ),
          )
        else
          for (final group in _conferenceData) ...[
            _ConferenceCard(group: group),
            const SizedBox(height: 20),
          ],
      ],
    );
  }
}

// ─── Monitoring Widgets ───────────────────────────────────────────────────────
class _MH extends StatelessWidget {
  const _MH(this.text, {required this.flex});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child:
            Text(text, style: const TextStyle(color: _kGray, fontSize: 10)),
      );
}

class _MonitorRow extends StatelessWidget {
  const _MonitorRow({required this.stock});
  final _MonitorStock stock;

  Color _rsiColor(int rsi) {
    if (rsi <= 40) return _kOrange;
    if (rsi >= 70) return _kRed;
    return _kText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(children: [
        Expanded(
            flex: 2,
            child: Text(stock.code,
                style: const TextStyle(color: _kText, fontSize: 11))),
        Expanded(
            flex: 2,
            child: Text(stock.name,
                style: const TextStyle(color: _kText, fontSize: 11))),
        Expanded(
            flex: 2,
            child: Text(stock.category,
                style: const TextStyle(color: _kText, fontSize: 11))),
        Expanded(
          flex: 4,
          child: RichText(
            text: TextSpan(
              text: stock.price,
              style: const TextStyle(color: _kText, fontSize: 11),
              children: [
                TextSpan(
                  text: '(${stock.change})',
                  style: TextStyle(
                    color: stock.changePos ? _kOrange : _kRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '${stock.str}',
            style: TextStyle(
              color: stock.str > 100 ? _kOrange : _kText,
              fontSize: 11,
              fontWeight:
                  stock.str > 100 ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '${stock.rsi}',
            style: TextStyle(
              color: _rsiColor(stock.rsi),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
            flex: 2,
            child: Text('${stock.bid}',
                style: const TextStyle(color: _kText, fontSize: 11))),
        Expanded(
          flex: 1,
          child: Text(
            stock.score != null ? '${stock.score}' : '-',
            style: const TextStyle(color: _kText, fontSize: 11),
          ),
        ),
        Expanded(flex: 2, child: _DebateBadge(stock.debate)),
      ]),
    );
  }
}

class _DebateBadge extends StatelessWidget {
  const _DebateBadge(this.isYes);
  final bool isYes;

  @override
  Widget build(BuildContext context) {
    if (isYes) {
      return const Text(
        'yes!',
        style: TextStyle(
            color: _kOrange, fontWeight: FontWeight.w700, fontSize: 11),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'no!',
        style: TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Conference Widgets ───────────────────────────────────────────────────────
class _ConferenceCard extends StatelessWidget {
  const _ConferenceCard({required this.group});
  final _ConferenceGroup group;

  Color get _headerColor => switch (group.decision) {
        'BUY!'   => const Color(0xFF1E88E5),
        'SALES!' => _kRed,
        _        => const Color(0xFF1A1A1A),
      };

  String get _tag => switch (group.decision) {
        'BUY!'   => '#buy',
        'SALES!' => '#sell',
        _        => '#hold',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          decoration: BoxDecoration(
            color: _headerColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(5)),
          ),
          child: Center(
            child: Text(
              '${group.stockName}(${group.stockCode}) $_tag',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          color: const Color(0xFFF5F5F5),
          child: const Row(children: [
            _CH('time', flex: 3),
            _CH('field', flex: 2),
            _CH('opinion', flex: 5),
            _CH('score', flex: 1),
            _CH('debate', flex: 1),
          ]),
        ),
        const Divider(color: _kBorder, height: 1),
        for (int i = 0; i < group.entries.length; i++) ...[
          _ConferenceRow(entry: group.entries[i]),
          if (i < group.entries.length - 1)
            const Divider(color: _kBorder, height: 1),
        ],
      ]),
    );
  }
}

class _CH extends StatelessWidget {
  const _CH(this.text, {required this.flex});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child:
            Text(text, style: const TextStyle(color: _kGray, fontSize: 10)),
      );
}

class _ConferenceRow extends StatelessWidget {
  const _ConferenceRow({required this.entry});
  final _ConferenceEntry entry;

  Color get _typeColor => switch (entry.type) {
        'buy'  => _kOrange,
        'sale' => _kRed,
        _      => _kGray,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(entry.time,
                style: const TextStyle(
                    color: _kGray, fontSize: 10, height: 1.4)),
          ),
          Expanded(
            flex: 2,
            child: Text(entry.field,
                style: const TextStyle(
                    color: _kText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 5,
            child: Text(entry.opinion,
                style: const TextStyle(
                    color: _kGray, fontSize: 10, height: 1.5)),
          ),
          Expanded(
            flex: 1,
            child: Text(entry.score.toString(),
                style: const TextStyle(color: _kText, fontSize: 10)),
          ),
          Expanded(
            flex: 1,
            child: Text('${entry.type}.',
                style: TextStyle(
                    color: _typeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
