#!/usr/bin/env python3
"""Generate a client-friendly NDU Platform Feature Guide PDF."""

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm, cm
from reportlab.lib.colors import HexColor, white, black
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable, Image
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.platypus.flowables import Flowable
from reportlab.graphics.shapes import Drawing, Rect, Circle, Line, String
from reportlab.graphics import renderPDF
import os

# ── Colours ──────────────────────────────────────────────────────────────
GOLD        = HexColor("#FFD700")
DARK_GOLD   = HexColor("#C5A600")
NAVY        = HexColor("#1A1A2E")
DARK_BLUE   = HexColor("#16213E")
MID_BLUE    = HexColor("#0F3460")
LIGHT_BG    = HexColor("#FAFAFA")
SOFT_GRAY   = HexColor("#F5F5F5")
BORDER_GRAY = HexColor("#E0E0E0")
TEXT_DARK    = HexColor("#1F2933")
TEXT_BODY    = HexColor("#4A5568")
ACCENT_GREEN = HexColor("#10B981")
ACCENT_BLUE  = HexColor("#3B82F6")
ACCENT_PURPLE = HexColor("#8B5CF6")
ACCENT_ORANGE = HexColor("#F59E0B")

WIDTH, HEIGHT = A4

# ── Custom Flowables ─────────────────────────────────────────────────────
class ColourBar(Flowable):
    """A full-width colour bar."""
    def __init__(self, colour=GOLD, height=4):
        Flowable.__init__(self)
        self.colour = colour
        self.bar_height = height
        self.width = WIDTH - 40*mm
    def wrap(self, aW, aH):
        return (aW, self.bar_height)
    def draw(self):
        self.canv.setFillColor(self.colour)
        self.canv.roundRect(0, 0, self.width, self.bar_height, 2, fill=1, stroke=0)

class IconCircle(Flowable):
    """A coloured circle with a symbol."""
    def __init__(self, text, colour, size=28):
        Flowable.__init__(self)
        self.text = text
        self.colour = colour
        self.size = size
    def wrap(self, aW, aH):
        return (self.size, self.size)
    def draw(self):
        c = self.canv
        r = self.size / 2
        c.setFillColor(self.colour)
        c.circle(r, r, r, fill=1, stroke=0)
        c.setFillColor(white)
        c.setFont("Helvetica-Bold", 12)
        c.drawCentredString(r, r - 4, self.text)

class SectionHeader(Flowable):
    """A styled section header with icon and title."""
    def __init__(self, icon_text, title, subtitle, colour):
        Flowable.__init__(self)
        self.icon_text = icon_text
        self.title = title
        self.subtitle = subtitle
        self.colour = colour
    def wrap(self, aW, aH):
        self.width = aW
        return (aW, 50)
    def draw(self):
        c = self.canv
        # Background strip
        c.setFillColor(HexColor("#F8FAFC"))
        c.roundRect(0, 0, self.width, 46, 8, fill=1, stroke=0)
        # Left colour bar
        c.setFillColor(self.colour)
        c.roundRect(0, 0, 5, 46, 2, fill=1, stroke=0)
        # Icon circle
        c.setFillColor(self.colour)
        c.circle(28, 23, 14, fill=1, stroke=0)
        c.setFillColor(white)
        c.setFont("Helvetica-Bold", 11)
        c.drawCentredString(28, 19, self.icon_text)
        # Title
        c.setFillColor(TEXT_DARK)
        c.setFont("Helvetica-Bold", 14)
        c.drawString(52, 26, self.title)
        # Subtitle
        c.setFillColor(TEXT_BODY)
        c.setFont("Helvetica", 9)
        c.drawString(52, 10, self.subtitle)

# ── Page Templates ───────────────────────────────────────────────────────
def cover_page(canvas, doc):
    """Draw the cover page background."""
    c = canvas
    c.saveState()
    # Full dark background
    c.setFillColor(NAVY)
    c.rect(0, 0, WIDTH, HEIGHT, fill=1, stroke=0)
    # Gold accent strip at top
    c.setFillColor(GOLD)
    c.rect(0, HEIGHT - 8, WIDTH, 8, fill=1, stroke=0)
    # Decorative circles
    c.setFillColor(HexColor("#FFFFFF08"))
    c.circle(WIDTH * 0.8, HEIGHT * 0.7, 180, fill=1, stroke=0)
    c.circle(WIDTH * 0.15, HEIGHT * 0.25, 120, fill=1, stroke=0)
    # Gold bar centre decoration
    c.setFillColor(GOLD)
    c.rect(WIDTH/2 - 40, HEIGHT * 0.42, 80, 3, fill=1, stroke=0)
    c.restoreState()

