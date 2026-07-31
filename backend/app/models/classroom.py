from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, String, Table, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base

classroom_students = Table(
    "classroom_students",
    Base.metadata,
    Column("classroom_id", ForeignKey("classrooms.id", ondelete="CASCADE"), primary_key=True),
    Column("student_id", ForeignKey("student_profiles.id", ondelete="CASCADE"), primary_key=True),
    Column("created_at", DateTime(timezone=True), server_default=func.now()),
)


class Classroom(Base):
    __tablename__ = "classrooms"

    id: Mapped[int] = mapped_column(primary_key=True)
    teacher_id: Mapped[int] = mapped_column(ForeignKey("teacher_profiles.id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    teacher: Mapped["TeacherProfile"] = relationship(back_populates="classrooms")
    students: Mapped[list["StudentProfile"]] = relationship(
        secondary=classroom_students, back_populates="classrooms"
    )
    announcements: Mapped[list["Announcement"]] = relationship(
        secondary="announcement_classrooms", back_populates="classrooms"
    )
    grades: Mapped[list["Grade"]] = relationship(back_populates="classroom")
