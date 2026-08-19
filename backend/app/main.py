from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.core.limiter import limiter
from app.routers import auth, parent, student, teacher

app = FastAPI(title="Student Tracking App API", version="0.1.0")

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

_cors_origins = settings.cors_origin_list
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_credentials="*" not in _cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    # @app.exception_handler(Exception) is routed to ServerErrorMiddleware, which sends
    # its response directly to the client — bypassing CORSMiddleware. CORS headers must
    # be added here manually, otherwise the browser blocks every 500 response.
    origin = request.headers.get("origin", "")
    cors_value = "*" if "*" in _cors_origins else (origin if origin in _cors_origins else None)
    headers = {"access-control-allow-origin": cors_value} if cors_value else {}
    return JSONResponse(status_code=500, content={"detail": "Internal server error"}, headers=headers)

app.include_router(auth.router)
app.include_router(teacher.router)
app.include_router(student.router)
app.include_router(parent.router)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