def normal_page(canvas, doc):
    """Header and footer for content pages."""
    c = canvas
    c.saveState()
    # Top gold line
    c.setStrokeColor(GOLD)
    c.setLineWidth(2)
    c.line(20*mm, HEIGHT - 12*mm, WIDTH - 20*mm, HEIGHT - 12*mm)
    # Header text
    c.setFont("Helvetica", 8)
    c.setFillColor(TEXT_BODY)
    c.drawString(20*mm, HEIGHT - 10*mm, "NDU Platform Feature Guide")
    c.drawRightString(WIDTH - 20*mm, HEIGHT - 10*mm, "Confidential")
    # Footer
    c.setStrokeColor(BORDER_GRAY)
    c.setLineWidth(0.5)
    c.line(20*mm, 15*mm, WIDTH - 20*mm, 15*mm)
    c.setFont("Helvetica", 8)
    c.setFillColor(TEXT_BODY)
    c.drawString(20*mm, 10*mm, "NDU Project Management Platform")
    c.drawRightString(WIDTH - 20*mm, 10*mm, f"Page {doc.page}")
    c.restoreState()

# ── Styles ───────────────────────────────────────────────────────────────
styles = getSampleStyleSheet()

s_cover_title = ParagraphStyle(
    'CoverTitle', parent=styles['Title'],
    fontName='Helvetica-Bold', fontSize=36, leading=42,
    textColor=white, alignment=TA_CENTER, spaceAfter=10,
)
s_cover_sub = ParagraphStyle(
    'CoverSub', parent=styles['Normal'],
    fontName='Helvetica', fontSize=14, leading=20,
    textColor=HexColor("#B0B0C0"), alignment=TA_CENTER,
)
s_cover_tagline = ParagraphStyle(
    'CoverTagline', parent=styles['Normal'],
    fontName='Helvetica-Oblique', fontSize=12, leading=18,
    textColor=GOLD, alignment=TA_CENTER,
)
s_body = ParagraphStyle(
    'BodyCustom', parent=styles['Normal'],
    fontName='Helvetica', fontSize=10, leading=15,
    textColor=TEXT_BODY, alignment=TA_JUSTIFY,
    spaceAfter=6,
)
s_body_bold = ParagraphStyle(
    'BodyBold', parent=s_body,
    fontName='Helvetica-Bold', textColor=TEXT_DARK,
)
s_bullet = ParagraphStyle(
    'BulletCustom', parent=s_body,
    leftIndent=18, bulletIndent=6,
    spaceAfter=4, spaceBefore=2,
)
s_sub_bullet = ParagraphStyle(
    'SubBullet', parent=s_bullet,
    leftIndent=36, bulletIndent=24, fontSize=9,
    spaceAfter=3,
)
s_heading2 = ParagraphStyle(
    'Heading2Custom', parent=styles['Heading2'],
    fontName='Helvetica-Bold', fontSize=13, leading=18,
    textColor=TEXT_DARK, spaceBefore=14, spaceAfter=6,
)
s_heading3 = ParagraphStyle(
    'Heading3Custom', parent=styles['Heading3'],
    fontName='Helvetica-Bold', fontSize=11, leading=15,
    textColor=MID_BLUE, spaceBefore=10, spaceAfter=4,
)
s_note = ParagraphStyle(
    'NoteStyle', parent=s_body,
    fontName='Helvetica-Oblique', fontSize=9, leading=13,
    textColor=HexColor("#6B7280"), leftIndent=12,
    borderColor=GOLD, borderWidth=0, borderPadding=6,
    backColor=HexColor("#FFFBEB"), borderRadius=4,
)
s_center = ParagraphStyle(
    'CenterStyle', parent=s_body,
    alignment=TA_CENTER,
)
s_toc_item = ParagraphStyle(
    'TOCItem', parent=s_body,
    fontName='Helvetica', fontSize=11, leading=22,
    textColor=TEXT_DARK, leftIndent=10,
)
s_toc_section = ParagraphStyle(
    'TOCSection', parent=s_body,
    fontName='Helvetica-Bold', fontSize=12, leading=26,
    textColor=NAVY, leftIndent=0, spaceBefore=6,
)

