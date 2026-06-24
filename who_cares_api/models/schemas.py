from pydantic import BaseModel
from typing import Optional, List


# ─── Auth ─────────────────────────────────────────────────────────────────────
class PinRequest(BaseModel):
    pin: str

class PinResponse(BaseModel):
    success: bool


# ─── Balance ──────────────────────────────────────────────────────────────────
class BalanceResponse(BaseModel):
    time: str
    deposit: int
    tradeable: int
    stock_value: int
    today_buy: int
    today_sell: int
    total_assets: int


# ─── Report ───────────────────────────────────────────────────────────────────
class StockRate(BaseModel):
    code: str
    name: str
    rate: float

class ReportResponse(BaseModel):
    date: str
    total_trades: int
    wins: int
    losses: int
    win_rate: int
    top_profit: Optional[StockRate]
    top_loss: Optional[StockRate]
    total_pnl: int


# ─── Trades (relearning) ──────────────────────────────────────────────────────
class AgentEntry(BaseModel):
    field: str
    opinion: str
    score: int
    type: str  # hold / buy / sale

class TradeRecord(BaseModel):
    no: int
    is_profit: bool
    name: str
    code: str
    buy_info: str
    sell_info: str
    mfe: Optional[str]
    mre: str
    analysis: Optional[List[AgentEntry]] = None
    ai_comment: Optional[str] = None
    next_strategy: Optional[str] = None


# ─── Transaction (details) ────────────────────────────────────────────────────
class TransactionRecord(BaseModel):
    time: str
    is_buy: bool
    code: str
    name: str
    count: str
    unit_price: str
    total_amount: str
    result: Optional[str]


# ─── Monitoring ───────────────────────────────────────────────────────────────
class MonitoringStock(BaseModel):
    code: str
    name: str
    category: str
    price: str
    change: str
    change_positive: bool
    str_val: int
    rsi: int
    bid: float
    score: Optional[int]
    debate: bool


# ─── Conference ───────────────────────────────────────────────────────────────
class ConferenceEntry(BaseModel):
    time: str
    field: str
    opinion: str
    score: int
    type: str  # hold / buy / sale

class ConferenceGroup(BaseModel):
    stock_name: str
    stock_code: str
    decision: str   # HOLD / BUY! / SALES!
    entries: List[ConferenceEntry]


# ─── Analysis (schedule / summary / recommendation) ──────────────────────────
class ScheduleItemOut(BaseModel):
    no: int
    time: str
    task: str
    status: str  # completed / active / pending

class ScheduleResponse(BaseModel):
    active_time: str
    active_task: str
    total: int
    completed: int
    pending: int
    items: List[ScheduleItemOut]

class SummaryItem(BaseModel):
    name: str
    type: str  # 호재 / 악재
    topic: str
    reliability: Optional[str]

class SummaryResponse(BaseModel):
    items: List[SummaryItem]
    disclaimer: str

class RecoItem(BaseModel):
    code: str
    name: str
    percent: float
    type: str  # buy. / hold. / sale.
