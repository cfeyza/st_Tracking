"""make student_profiles.user_id nullable (roster placeholders)

Revision ID: 0002_roster_placeholders
Revises: 0001_initial
Create Date: 2026-07-30

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0002_roster_placeholders"
down_revision: Union[str, None] = "0001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column("student_profiles", "user_id", existing_type=sa.Integer(), nullable=True)


def downgrade() -> None:
    op.alter_column("student_profiles", "user_id", existing_type=sa.Integer(), nullable=False)