# ── Helper Functions ─────────────────────────────────────────────────────
def bullet(text, style=s_bullet):
    return Paragraph(f'<bullet>&bull;</bullet> {text}', style)

def sub_bullet(text):
    return Paragraph(f'<bullet>&#8212;</bullet> {text}', s_sub_bullet)

def feature_row(icon, title, description, colour):
    """Create a styled feature row as a table."""
    icon_p = Paragraph(f'<font color="{colour.hexval()}" size="14"><b>{icon}</b></font>', s_body)
    title_p = Paragraph(f'<b>{title}</b>', s_body_bold)
    desc_p = Paragraph(description, s_body)
    data = [[icon_p, title_p, desc_p]]
    t = Table(data, colWidths=[22, 120, None])
    t.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (0,0), 0),
    ]))
    return t

def comparison_table(mobile_items, web_items):
    """Create a side-by-side comparison table."""
    # Build rows
    header = [
        Paragraph('<font color="white"><b>Mobile App (iOS &amp; Android)</b></font>', s_center),
        Paragraph('<font color="white"><b>Web App (Desktop &amp; Tablet)</b></font>', s_center),
    ]
    data = [header]
    max_rows = max(len(mobile_items), len(web_items))
    for i in range(max_rows):
        m = mobile_items[i] if i < len(mobile_items) else ""
        w = web_items[i] if i < len(web_items) else ""
        m_p = Paragraph(m, s_body) if m else Paragraph("", s_body)
        w_p = Paragraph(w, s_body) if w else Paragraph("", s_body)
        data.append([m_p, w_p])

    col_w = (WIDTH - 40*mm) / 2
    t = Table(data, colWidths=[col_w, col_w])
    style_cmds = [
        ('BACKGROUND', (0,0), (-1,0), NAVY),
        ('TEXTCOLOR', (0,0), (-1,0), white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,0), 11),
        ('ALIGN', (0,0), (-1,0), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
        ('GRID', (0,0), (-1,-1), 0.5, BORDER_GRAY),
        ('BACKGROUND', (0,1), (-1,-1), white),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [white, SOFT_GRAY]),
    ]
    t.setStyle(TableStyle(style_cmds))
    return t

def note_box(text):
    """A highlighted note/tip box."""
    data = [[Paragraph(f'<font color="#92400E"><b>Tip:</b></font> {text}', s_note)]]
    t = Table(data, colWidths=[WIDTH - 46*mm])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), HexColor("#FFFBEB")),
        ('BOX', (0,0), (-1,-1), 1, GOLD),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
        ('ROUNDEDCORNERS', [4, 4, 4, 4]),
    ]))
    return t

# ── Build Document ───────────────────────────────────────────────────────
output_path = os.path.join(os.path.dirname(__file__), "..", "NDU_Platform_Feature_Guide.pdf")
output_path = os.path.abspath(output_path)

doc = SimpleDocTemplate(
    output_path,
    pagesize=A4,
    topMargin=18*mm,
    bottomMargin=20*mm,
    leftMargin=20*mm,
    rightMargin=20*mm,
)

story = []

# ═══════════════════════════════════════════════════════════════════════════
# COVER PAGE
# ═══════════════════════════════════════════════════════════════════════════
story.append(Spacer(1, HEIGHT * 0.28))
story.append(Paragraph("NDU", s_cover_title))
story.append(Paragraph("Project Management Platform", ParagraphStyle(
    's', parent=s_cover_title, fontSize=22, leading=28, spaceAfter=16,
)))
story.append(Spacer(1, 8))
story.append(Paragraph("Platform Feature Guide", s_cover_tagline))
story.append(Spacer(1, 30))
story.append(Paragraph(
    "A clear overview of what's available on each platform —<br/>"
    "Mobile (iOS &amp; Android) and Web (Desktop &amp; Tablet).",
    s_cover_sub
))
story.append(Spacer(1, 40))
story.append(Paragraph("Version 1.0  |  May 2026", ParagraphStyle(
    's2', parent=s_cover_sub, fontSize=10, textColor=HexColor("#808098"),
)))

# ═══════════════════════════════════════════════════════════════════════════
# PAGE 2 — TABLE OF CONTENTS
# ═══════════════════════════════════════════════════════════════════════════
story.append(PageBreak())
story.append(Paragraph("Contents", ParagraphStyle(
    'TOCTitle', parent=styles['Heading1'],
    fontName='Helvetica-Bold', fontSize=24, leading=30,
    textColor=NAVY, spaceAfter=20,
)))
story.append(ColourBar(GOLD, 3))
story.append(Spacer(1, 16))

