"""
Shared HTML email utilities for NutriLift.
All emails are sent as HTML with the NutriLift branding.
"""
from django.core.mail import EmailMultiAlternatives
from django.conf import settings

# NutriLift logo hosted on a public CDN-friendly URL
# Using a base64 inline red dumbbell icon as fallback
_LOGO_URL = 'https://raw.githubusercontent.com/lujamanandhar/FYP/main/nutrilift/frontend/assets/nutrilift_logo.png'

_BASE_HTML = """
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; margin: 0; padding: 0; }}
    .container {{ max-width: 520px; margin: 32px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }}
    .header {{ background: linear-gradient(135deg, #B71C1C, #E53935); padding: 32px 24px; text-align: center; }}
    .header img {{ width: 72px; height: 72px; border-radius: 16px; border: 3px solid rgba(255,255,255,0.3); }}
    .header h1 {{ color: #ffffff; font-size: 22px; font-weight: 800; letter-spacing: 3px; margin: 12px 0 4px; }}
    .header p {{ color: rgba(255,255,255,0.8); font-size: 13px; margin: 0; }}
    .body {{ padding: 32px 28px; }}
    .body h2 {{ color: #212121; font-size: 20px; font-weight: 700; margin: 0 0 12px; }}
    .body p {{ color: #555555; font-size: 15px; line-height: 1.6; margin: 0 0 16px; }}
    .otp-box {{ background: #FFF3F3; border: 2px solid #E53935; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0; }}
    .otp-box .otp {{ font-size: 40px; font-weight: 900; letter-spacing: 10px; color: #E53935; }}
    .otp-box .otp-note {{ font-size: 12px; color: #888; margin-top: 8px; }}
    .features {{ background: #fafafa; border-radius: 10px; padding: 16px 20px; margin: 20px 0; }}
    .features li {{ color: #444; font-size: 14px; line-height: 2; list-style: none; padding: 0; }}
    .footer {{ background: #f5f5f5; padding: 20px 28px; text-align: center; border-top: 1px solid #eeeeee; }}
    .footer p {{ color: #aaaaaa; font-size: 12px; margin: 0; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <img src="{logo_url}" alt="NutriLift" onerror="this.style.display='none'">
      <h1>NUTRILIFT</h1>
      <p>Your Fitness Companion</p>
    </div>
    <div class="body">
      {content}
    </div>
    <div class="footer">
      <p>© 2025 NutriLift · Your personal fitness companion</p>
      <p style="margin-top:4px;">This email was sent by NutriLift. Please do not reply.</p>
    </div>
  </div>
</body>
</html>
"""


def send_welcome_email(to_email: str, name: str):
    """Send a branded welcome email after registration."""
    display_name = name or to_email.split('@')[0]
    content = f"""
      <h2>Welcome, {display_name}! 🎉</h2>
      <p>Congratulations on joining <strong>NutriLift</strong> — your personal fitness companion. We're excited to have you on board!</p>
      <ul class="features">
        <li>💪 &nbsp;Track your workouts and personal records</li>
        <li>🥗 &nbsp;Log your nutrition and hit your goals</li>
        <li>🏆 &nbsp;Join challenges and compete with others</li>
        <li>📍 &nbsp;Find gyms near you</li>
      </ul>
      <p>Start your fitness journey today. We're rooting for you!</p>
    """
    html = _BASE_HTML.format(logo_url=_LOGO_URL, content=content)
    _send(
        subject='Welcome to NutriLift! 🎉',
        text=f"Hi {display_name},\n\nWelcome to NutriLift! Start your fitness journey today.\n\n— The NutriLift Team",
        html=html,
        to=to_email,
    )


def send_otp_email(to_email: str, name: str, otp: str):
    """Send a branded password reset OTP email."""
    display_name = name or to_email.split('@')[0]
    content = f"""
      <h2>Password Reset Code</h2>
      <p>Hi <strong>{display_name}</strong>,</p>
      <p>We received a request to reset your NutriLift password. Use the code below:</p>
      <div class="otp-box">
        <div class="otp">{otp}</div>
        <div class="otp-note">This code expires in <strong>10 minutes</strong></div>
      </div>
      <p>If you did not request a password reset, you can safely ignore this email. Your account remains secure.</p>
    """
    html = _BASE_HTML.format(logo_url=_LOGO_URL, content=content)
    _send(
        subject='NutriLift — Your Password Reset Code',
        text=f"Hi {display_name},\n\nYour NutriLift password reset code is: {otp}\n\nExpires in 10 minutes.\n\n— The NutriLift Team",
        html=html,
        to=to_email,
    )


def _send(subject: str, text: str, html: str, to: str):
    """Send an email with both plain text and HTML alternatives."""
    msg = EmailMultiAlternatives(
        subject=subject,
        body=text,
        from_email=settings.DEFAULT_FROM_EMAIL,
        to=[to],
    )
    msg.attach_alternative(html, 'text/html')
    msg.send(fail_silently=True)
