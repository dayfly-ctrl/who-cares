from datetime import date as date_type
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from database import get_db
from models.db_models import Transaction
from models.schemas import ReportResponse, StockRate

router = APIRouter()


@router.get("/", response_model=ReportResponse)
def get_report(
    date: str = Query(default=None, description="YYYY-MM-DD (기본: 오늘)"),
    db: Session = Depends(get_db),
):
    target = date or str(date_type.today())

    txs = (db.query(Transaction)
           .filter(Transaction.trade_date == target,
                   Transaction.result.isnot(None),
                   Transaction.is_buy == False)
           .all())

    wins   = [t for t in txs if t.result > 0]
    losses = [t for t in txs if t.result < 0]
    total  = len(txs)
    total_pnl = sum(t.result for t in txs)
    win_rate = int(len(wins) / total * 100) if total else 0

    top_profit = max(wins,   key=lambda t: t.result, default=None)
    top_loss   = min(losses, key=lambda t: t.result, default=None)

    def to_rate(tx: Transaction) -> StockRate:
        rate = tx.result / (tx.unit_price * tx.count) * 100
        return StockRate(code=tx.code, name=tx.name, rate=round(rate, 2))

    # Fallback to mock if no DB data for requested date
    if total == 0 and target != str(date_type.today()):
        return _mock_report(target)

    return ReportResponse(
        date=target,
        total_trades=total,
        wins=len(wins),
        losses=len(losses),
        win_rate=win_rate,
        top_profit=to_rate(top_profit) if top_profit else None,
        top_loss=to_rate(top_loss) if top_loss else None,
        total_pnl=total_pnl,
    )


def _mock_report(date: str) -> ReportResponse:
    return ReportResponse(
        date=date,
        total_trades=6,
        wins=3,
        losses=3,
        win_rate=50,
        top_profit=StockRate(code="088350", name="한화생명", rate=2.37),
        top_loss=StockRate(code="008970", name="KBI동양철관", rate=-1.83),
        total_pnl=4747,
    )


@router.get("/trades")
def get_trades(
    date: str = Query(default=None),
    db: Session = Depends(get_db),
):
    """거래 기록 (relearning to db 섹션)."""
    target = date or str(date_type.today())
    txs = (db.query(Transaction)
           .filter(Transaction.trade_date == target)
           .all())

    if not txs:
        return _mock_trades()

    # Group buy/sell pairs into trade records
    records = []
    sells = [t for t in txs if not t.is_buy]
    for i, t in enumerate(sells, start=1):
        buy = next((b for b in txs if b.is_buy and b.code == t.code), None)
        is_profit = (t.result or 0) > 0
        buy_price = buy.unit_price if buy else t.unit_price
        pnl_pct = ((t.unit_price - buy_price) / buy_price * 100) if buy_price else 0
        records.append({
            "no": i,
            "is_profit": is_profit,
            "name": t.name,
            "code": t.code,
            "buy_info": f"{t.count}주({buy_price:,}원)" if buy else "-",
            "sell_info": f"{t.count}주({t.unit_price:,}원)",
            "mfe": f"+{pnl_pct:.2f}%" if pnl_pct > 0 else None,
            "mre": f"{min(pnl_pct, 0):.2f}%",
        })
    return records


def _mock_trades():
    return [
        {
            "no": 1, "is_profit": True, "name": "광전자", "code": "017900",
            "buy_info": "49주(10,150원)", "sell_info": "49주(10,410원)",
            "mfe": "+2.56%", "mre": "-1.08%",
        },
        {
            "no": 2, "is_profit": False, "name": "광전자", "code": "017900",
            "buy_info": "49주(10,150원)", "sell_info": "49주(10,410원)",
            "mfe": None, "mre": "-1.08%",
        },
    ]
