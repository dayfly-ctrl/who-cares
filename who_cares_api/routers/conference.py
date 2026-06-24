from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from database import get_db
from models.db_models import WatchlistItem
from models.schemas import ConferenceGroup
from services.agent_service import run_conference_for
from typing import List

router = APIRouter()


@router.get("/", response_model=List[ConferenceGroup])
def get_conference(
    filter: str = Query("all", description="all | hold | buy | sell"),
    db: Session = Depends(get_db),
):
    items = db.query(WatchlistItem).filter(WatchlistItem.active == True).all()

    results = [run_conference_for(item.code, item.name) for item in items]

    if filter == "buy":
        results = [r for r in results if r["decision"] == "BUY!"]
    elif filter == "sell":
        results = [r for r in results if r["decision"] == "SALES!"]
    elif filter == "hold":
        results = [r for r in results if r["decision"] == "HOLD"]

    return results


@router.get("/{code}", response_model=ConferenceGroup)
def get_conference_for_stock(code: str, db: Session = Depends(get_db)):
    item = db.query(WatchlistItem).filter(WatchlistItem.code == code).first()
    name = item.name if item else code
    return run_conference_for(code, name)
