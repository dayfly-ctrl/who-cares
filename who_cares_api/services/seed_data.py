"""Initial data — runs once on first startup if tables are empty."""
from sqlalchemy.orm import Session
from models.db_models import (
    Balance, Transaction, WatchlistItem, ScheduleItem, NewsItem,
)


def seed_all(db: Session):
    _seed_balance(db)
    _seed_transactions(db)
    _seed_watchlist(db)
    _seed_schedule(db)
    _seed_news(db)


def _seed_balance(db: Session):
    if db.query(Balance).count():
        return
    db.add(Balance(
        deposit=4_450_280,
        tradeable=4_450_280,
        stock_value=4_910_700,
        today_buy=0,
        today_sell=0,
    ))
    db.commit()


def _seed_transactions(db: Session):
    if db.query(Transaction).count():
        return
    rows = [
        Transaction(trade_date="2026-06-18", trade_time="17:57", is_buy=True,
                    code="105560", name="kb금융", count=9,
                    unit_price=150_600, result=None, tab="short"),
        Transaction(trade_date="2026-06-18", trade_time="18:13", is_buy=False,
                    code="035720", name="카카오", count=39,
                    unit_price=39_350, result=11_711, tab="short"),
        Transaction(trade_date="2026-06-18", trade_time="18:13", is_buy=False,
                    code="035720", name="네이버", count=32,
                    unit_price=39_350, result=-11_711, tab="short"),
    ]
    db.add_all(rows)
    db.commit()


def _seed_watchlist(db: Session):
    if db.query(WatchlistItem).count():
        return
    items = [
        WatchlistItem(code="005930", name="삼성전자", category="반도체"),
        WatchlistItem(code="067290", name="JW신약", category="의약"),
        WatchlistItem(code="000660", name="SK하이닉스", category="반도체"),
        WatchlistItem(code="088350", name="한화생명", category="금융"),
    ]
    db.add_all(items)
    db.commit()


def _seed_schedule(db: Session):
    if db.query(ScheduleItem).count():
        return
    schedule = [
        (1,  "02:30", "DB 정리 / 백업",               "completed"),
        (2,  "03:00", "데이터 정합성 검사",             "completed"),
        (3,  "04:00", "해외장·환율·금리·지수 수집",    "completed"),
        (4,  "04:30", "뉴스·공시·토픽 수집 1차",       "completed"),
        (5,  "05:10", "뉴스 분석 / 감성점수 / 테마 분류","completed"),
        (6,  "05:40", "피처 생성 / 종목 스코어링",      "completed"),
        (7,  "06:20", "모델 업데이트 / 백테스트",       "completed"),
        (8,  "06:50", "오늘의 전략 확정",               "completed"),
        (9,  "07:20", "브리핑 생성",                    "active"),
        (10, "08:00", "계좌·잔고·현금·API 상태 확인",  "pending"),
        (11, "08:20", "주문 후보 확정",                 "pending"),
        (12, "08:50", "최종 리스크 검증",               "pending"),
        (13, "09:00", "1차 주문",                       "pending"),
        (14, "09:30", "체결 확인 / 미체결 정리",        "pending"),
        (15, "10:30", "장중 분석 1차",                  "pending"),
        (16, "13:30", "장중 분석 2차",                  "pending"),
        (17, "15:00", "마감 전 리스크 점검",            "pending"),
        (18, "15:20", "종가 동시호가 대응",              "pending"),
        (19, "15:35", "체결·잔고·손익 확정",            "pending"),
        (20, "16:10", "일일 리포트",                    "pending"),
        (21, "17:00", "손실 원인 라벨링 / 복기",        "pending"),
        (22, "19:30", "뉴스·공시·토픽 수집 2차",        "pending"),
        (23, "21:00", "내일 관심 테마 업데이트",         "pending"),
    ]
    db.add_all([ScheduleItem(no=n, time=t, task=task, status=s)
                for n, t, task, s in schedule])
    db.commit()


def _seed_news(db: Session):
    if db.query(NewsItem).count():
        return
    items = [
        NewsItem(
            stock_name="SK 하이닉스", news_type="호재",
            topic="하이닉스 美 ADR 상장면 외국인자금 밀물 ... 실적·수급 양날개 "
                  "ADR이 상장되면 다양한 미국 상장 ETF에서 자금 유입이 이어지게 된다.",
            reliability="60.",
        ),
        NewsItem(
            stock_name="현대자동차", news_type="악재",
            topic="에이전트 오류로 인하여 뉴스 내용 미수집",
            reliability=None,
        ),
    ]
    db.add_all(items)
    db.commit()