toc_sections = [
    ("1", "Introduction", "What this guide covers"),
    ("2", "Platform Overview", "How mobile and web work together"),
    ("3", "Mobile App Features", "iOS & Android capabilities"),
    ("4", "Web App Features", "Desktop & tablet capabilities"),
    ("5", "Feature Comparison", "Side-by-side at a glance"),
    ("6", "Getting Started", "How to access each platform"),
]
for num, title, desc in toc_sections:
    story.append(Paragraph(
        f'<font color="{NAVY.hexval()}"><b>{num}.</b></font>  '
        f'<b>{title}</b>  '
        f'<font color="{TEXT_BODY.hexval()}">— {desc}</font>',
        s_toc_section,
    ))

# ═══════════════════════════════════════════════════════════════════════════
# PAGE 3 — INTRODUCTION
# ═══════════════════════════════════════════════════════════════════════════
story.append(PageBreak())
story.append(Paragraph("1. Introduction", s_heading2))
story.append(ColourBar(GOLD, 2))
story.append(Spacer(1, 10))

story.append(Paragraph(
    "NDU is a comprehensive project management platform designed to support your team "
    "through every phase of the project lifecycle — from initial concept through to delivery and closure.",
    s_body
))
story.append(Spacer(1, 6))
story.append(Paragraph(
    "To give you the best experience, NDU is available across two platforms, each tailored to how you work:",
    s_body
))
story.append(Spacer(1, 8))
story.append(bullet('<b>Mobile App</b> (iOS &amp; Android) — for staying connected and productive while on the move.'))
story.append(bullet('<b>Web App</b> (Desktop &amp; Tablet) — for in-depth planning, detailed reporting, and administrative tasks.'))
story.append(Spacer(1, 10))
story.append(note_box(
    "Both platforms connect to the same project data in real time. "
    "Updates made on your phone are instantly reflected on the web, and vice versa."
))
story.append(Spacer(1, 12))
story.append(Paragraph(
    "This guide outlines exactly which features are available on each platform, "
    "so your team can make the most of NDU no matter where they are.",
    s_body
))

# ═══════════════════════════════════════════════════════════════════════════
# PAGE 4 — PLATFORM OVERVIEW
# ═══════════════════════════════════════════════════════════════════════════
story.append(PageBreak())
story.append(Paragraph("2. Platform Overview", s_heading2))
story.append(ColourBar(GOLD, 2))
story.append(Spacer(1, 10))

story.append(Paragraph(
    "NDU uses a <b>single codebase</b> approach, meaning both the mobile and web versions "
    "share the same core logic, security, and data. The difference is in the user experience — "
    "each platform presents features in a way that suits the device you're using.",
    s_body
))
story.append(Spacer(1, 12))

# Two-column overview cards
overview_data = [
    [
        Paragraph('<font color="white"><b>Mobile App</b></font><br/>'
                  '<font color="#B0B0C0">iOS &amp; Android</font>',
                  ParagraphStyle('p', parent=s_body, alignment=TA_CENTER, textColor=white, fontSize=12, leading=18)),
        Paragraph('<font color="white"><b>Web App</b></font><br/>'
                  '<font color="#B0B0C0">Desktop &amp; Tablet</font>',
                  ParagraphStyle('p', parent=s_body, alignment=TA_CENTER, textColor=white, fontSize=12, leading=18)),
    ],
    [
        Paragraph(
            '&#8226; On-the-go access<br/>'
            '&#8226; Quick updates &amp; approvals<br/>'
            '&#8226; Push notifications<br/>'
            '&#8226; Camera &amp; photo uploads<br/>'
            '&#8226; Streamlined interface<br/>'
            '&#8226; Works offline',
            ParagraphStyle('p', parent=s_body, fontSize=10, leading=16, textColor=HexColor("#E0E0E0")),
        ),
        Paragraph(
            '&#8226; Full planning &amp; design tools<br/>'
            '&#8226; Detailed reporting &amp; analytics<br/>'
            '&#8226; Admin &amp; user management<br/>'
            '&#8226; Complex document editing<br/>'
            '&#8226; Multi-window workflows<br/>'
            '&#8226; Large-screen data views',
            ParagraphStyle('p', parent=s_body, fontSize=10, leading=16, textColor=HexColor("#E0E0E0")),
        ),
    ],
]
col_w = (WIDTH - 42*mm) / 2
overview_table = Table(overview_data, colWidths=[col_w, col_w])
overview_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (0,-1), MID_BLUE),
    ('BACKGROUND', (1,0), (1,-1), NAVY),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('TOPPADDING', (0,0), (-1,0), 16),
    ('BOTTOMPADDING', (0,0), (-1,0), 12),
    ('TOPPADDING', (0,1), (-1,1), 10),
    ('BOTTOMPADDING', (0,1), (-1,1), 16),
    ('LEFTPADDING', (0,0), (-1,-1), 14),
    ('RIGHTPADDING', (0,0), (-1,-1), 14),
    ('ROUNDEDCORNERS', [8, 8, 8, 8]),
]))
story.append(overview_table)

