"""Korean stock data via pykrx + technical indicators."""
import time
from datetime import datetime, timedelta
from typing import Optional

import numpy as np
import pandas as pd

try:
    from pykrx import stock as pykrx_stock
    PYKRX_AVAILABLE = True
except ImportError:
    PYKRX_AVAILABLE = False

# ─── Simple TTL cache ─────────────────────────────────────────────────────────
_cache: dict = {}
_TTL = 300  # seconds


def _cache_get(key: str):
    entry = _cache.get(key)
    if entry and time.time() - entry["ts"] < _TTL:
        return entry["data"]
    return None


def _cache_set(key: str, data):
    _cache[key] = {"ts": time.time(), "data": data}


# ─── OHLCV ────────────────────────────────────────────────────────────────────
def get_ohlcv(code: str, days: int = 90) -> Optional[pd.DataFrame]:
    key = f"ohlcv_{code}"
    cached = _cache_get(key)
    if cached is not None:
        return cached

    if not PYKRX_AVAILABLE:
        return None

    try:
        today = datetime.now().strftime("%Y%m%d")
        start = (datetime.now() - timedelta(days=days)).strftime("%Y%m%d")
        df = pykrx_stock.get_market_ohlcv_by_date(start, today, code)
        if df is not None and not df.empty:
            _cache_set(key, df)
            return df
    except Exception:
        pass
    return None


# ─── Technical indicators ─────────────────────────────────────────────────────
def calculate_rsi(prices: pd.Series, period: int = 14) -> float:
    delta = prices.diff()
    gain = delta.where(delta > 0, 0.0).rolling(period).mean()
    loss = (-delta.where(delta < 0, 0.0)).rolling(period).mean()
    rs = gain / loss.replace(0, np.nan)
    rsi = 100 - (100 / (1 + rs))
    val = rsi.dropna()
    return float(val.iloc[-1]) if not val.empty else 50.0


def calculate_bollinger(prices: pd.Series, period: int = 20):
    ma = prices.rolling(period).mean()
    std = prices.rolling(period).std()
    upper = ma + 2 * std
    lower = ma - 2 * std
    return {
        "upper": float(upper.iloc[-1]),
        "middle": float(ma.iloc[-1]),
        "lower": float(lower.iloc[-1]),
        "current": float(prices.iloc[-1]),
    }


def calculate_macd(prices: pd.Series, fast=12, slow=26, signal=9):
    ema_f = prices.ewm(span=fast, adjust=False).mean()
    ema_s = prices.ewm(span=slow, adjust=False).mean()
    macd = ema_f - ema_s
    sig = macd.ewm(span=signal, adjust=False).mean()
    return {
        "macd": float(macd.iloc[-1]),
        "signal": float(sig.iloc[-1]),
        "histogram": float((macd - sig).iloc[-1]),
    }


def volume_strength(df: pd.DataFrame) -> int:
    """체결강도 – current volume vs 20-day average."""
    avg = df["거래량"].rolling(20).mean().iloc[-1]
    curr = df["거래량"].iloc[-1]
    if avg and avg > 0:
        return int(curr / avg * 100)
    return 100


# ─── Per-stock snapshot ───────────────────────────────────────────────────────
def get_stock_snapshot(code: str) -> dict:
    """Return monitoring-row data.  Falls back to mock on any error."""
    df = get_ohlcv(code)
    if df is None or len(df) < 20:
        return _mock_snapshot(code)

    try:
        prices = df["종가"]
        curr = float(prices.iloc[-1])
        prev = float(prices.iloc[-2])
        pct = (curr - prev) / prev * 100

        rsi = calculate_rsi(prices)
        bb = calculate_bollinger(prices)
        macd_data = calculate_macd(prices)
        str_val = volume_strength(df)

        score = _composite_score(rsi, pct, bb, macd_data)

        return {
            "price": f"{int(curr):,}원",
            "change": f"+{pct:.2f}%" if pct >= 0 else f"{pct:.2f}%",
            "change_positive": pct >= 0,
            "str_val": str_val,
            "rsi": int(rsi),
            "bid": round(float(df["거래량"].iloc[-1]) /
                         float(df["거래량"].rolling(20).mean().iloc[-1]), 2),
            "score": score,
            "debate": score >= 65,
            # raw indicators for agents
            "_rsi": rsi, "_pct": pct, "_bb": bb, "_macd": macd_data,
        }
    except Exception:
        return _mock_snapshot(code)


def _composite_score(rsi, pct, bb, macd) -> int:
    score = 50
    # RSI
    if rsi < 25:   score += 25
    elif rsi < 35: score += 15
    elif rsi < 45: score += 5
    elif rsi > 75: score -= 25
    elif rsi > 65: score -= 15
    elif rsi > 55: score -= 5
    # Price momentum
    if pct > 3:    score += 15
    elif pct > 1:  score += 7
    elif pct < -3: score -= 15
    elif pct < -1: score -= 7
    # Bollinger
    span = bb["upper"] - bb["lower"]
    if span > 0:
        pos = (bb["current"] - bb["lower"]) / span
        if pos < 0.15: score += 10
        elif pos > 0.85: score -= 10
    # MACD
    if macd["histogram"] > 0: score += 5
    else: score -= 5
    return max(0, min(100, score))


# ─── Mock fallbacks ───────────────────────────────────────────────────────────
_MOCK = {
    "005930": dict(price="362,500원", change="+2.90%", change_positive=True,
                   str_val=134, rsi=33, bid=1.35, score=100, debate=True,
                   _rsi=33, _pct=2.9, _bb={"upper":380000,"middle":365000,
                   "lower":350000,"current":362500}, _macd={"macd":500,"signal":400,"histogram":100}),
    "067290": dict(price="2,065원", change="-11.56%", change_positive=False,
                   str_val=81, rsi=74, bid=0.81, score=None, debate=False,
                   _rsi=74, _pct=-11.56, _bb={"upper":2500,"middle":2300,
                   "lower":2065,"current":2065}, _macd={"macd":-50,"signal":-30,"histogram":-20}),
    "000660": dict(price="198,500원", change="+1.20%", change_positive=True,
                   str_val=112, rsi=52, bid=1.12, score=60, debate=False,
                   _rsi=52, _pct=1.2, _bb={"upper":205000,"middle":198000,
                   "lower":191000,"current":198500}, _macd={"macd":200,"signal":150,"histogram":50}),
    "088350": dict(price="3,840원", change="+2.37%", change_positive=True,
                   str_val=120, rsi=45, bid=1.20, score=72, debate=True,
                   _rsi=45, _pct=2.37, _bb={"upper":4000,"middle":3800,
                   "lower":3600,"current":3840}, _macd={"macd":30,"signal":20,"histogram":10}),
}

def _mock_snapshot(code: str) -> dict:
    return _MOCK.get(code, dict(
        price="0원", change="0.00%", change_positive=True,
        str_val=100, rsi=50, bid=1.0, score=50, debate=False,
        _rsi=50, _pct=0, _bb={"upper":0,"middle":0,"lower":0,"current":0},
        _macd={"macd":0,"signal":0,"histogram":0},
    ))
