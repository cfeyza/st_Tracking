from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import auth, parent, student, teacher

app = FastAPI(title="Student Tracking App API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(teacher.router)
app.include_router(student.router)
app.include_router(parent.router)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
