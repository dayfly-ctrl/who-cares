from fastapi import APIRouter, HTTPException
from models.schemas import PinRequest, PinResponse
from config import settings

router = APIRouter()


@router.post("/verify-pin", response_model=PinResponse)
def verify_pin(req: PinRequest):
    if req.pin == settings.PIN:
        return PinResponse(success=True)
    raise HTTPException(status_code=401, detail="PIN이 올바르지 않습니다.")
