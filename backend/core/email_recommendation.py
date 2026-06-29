import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging
from backend.config import settings

logger = logging.getLogger("uvicorn.error")

def send_recommendation_email(receiver_email: str, username: str, books: list) -> bool:
    """
    Builds and transmits a curated catalog update to a designated target subscriber.
    'books' expects a list of dictionaries or SQLAlchemy Book instances containing:
    [.title, .author, .description]
    """
    # 1. Verification Guardrail
    if not receiver_email or not books:
        logger.warning(f"Aborted email execution pipeline: Missing target parameters for user '{username}'.")
        return False

    # 2. Build the Multi-part Container Frame
    message = MIMEMultipart("alternative")
    message["From"] = settings.TEST_SENDER_EMAIL
    message["To"] = receiver_email
    message["Subject"] = f"{username}, Your Curated Book Discoveries are Ready!"

    # 3. Generate HTML Content Rows dynamically from the catalog list
    book_rows_html = ""
    for book in books:
        # Support both raw SQLAlchemy model instances and flat dictionary objects safely
        title = getattr(book, "title", book.get("title", "Unknown Title"))
        author = getattr(book, "author", book.get("author", "Unknown Author"))
        desc = getattr(book, "description", book.get("description", "No description available."))
        
        book_rows_html += f"""
        <div style="margin-bottom: 24px; padding: 16px; border-left: 4px solid #1B5E20; background-color: #f9f9f9;">
            <h3 style="margin: 0 0 4px 0; color: #1B5E20;">{title}</h3>
            <p style="margin: 0 0 8px 0; font-style: italic; color: #555;">by {author}</p>
            <p style="margin: 0; color: #333; font-size: 14px; line-height: 1.5;">{desc}</p>
        </div>
        """

    # 4. Standard structural email HTML wrap
    html_body = f"""
    <html>
        <body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #333; padding: 20px; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #1B5E20; border-bottom: 2px solid #1B5E20; padding-bottom: 8px;">Biblo Personalized Picks ✨</h2>
            <p>Hi {username},</p>
            <p>Based on your chosen reading preferences and genre vectors, our engine has handpicked these titles just for you:</p>
            
            <div style="margin-top: 20px;">
                {book_rows_html}
            </div>
            
            <hr style="border: 0; border-top: 1px solid #eee; margin: 30px 0;" />
            <p style="font-size: 12px; color: #888; text-align: center;">
                Sent automatically by the Biblo Engine. Happy Reading!<br>
                To adjust preferences, open your application dashboard settings.
            </p>
        </body>
    </html>
    """

    # Attach the HTML body payload
    message.attach(MIMEText(html_body, "html"))

    # 5. Network Socket Execution Stream
    try:
        with smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT) as server:
            server.starttls()
            server.login(settings.TEST_SENDER_EMAIL, settings.TEST_SENDER_PASSWORD)
            server.sendmail(settings.TEST_SENDER_EMAIL, receiver_email, message.as_string())
        
        logger.info(f"Successfully dispatched recommendation payload to user: {receiver_email}")
        return True

    except Exception as smtp_error:
        logger.error(f"Service failure transmitting mail packet to {receiver_email}: {smtp_error}")
        return False