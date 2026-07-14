from datetime import datetime, timedelta

from jose import jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from database.models import Pilot
from schemas.auth_schemas import PilotCreate


SECRET_KEY = "CHANGE_ME_IN_PRODUCTION"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expires_at = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expires_at})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_pilot_by_email(db: Session, email: str) -> Pilot | None:
    return db.query(Pilot).filter(Pilot.email == email).first()


def create_pilot(db: Session, pilot: PilotCreate) -> Pilot:
    db_pilot = Pilot(
        email=pilot.email,
        full_name=pilot.full_name,
        hashed_password=get_password_hash(pilot.password),
    )
    db.add(db_pilot)
    db.commit()
    db.refresh(db_pilot)
    return db_pilot


def authenticate_pilot(db: Session, email: str, password: str) -> Pilot | None:
    pilot = get_pilot_by_email(db, email)
    if not pilot:
        return None
    if not verify_password(password, pilot.hashed_password):
        return None
    return pilot
