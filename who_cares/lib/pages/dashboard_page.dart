import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'short_page.dart';
import 'long_page.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const Color _kOrange  = Color(0xFFFF7500);
const Color _kBg      = Color(0xFF0D0D0D);
const Color _kSurface = Color(0xFF161616);
const Color _kBorder  = Color(0xFF262626);
const Color _kGray    = Color(0xFF777777);
const Color _kGreen   = Color(0xFF4CAF50);
const Color _kRed     = Color(0xFFE53935);

// ─── Enums ────────────────────────────────────────────────────────────────────
enum _Tab { borad, short, long }

enum _ViewState { normal, balanceLocked, reportCollecting }

// ─── Data Models ──────────────────────────────────────────────────────────────
class _TradeRecord {
  const _TradeRecord({
    required this.no,
    required this.isProfit,
    required this.name,
    required this.code,
    required this.buyInfo,
    required this.sellInfo,
    this.mfe,
    required this.mre,
  });
  final int no;
  final bool isProfit;
  final String name, code, buyInfo, sellInfo, mre;
  final String? mfe;
}

class _Transaction {
  const _Transaction({
    required this.time,
    required this.isBuy,
    required this.code,
    required this.name,
    required this.count,
    required this.unitPrice,
    required this.totalAmount,
    this.result,
  });
  final String time, code, name, count, unitPrice, totalAmount;
  final bool isBuy;
  final String? result;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
String _fmtNum(num n) {
  final abs = n.abs().toInt();
  final str = abs.toString();
  final buf = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
    buf.write(str[i]);
  }
  return '${n < 0 ? '-' : ''}$buf원';
}

// Wide screen = light background, so text must be dark.
Color _textColor(BuildContext context) =>
    MediaQuery.of(context).size.width > 700
        ? const Color(0xFF1A1A1A)
        : Colors.white;

