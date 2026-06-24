from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models.db_models import ScheduleItem, NewsItem, WatchlistItem
from models.schemas import (
    ScheduleResponse, ScheduleItemOut, SummaryResponse, SummaryItem, RecoItem,
)
from services.stock_service import get_stock_snapshot
from typing import List

router = APIRouter()


@router.get("/schedule", response_model=ScheduleResponse)
def get_schedule(db: Session = Depends(get_db)):
    items = db.query(ScheduleItem).order_by(ScheduleItem.no).all()

    active = next((i for i in items if i.status == "active"), None)
    completed = sum(1 for i in items if i.status == "completed")
    pending = sum(1 for i in items if i.status == "pending")

    return ScheduleResponse(
        active_time=active.time if active else "-",
        active_task=active.task if active else "-",
        total=len(items),
        completed=completed,
        pending=pending,
        items=[ScheduleItemOut(no=i.no, time=i.time, task=i.task, status=i.status)
               for i in items],
    )


@router.patch("/schedule/{no}/status")
def update_schedule_status(no: int, status: str,
                            db: Session = Depends(get_db)):
    """status: completed | active | pending"""
    item = db.query(ScheduleItem).filter(ScheduleItem.no == no).first()
    if item:
        item.status = status
        db.commit()
    return {"ok": True}


@router.get("/summary", response_model=SummaryResponse)
def get_summary(db: Session = Depends(get_db)):
    news = db.query(NewsItem).all()
    return SummaryResponse(
        items=[SummaryItem(name=n.stock_name, type=n.news_type,
                           topic=n.topic, reliability=n.reliability)
               for n in news],
        disclaimer=(
            "웹 검색 기능 오류로 인해 글로벌 거시경제 지표 및 최신 뉴스(호재/악재)를 "
            "제대로 로드하지 못했습니다. 이는 투자 결정에 있어 매우 높은 불확실성을 "
            "야기하며, 포트폴리오의 현금 비중을 대폭 상향 조정하며 리스크 관리에 집중합니다. "
            "정보 확보 시 즉시 포트폴리오 재검토 예정입니다."
        ),
    )


@router.get("/recommendation", response_model=List[RecoItem])
def get_recommendation(db: Session = Depends(get_db)):
    """종목별 점수를 기반으로 추천 목록 생성."""
    items = db.query(WatchlistItem).filter(WatchlistItem.active == True).all()

    recos = []
    for item in items:
        snap = get_stock_snapshot(item.code)
        score = snap.get("score") or 50
        if score < 40:
            continue  # 추천하지 않음
        pct = score / 100
        reco_type = "buy." if score >= 65 else "hold."
        recos.append(RecoItem(
            code=item.code,
            name=item.name,
            percent=pct,
            type=reco_type,
        ))

    recos.sort(key=lambda r: r.percent, reverse=True)
    return recos


@router.get("/transactions")
def get_transactions(
    tab: str = "short",
    db: Session = Depends(get_db),
):
    """매수/매도 내역 (details of purchase/sale 섹션)."""
    from models.db_models import Transaction
    txs = (db.query(Transaction)
           .filter(Transaction.tab == tab)
           .order_by(Transaction.trade_date.desc(), Transaction.trade_time.desc())
           .all())

    if not txs:
        return _mock_transactions()

    return [
        {
            "time": f"{t.trade_date} {t.trade_time}",
            "is_buy": t.is_buy,
            "code": t.code,
            "name": t.name,
            "count": f"{t.count}주",
            "unit_price": f"{t.unit_price:,}원",
            "total_amount": f"{t.unit_price * t.count:,}원",
            "result": (f"+{t.result:,}원" if t.result > 0 else f"{t.result:,}원")
                      if t.result is not None else None,
        }
        for t in txs
    ]


def _mock_transactions():
    return [
        {"time": "2026-06-18 17:57", "is_buy": True, "code": "105560",
         "name": "kb금융", "count": "9주", "unit_price": "150,600원",
         "total_amount": "1,355,400원", "result": None},
        {"time": "2026-06-18 18:13", "is_buy": False, "code": "035720",
         "name": "카카오", "count": "39주", "unit_price": "39,350원",
         "total_amount": "1,534,650원", "result": "+11,711원"},
        {"time": "2026-06-18 18:13", "is_buy": False, "code": "035720",
         "name": "네이버", "count": "32주", "unit_price": "39,350원",
         "total_amount": "1,534,650원", "result": "-11,711원"},
    ]
