from pydantic import BaseModel, EmailStr, Field, field_validator, model_validator

from app.models.user import Role


class RegisterRequest(BaseModel):
    role: Role
    name: str = Field(max_length=100)
    surname: str = Field(max_length=100)
    email: EmailStr = Field(max_length=255)
    password: str
    school_id: int | None = None

    @field_validator("name", "surname")
    @classmethod
    def not_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("must not be blank")
        return value.strip()

    @field_validator("password")
    @classmethod
    def password_length(cls, value: str) -> str:
        if len(value) < 8:
            raise ValueError("password must be at least 8 characters")
        if len(value.encode("utf-8")) > 72:
            raise ValueError("password must not exceed 72 characters")
        return value

    @model_validator(mode="after")
    def school_id_required_for_students(self) -> "RegisterRequest":
        if self.role == Role.STUDENT and not (self.school_id and self.school_id > 0):
            raise ValueError("school_id is required for students")
        return self


class RegisterResponse(BaseModel):
    message: str = "Registration successful. Please check your email to verify your account before logging in."


class VerifyEmailResponse(BaseModel):
    message: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: Role