// ─── Dashboard Page ───────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  _Tab _tab = _Tab.borad;
  _ViewState _viewState = _ViewState.normal;
  int? _expandedTrade;
  int _detailTab = 0;

  // API data
  Map<String, dynamic>? _balanceData;
  Map<String, dynamic>? _reportData;
  List<dynamic> _tradesData = [];
  List<dynamic> _txData = [];

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadReport();
    _loadTrades();
    _loadTransactions(0);
  }

  Future<void> _loadBalance() async {
    try {
      final data = await fetchBalance();
      if (mounted) setState(() => _balanceData = data);
    } catch (_) {}
  }

  Future<void> _loadReport() async {
    try {
      final data = await fetchReport();
      if (mounted) setState(() => _reportData = data);
    } catch (_) {}
  }

  Future<void> _loadTrades() async {
    try {
      final data = await fetchTrades();
      if (mounted) setState(() => _tradesData = data);
    } catch (_) {}
  }

  Future<void> _loadTransactions(int tabIndex) async {
    try {
      final tab = tabIndex == 0 ? 'short' : 'long';
      final data = await fetchTransactions(tab);
      if (mounted) setState(() => _txData = data);
    } catch (_) {}
  }

  List<_TradeRecord> get _trades => _tradesData.map((t) => _TradeRecord(
        no: t['no'] as int,
        isProfit: t['is_profit'] as bool,
        name: t['name'] as String,
        code: t['code'] as String,
        buyInfo: t['buy_info'] as String,
        sellInfo: t['sell_info'] as String,
        mfe: t['mfe'] as String?,
        mre: t['mre'] as String,
      )).toList();

  List<_Transaction> get _transactions => _txData.map((t) => _Transaction(
        time: t['time'] as String,
        isBuy: t['is_buy'] as bool,
        code: t['code'] as String,
        name: t['name'] as String,
        count: t['count'] as String,
        unitPrice: t['unit_price'] as String,
        totalAmount: t['total_amount'] as String,
        result: t['result'] as String?,
      )).toList();

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width > 700;

  bool _isDark(BuildContext context) =>
      _tab == _Tab.borad && !_isWide(context);

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final isWide = _isWide(context);

    Widget body = Stack(
      children: [
        Column(
          children: [
            _buildHeader(isDark: isDark),
            Expanded(
              child: switch (_tab) {
                _Tab.borad => _buildBoradScrollView(isWide: isWide),
                _Tab.short => const ShortPage(),
                _Tab.long  => const LongPage(),
              },
            ),
          ],
        ),
        if (isDark && _viewState == _ViewState.balanceLocked)
          _PinOverlay(
            onDismiss: () => setState(() => _viewState = _ViewState.normal),
          ),
      ],
    );

    if (isWide) {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: body,
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? _kBg : Colors.white,
      floatingActionButton: _tab == _Tab.borad
          ? _StateSwitcherFab(
              current: _viewState,
              onChanged: (s) => setState(() {
                _viewState = s;
                _expandedTrade = null;
              }),
            )
          : null,
      body: SafeArea(child: body),
    );
  }

  Widget _buildBoradScrollView({bool isWide = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceSection(),
          const SizedBox(height: 24),
          _buildReportSection(),
          const SizedBox(height: 24),
          _buildRelearningSection(),
          const SizedBox(height: 24),
          _buildDetailsSection(),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader({required bool isDark}) {
    final inactiveColor = isDark ? Colors.white : const Color(0xFF444444);
    return Container(
      color: isDark ? _kBg : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          const Text(
            'who cares?',
            style: TextStyle(
              color: _kOrange,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          for (final tab in _Tab.values)
            GestureDetector(
              onTap: () => setState(() => _tab = tab),
              child: Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Text(
                  tab.name,
                  style: TextStyle(
                    color: _tab == tab ? _kOrange : inactiveColor,
                    fontWeight:
                        _tab == tab ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Balance Section ─────────────────────────────────────────────────────────
  Widget _buildBalanceSection() {
    final locked = _viewState != _ViewState.normal;
    final time = _balanceData?['time'] as String? ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const _SectionLabel('balance.'),
          const Spacer(),
          if (!locked) ...[
            if (time.isNotEmpty)
              Text(time, style: const TextStyle(color: _kGray, fontSize: 11)),
            const SizedBox(width: 8),
            _ChipButton('청구기', onTap: _loadBalance),
          ],
        ]),
        const SizedBox(height: 10),
        if (locked)
          _LockedBalanceView(
            onTap: () =>
                setState(() => _viewState = _ViewState.balanceLocked),
          )
        else if (_balanceData == null)
          const _LoadingCell()
        else
          _BalanceContent(data: _balanceData!),
      ],
    );
  }

  // ─── Report Section ──────────────────────────────────────────────────────────
  Widget _buildReportSection() {
    final collecting = _viewState == _ViewState.reportCollecting;
    final r = _reportData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const _SectionLabel('report.'),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Row(children: [
              Text(
                r?['date'] as String? ?? '날짜 로딩 중',
                style: const TextStyle(color: _kGray, fontSize: 12),
              ),
              const Icon(Icons.arrow_drop_down, color: _kGray, size: 18),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        if (collecting)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Center(
                child: Text(
                  '장 마감 후 확인 가능합니다. (오후 3시 30분)',
                  style: const TextStyle(color: _kGray, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Available after the closing of the stock market\nPlease check after 15:30(KST)',
                  style: TextStyle(
                      color: _kGray.withValues(alpha: 0.6), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
            ]),
          )
        else if (r == null)
          const _LoadingCell()
        else ...[
          _ReportRow(
            '총 거래 (승/패), 승률',
            '${r['total_trades']}건 (${r['wins']}승, ${r['losses']}패), ${r['win_rate']}%',
          ),
          const SizedBox(height: 7),
          if (r['top_profit'] != null)
            _ReportRow(
              '최고 수익 종목',
              '${r['top_profit']['code']} ${r['top_profit']['name']}',
              trailing:
                  '+${(r['top_profit']['rate'] as num).toStringAsFixed(2)}%',
              positive: true,
            ),
          const SizedBox(height: 7),
          if (r['top_loss'] != null)
            _ReportRow(
              '최고 손실 종목',
              '${r['top_loss']['code']} ${r['top_loss']['name']}',
              trailing:
                  '${(r['top_loss']['rate'] as num).toStringAsFixed(2)}%',
              positive: false,
            ),
          const SizedBox(height: 7),
          _ReportRow(
            '총 손익',
            '',
            trailing:
                '${(r['total_pnl'] as int) >= 0 ? '+' : ''}${_fmtNum(r['total_pnl'] as int)}',
            positive: (r['total_pnl'] as int) >= 0,
            bold: true,
          ),
        ],
      ],
    );
  }

  // ─── Relearning Section ──────────────────────────────────────────────────────
  Widget _buildRelearningSection() {
    final hasData = _viewState != _ViewState.reportCollecting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('relearning to db.'),
        const SizedBox(height: 10),
        if (!hasData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(children: [
              Center(
                child: Text(
                  '리포트 데이터가 존재하지 않습니다.\n장 마감 후 다시 확인해주세요. (오후 3시 30분)',
                  style: const TextStyle(color: _kGray, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Report data does not exist.\nPlease check again after closing the market. (KST 15:30)',
                  style: TextStyle(
                      color: _kGray.withValues(alpha: 0.6), fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ]),
          )
        else if (_tradesData.isEmpty)
          const _LoadingCell()
        else
          _RelearningTable(
            trades: _trades,
            expandedIndex: _expandedTrade,
            onToggle: (i) => setState(
              () => _expandedTrade = _expandedTrade == i ? null : i,
            ),
          ),
      ],
    );
  }

  // ─── Details Section ─────────────────────────────────────────────────────────
  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const _SectionLabel('details of purchase/sale.'),
          const Spacer(),
          _TabToggle(
            tabs: const ['short', 'long'],
            selectedIndex: _detailTab,
            onChanged: (i) {
              setState(() {
                _detailTab = i;
                _txData = [];
              });
              _loadTransactions(i);
            },
          ),
        ]),
        const SizedBox(height: 10),
        if (_txData.isEmpty)
          const _LoadingCell()
        else
          _TransactionTable(transactions: _transactions),
      ],
    );
  }
}

// ─── Loading placeholder ──────────────────────────────────────────────────────
class _LoadingCell extends StatelessWidget {
  const _LoadingCell();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kOrange),
      ),
    );
  }
}