# ═══════════════════════════════════════════════════════════════════════════
# PAGES 5-7 — MOBILE FEATURES
# ═══════════════════════════════════════════════════════════════════════════
story.append(PageBreak())
story.append(Paragraph("3. Mobile App Features", s_heading2))
story.append(ColourBar(ACCENT_BLUE, 2))
story.append(Spacer(1, 6))
story.append(Paragraph(
    "The NDU mobile app puts essential project management tools in your pocket. "
    "It's designed for speed and convenience when you're away from your desk.",
    s_body
))
story.append(Spacer(1, 10))

# --- 3.1 Auth & Onboarding ---
story.append(SectionHeader("A", "Authentication & Onboarding",
    "Secure access and guided setup", ACCENT_BLUE))
story.append(Spacer(1, 8))
story.append(bullet('<b>Sign In &amp; Account Creation</b> — Log in with email/password or Google Sign-In'))
story.append(bullet('<b>Biometric Login</b> — Face ID and fingerprint support for quick, secure access'))
story.append(bullet('<b>Password Recovery</b> — Reset your password directly from the app'))
story.append(bullet('<b>Guided Onboarding</b> — A three-step introduction for new users'))
story.append(Spacer(1, 10))

# --- 3.2 Dashboard ---
story.append(SectionHeader("B", "Dashboard & Project Overview",
    "Your projects at a glance", ACCENT_GREEN))
story.append(Spacer(1, 8))
story.append(bullet('<b>Mobile Dashboard</b> — See all your active projects, milestones, and progress'))
story.append(bullet('<b>Program &amp; Portfolio View</b> — Navigate program and portfolio levels with summary cards'))
story.append(bullet('<b>Quick Stats</b> — Budget, schedule, and risk indicators at a glance'))
story.append(bullet('<b>Project Switching</b> — Jump between projects without leaving the screen'))
story.append(Spacer(1, 10))

# --- 3.3 Daily Operations ---
story.append(SectionHeader("C", "Daily Project Operations",
    "Stay on top of tasks and issues in the field", ACCENT_ORANGE))
story.append(Spacer(1, 8))
story.append(bullet('<b>Progress Tracking</b> — Update task status and log progress on the go'))
story.append(bullet('<b>Issue Logging</b> — Capture and escalate issues immediately with photos'))
story.append(bullet('<b>Risk Flagging</b> — Identify and flag risks before they become problems'))
story.append(bullet('<b>Change Requests</b> — Submit and review change requests'))
story.append(bullet('<b>Meeting Notes</b> — Record action items and decisions during meetings'))
story.append(bullet('<b>Milestone Check-ins</b> — Mark milestones complete and add notes'))
story.append(Spacer(1, 10))

# --- 3.4 Team ---
story.append(PageBreak())
story.append(SectionHeader("D", "Team & Communication",
    "Stay connected with your team", ACCENT_PURPLE))
story.append(Spacer(1, 8))
story.append(bullet('<b>Team Directory</b> — View team members, roles, and contact information'))
story.append(bullet('<b>Task Assignments</b> — Assign and reassign tasks to team members'))
story.append(bullet('<b>Activity Feed</b> — See recent activity and updates across the project'))
story.append(bullet('<b>Role &amp; Responsibility Matrix</b> — Quick reference for who owns what'))
story.append(Spacer(1, 10))

# --- 3.5 Documents ---
story.append(SectionHeader("E", "Documents & Files",
    "Access and share project documents", ACCENT_BLUE))
story.append(Spacer(1, 8))
story.append(bullet('<b>Document Viewer</b> — Open and review project documents directly'))
story.append(bullet('<b>Photo Uploads</b> — Attach photos from your camera to issues, tasks, or reports'))
story.append(bullet('<b>File Sharing</b> — Share documents with team members'))
story.append(bullet('<b>Document Review</b> — Approve or request changes on submitted documents'))
story.append(Spacer(1, 10))

