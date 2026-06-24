from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Text
from sqlalchemy.sql import func
from database import Base


class Balance(Base):
    __tablename__ = "balance"
    id          = Column(Integer, primary_key=True)
    deposit     = Column(Integer, default=0)   # 예수금
    tradeable   = Column(Integer, default=0)   # 거래 가능 금액
    stock_value = Column(Integer, default=0)   # 보유 주식 평가액
    today_buy   = Column(Integer, default=0)   # 오늘 매수 금액
    today_sell  = Column(Integer, default=0)   # 오늘 매도 금액


class Transaction(Base):
    __tablename__ = "transactions"
    id          = Column(Integer, primary_key=True, autoincrement=True)
    trade_date  = Column(String(20))           # "2026-06-18"
    trade_time  = Column(String(8))            # "17:57"
    is_buy      = Column(Boolean)
    code        = Column(String(10))
    name        = Column(String(50))
    count       = Column(Integer)
    unit_price  = Column(Integer)
    result      = Column(Integer, nullable=True)  # 손익 (null = 미확정)
    tab         = Column(String(10), default="short")  # short / long


class WatchlistItem(Base):
    __tablename__ = "watchlist"
    id       = Column(Integer, primary_key=True, autoincrement=True)
    code     = Column(String(10), unique=True)
    name     = Column(String(50))
    category = Column(String(30))
    active   = Column(Boolean, default=True)


class ScheduleItem(Base):
    __tablename__ = "schedule_items"
    id     = Column(Integer, primary_key=True, autoincrement=True)
    no     = Column(Integer)
    time   = Column(String(10))   # "02:30"
    task   = Column(String(100))
    status = Column(String(20), default="pending")  # completed / active / pending


class NewsItem(Base):
    __tablename__ = "news_items"
    id          = Column(Integer, primary_key=True, autoincrement=True)
    stock_name  = Column(String(50))
    news_type   = Column(String(10))   # 호재 / 악재
    topic       = Column(Text)
    reliability = Column(String(10), nullable=True)
