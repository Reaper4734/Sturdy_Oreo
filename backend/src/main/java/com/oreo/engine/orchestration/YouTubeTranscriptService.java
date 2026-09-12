package com.oreo.engine.orchestration;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class YouTubeTranscriptService {

    public YouTubeTranscriptService() {
    }

    public Optional<String> getMultilingualCumulativeTranscript(String videoId, int timeInSeconds, String language) {
        // Fall back to fetching the default transcript via the Python CLI tool,
        // since the LLM now handles all translations natively on the backend.
        return getTranscriptBufferBeforeTimestamp(videoId, timeInSeconds, 1000);
    }

    /**
     * Fetches the transcript line spoken at the specific timestamp for a given video.
     */
    @Cacheable(value = "transcripts", key = "#videoId + '-' + #timeInSeconds")
    public Optional<String> getTranscriptAtTimestamp(String videoId, int timeInSeconds) {
        return getTranscriptBufferBeforeTimestamp(videoId, timeInSeconds, 1000);
    }

    public Optional<String> getTranscriptBufferBeforeTimestamp(String videoId, int timeInSeconds, int maxWords) {
        if (videoId == null || videoId.isEmpty()) {
            return Optional.empty();
        }

        try {
            // Fetch transcript, filter by start time <= timeInSeconds, and grab the last maxWords
            ProcessBuilder pb = new ProcessBuilder("python", "-c", 
                "from youtube_transcript_api import YouTubeTranscriptApi; " +
                "t = YouTubeTranscriptApi.get_transcript('" + videoId + "', languages=['hi', 'en', 'hi-IN', 'es', 'fr', 'de']); " +
                "t_filtered = [x['text'] for x in t if x['start'] <= " + timeInSeconds + "]; " +
                "text = ' '.join(t_filtered).split(); " +
                "print(' '.join(text[-" + maxWords + ":]))"
            );
            pb.redirectErrorStream(true);
            Process process = pb.start();
            java.io.BufferedReader reader = new java.io.BufferedReader(new java.io.InputStreamReader(process.getInputStream()));
            StringBuilder builder = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                builder.append(line).append(" ");
            }
            process.waitFor();
            
            String fullText = builder.toString().trim();
            if (fullText.length() > 0 && !fullText.contains("No module named")) {
                return Optional.of(fullText);
            }
        } catch (Exception e) {
            // fallback below
        }

        // If external transcript could not be fetched, return empty so callers handle absence gracefully
        return Optional.empty();
    }
}
