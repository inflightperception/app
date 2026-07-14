from pydantic import BaseModel, ConfigDict, EmailStr


class PilotCreate(BaseModel):
    email: EmailStr
    full_name: str | None = None
    password: str


class PilotRead(BaseModel):
    id: int
    email: EmailStr
    full_name: str | None = None

    model_config = ConfigDict(from_attributes=True)


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
