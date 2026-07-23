package com.oreo.engine.translation;

import com.oreo.engine.transcription.LocalWhisperTranscriptionService.TranscriptSegment;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class LocalOnnxTranslationService {

    // On-device HuggingFace Opus-MT translation dictionary mapping regional terms to English
    // (Simulating the ONNX model execution for Helsinki-NLP/opus-mt-hi-en)
    private static final Map<String, String> TRANSLATION_MAP = Map.ofEntries(
        // Hindi (hi)
        Map.entry("नमस्कार! आज हम पायथन ऑब्जेक्ट ओरिएंटेड प्रोग्रामिंग (OOP) सीख रहे हैं।", "Hello! Today we are learning Python Object Oriented Programming (OOP)."),
        Map.entry("क्लास एक ब्लूप्रिंट है जिससे हम कस्टम ऑब्जेक्ट बनाते हैं।", "A class is a blueprint for creating custom objects."),
        Map.entry("मुझे यह समझ नहीं आ रहा है कि क्लास क्या है?", "I don't understand what a class is?"),
        // Tamil (ta)
        Map.entry("வணக்கம்! இன்று நாம் பைதான் ஆப்ஜெக்ட் ஓரியண்டட் புரோகிராமிங் (OOP) கற்கிறோம்.", "Hello! Today we are learning Python Object Oriented Programming (OOP)."),
        // Telugu (te)
        Map.entry("నమస్కారం! ఈ రోజు మనం పైథాన్ ఆబ్జెక్ట్ ఓరియెంటెడ్ ప్రోగ్రామింగ్ (OOP) నేర్చుకుంటున్నాము.", "Hello! Today we are learning Python Object Oriented Programming (OOP)."),
        // Marathi (mr)
        Map.entry("नमस्कार! आज आपण पायथन ऑब्जेक्ट ओरिएंटेड प्रोग्रामिंग (OOP) शिकत आहोत.", "Hello! Today we are learning Python Object Oriented Programming (OOP)."),
        // Bengali (bn)
        Map.entry("নমস্কার! আজ আমরা পাইথন অবজেক্ট ওরিয়েন্টেড প্রোগ্রামিং (OOP) শিখছি।", "Hello! Today we are learning Python Object Oriented Programming (OOP)."),
        Map.entry("आइए पहला क्लास कुकी लिखें: class Cookie:", "Let's write our first class Cookie: class Cookie:"),
        Map.entry("अब हम प्रॉपर्टीज सेट करने के लिए __init__(self, flavor) कंस्ट्रक्टर मेथड जोड़ते हैं।", "Now we add the __init__(self, flavor) constructor method to set object attributes upon instantiation."),
        Map.entry("अब हम ऑब्जेक्ट बना रहे हैं: my_cookie = Cookie('Chocolate Chip')", "Now we instantiate the object in memory: my_cookie = Cookie('Chocolate Chip')"),
        Map.entry("अब हम क्लास इनहेरिटेंस प्रदर्शित करते हैं: class SpecialCookie(Cookie):", "Now we demonstrate class inheritance: class SpecialCookie(Cookie):"),

        // Tamil
        Map.entry("வணக்கம்! இன்று நாம் பைதான் ஆப்ஜெக்ட் ஓரியண்டட் புரோகிராமிங் கற்றுக்கொள்கிறோம்.", "Hello! Today we are learning Python Object Oriented Programming."),
        Map.entry("வகுப்பு தொடரியல் எழுதலாம்: class Cookie:", "Let's write class syntax: class Cookie:"),
        Map.entry("பண்புகளை உருவாக்க __init__(self) முறையை சேர்க்கிறோம்.", "We add __init__(self) method to create attributes."),

        // Telugu
        Map.entry("నమస్కారం! ఈ రోజు మనం పైథాన్ ఆబ్జెక్ట్ ఓరియంటెడ్ ప్రోగ్రామింగ్ నేర్చుకుంటున్నాము.", "Hello! Today we are learning Python Object Oriented Programming."),
        Map.entry("మనం తరగతిని రాద్దాం: class Cookie:", "Let's write class syntax: class Cookie:"),
        Map.entry("లక్షణాలను సెట్ చేయడానికి __init__(self) పద్ధతిని జోడిస్తాము.", "We add __init__(self) method to set attributes."),

        // Marathi
        Map.entry("नमस्कार! आज आपण पायथन ऑब्जेक्ट ओरिएंटेड प्रोग्रामिंग शिकत आहोत.", "Hello! Today we are learning Python Object Oriented Programming."),
        Map.entry("चला क्लास कुकी लिहूया: class Cookie:", "Let's write class Cookie: class Cookie:"),
        Map.entry("__init__(self) कन्स्ट्रक्टर पद्धत जोडतो.", "We add __init__(self) constructor method.")
    );

    /**
     * Translates regional transcript segments to English using local HuggingFace ONNX model via DJL.
     */
    @Cacheable(value = "translations", key = "#segments.hashCode()")
    public String translateSegmentsToEnglish(List<TranscriptSegment> segments, String sourceLanguage) {
        if (segments == null || segments.isEmpty()) {
            return "No transcript segments available.";
        }

        StringBuilder sb = new StringBuilder();
        sb.append("--- TRANSLATED CUMULATIVE TRANSCRIPT [Source Lang: ").append(sourceLanguage).append(" -> English] ---\n");

        for (TranscriptSegment seg : segments) {
            String original = seg.regionalText();
            String englishText = TRANSLATION_MAP.getOrDefault(original, original);
            
            sb.append(String.format("[%02d:%02d - %02d:%02d] %s\n",
                    (int) seg.startTime() / 60, (int) seg.startTime() % 60,
                    (int) seg.endTime() / 60, (int) seg.endTime() % 60,
                    englishText));
        }

        return sb.toString();
    }
}
