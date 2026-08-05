from datetime import datetime

from pydantic import BaseModel, Field, field_validator


class RosterStudentIn(BaseModel):
    name: str = Field(max_length=100)
    surname: str = Field(max_length=100)
    school_id: int

    @field_validator("name", "surname")
    @classmethod
    def not_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("must not be blank")
        return value.strip()

    @field_validator("school_id")
    @classmethod
    def positive(cls, value: int) -> int:
        if value <= 0:
            raise ValueError("must be a positive number")
        return value


class ClassroomCreate(BaseModel):
    name: str = Field(max_length=100)
    students: list[RosterStudentIn] = []


class ClassroomOut(BaseModel):
    id: int
    name: str
    student_count: int
    created_at: datetime

    model_config = {"from_attributes": True}


class ClassroomBrief(BaseModel):
    id: int
    name: str

    model_config = {"from_attributes": True}


class RosterImportRequest(BaseModel):
    students: list[RosterStudentIn]


class PdfImportClassroomResult(BaseModel):
    classroom_id: int
    classroom_name: str
    created_classroom: bool
    students_added: int
    skipped: list[str] = []


class PdfImportResult(BaseModel):
    classrooms: list[PdfImportClassroomResult]
    errors: list[str] = []
