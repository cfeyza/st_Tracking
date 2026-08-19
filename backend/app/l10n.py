from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse


class L10nHTTPException(HTTPException):
    """HTTPException that carries both English and Turkish detail strings.
    The exception handler in main.py picks the right one from Accept-Language."""

    def __init__(
        self,
        status_code: int,
        en: str,
        tr: str,
        headers: dict | None = None,
    ) -> None:
        super().__init__(status_code=status_code, detail=en, headers=headers)
        self.en = en
        self.tr = tr


def _locale_for(request: Request) -> str:
    lang = request.headers.get("accept-language", "tr")
    return "tr" if lang.startswith("tr") else "en"


async def l10n_exception_handler(request: Request, exc: L10nHTTPException) -> JSONResponse:
    detail = exc.tr if _locale_for(request) == "tr" else exc.en
    headers = getattr(exc, "headers", None) or {}
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": detail},
        headers=headers,
    )
