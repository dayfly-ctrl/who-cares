from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models.db_models import Balance
from models.schemas import BalanceResponse

router = APIRouter()


@router.get("/", response_model=BalanceResponse)
def get_balance(db: Session = Depends(get_db)):
    bal = db.query(Balance).first()
    if not bal:
        raise HTTPException(404, "잔고 정보가 없습니다.")
    return BalanceResponse(
        time=datetime.now().strftime("%p %I:%M:%S").replace("AM", "오전").replace("PM", "오후"),
        deposit=bal.deposit,
        tradeable=bal.tradeable,
        stock_value=bal.stock_value,
        today_buy=bal.today_buy,
        today_sell=bal.today_sell,
        total_assets=bal.deposit + bal.stock_value,
    )


@router.patch("/")
def update_balance(deposit: int = None, stock_value: int = None,
                   today_buy: int = None, today_sell: int = None,
                   db: Session = Depends(get_db)):
    bal = db.query(Balance).first()
    if not bal:
        raise HTTPException(404)
    if deposit is not None:
        bal.deposit = deposit
        bal.tradeable = deposit
    if stock_value is not None:
        bal.stock_value = stock_value
    if today_buy is not None:
        bal.today_buy = today_buy
    if today_sell is not None:
        bal.today_sell = today_sell
    db.commit()
    return {"ok": True}