// ─── Balance Content ──────────────────────────────────────────────────────────
class _BalanceContent extends StatelessWidget {
  const _BalanceContent({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final buyAmt = data['today_buy'] as int;
    final sellAmt = data['today_sell'] as int;
    return Column(
      children: [
        _BalRow('예수금', _fmtNum(data['deposit'] as int)),
        _BalRow('거래 가능 금액', _fmtNum(data['tradeable'] as int)),
        _BalRow('보유 주식 평가액', _fmtNum(data['stock_value'] as int)),
        _BalRowDouble(
          '오늘 거래 금액(매수,매도)',
          '+${_fmtNum(buyAmt)}',
          '-${_fmtNum(sellAmt)}',
        ),
        const Divider(color: _kBorder, height: 16),
        _BalRow('총 자산', _fmtNum(data['total_assets'] as int), bold: true),
      ],
    );
  }
}

class _BalRow extends StatelessWidget {
  const _BalRow(this.label, this.value, {this.bold = false});
  final String label, value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(children: [
        Text(label, style: const TextStyle(color: _kGray, fontSize: 12)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: _textColor(context),
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ]),
    );
  }
}

class _BalRowDouble extends StatelessWidget {
  const _BalRowDouble(this.label, this.buy, this.sell);
  final String label, buy, sell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(children: [
        Text(label, style: const TextStyle(color: _kGray, fontSize: 12)),
        const Spacer(),
        Text(buy, style: const TextStyle(color: _kGreen, fontSize: 13)),
        const SizedBox(width: 4),
        const Text('/', style: TextStyle(color: _kGray, fontSize: 13)),
        const SizedBox(width: 4),
        Text(sell, style: const TextStyle(color: _kRed, fontSize: 13)),
      ]),
    );
  }
}

