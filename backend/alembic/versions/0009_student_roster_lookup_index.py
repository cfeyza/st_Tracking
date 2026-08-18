"""partial index on student_profiles.school_id for placeholder roster lookups

Revision ID: 0009_student_roster_lookup_index
Revises: 0008_add_missing_indexes
Create Date: 2026-08-18

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0009_student_roster_lookup_index"
down_revision: Union[str, None] = "0008_add_missing_indexes"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # find_and_link_teacher_code always looks for placeholder rows
    # (user_id IS NULL) filtered by school_id. A partial index covering
    # only those rows is small and perfectly selective for that query.
    op.create_index(
        "ix_student_profiles_school_id_placeholder",
        "student_profiles",
        ["school_id"],
        postgresql_where=sa.text("user_id IS NULL"),
    )


def downgrade() -> None:
    op.drop_index("ix_student_profiles_school_id_placeholder", table_name="student_profiles")
