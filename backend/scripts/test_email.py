import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Import your Pydantic settings instance
from backend.config import settings

# CONFIGURATION (Pulled dynamically from your .env file via Pydantic)
SMTP_SERVER = settings.SMTP_SERVER
SMTP_PORT = settings.SMTP_PORT
TEST_SENDER_EMAIL = settings.TEST_SENDER_EMAIL
TEST_SENDER_PASSWORD = settings.TEST_SENDER_PASSWORD

# Keep this hardcoded for just this quick script run since it's your personal test inbox
TEST_RECEIVER_EMAIL = settings.TEST_RECEIVER_EMAIL 

print("Initializing SMTP connection sequence using .env variables...")

# 1. Build the multi-part email payload container
message = MIMEMultipart()
message["From"] = TEST_SENDER_EMAIL
message["To"] = TEST_RECEIVER_EMAIL
message["Subject"] = "Biblo SMTP Configuration Integration Success!"

# 2. Attach the raw string text body
body = """
Hello!

If you are reading this, your Python backend successfully pulled your configuration
parameters from your .env file, negotiated the TLS handshake, and fired an email.

Cheers,
Biblo
"""
message.attach(MIMEText(body, "plain"))

try:
    # 3. Establish the secure connection stream using config properties
    print(f"Connecting to {SMTP_SERVER}:{SMTP_PORT}...")
    server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
    
    print("Upgrading connection safety parameters to TLS encrypted...")
    server.starttls()  
    
    print(f"Authenticating session using provider profile: {TEST_SENDER_EMAIL}...")
    server.login(TEST_SENDER_EMAIL, TEST_SENDER_PASSWORD)
    
    print("Transmitting email envelope down the pipe...")
    server.sendmail(TEST_SENDER_EMAIL, TEST_RECEIVER_EMAIL, message.as_string())
    
    # 4. Gracefully close the socket session connection
    server.quit()
    print("SUCCESS! Test email using .env configuration variables has flown out the door.")

except Exception as e:
    print(f"SMTP FAILURE: Something went wrong during transmission:\n{e}")
    print("\nTip: Double check that your .env keys match your Settings class exactly!")