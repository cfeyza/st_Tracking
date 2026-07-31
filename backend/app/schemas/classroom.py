from datetime import datetime

from pydantic import BaseModel, field_validator


class RosterStudentIn(BaseModel):
    name: str
    surname: str
    school_id: str

    @field_validator("name", "surname", "school_id")
    @classmethod
    def not_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("must not be blank")
        return value.strip()


class ClassroomCreate(BaseModel):
    name: str
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