# --- 3.6 Notifications ---
story.append(SectionHeader("F", "Notifications & Alerts",
    "Never miss a critical update", HexColor("#EF4444")))
story.append(Spacer(1, 8))
story.append(bullet('<b>Push Notifications</b> — Instant alerts for deadlines, approvals, and escalations'))
story.append(bullet('<b>In-App Notification Centre</b> — A central place to review all your alerts'))
story.append(bullet('<b>Configurable Preferences</b> — Choose which notifications matter most to you'))
story.append(Spacer(1, 10))

# --- 3.7 AI ---
story.append(SectionHeader("G", "AI Assistant (Mobile)",
    "Intelligent help wherever you are", ACCENT_GREEN))
story.append(Spacer(1, 8))
story.append(bullet('<b>Quick AI Suggestions</b> — Get AI-powered recommendations for your project'))
story.append(bullet('<b>Smart Notes</b> — AI-generated notes and summaries from your project data'))
story.append(bullet('<b>Voice-to-Text Input</b> — Dictate notes and updates hands-free'))

# ═══════════════════════════════════════════════════════════════════════════
# PAGES 8-10 — WEB FEATURES
# ═══════════════════════════════════════════════════════════════════════════
story.append(PageBreak())
story.append(Paragraph("4. Web App Features", s_heading2))
story.append(ColourBar(ACCENT_PURPLE, 2))
story.append(Spacer(1, 6))
story.append(Paragraph(
    "The NDU web app provides the full suite of project management capabilities. "
    "It's optimised for larger screens and in-depth work sessions.",
    s_body
))
story.append(Spacer(1, 10))

# --- 4.1 Everything in Mobile ---
story.append(SectionHeader("*", "Everything in the Mobile App, Plus...",
    "The web app includes all mobile features and more", ACCENT_PURPLE))
story.append(Spacer(1, 8))
story.append(Paragraph(
    "The web app includes every feature listed in Section 3, along with the following additional capabilities "
    "that are designed for desktop and tablet use.",
    s_body
))
story.append(Spacer(1, 10))

# --- 4.2 Full Planning ---
story.append(SectionHeader("H", "Front-End Planning Suite",
    "Comprehensive 12-module planning workflow", MID_BLUE))
story.append(Spacer(1, 8))
story.append(bullet('<b>Requirements Capture</b> — Detailed requirements documentation and traceability'))
story.append(bullet('<b>Procurement Strategy</b> — Vendor evaluation, sourcing approach, and negotiation planning'))
story.append(bullet('<b>Personnel &amp; Organisation</b> — Organisational structure and staffing plans'))
story.append(bullet('<b>Infrastructure Planning</b> — Facilities, equipment, and logistics'))
story.append(bullet('<b>Technology Assessment</b> — Technology stack decisions and integration planning'))
story.append(bullet('<b>Risk &amp; Opportunity Analysis</b> — Detailed risk registers and mitigation plans'))
story.append(bullet('<b>Security &amp; Compliance</b> — Security requirements and compliance frameworks'))
story.append(bullet('<b>Planning Workspace</b> — A unified workspace to navigate all planning modules'))
story.append(bullet('<b>Planning Summary Reports</b> — Auto-generated reports from your planning data'))
story.append(Spacer(1, 10))

# --- 4.3 Design & Technical ---
story.append(SectionHeader("I", "Design & Technical Development",
    "End-to-end design and engineering workflows", ACCENT_BLUE))
story.append(Spacer(1, 8))
story.append(bullet('<b>Design Initiation</b> — Define design scope, constraints, and approach'))
story.append(bullet('<b>Detailed Design</b> — Comprehensive design specifications and documentation'))
story.append(bullet('<b>Engineering Design</b> — Technical engineering plans and blueprints'))
story.append(bullet('<b>Backend Design</b> — Architecture, database, and API design'))
story.append(bullet('<b>UI/UX Design</b> — User interface and experience design workflows'))
story.append(bullet('<b>Architecture Planning</b> — System architecture and integration diagrams'))
story.append(bullet('<b>Technical Debt Management</b> — Track and address technical debt'))
story.append(Spacer(1, 10))

# --- 4.4 Scheduling & Cost ---
story.append(PageBreak())
story.append(SectionHeader("J", "Scheduling, Cost & Financial Management",
    "Precise project financial control", ACCENT_GREEN))
