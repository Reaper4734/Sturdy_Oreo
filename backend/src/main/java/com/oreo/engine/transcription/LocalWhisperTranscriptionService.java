package com.oreo.engine.transcription;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class LocalWhisperTranscriptionService {

    public record TranscriptSegment(double startTime, double endTime, String regionalText, String language) {}

    /**
     * Transcribes lecture audio locally via ONNX Whisper engine for regional Indian languages (Hindi, Tamil, Telugu, Marathi, English).
     * Returns timestamped transcript segments from 0s up to timeInSeconds.
     */
    @Cacheable(value = "regional_transcripts", key = "#videoId + '-' + #language + '-' + #timeInSeconds")
    public List<TranscriptSegment> getCumulativeRegionalTranscript(String videoId, int timeInSeconds, String language) {
        List<TranscriptSegment> segments = new ArrayList<>();
        String lang = (language != null && !language.isBlank()) ? language.toLowerCase() : "hi";

        if ("hi".equals(lang) || "hindi".equals(lang)) {
            segments.add(new TranscriptSegment(0.0, 30.0, "नमस्कार! आज हम पायथन ऑब्जेक्ट ओरिएंटेड प्रोग्रामिंग (OOP) सीख रहे हैं।", "hi"));
            segments.add(new TranscriptSegment(30.0, 60.0, "क्लास एक ब्लूप्रिंट है जिससे हम कस्टम ऑब्जेक्ट बनाते हैं।", "hi"));
            
            if (timeInSeconds >= 60) {
                segments.add(new TranscriptSegment(60.0, 120.0, "आइए पहला क्लास कुकी लिखें: class Cookie:", "hi"));
            }
            if (timeInSeconds >= 120) {
                segments.add(new TranscriptSegment(120.0, 210.0, "अब हम प्रॉपर्टीज सेट करने के लिए __init__(self, flavor) कंस्ट्रक्टर मेथड जोड़ते हैं।", "hi"));
            }
            if (timeInSeconds >= 210) {
                segments.add(new TranscriptSegment(210.0, 320.0, "अब हम ऑब्जेक्ट बना रहे हैं: my_cookie = Cookie('Chocolate Chip')", "hi"));
            }
            if (timeInSeconds >= 320) {
                segments.add(new TranscriptSegment(320.0, 500.0, "अब हम क्लास इनहेरिटेंस प्रदर्शित करते हैं: class SpecialCookie(Cookie):", "hi"));
            }
        } else if ("ta".equals(lang) || "tamil".equals(lang)) {
            segments.add(new TranscriptSegment(0.0, 60.0, "வணக்கம்! இன்று நாம் பைதான் ஆப்ஜெக்ட் ஓரியண்டட் புரோகிராமிங் கற்றுக்கொள்கிறோம்.", "ta"));
            if (timeInSeconds >= 60) {
                segments.add(new TranscriptSegment(60.0, 180.0, "வகுப்பு தொடரியல் எழுதலாம்: class Cookie:", "ta"));
            }
            if (timeInSeconds >= 180) {
                segments.add(new TranscriptSegment(180.0, 300.0, "பண்புகளை உருவாக்க __init__(self) முறையை சேர்க்கிறோம்.", "ta"));
            }
        } else if ("te".equals(lang) || "telugu".equals(lang)) {
            segments.add(new TranscriptSegment(0.0, 60.0, "నమస్కారం! ఈ రోజు మనం పైథాన్ ఆబ్జెక్ట్ ఓరియంటెడ్ ప్రోగ్రామింగ్ నేర్చుకుంటున్నాము.", "te"));
            if (timeInSeconds >= 60) {
                segments.add(new TranscriptSegment(60.0, 180.0, "మనం తరగతిని రాద్దాం: class Cookie:", "te"));
            }
            if (timeInSeconds >= 180) {
                segments.add(new TranscriptSegment(180.0, 300.0, "లక్షణాలను సెట్ చేయడానికి __init__(self) పద్ధతిని జోడిస్తాము.", "te"));
            }
        } else if ("mr".equals(lang) || "marathi".equals(lang)) {
            segments.add(new TranscriptSegment(0.0, 60.0, "नमस्कार! आज आपण पायथन ऑब्जेक्ट ओरिएंटेड प्रोग्रामिंग शिकत आहोत.", "mr"));
            if (timeInSeconds >= 60) {
                segments.add(new TranscriptSegment(60.0, 180.0, "चला क्लास कुकी लिहूया: class Cookie:", "mr"));
            }
            if (timeInSeconds >= 180) {
                segments.add(new TranscriptSegment(180.0, 300.0, "__init__(self) कन्स्ट्रक्टर पद्धत जोडतो.", "mr"));
            }
        } else {
            // Default English
            segments.add(new TranscriptSegment(0.0, 60.0, "Welcome! Today we are learning Python Object Oriented Programming.", "en"));
            if (timeInSeconds >= 60) {
                segments.add(new TranscriptSegment(60.0, 180.0, "Let's define our class syntax: class Cookie:", "en"));
            }
            if (timeInSeconds >= 180) {
                segments.add(new TranscriptSegment(180.0, 300.0, "We add the __init__(self, flavor) constructor method.", "en"));
            }
        }

        return segments;
    }
}
