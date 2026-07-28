# ?? Developer Documentation: YouTube Transcription & AI Integration Workflow

This document explains the technical implementation of how Oreo processes YouTube videos, syncs timestamps with transcripts, and utilizes AI and search tools to enhance the learning experience.

---

## 1. Context-Aware Transcript Engine

**Location:** ackend/src/main/java/com/oreo/engine/orchestration/YouTubeTranscriptService.java

Oreo does not rely on guessing. When a user pauses a video to ask a question, the backend retrieves the exact spoken words up to that moment.

### How it Works:
- **The Call:** The frontend sends the ideoId and the exact ideoTimestamp (in seconds).
- **The Execution:** Inside getTranscriptBufferBeforeTimestamp(...), we spawn a lightweight Python sub-process using ProcessBuilder that executes the youtube_transcript_api module.
- **The Logic:**
  `python
  from youtube_transcript_api import YouTubeTranscriptApi
  t = YouTubeTranscriptApi.get_transcript('VIDEO_ID', languages=['en', 'hi', 'es'])
  t_filtered = [x['text'] for x in t if x['start'] <= TIMESTAMP_SECONDS]
  `
- **The Result:** The AI receives only the portion of the video the student has actually watched, preventing "spoilers" or out-of-context answers.

---

## 2. LLM Tool Calling: YouTube Search

**Location:** ackend/src/main/java/com/oreo/engine/orchestration/tools/YouTubeSearchTool.java

When the LLM generates a study plan or remedial quiz tasks, it needs to provide real tutorial links. To prevent the LLM from hallucinating fake URLs, we give it a native tool.

### How it Works:
- **The Tool Definition:** We expose a @Tool("Searches YouTube...") method to LangChain4j.
- **The API Call:** When the LLM calls this tool with a topic (e.g., "Java Arrays"), the method makes an HTTP REST request to the official Google YouTube v3 Data API.
- **The Feedback Loop:** The tool parses the JSON response and returns a string back to the LLM formatted as:
  Title: Java Arrays for Beginners, URL: https://youtube.com/watch?v=12345
- **Result:** The LLM injects these real, verified URLs into the JSON response payload.

---

## 3. Web Search Enrichment

**Location:** ackend/src/main/java/com/oreo/engine/orchestration/config/LlmConfig.java

To ensure the AI produces modern curricula, it has access to a live search engine.

### How it Works:
- In LlmConfig.java, we inject the WebSearchEngine (Tavily/Google Search) directly into the PlannerAssistant's AiServices builder.
- The system prompt explicitly instructs the AI: *"You MUST use your web search tool to research real curriculums... so you do not hallucinate."*
- The AI autonomously pauses its generation, searches the web, reads the results, and then constructs the JSON learning path.

---

## 4. The Autonomous Ingestion Pipeline

**Location:** ackend/src/main/java/com/oreo/engine/orchestration/AutonomousIngestionService.java

This service handles bulk processing when an entire video is uploaded.

### Workflow:
1. **Fetch Full Transcript:** Calls YouTubeTranscriptService with a high max timestamp.
2. **AI Processing:** Passes the transcript to FlashcardGeneratorPipeline which uses the LLM to chunk the text and extract question/answer pairs.
3. **WebSockets (SimpMessagingTemplate):** The backend streams progress updates ("Downloading...") over WebSockets to /topic/ingestion/{videoId} so the frontend UI can display a live progress bar.
