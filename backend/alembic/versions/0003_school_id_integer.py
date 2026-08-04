"""change student_profiles.school_id to integer

Revision ID: 0003_school_id_integer
Revises: 0002_roster_placeholders
Create Date: 2026-08-04

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0003_school_id_integer"
down_revision: Union[str, None] = "0002_roster_placeholders"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        "student_profiles",
        "school_id",
        existing_type=sa.String(length=50),
        type_=sa.Integer(),
        postgresql_using="school_id::integer",
    )


def downgrade() -> None:
    op.alter_column(
        "student_profiles",
        "school_id",
        existing_type=sa.Integer(),
        type_=sa.String(length=50),
        postgresql_using="school_id::varchar",
    )