story.append(Spacer(1, 8))
story.append(bullet('<b>CPM Scheduling</b> — Critical Path Method scheduling with Gantt-style views'))
story.append(bullet('<b>Work Breakdown Structure (WBS)</b> — Hierarchical task decomposition'))
story.append(bullet('<b>Cost Estimation</b> — Detailed bottom-up and top-down cost modelling'))
story.append(bullet('<b>Budget Tracking</b> — Real-time budget vs. actual monitoring'))
story.append(bullet('<b>Forecasting</b> — Predictive analytics for cost and schedule outcomes'))
story.append(Spacer(1, 10))

# --- 4.5 Procurement & Contracts ---
story.append(SectionHeader("K", "Procurement & Contract Management",
    "Full procurement and vendor lifecycle", ACCENT_ORANGE))
story.append(Spacer(1, 8))
story.append(bullet('<b>Contract Drafting</b> — AI-assisted contract plan generation and editing'))
story.append(bullet('<b>Vendor Management</b> — Vendor evaluation, comparison, and tracking'))
story.append(bullet('<b>Contract Tracking</b> — Milestone-based contract monitoring'))
story.append(bullet('<b>Contract Close-Out</b> — Formal contract completion and documentation'))
story.append(bullet('<b>Procurement Workflow</b> — End-to-end procurement process management'))
story.append(Spacer(1, 10))

# --- 4.6 Admin ---
story.append(SectionHeader("L", "Administration & Reporting",
    "Manage users, subscriptions, and reporting", HexColor("#EF4444")))
story.append(Spacer(1, 8))
story.append(bullet('<b>User Management</b> — Add, remove, and manage user accounts and permissions'))
story.append(bullet('<b>Subscription Management</b> — Manage plans, billing, and access levels'))
story.append(bullet('<b>Coupon Management</b> — Create and distribute promotional coupons'))
story.append(bullet('<b>Executive Dashboard</b> — High-level portfolio and program analytics'))
story.append(bullet('<b>Status Reports</b> — Comprehensive project status reporting'))
story.append(bullet('<b>Lessons Learned</b> — Capture and share project learnings'))
story.append(bullet('<b>Project Closure</b> — Formal project close-out workflows'))
story.append(bullet('<b>Content Management</b> — Edit and manage platform content'))
story.append(Spacer(1, 10))

# --- 4.7 Safety ---
story.append(SectionHeader("M", "Safety, Health & Environment (SSHER)",
    "Comprehensive safety management", ACCENT_BLUE))
story.append(Spacer(1, 8))
story.append(bullet('<b>Safety Planning</b> — Develop and manage safety plans'))
story.append(bullet('<b>Hazard Identification</b> — Systematic hazard assessment and controls'))
story.append(bullet('<b>Incident Tracking</b> — Log, investigate, and resolve safety incidents'))
story.append(bullet('<b>Compliance Monitoring</b> — Track regulatory and standards compliance'))

# ═══════════════════════════════════════════════════════════════════════════
# FEATURE COMPARISON TABLE
# ═══════════════════════════════════════════════════════════════════════════
story.append(PageBreak())
story.append(Paragraph("5. Feature Comparison", s_heading2))
story.append(ColourBar(GOLD, 2))
story.append(Spacer(1, 6))
story.append(Paragraph(
    "The table below provides a quick reference showing which features are available on each platform.",
    s_body
))
story.append(Spacer(1, 12))

# Comparison data
mobile = [
    '<b>Sign In, Sign Up &amp; Password Recovery</b>',
    '<b>Biometric Login</b> (Face ID / Fingerprint)',
    '<b>Mobile Dashboard</b> with project cards',
    '<b>Progress Updates</b> &amp; status tracking',
    '<b>Issue Logging</b> with photo attachment',
    '<b>Risk Flagging</b> &amp; quick escalation',
    '<b>Change Requests</b> — submit and review',
    '<b>Meeting Notes</b> &amp; action items',
    '<b>Team Directory</b> &amp; role look-up',
    '<b>Document Viewer</b> &amp; file access',
    '<b>Camera Uploads</b> — attach photos',
    '<b>Push Notifications</b> &amp; alerts',
    '<b>AI Quick Suggestions</b>',
    '<b>Voice-to-Text Input</b>',
]
web = [
    'All mobile features, plus:',
    '',
    '<b>Full Dashboard Suite</b> (project, program, portfolio, executive)',
    '<b>Front-End Planning Suite</b> (12 modules)',
    '<b>Design &amp; Technical Development</b> (7 modules)',
    '<b>CPM Scheduling</b> &amp; Gantt Views',
    '<b>Work Breakdown Structure (WBS)</b>',
    '<b>Cost Estimation &amp; Budget Tracking</b>',
    '<b>Contract Drafting &amp; Management</b>',
    '<b>Vendor Management</b>',
    '<b>Procurement Workflow</b>',
    '<b>Admin Dashboard</b> — users, subscriptions, coupons',
    '<b>Executive Reporting &amp; Analytics</b>',
    '<b>SSHER Safety Management</b>',
    '<b>Project Closure Workflows</b>',
    '<b>Lessons Learned Documentation</b>',
]

