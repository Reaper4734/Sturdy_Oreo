# PenEcho Feature Cloning Guide

This document maps the best features of PenEcho (the AI-powered sparse canvas) to our custom AI Canvas engine, utilizing **Flutter's UI engine** and the **3.1 Flash Lite** multimodal vision model.

---

## 1. Region-Based Vision Context (The Secret Sauce)
**PenEcho Feature:** The canvas is massively infinite (20,000 x 20,000 pixels). The AI cannot process an image that large. Instead, PenEcho dynamically crops only the "active region" where the user is currently writing and sends that to the Vision model.
**Our Flutter Implementation:**
*   **The Hack:** We use Flutter's `RepaintBoundary` widget.
*   Instead of wrapping the entire screen, we allow the user to drag a "Selection Box" (a translucent rectangle) over a specific diagram or handwritten note.
*   Flutter takes a silent screenshot (PNG) of *only* what is inside that `RepaintBoundary` selection box.
*   We convert the PNG to a base64 string and send it to **3.1 Flash Lite** via WebSockets or HTTP.

## 2. Auto-Trigger on Pause (Frictionless AI)
**PenEcho Feature:** You don't have to press an "Ask AI" button. When you stop drawing for 3 seconds, PenEcho automatically evaluates the math equation or diagram you just sketched.
**Our Flutter Implementation:**
*   **The Hack:** Use a Flutter `Timer` (Debouncer).
*   Every time the user lifts their finger/stylus from the screen, a 3-second timer starts.
*   If they touch the screen again before 3 seconds, the timer resets.
*   If the timer hits 3 seconds, Flutter automatically triggers the `RepaintBoundary` screenshot of the active area and sends it to the AI with a default prompt: *"Evaluate this diagram/math and provide a short hint or continuation."*

## 3. Native Canvas Output (No Chatboxes)
**PenEcho Feature:** The AI doesn't reply in a separate chat sidebar. Its answers magically appear as text or math blocks directly on the canvas next to your drawing.
**Our Flutter Implementation:**
*   When the user triggers the AI (via selection box), Flutter stores the `(X, Y)` coordinates of the bottom-right corner of that selection box.
*   When **3.1 Flash Lite** streams its textual explanation back, Flutter spawns a new `Positioned` text widget at those exact `(X, Y)` coordinates on the infinite `Stack`.
*   The AI's explanation looks like it was written directly onto the whiteboard next to the user's diagram.

## 4. Multi-Modal LaTeX and Math Support
**PenEcho Feature:** Built for physics and math, it understands complex formulas and outputs beautifully rendered LaTeX.
**Our Flutter Implementation:**
*   Use the `flutter_math_fork` or `katex_flutter` package.
*   **System Prompt to 3.1 Flash Lite:** *"If you are explaining a mathematical concept from the image, output the formulas using strictly valid LaTeX enclosed in `$$`."*
*   When the UI detects `$$`, it renders it as a crisp math equation on the canvas.

---

## The Master Vision Prompt (For 3.1 Flash Lite)
To make 3.1 Flash Lite behave exactly like PenEcho, inject this prompt when sending the screenshot:

> "You are an AI Tutor looking at a cropped region of a student's digital whiteboard.
> I have attached an image of what they are working on.
> 1. If it is a diagram, explain its components briefly.
> 2. If it is a math/physics problem, point out any errors or provide the next logical step using LaTeX `$$`.
> Keep your answer extremely concise so it fits nicely on a digital sticky note."
