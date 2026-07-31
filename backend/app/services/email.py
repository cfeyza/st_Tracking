import logging
import smtplib
from email.message import EmailMessage

from app.core.config import settings

logger = logging.getLogger("app.email")


def _build_verification_link(token: str) -> str:
    base = settings.VERIFICATION_BASE_URL.rstrip("/")
    return f"{base}/auth/verify-email?token={token}"


def send_verification_email(to_email: str, name: str, token: str) -> None:
    link = _build_verification_link(token)
    subject = "Verify your Student Tracking App account"
    body = (
        f"Hi {name},\n\n"
        "Thanks for registering for the Student Tracking App. "
        "Please verify your email address by opening the link below:\n\n"
        f"{link}\n\n"
        "This link expires in "
        f"{settings.EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS} hours.\n\n"
        "If you did not create this account, you can ignore this email."
    )

    if not settings.SMTP_HOST:
        logger.info("SMTP not configured; printing verification email instead.\nTo: %s\n%s", to_email, body)
        print(f"[DEV EMAIL] To: {to_email}\nSubject: {subject}\n\n{body}\n")
        return

    message = EmailMessage()
    message["From"] = settings.SMTP_FROM_EMAIL
    message["To"] = to_email
    message["Subject"] = subject
    message.set_content(body)

    with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
        if settings.SMTP_USE_TLS:
            server.starttls()
        if settings.SMTP_USERNAME:
            server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
        server.send_message(message)