// ─── Locked Balance View ──────────────────────────────────────────────────────
class _LockedBalanceView extends StatelessWidget {
  const _LockedBalanceView({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRect(
        child: Stack(children: [
          Column(children: [
            for (int i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Container(
                    width: 110 + (i % 3) * 20.0,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 80 + (i % 2) * 20.0,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ]),
              ),
          ]),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: _kBg.withValues(alpha: 0.25)),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Icon(Icons.lock_outline,
                  color: _kOrange.withValues(alpha: 0.8), size: 28),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Report Row ───────────────────────────────────────────────────────────────
class _ReportRow extends StatelessWidget {
  const _ReportRow(
    this.label,
    this.value, {
    this.trailing,
    this.positive,
    this.bold = false,
  });
  final String label, value;
  final String? trailing;
  final bool? positive;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: const TextStyle(color: _kGray, fontSize: 12)),
      if (value.isNotEmpty) ...[
        const SizedBox(width: 8),
        Text(value, style: TextStyle(color: _textColor(context), fontSize: 13)),
      ],
      const Spacer(),
      if (trailing != null)
        Text(
          trailing!,
          style: TextStyle(
            color: positive == true ? _kGreen : _kRed,
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
    ]);
  }
}

// ─── Relearning Table ─────────────────────────────────────────────────────────
class _RelearningTable extends StatelessWidget {
  const _RelearningTable({
    required this.trades,
    required this.expandedIndex,
    required this.onToggle,
  });
  final List<_TradeRecord> trades;
  final int? expandedIndex;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: const [
            _TC('no.', flex: 1, header: true),
            _TC('type', flex: 2, header: true),
            _TC('name', flex: 4, header: true),
            _TC('buy', flex: 3, header: true),
            _TC('sell', flex: 3, header: true),
            _TC('MFE', flex: 2, header: true),
            _TC('MRE', flex: 2, header: true),
          ]),
        ),
        const Divider(color: _kBorder, height: 1),
        for (int i = 0; i < trades.length; i++) ...[
          GestureDetector(
            onTap: () => onToggle(i),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                _TC('${trades[i].no}', flex: 1),
                Expanded(flex: 2, child: _TypeBadge(trades[i].isProfit)),
                _TC('${trades[i].name}(${trades[i].code})', flex: 4),
                _TC(trades[i].buyInfo, flex: 3),
                _TC(trades[i].sellInfo, flex: 3),
                _TC(
                  trades[i].mfe ?? '-',
                  flex: 2,
                  color: trades[i].mfe != null ? _kGreen : null,
                ),
                _TC(trades[i].mre, flex: 2, color: _kRed),
              ]),
            ),
          ),
          if (expandedIndex == i) _TradeAnalysisPanel(trade: trades[i]),
          const Divider(color: _kBorder, height: 1),
        ],
      ],
    );
  }
}

