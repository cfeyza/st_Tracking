from pydantic import BaseModel, EmailStr


class ParentProfileOut(BaseModel):
    name: str
    surname: str
    email: EmailStr


class StudentCodeRequest(BaseModel):
    code: str


class ParentStudentListItem(BaseModel):
    id: int
    name: str
    surname: str
    school_id: str
