"""Rule-based AI agents for the conference section."""
from datetime import datetime
from services.stock_service import get_stock_snapshot

_AGENTS = ["차트 분석가", "수급 전문가", "뉴스 분석가", "리스크 심사관"]


def _now_str() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


# ─── Individual agent logic ───────────────────────────────────────────────────
def _chart_agent(snap: dict) -> tuple[int, str, str]:
    rsi = snap["_rsi"]
    bb = snap["_bb"]
    macd = snap["_macd"]
    pct = snap["_pct"]

    score = 50
    parts = []

    # RSI analysis
    if rsi < 30:
        score += 25
        parts.append(f"RSI({int(rsi)})가 극도 과매도 구간으로 강한 반등 가능성이 있습니다.")
    elif rsi < 40:
        score += 15
        parts.append(f"RSI({int(rsi)}) 과매도 구간 진입으로 매수 신호가 감지됩니다.")
    elif rsi > 70:
        score -= 25
        parts.append(f"RSI({int(rsi)})가 과매수 구간으로 조정 가능성이 있습니다.")
    elif rsi > 60:
        score -= 10
        parts.append(f"RSI({int(rsi)}) 상단에 근접해 추가 상승 여력이 제한적입니다.")
    else:
        parts.append(f"RSI({int(rsi)}) 중립 구간으로 방향성이 불분명합니다.")

    # Bollinger
    span = bb["upper"] - bb["lower"]
    if span > 0:
        pos = (bb["current"] - bb["lower"]) / span
        if pos < 0.15:
            score += 15
            parts.append("현재가가 볼린저 하단에 근접해 반등 신호입니다.")
        elif pos > 0.85:
            score -= 15
            parts.append("현재가가 볼린저 상단에 근접하고 있어 조정 가능성이 있습니다.")
        else:
            parts.append("현재가가 볼린저 중간선 부근에서 횡보 중입니다.")

    # MACD
    if macd["histogram"] > 0:
        score += 5
        parts.append("MACD 히스토그램이 양수로 상승 모멘텀이 유지되고 있습니다.")
    else:
        score -= 5
        parts.append("MACD 히스토그램이 음수로 하락 모멘텀이 있습니다.")

    score = max(0, min(100, score))
    opinion = " ".join(parts)
    verdict = _verdict(score)
    return score, opinion, verdict


def _volume_agent(snap: dict) -> tuple[int, str, str]:
    str_val = snap["str_val"]
    pct = snap["_pct"]

    score = 50
    parts = []

    if str_val > 130:
        score += 20
        parts.append(f"체결강도({str_val})가 평균 대비 매우 강해 매수 우위입니다.")
    elif str_val > 110:
        score += 10
        parts.append(f"체결강도({str_val})가 평균보다 강해 수급이 양호합니다.")
    elif str_val < 80:
        score -= 15
        parts.append(f"체결강도({str_val})가 낮아 매도 압력이 우세합니다.")
    else:
        parts.append(f"체결강도({str_val})가 보통 수준으로 뚜렷한 수급 신호가 없습니다.")

    if abs(pct) > 0.01:
        bid_ratio = snap["bid"]
        if bid_ratio > 1.2:
            score += 10
            parts.append("매수/매도 잔량 비율이 높아 매수 지지세가 강합니다.")
        elif bid_ratio < 0.8:
            score -= 10
            parts.append("매수/매도 잔량 비율이 낮아 매도 압력이 존재합니다.")
        else:
            parts.append("매수/매도 잔량 비율이 0.00으로 극심한 유동성 부족 및 매수 지지세 부재가 확실하지 않습니다.")

    score = max(0, min(100, score))
    return score, " ".join(parts), _verdict(score)


def _news_agent(snap: dict) -> tuple[int, str, str]:
    # Placeholder – real implementation requires news API
    pct = snap["_pct"]
    score = 50
    if pct > 2:
        score = 65
        opinion = ("관련 뉴스에서 긍정적 재료가 확인되며 주가 상승을 지지하는 "
                   "요인들이 나타나고 있습니다.")
    elif pct < -2:
        score = 35
        opinion = ("관련 뉴스에서 부정적 재료가 감지되며 주가 하락 요인이 "
                   "존재합니다. 추가 확인이 필요합니다.")
    else:
        opinion = ("관련된 뉴스가 다수 있으나, 직접적인 주가 상승/하락을 유발할 "
                   "만한 명확한 호재나 악재는 보이지 않습니다.")
    return score, opinion, _verdict(score)


def _risk_agent(scores: list[int], snap: dict) -> tuple[int, str, str]:
    avg = sum(scores) / len(scores)
    score = int(avg)
    rsi = snap["_rsi"]

    parts = []
    if min(scores) < 20:
        score -= 10
        parts.append("일부 에이전트 신뢰도가 매우 낮아 리스크 패널티가 적용됩니다.")
    if rsi < 25 or rsi > 80:
        parts.append(f"RSI({int(rsi)})가 극단 구간이며 반전 리스크를 주시해야 합니다.")

    all_verdicts = [_verdict(s) for s in scores]
    if all_verdicts.count("buy") >= 3:
        parts.append("3개 이상의 에이전트가 매수 의견으로 최종 BUY 결정을 지지합니다.")
    elif all_verdicts.count("sale") >= 3:
        parts.append("3개 이상의 에이전트가 매도 의견으로 최종 SELL 결정을 지지합니다.")
    else:
        parts.append("에이전트 의견이 혼재하여 최종 HOLD 결정을 권고합니다.")

    score = max(0, min(100, score))
    return score, " ".join(parts) if parts else "에이전트 분석이 완료되었습니다.", _verdict(score)


def _verdict(score: int) -> str:
    if score >= 65: return "buy"
    if score <= 35: return "sale"
    return "hold"


def _final_decision(score: int) -> str:
    if score >= 65: return "BUY!"
    if score <= 35: return "SALES!"
    return "HOLD"


# ─── Public API ───────────────────────────────────────────────────────────────
def run_conference_for(code: str, name: str) -> dict:
    snap = get_stock_snapshot(code)
    ts = _now_str()

    s1, o1, v1 = _chart_agent(snap)
    s2, o2, v2 = _volume_agent(snap)
    s3, o3, v3 = _news_agent(snap)
    s4, o4, v4 = _risk_agent([s1, s2, s3], snap)

    final_score = (s1 + s2 + s3 + s4) // 4

    return {
        "stock_name": name,
        "stock_code": code,
        "decision": _final_decision(final_score),
        "entries": [
            {"time": ts, "field": "차트 분석가",  "opinion": o1, "score": s1, "type": v1},
            {"time": ts, "field": "수급 전문가",  "opinion": o2, "score": s2, "type": v2},
            {"time": ts, "field": "뉴스 분석가",  "opinion": o3, "score": s3, "type": v3},
            {"time": ts, "field": "리스크 심사관","opinion": o4, "score": s4, "type": v4},
        ],
    }
