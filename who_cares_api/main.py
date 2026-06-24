from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import init_db
from routers import auth, balance, report, monitoring, conference, analysis


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(
    title="Who Cares? API",
    description="주식 대시보드 백엔드 API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,        prefix="/api/auth",        tags=["인증"])
app.include_router(balance.router,     prefix="/api/balance",     tags=["잔고"])
app.include_router(report.router,      prefix="/api/report",      tags=["리포트"])
app.include_router(monitoring.router,  prefix="/api/monitoring",  tags=["모니터링"])
app.include_router(conference.router,  prefix="/api/conference",  tags=["컨퍼런스"])
app.include_router(analysis.router,    prefix="/api/analysis",    tags=["분석"])


@app.get("/", tags=["헬스체크"])
def root():
    return {"status": "ok", "message": "Who Cares? API is running"}
