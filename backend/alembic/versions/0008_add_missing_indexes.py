"""add missing indexes for student-side queries

Revision ID: 0008_add_missing_indexes
Revises: 0007_soft_delete_announcements
Create Date: 2026-08-18

"""
from typing import Sequence, Union

from alembic import op

revision: str = "0008_add_missing_indexes"
down_revision: Union[str, None] = "0007_soft_delete_announcements"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # grades: both FK columns are queried individually (student views their grades,
    # teacher views grades they entered). Postgres only auto-indexes the PK.
    op.create_index("ix_grades_student_id", "grades", ["student_id"])
    op.create_index("ix_grades_teacher_id", "grades", ["teacher_id"])

    # classroom_students and teacher_students have composite PKs whose leading
    # column is classroom_id / teacher_id respectively. Postgres creates a btree
    # on (leading, student_id) but cannot use it for WHERE student_id = ? alone.
    # A dedicated index on student_id lets announcement-recipient selection and
    # roster lookups avoid a sequential scan as the dataset grows.
    op.create_index("ix_classroom_students_student_id", "classroom_students", ["student_id"])
    op.create_index("ix_teacher_students_student_id", "teacher_students", ["student_id"])


def downgrade() -> None:
    op.drop_index("ix_teacher_students_student_id", table_name="teacher_students")
    op.drop_index("ix_classroom_students_student_id", table_name="classroom_students")
    op.drop_index("ix_grades_teacher_id", table_name="grades")
    op.drop_index("ix_grades_student_id", table_name="grades")
