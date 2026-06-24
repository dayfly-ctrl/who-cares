from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models.db_models import WatchlistItem, Transaction
from models.schemas import MonitoringStock
from services.stock_service import get_stock_snapshot
from typing import List
from datetime import date

router = APIRouter()


@router.get("/", response_model=List[MonitoringStock])
def get_monitoring(db: Session = Depends(get_db)):
    items = db.query(WatchlistItem).filter(WatchlistItem.active == True).all()
    today = str(date.today())

    results = []
    for item in items:
        snap = get_stock_snapshot(item.code)

        # score from today's conference (if exists) else snap score
        score = snap.get("score")

        results.append(MonitoringStock(
            code=item.code,
            name=item.name,
            category=item.category,
            price=snap["price"],
            change=snap["change"],
            change_positive=snap["change_positive"],
            str_val=snap["str_val"],
            rsi=snap["rsi"],
            bid=snap["bid"],
            score=score,
            debate=snap["debate"],
        ))
    return results


@router.post("/watchlist")
def add_to_watchlist(code: str, name: str, category: str,
                     db: Session = Depends(get_db)):
    existing = db.query(WatchlistItem).filter(WatchlistItem.code == code).first()
    if existing:
        existing.active = True
    else:
        db.add(WatchlistItem(code=code, name=name, category=category))
    db.commit()
    return {"ok": True}


@router.delete("/watchlist/{code}")
def remove_from_watchlist(code: str, db: Session = Depends(get_db)):
    item = db.query(WatchlistItem).filter(WatchlistItem.code == code).first()
    if item:
        item.active = False
        db.commit()
    return {"ok": True}
