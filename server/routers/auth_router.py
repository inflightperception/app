from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from database.db import get_db
from database.models import Pilot
from schemas.auth_schemas import PilotCreate, PilotRead, Token
from services.auth_service import (
    ALGORITHM,
    SECRET_KEY,
    authenticate_pilot,
    create_access_token,
    create_pilot,
    get_pilot_by_email,
)


router = APIRouter(prefix="/auth", tags=["auth"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_pilot(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[Session, Depends(get_db)],
) -> Pilot:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError as exc:
        raise credentials_exception from exc

    pilot = get_pilot_by_email(db, email=email)
    if pilot is None:
        raise credentials_exception
    return pilot


@router.post("/register", response_model=PilotRead, status_code=status.HTTP_201_CREATED)
def register_pilot(
    pilot: PilotCreate,
    db: Annotated[Session, Depends(get_db)],
) -> Pilot:
    existing_pilot = get_pilot_by_email(db, pilot.email)
    if existing_pilot:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A pilot with this email already exists.",
        )

    return create_pilot(db, pilot)


@router.post("/login", response_model=Token)
def login_pilot(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: Annotated[Session, Depends(get_db)],
) -> Token:
    pilot = authenticate_pilot(db, form_data.username, form_data.password)
    if not pilot:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(data={"sub": pilot.email})
    return Token(access_token=access_token)


@router.get("/me", response_model=PilotRead)
def read_current_pilot(
    current_pilot: Annotated[Pilot, Depends(get_current_pilot)],
) -> Pilot:
    return current_pilot