story.append(comparison_table(mobile, web))
story.append(Spacer(1, 14))
story.append(note_box(
    "Features marked as 'mobile' are also available on the web. "
    "Web-only features require a larger screen for the best experience."
))

# ═══════════════════════════════════════════════════════════════════════════
# GETTING STARTED
# ═══════════════════════════════════════════════════════════════════════════
story.append(PageBreak())
story.append(Paragraph("6. Getting Started", s_heading2))
story.append(ColourBar(GOLD, 2))
story.append(Spacer(1, 10))

story.append(Paragraph(
    "Getting started with NDU is simple. Here's how to access each platform:",
    s_body
))
story.append(Spacer(1, 14))

# Mobile steps
story.append(Paragraph('<font color="#3B82F6"><b>Mobile App</b></font>', s_heading3))
story.append(Spacer(1, 4))
steps_mobile = [
    ('1', 'Download the NDU app from the Apple App Store (iOS) or Google Play Store (Android).'),
    ('2', 'Open the app and complete the one-time onboarding.'),
    ('3', 'Sign in with your credentials or create a new account.'),
    ('4', 'You\'re ready to go! Your projects and data will sync automatically.'),
]
for num, text in steps_mobile:
    story.append(Paragraph(
        f'<font color="{ACCENT_BLUE.hexval()}" size="14"><b>{num}</b></font>  '
        f'  {text}', s_bullet
    ))
story.append(Spacer(1, 16))

# Web steps
story.append(Paragraph('<font color="#8B5CF6"><b>Web App</b></font>', s_heading3))
story.append(Spacer(1, 4))
steps_web = [
    ('1', 'Open your browser and navigate to the NDU web address provided by your organisation.'),
    ('2', 'Sign in with the same credentials you use on mobile.'),
    ('3', 'All your projects, updates, and data will be waiting for you.'),
    ('4', 'For the best experience, use a desktop or tablet with a screen size of 10 inches or larger.'),
]
for num, text in steps_web:
    story.append(Paragraph(
        f'<font color="{ACCENT_PURPLE.hexval()}" size="14"><b>{num}</b></font>  '
        f'  {text}', s_bullet
    ))

story.append(Spacer(1, 20))
story.append(note_box(
    "Your account works across both platforms. There's no separate sign-up needed — "
    "use the same login everywhere."
))

# ═══════════════════════════════════════════════════════════════════════════
# CLOSING PAGE
# ═══════════════════════════════════════════════════════════════════════════
story.append(PageBreak())
story.append(Spacer(1, HEIGHT * 0.25))
story.append(ColourBar(GOLD, 3))
story.append(Spacer(1, 24))
story.append(Paragraph(
    "Thank you for choosing NDU.",
    ParagraphStyle('Closing', parent=s_body, fontSize=18, leading=24,
                   fontName='Helvetica-Bold', textColor=NAVY, alignment=TA_CENTER),
))
story.append(Spacer(1, 12))
story.append(Paragraph(
    "We're here to help your projects succeed — from concept to launch.",
    ParagraphStyle('Closing2', parent=s_body, fontSize=12, leading=18,
                   textColor=TEXT_BODY, alignment=TA_CENTER),
))
story.append(Spacer(1, 30))
story.append(ColourBar(GOLD, 3))
story.append(Spacer(1, 40))
story.append(Paragraph(
    "For support or questions, please contact your NDU account manager.",
    ParagraphStyle('Closing3', parent=s_body, fontSize=10,
                   textColor=TEXT_BODY, alignment=TA_CENTER),
))

# ── Build with page templates ────────────────────────────────────────────
doc.build(
    story,
    onFirstPage=cover_page,
    onLaterPages=normal_page,
)

print(f"PDF generated: {output_path}")
