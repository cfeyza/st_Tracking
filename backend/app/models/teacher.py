from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, String, Table, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base

teacher_students = Table(
    "teacher_students",
    Base.metadata,
    Column("teacher_id", ForeignKey("teacher_profiles.id", ondelete="CASCADE"), primary_key=True),
    Column("student_id", ForeignKey("student_profiles.id", ondelete="CASCADE"), primary_key=True),
    Column("created_at", DateTime(timezone=True), server_default=func.now()),
)


class TeacherProfile(Base):
    __tablename__ = "teacher_profiles"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    surname: Mapped[str] = mapped_column(String(100), nullable=False)
    teacher_code: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)

    user: Mapped["User"] = relationship(back_populates="teacher_profile")
    classrooms: Mapped[list["Classroom"]] = relationship(back_populates="teacher", cascade="all, delete-orphan")
    announcements: Mapped[list["Announcement"]] = relationship(back_populates="teacher", cascade="all, delete-orphan")
    students: Mapped[list["StudentProfile"]] = relationship(
        secondary=teacher_students, back_populates="teachers"
    )