class _TC extends StatelessWidget {
  const _TC(this.text, {required this.flex, this.header = false, this.color});
  final String text;
  final int flex;
  final bool header;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          color: color ?? (header ? _kGray : _textColor(context)),
          fontSize: header ? 10 : 11,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.isProfit);
  final bool isProfit;

  @override
  Widget build(BuildContext context) {
    final color = isProfit ? _kGreen : _kRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        isProfit ? '수익' : '손실',
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Trade Analysis Panel ─────────────────────────────────────────────────────
class _TradeAnalysisPanel extends StatelessWidget {
  const _TradeAnalysisPanel({required this.trade});
  final _TradeRecord trade;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(left: BorderSide(color: _kOrange, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnalysisRow(Icons.candlestick_chart, '패턴 분석', '매수 의견(70%)'),
          _AnalysisRow(Icons.trending_up, '수급 분석', '매수 의견(70%)'),
          _AnalysisRow(Icons.newspaper, '뉴스 감성가', '매수 의견 없음'),
          _AnalysisRow(Icons.shield_outlined, '리스크 설정관', '매수 의견(70%)'),
          const SizedBox(height: 10),
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _kOrange,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'AI COMMENT',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text('보통',
                  style: TextStyle(fontSize: 10, color: _kGray)),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(
            '패턴 분석\n'
            '피날레 143.85 근처에서 보유 중 입니다. 언제까지가 필연적인 101Z월의 처럼 보면 후 반등이 '
            '될 경우 시장 진격에 맞게 준비하는 것이 좋습니다.\n'
            '패턴값이 100이하로 떨어지면 상황에 맞게 준비하는 것이 좋습니다.\n'
            '패드 언팔이 거의 없어서 추가 상승 가능성이 낮습니다.',
            style: TextStyle(color: _kGray, fontSize: 11, height: 1.6),
          ),
          const SizedBox(height: 10),
          const Text(
            '다음 전략',
            style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'IF (전략이가 청산되고 있다, 현재 가격이 수익권 진입 이후 이격치)\n'
            '#NO (N봉수익조건이 모두 3봉 이상으로 떨어지는 경우)\n'
            'AND (이월모드의 3봉 이상으로 이격도 진입)\n'
            'THEN (패도 수익 후 +2% 이상 익절 비율 설정)',
            style: TextStyle(
              color: _kGray,
              fontSize: 10,
              height: 1.8,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  const _AnalysisRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 13, color: _kGray),
        const SizedBox(width: 6),
        Expanded(
            child: Text(label,
                style: const TextStyle(color: _kGray, fontSize: 11))),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }
}

// ─── Transaction Table ────────────────────────────────────────────────────────
class _TransactionTable extends StatelessWidget {
  const _TransactionTable({required this.transactions});
  final List<_Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: const [
          _TxC('time', flex: 4, header: true),
          _TxC('type', flex: 2, header: true),
          _TxC('code', flex: 2, header: true),
          _TxC('name', flex: 2, header: true),
          _TxC('count', flex: 2, header: true),
          _TxC('price(total)', flex: 4, header: true),
          _TxC('result', flex: 3, header: true),
        ]),
      ),
      const Divider(color: _kBorder, height: 1),
      for (final tx in transactions)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            _TxC(tx.time, flex: 4),
            Expanded(
              flex: 2,
              child: Text(
                tx.isBuy ? 'buy' : 'sell',
                style: TextStyle(
                  color: tx.isBuy ? _kGreen : _kRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _TxC(tx.code, flex: 2),
            _TxC(tx.name, flex: 2),
            _TxC(tx.count, flex: 2),
            _TxC('${tx.unitPrice}\n(${tx.totalAmount})', flex: 4),
            _TxC(
              tx.result ?? '-',
              flex: 3,
              color: tx.result == null
                  ? _kGray
                  : (tx.result!.startsWith('+') ? _kGreen : _kRed),
            ),
          ]),
        ),
    ]);
  }
}

class _TxC extends StatelessWidget {
  const _TxC(this.text, {required this.flex, this.header = false, this.color});
  final String text;
  final int flex;
  final bool header;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          color: color ?? (header ? _kGray : _textColor(context)),
          fontSize: 10,
          height: 1.4,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }
}

// ─── PIN Overlay ──────────────────────────────────────────────────────────────
class _PinOverlay extends StatelessWidget {
  const _PinOverlay({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                border: Border.all(color: _kOrange, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kOrange, width: 2),
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: _kOrange, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please enter your PIN number.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '5  ✱  ✱  ✱  ✱  ✱',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared Small Widgets ─────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _textColor(context),
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: const TextStyle(color: _kGray, fontSize: 11)),
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  const _TabToggle({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabs.length, (i) {
        final selected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              tabs[i],
              style: TextStyle(
                color: selected ? _textColor(context) : _kGray,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Demo State Switcher FAB ──────────────────────────────────────────────────
class _StateSwitcherFab extends StatelessWidget {
  const _StateSwitcherFab({required this.current, required this.onChanged});
  final _ViewState current;
  final ValueChanged<_ViewState> onChanged;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      backgroundColor: _kSurface,
      onPressed: () => _showMenu(context),
      child: const Icon(Icons.tune, color: _kOrange, size: 18),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demo State',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final s in _ViewState.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  s == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: s == current ? _kOrange : _kGray,
                  size: 18,
                ),
                title: Text(
                  switch (s) {
                    _ViewState.normal => '01-01. Normal',
                    _ViewState.balanceLocked => '01-01-02. Balance Lock',
                    _ViewState.reportCollecting =>
                      '01-01-03. Report Collecting',
                  },
                  style: TextStyle(
                    color: s == current ? Colors.white : _kGray,
                    fontSize: 13,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onChanged(s);
                },
              ),
          ],
        ),
      ),
    );
  }
}
