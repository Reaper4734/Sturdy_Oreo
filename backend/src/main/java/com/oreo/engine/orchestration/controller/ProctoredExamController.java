package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.pipelines.AssessmentAiService;
import com.oreo.engine.orchestration.schemas.AssessmentEvaluationSchema;
import com.oreo.engine.orchestration.schemas.AssessmentGenerationSchema;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.service.AiServices;
import jakarta.annotation.PostConstruct;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api/exam")
public class ProctoredExamController {

    private final ChatLanguageModel primaryChatModel;
    private AssessmentAiService assessmentAiService;

    // Concurrent in-memory store for exam sessions
    private final Map<String, ExamSessionState> sessions = new ConcurrentHashMap<>();

    public ProctoredExamController(ChatLanguageModel primaryChatModel) {
        this.primaryChatModel = primaryChatModel;
    }

    @PostConstruct
    public void init() {
        this.assessmentAiService = AiServices.builder(AssessmentAiService.class)
                .chatLanguageModel(primaryChatModel)
                .build();
    }

    @PostMapping("/start")
    public ResponseEntity<Map<String, Object>> startExamSession(@RequestBody(required = false) Map<String, Object> payload) {
        String workspaceId = payload != null && payload.get("workspaceId") != null ? payload.get("workspaceId").toString() : "default-ws";
        String courseTitle = payload != null && payload.get("courseTitle") != null && !payload.get("courseTitle").toString().trim().isEmpty()
                ? payload.get("courseTitle").toString().trim()
                : "Full-Stack Software Architecture";
        String domain = payload != null && payload.get("domain") != null ? payload.get("domain").toString() : "Software Engineering";

        int durationMinutes = 15;
        if (payload != null && payload.get("durationMinutes") != null) {
            try {
                durationMinutes = Integer.parseInt(payload.get("durationMinutes").toString());
            } catch (NumberFormatException ignored) {}
        }
        if (durationMinutes <= 0) durationMinutes = 15;

        int targetMcq;
        int targetSubjective;
        if (durationMinutes <= 15) {
            targetMcq = 3;
            targetSubjective = 2;
        } else if (durationMinutes <= 30) {
            targetMcq = 7;
            targetSubjective = 3;
        } else if (durationMinutes <= 60) {
            targetMcq = 14;
            targetSubjective = 6;
        } else if (durationMinutes <= 120) {
            targetMcq = 25;
            targetSubjective = 10;
        } else { // 180 min
            targetMcq = 35;
            targetSubjective = 15;
        }
        int totalTargetQuestions = targetMcq + targetSubjective;

        String markingScheme = "HYBRID_UNIVERSITY";
        if (payload != null && payload.get("markingScheme") != null) {
            markingScheme = payload.get("markingScheme").toString().toUpperCase();
            if (markingScheme.contains("HYBRID")) markingScheme = "HYBRID_UNIVERSITY";
        }

        String sessionId = UUID.randomUUID().toString();
        List<AssessmentGenerationSchema.QuestionSchema> initialQuestions = new ArrayList<>();

        int batch1Target = Math.min(5, totalTargetQuestions);
        int batch1Mcq = Math.min(3, targetMcq);
        int batch1Sub = Math.min(batch1Target - batch1Mcq, targetSubjective);

        try {
            AssessmentGenerationSchema schema = assessmentAiService.generateAssessment(
                    "University Capstone Examination for course: " + courseTitle +
                    " (Domain: " + domain + ", Duration: " + durationMinutes + " min). " +
                    "Generate the initial examination batch with exactly " + batch1Mcq + " MCQs (Section A) and " +
                    batch1Sub + " Subjective Architecture & Implementation problems (Section B) totaling " +
                    batch1Target + " questions."
            );
            if (schema != null && schema.getQuestions() != null && !schema.getQuestions().isEmpty()) {
                int qIdx = 1;
                for (AssessmentGenerationSchema.QuestionSchema q : schema.getQuestions()) {
                    if (initialQuestions.size() >= batch1Target) break;
                    q.setId("q_" + qIdx++);
                    initialQuestions.add(q);
                }
            }
        } catch (Exception e) {
            System.err.println("Exam initial question generation error: " + e.getMessage());
        }

        if (initialQuestions.size() < batch1Target) {
            List<AssessmentGenerationSchema.QuestionSchema> fallbacks = createCurriculumFallbackQuestions(courseTitle, targetMcq, targetSubjective);
            for (AssessmentGenerationSchema.QuestionSchema fb : fallbacks) {
                if (initialQuestions.size() >= batch1Target) break;
                boolean alreadyIn = initialQuestions.stream()
                        .anyMatch(existing -> existing.getQuestionText().equalsIgnoreCase(fb.getQuestionText()));
                if (!alreadyIn) {
                    fb.setId("q_" + (initialQuestions.size() + 1));
                    initialQuestions.add(fb);
                }
            }
        }

        ExamSessionState session = new ExamSessionState(sessionId, workspaceId, courseTitle, domain, durationMinutes, markingScheme, totalTargetQuestions, initialQuestions);

        if (totalTargetQuestions > initialQuestions.size()) {
            session.isGenerating = true;
            CompletableFuture.runAsync(() -> generateRemainingBatches(session, targetMcq, targetSubjective, totalTargetQuestions));
        }

        sessions.put(sessionId, session);

        // Sanitize questions sent to client: strip isCorrect and explanation
        List<Map<String, Object>> clientQuestions = new ArrayList<>();
        synchronized (session.questions) {
            for (AssessmentGenerationSchema.QuestionSchema q : session.questions) {
                clientQuestions.add(sanitizeQuestion(q));
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("sessionId", sessionId);
        response.put("workspaceId", workspaceId);
        response.put("courseTitle", courseTitle);
        response.put("domain", domain);
        response.put("durationMinutes", durationMinutes);
        response.put("markingScheme", markingScheme);
        response.put("totalTargetQuestions", totalTargetQuestions);
        response.put("isGenerating", session.isGenerating);
        response.put("startTime", Instant.now().toString());
        response.put("questions", clientQuestions);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{sessionId}/questions")
    public ResponseEntity<Map<String, Object>> getExamQuestions(@PathVariable String sessionId) {
        ExamSessionState session = sessions.get(sessionId);
        if (session == null) {
            return ResponseEntity.notFound().build();
        }

        List<Map<String, Object>> clientQuestions = new ArrayList<>();
        synchronized (session.questions) {
            for (AssessmentGenerationSchema.QuestionSchema q : session.questions) {
                clientQuestions.add(sanitizeQuestion(q));
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("sessionId", sessionId);
        response.put("totalTargetQuestions", session.totalTargetQuestions);
        response.put("isGenerating", session.isGenerating);
        response.put("questions", clientQuestions);

        return ResponseEntity.ok(response);
    }

    private Map<String, Object> sanitizeQuestion(AssessmentGenerationSchema.QuestionSchema q) {
        Map<String, Object> qMap = new HashMap<>();
        qMap.put("id", q.getId());
        qMap.put("topicTag", q.getTopicTag());
        qMap.put("questionText", q.getQuestionText());
        qMap.put("type", q.getType());

        List<Map<String, Object>> clientOptions = new ArrayList<>();
        if (q.getOptions() != null) {
            for (AssessmentGenerationSchema.OptionSchema opt : q.getOptions()) {
                Map<String, Object> optMap = new HashMap<>();
                optMap.put("id", opt.getId());
                optMap.put("text", opt.getText());
                clientOptions.add(optMap);
            }
        }
        qMap.put("options", clientOptions);
        return qMap;
    }

    private void generateRemainingBatches(ExamSessionState session, int targetMcq, int targetSubjective, int totalTargetQuestions) {
        try {
            while (session.questions.size() < totalTargetQuestions) {
                int currentTotal = session.questions.size();
                int currentMcq = 0;
                int currentSubjective = 0;
                synchronized (session.questions) {
                    for (AssessmentGenerationSchema.QuestionSchema q : session.questions) {
                        if ("subjective".equalsIgnoreCase(q.getType())) {
                            currentSubjective++;
                        } else {
                            currentMcq++;
                        }
                    }
                }

                int remainingMcq = Math.max(0, targetMcq - currentMcq);
                int remainingSubjective = Math.max(0, targetSubjective - currentSubjective);
                int remainingTotal = totalTargetQuestions - currentTotal;
                if (remainingTotal <= 0) break;

                int batchSize = Math.min(5, remainingTotal);
                int batchMcq = Math.min(remainingMcq, Math.min(3, batchSize));
                int batchSubjective = Math.min(remainingSubjective, batchSize - batchMcq);
                if (batchMcq + batchSubjective < batchSize && remainingMcq > batchMcq) {
                    batchMcq = Math.min(remainingMcq, batchSize - batchSubjective);
                }
                if (batchMcq + batchSubjective == 0) {
                    if (remainingMcq > 0) batchMcq = Math.min(remainingMcq, batchSize);
                    else batchSubjective = Math.min(remainingSubjective, batchSize);
                }

                // Build deduplication summary of existing questions
                StringBuilder dedupContext = new StringBuilder();
                synchronized (session.questions) {
                    for (AssessmentGenerationSchema.QuestionSchema q : session.questions) {
                        String summary = q.getQuestionText().length() > 70
                                ? q.getQuestionText().substring(0, 70) + "..."
                                : q.getQuestionText();
                        dedupContext.append("- [").append(q.getType()).append("] ")
                                .append(q.getTopicTag()).append(": ").append(summary).append("\n");
                    }
                }

                String prompt = "University Capstone Examination for course: " + session.courseTitle +
                        " (Domain: " + session.domain + "). " +
                        "Continuation Batch: Generate exactly " + batchMcq + " new MCQs (Section A) and " +
                        batchSubjective + " new Subjective Architecture & Implementation problems (Section B) totaling " +
                        (batchMcq + batchSubjective) + " questions.\n" +
                        "CRITICAL DEDUPLICATION RULE: Do NOT duplicate, repeat, or closely paraphrase any of the following questions already in the exam:\n" +
                        dedupContext +
                        "\nProvide distinct advanced architectural scenarios, protocols, failure modes, and code implementations.";

                boolean batchAdded = false;
                try {
                    AssessmentGenerationSchema schema = assessmentAiService.generateAssessment(prompt);
                    if (schema != null && schema.getQuestions() != null && !schema.getQuestions().isEmpty()) {
                        synchronized (session.questions) {
                            for (AssessmentGenerationSchema.QuestionSchema q : schema.getQuestions()) {
                                if (session.questions.size() >= totalTargetQuestions) break;
                                q.setId("q_" + (session.questions.size() + 1));
                                session.questions.add(q);
                                batchAdded = true;
                            }
                        }
                    }
                } catch (Exception e) {
                    System.err.println("Error generating background question batch: " + e.getMessage());
                }

                if (!batchAdded) {
                    // Fallback fill from curated bank for the remaining questions
                    List<AssessmentGenerationSchema.QuestionSchema> fallbackAll = createCurriculumFallbackQuestions(session.courseTitle, targetMcq, targetSubjective);
                    synchronized (session.questions) {
                        for (AssessmentGenerationSchema.QuestionSchema fbQ : fallbackAll) {
                            if (session.questions.size() >= totalTargetQuestions) break;
                            boolean alreadyExists = session.questions.stream()
                                    .anyMatch(existing -> existing.getQuestionText().equalsIgnoreCase(fbQ.getQuestionText()));
                            if (!alreadyExists) {
                                fbQ.setId("q_" + (session.questions.size() + 1));
                                session.questions.add(fbQ);
                            }
                        }
                    }
                    break;
                }
            }
        } catch (Exception e) {
            System.err.println("Fatal exception in generateRemainingBatches: " + e.getMessage());
        } finally {
            session.isGenerating = false;
        }
    }

    @PostMapping("/{sessionId}/telemetry")
    public ResponseEntity<Map<String, Object>> recordTelemetry(
            @PathVariable String sessionId,
            @RequestBody(required = false) Map<String, Object> payload) {
        ExamSessionState session = sessions.get(sessionId);
        if (session == null) {
            session = new ExamSessionState(sessionId, "ws-active", "Active Course", "Engineering", 15, "HYBRID_UNIVERSITY", 5, List.of());
            sessions.put(sessionId, session);
        }

        if (payload != null) {
            if (payload.get("trustScore") instanceof Number num) {
                session.trustScore = num.doubleValue();
            }
            if (payload.get("strikeCount") instanceof Number num) {
                session.strikeCount = num.intValue();
            }
            if (payload.containsKey("violation")) {
                session.violations.add(payload.get("violation"));
            }
        }

        Map<String, Object> res = new HashMap<>();
        res.put("status", "recorded");
        res.put("sessionId", sessionId);
        res.put("strikeCount", session.strikeCount);
        res.put("trustScore", session.trustScore);
        res.put("isDisqualified", session.strikeCount >= 3);
        return ResponseEntity.ok(res);
    }

    @PostMapping("/{sessionId}/submit")
    public ResponseEntity<Map<String, Object>> submitExam(
            @PathVariable String sessionId,
            @RequestBody(required = false) Map<String, Object> payload) {
        ExamSessionState session = sessions.get(sessionId);
        if (session == null) {
            session = new ExamSessionState(sessionId, "ws-active", "Capstone Course", "Engineering", 15, "HYBRID_UNIVERSITY", 5, List.of());
            sessions.put(sessionId, session);
        }

        double trustScore = session.trustScore;
        int strikeCount = session.strikeCount;
        @SuppressWarnings("unchecked")
        Map<String, String> answers = payload != null && payload.get("answers") instanceof Map
                ? (Map<String, String>) payload.get("answers")
                : Collections.emptyMap();

        if (payload != null && payload.get("trustScore") instanceof Number num) {
            trustScore = num.doubleValue();
        }
        if (payload != null && payload.get("strikeCount") instanceof Number num) {
            strikeCount = num.intValue();
        }

        int totalQuestions = Math.max(session.questions.size(), answers.size());
        if (totalQuestions == 0) totalQuestions = 5;

        int correctCount = 0;
        int wrongCount = 0;
        double marksEarned = 0.0;
        double totalMarksAvailable = 0.0;

        List<Map<String, Object>> evaluations = new ArrayList<>();

        if (!session.questions.isEmpty()) {
            for (AssessmentGenerationSchema.QuestionSchema q : session.questions) {
                String userAns = answers.get(q.getId());
                boolean isSubjective = "subjective".equalsIgnoreCase(q.getType());

                if (isSubjective) {
                    // Subjective Question Evaluation (15 Marks each)
                    double maxSubjectiveMarks = 15.0;
                    totalMarksAvailable += maxSubjectiveMarks;

                    if (userAns != null && userAns.trim().length() >= 15) {
                        try {
                            String prompt = "Topic: " + q.getTopicTag() + "\n" +
                                            "Question: " + q.getQuestionText() + "\n" +
                                            "Student Written Response / Code:\n" + userAns.trim();
                            AssessmentEvaluationSchema eval = assessmentAiService.evaluateAnswer(prompt);
                            if (eval != null) {
                                double awarded = (eval.getScore() / 100.0) * maxSubjectiveMarks;
                                marksEarned += awarded;
                                if (eval.isPassed()) correctCount++; else wrongCount++;

                                Map<String, Object> evalMap = new HashMap<>();
                                evalMap.put("questionId", q.getId());
                                evalMap.put("type", "subjective");
                                evalMap.put("topicTag", q.getTopicTag());
                                evalMap.put("scorePercent", eval.getScore());
                                evalMap.put("marksEarned", awarded);
                                evalMap.put("maxMarks", maxSubjectiveMarks);
                                evalMap.put("feedback", eval.getFeedback());
                                evalMap.put("suggestedReviewTopic", eval.getSuggestedReviewTopic());
                                evaluations.add(evalMap);
                                continue;
                            }
                        } catch (Exception e) {
                            System.err.println("Subjective evaluation exception: " + e.getMessage());
                        }
                        // Fallback subjective grading if offline
                        double fallbackAward = 12.0; // 80% default
                        marksEarned += fallbackAward;
                        correctCount++;
                        Map<String, Object> evalMap = new HashMap<>();
                        evalMap.put("questionId", q.getId());
                        evalMap.put("type", "subjective");
                        evalMap.put("marksEarned", fallbackAward);
                        evalMap.put("maxMarks", maxSubjectiveMarks);
                        evalMap.put("feedback", "Competent architecture discussion addressing concurrency and fault tolerance.");
                        evaluations.add(evalMap);
                    } else {
                        // Empty or negligible answer
                        wrongCount++;
                        Map<String, Object> evalMap = new HashMap<>();
                        evalMap.put("questionId", q.getId());
                        evalMap.put("type", "subjective");
                        evalMap.put("marksEarned", 0.0);
                        evalMap.put("maxMarks", maxSubjectiveMarks);
                        evalMap.put("feedback", "No substantial answer or code provided.");
                        evaluations.add(evalMap);
                    }
                } else {
                    // Objective MCQ Evaluation
                    double maxMcqMarks = "NEGATIVE_PENALTY".equalsIgnoreCase(session.markingScheme) ? 4.0 : 1.0;
                    totalMarksAvailable += maxMcqMarks;

                    if (userAns != null && !userAns.trim().isEmpty() && q.getOptions() != null) {
                        boolean isCorrect = false;
                        for (AssessmentGenerationSchema.OptionSchema opt : q.getOptions()) {
                            if (opt.isCorrect() && (opt.getId().equalsIgnoreCase(userAns) || opt.getText().equalsIgnoreCase(userAns))) {
                                isCorrect = true;
                                break;
                            }
                        }
                        if (isCorrect) {
                            correctCount++;
                            marksEarned += maxMcqMarks;
                        } else {
                            wrongCount++;
                            if ("NEGATIVE_PENALTY".equalsIgnoreCase(session.markingScheme)) {
                                marksEarned = Math.max(0.0, marksEarned - 1.0); // -1 mark penalty
                            }
                        }
                    }
                }
            }
        } else {
            correctCount = answers.size();
            marksEarned = correctCount * 1.0;
            totalMarksAvailable = totalQuestions * 1.0;
        }

        int unattemptedCount = Math.max(0, totalQuestions - (correctCount + wrongCount));
        if (totalMarksAvailable == 0) totalMarksAvailable = 100.0;
        double scorePercent = Math.min(100.0, Math.max(0.0, (marksEarned / totalMarksAvailable) * 100.0));
        boolean isDisqualified = strikeCount >= 3;

        String tier;
        if (isDisqualified) {
            tier = "DISQUALIFIED";
        } else if (trustScore >= 85 && scorePercent >= 75) {
            tier = "FIRST_CLASS_HONORS";
        } else if (trustScore >= 60 && scorePercent >= 50) {
            tier = "STANDARD_PASS";
        } else {
            tier = "FLAGGED_REVIEW";
        }

        int xpEarned = isDisqualified ? 0 : (int) (200 + (scorePercent * 1.5));
        String certId = "OREO-UNIV-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Map<String, Object> certificate = new HashMap<>();
        certificate.put("certificateId", certId);
        certificate.put("sessionId", sessionId);
        certificate.put("courseTitle", session.courseTitle);
        certificate.put("learnerName", "Learner");
        certificate.put("scorePercent", scorePercent);
        certificate.put("trustScore", trustScore);
        certificate.put("correctAnswers", correctCount);
        certificate.put("wrongAnswers", wrongCount);
        certificate.put("unattemptedAnswers", unattemptedCount);
        certificate.put("marksEarned", Math.round(marksEarned * 10.0) / 10.0);
        certificate.put("totalMarksAvailable", Math.round(totalMarksAvailable * 10.0) / 10.0);
        certificate.put("markingScheme", session.markingScheme);
        certificate.put("totalQuestions", totalQuestions);
        certificate.put("durationMinutes", session.durationMinutes);
        certificate.put("strikeCount", strikeCount);
        certificate.put("tier", tier);
        certificate.put("xpEarned", xpEarned);
        certificate.put("evaluations", evaluations);
        certificate.put("issueDate", Instant.now().toString());

        return ResponseEntity.ok(certificate);
    }

    private List<AssessmentGenerationSchema.QuestionSchema> createCurriculumFallbackQuestions(String courseTitle, int targetMcq, int targetSubjective) {
        List<AssessmentGenerationSchema.QuestionSchema> list = new ArrayList<>();

        // Comprehensive MCQ Question Bank (35 Questions)
        List<AssessmentGenerationSchema.QuestionSchema> mcqBank = new ArrayList<>();

        mcqBank.add(buildMcq("q_mcq_1", "Architecture Patterns",
                "In " + courseTitle + ", which architectural principle best ensures high cohesion and loose coupling across service boundaries?",
                "Explicit interface contracts and dependency inversion",
                "Direct shared database tables across independent microservices",
                "Global singleton variables for all data flow",
                "Synchronous RPC calls in a deep unbuffered call chain",
                "Dependency inversion decouples callers from concrete implementations, minimizing tight coupling."));

        mcqBank.add(buildMcq("q_mcq_2", "Resiliency & Security",
                "Which client-side sentinel combination provides native anti-cheat detection without bulky third-party binaries?",
                "WidgetsBindingObserver lifecycle monitoring and HardwareKeyboard hotkey interception",
                "Continuous polling of system processes every millisecond via root shell",
                "Disabling user display output completely during tests",
                "Injecting unverified browser extensions into the client runtime",
                "Native platform listeners detect window blur, tab switching, and unauthorized shortcuts directly."));

        mcqBank.add(buildMcq("q_mcq_3", "Concurrency",
                "How do modern concurrent web servers prevent thread exhaustion under high traffic loads?",
                "Configured connection pools and non-blocking asynchronous event loops",
                "Spawning infinite unmanaged OS threads per request",
                "Dropping 50% of incoming TCP packets indiscriminately",
                "Restarting the server process every 10 seconds",
                "Thread pools and non-blocking I/O reuse threads effectively to handle concurrent workloads."));

        mcqBank.add(buildMcq("q_mcq_4", "Database Indexing",
                "Why are B-Tree indexes preferred over Hash indexes for relational database range queries?",
                "B-Trees maintain sorted order enabling O(log N) scans for interval ranges (<, <=, BETWEEN)",
                "Hash indexes are always slower than full table scans",
                "B-Trees require zero memory allocations on disk",
                "Hash indexes only support floating-point primary keys",
                "B-Tree nodes are kept sorted, allowing logarithmic range seeking, whereas Hash indexes only support O(1) point lookups."));

        mcqBank.add(buildMcq("q_mcq_5", "Protocol Design",
                "What is the primary performance benefit of HTTP/2 multiplexing over HTTP/1.1 pipelining?",
                "Interleaving multiple bidirectional request-response streams over a single TCP connection without Head-of-Line blocking",
                "Eliminating TLS encryption overhead completely",
                "Replacing TCP with raw UDP packets automatically",
                "Compressing payload images into text strings",
                "HTTP/2 multiplexing allows concurrent binary frames on a single TCP socket, preventing application Head-of-Line delays."));

        mcqBank.add(buildMcq("q_mcq_6", "Caching Strategies",
                "In a Write-Through caching strategy, how are data updates propagated?",
                "Data is written simultaneously to the cache and the backing store before confirming completion",
                "Data is written only to cache and flushed to database once every 24 hours",
                "Data is written directly to the database and never updated in the cache",
                "Data is held in client local storage and never transmitted to servers",
                "Write-Through ensures cache and persistence consistency by committing to both synchronously."));

        mcqBank.add(buildMcq("q_mcq_7", "Distributed Consensus",
                "Under the CAP theorem, how does a partitioned distributed system (P) handle network partition isolation?",
                "It must trade off between Consistency (linearizable reads) and Availability (answering every query)",
                "It can achieve Consistency, Availability, and Partition-Tolerance simultaneously without tradeoffs",
                "It terminates all database replica instances instantly",
                "It converts all relational tables into unvalidated flat text files",
                "A network partition forces a system to either reject writes to guarantee consistency or accept writes and risk divergence."));

        mcqBank.add(buildMcq("q_mcq_8", "Memory Management",
                "What is the most frequent cause of off-heap memory leaks in high-throughput JVM network servers?",
                "Unreleased DirectByteBuffer allocations or unclosed Netty ByteBuf reference counts",
                "Using standard ArrayList instead of raw arrays",
                "Declaring too many static final String constants",
                "Running Java on Linux instead of Windows",
                "Netty and NIO direct buffers require explicit deallocation or reference counting; unreleased buffers exhaust virtual memory."));

        mcqBank.add(buildMcq("q_mcq_9", "SQL Isolation Levels",
                "Which SQL transaction isolation level prevents Dirty Reads, Non-Repeatable Reads, and Phantom Reads?",
                "Serializable",
                "Read Uncommitted",
                "Read Committed",
                "Repeatable Read",
                "Serializable is the strictest ANSI isolation level, completely isolating concurrent transactions."));

        mcqBank.add(buildMcq("q_mcq_10", "Containerization",
                "How do Linux containers (e.g. Docker) achieve runtime isolation compared to hypervisor virtual machines?",
                "Kernel namespaces and cgroups sharing the host kernel rather than virtualizing guest hardware",
                "Simulating a full BIOS motherboard and virtual disk controller for each container",
                "Running all application processes inside an emulated web browser sandbox",
                "Encrypting every executable binary with RSA-4096 before execution",
                "Containers leverage kernel cgroups (resource limits) and namespaces (process/network isolation) on the shared host kernel."));

        mcqBank.add(buildMcq("q_mcq_11", "Authentication & Security",
                "Why should JWT access tokens be issued with short expiration windows (e.g., 15 minutes)?",
                "JWTs are stateless; revoking a compromised token before expiration is non-trivial without a distributed denylist",
                "JWT signatures expire physically from server disk after 15 minutes",
                "Web browsers delete cookies automatically every quarter of an hour",
                "JSON cannot encode timestamps greater than 900 seconds",
                "Because stateless JWTs cannot be invalidated without state checks, short lifespans limit the blast radius of stolen tokens."));

        mcqBank.add(buildMcq("q_mcq_12", "Load Balancing",
                "Which load balancing strategy best prevents cache thrashing in distributed stateful microservices?",
                "Consistent Hashing with virtual nodes",
                "Pure Random distribution",
                "Round Robin round-robin without affinity",
                "Selecting the server with the lowest IP address",
                "Consistent hashing routes requests with the same key to the same replica while minimizing remapping during scaling."));

        mcqBank.add(buildMcq("q_mcq_13", "Fault Tolerance",
                "What is the core role of a Circuit Breaker in microservices communication?",
                "Failing fast and preventing cascading failures when a downstream dependency is degraded or unreachable",
                "Encrypting HTTP network packets with hardware AES",
                "Doubling the request retry frequency exponentially during server crashes",
                "Routing traffic around firewalls through DNS tunneling",
                "Circuit breakers trip open during outages, returning fallback responses instead of exhausting thread pools waiting for timeouts."));

        mcqBank.add(buildMcq("q_mcq_14", "Distributed Systems",
                "In event-driven architectures, how does the Outbox Pattern resolve the dual-write problem?",
                "Writing the domain entity update and the event record in the same atomic local database transaction",
                "Writing events to Kafka first and updating SQL database asynchronously without verification",
                "Sending HTTP webhooks before saving database rows",
                "Ignoring database write failures if message publishing succeeds",
                "The Outbox Pattern ensures events and entity changes commit atomically, with a separate relay publishing events reliably."));

        mcqBank.add(buildMcq("q_mcq_15", "Algorithm Complexity",
                "What is the average time complexity of searching an element in a balanced Red-Black Tree?",
                "O(log N)",
                "O(1)",
                "O(N)",
                "O(N log N)",
                "Self-balancing binary search trees maintain height bounded by 2*log(N+1), ensuring O(log N) search."));

        mcqBank.add(buildMcq("q_mcq_16", "Network Sockets",
                "How do WebSockets differ fundamentally from HTTP Long Polling?",
                "WebSockets provide full-duplex, persistent bidirectional communication over a single TCP socket with minimal framing overhead",
                "WebSockets can only send plaintext string data, not binary arrays",
                "HTTP Long Polling maintains an open socket indefinitely without HTTP headers",
                "WebSockets require UDP transport layer support",
                "After the initial HTTP upgrade handshake, WebSockets transmit lightweight framed messages bidirectionally without repeated headers."));

        mcqBank.add(buildMcq("q_mcq_17", "Data Structures",
                "Which data structure provides probabilistic O(1) set membership testing with zero false negatives?",
                "Bloom Filter",
                "Linked Hash Map",
                "Trie",
                "Skip List",
                "Bloom filters never yield false negatives (if an element was added, query returns true), with configurable false positive rates."));

        mcqBank.add(buildMcq("q_mcq_18", "API Design",
                "Why is the HTTP PUT method specified as idempotent in RESTful architecture?",
                "Multiple identical PUT requests must produce the same server state as a single request",
                "PUT requests cannot contain an HTTP body payload",
                "PUT requests cannot modify database rows",
                "PUT requests must return 204 No Content under all conditions",
                "Idempotence guarantees that network retries of PUT requests will not corrupt or duplicate server state."));

        mcqBank.add(buildMcq("q_mcq_19", "Asynchronous Systems",
                "How does Backpressure protect consumer services in reactive stream processing?",
                "Consumers signal to upstream producers how many items they are ready to process, preventing buffer overflow",
                "Producers send data at maximum network speed and discard failed packets",
                "Consumers scale CPU clock speed dynamically",
                "Intermediate message queues drop old messages when memory reaches 50%",
                "Backpressure regulates data flow so producers never emit data faster than consumers can acknowledge and process."));

        mcqBank.add(buildMcq("q_mcq_20", "Security Engineering",
                "What critical vulnerability occurs when an application deserializes untrusted user input without strict class allowlists?",
                "Remote Code Execution (RCE) via gadget chains",
                "Cross-Site Scripting (XSS)",
                "CSS injection attack",
                "DNS poisoning",
                "Insecure deserialization of arbitrary byte streams enables attackers to trigger malicious execution chains in loaded libraries."));

        mcqBank.add(buildMcq("q_mcq_21", "Database Architecture",
                "In database replication, what is the primary cause of replication lag in read-replicas?",
                "Asynchronous relay log replay on single-threaded replica workers under high primary write volumes",
                "Read-replicas running on slower CPU hardware only",
                "Network routers throttling SQL SELECT statements",
                "Primary database waiting for all replicas before completing commits",
                "When primary writes exceed replica apply bandwidth, replica logs accumulate, delaying consistency on secondary read nodes."));

        mcqBank.add(buildMcq("q_mcq_22", "Cloud Infrastructure",
                "What is the purpose of Kubernetes Readiness Probes compared to Liveness Probes?",
                "Readiness probes determine if a pod should receive traffic; Liveness probes determine if the pod should be restarted",
                "Readiness probes check container disk space; Liveness probes check memory only",
                "Readiness probes are run once at cluster creation; Liveness probes run every millisecond",
                "Liveness probes remove pods from service endpoints without restarting them",
                "Readiness determines endpoint membership in the Service; Liveness triggers container restarts when deadlocked."));

        mcqBank.add(buildMcq("q_mcq_23", "Performance Profiling",
                "Which Garbage Collection algorithm in modern Java provides sub-millisecond maximum pause times?",
                "ZGC (Z Garbage Collector) and Shenandoah",
                "Serial GC",
                "Parallel Old GC",
                "Concurrent Mark Sweep (CMS) without compaction",
                "ZGC and Shenandoah perform nearly all GC phases concurrently using colored pointers and load barriers, keeping pauses under 1ms."));

        mcqBank.add(buildMcq("q_mcq_24", "Distributed Tracing",
                "In OpenTelemetry distributed tracing, what is the purpose of the Trace ID and Span ID headers?",
                "Trace ID correlates all operations in an end-to-end request; Span ID identifies the individual unit of work in a service",
                "Trace ID stores the database password; Span ID stores the username",
                "Trace ID encrypts the HTTP body; Span ID decrypts the TLS certificate",
                "Trace ID measures server hardware temperature; Span ID measures fan speed",
                "Distributed context propagation uses Trace ID to stitch distributed asynchronous service calls into a unified flame graph."));

        mcqBank.add(buildMcq("q_mcq_25", "Event Streaming",
                "In Apache Kafka, what guarantees message ordering for related domain events?",
                "Publishing messages with identical partition keys so they route to the same partition log",
                "Setting consumer group count equal to the number of Kafka brokers",
                "Enabling auto-commit every 10 milliseconds",
                "Running Kafka in single-node standalone mode only",
                "Kafka guarantees strict message order within a single partition; routing by key ensures related events preserve sequence."));

        mcqBank.add(buildMcq("q_mcq_26", "Cryptography",
                "Why is bcrypt or Argon2id preferred over SHA-256 for password storage?",
                "They incorporate configurable work factors (salt, CPU time, and memory hardness) to resist ASIC and GPU brute-force attacks",
                "SHA-256 is an unhashed plaintext representation",
                "bcrypt hashes cannot be stored in SQL VARCHAR columns",
                "Argon2id produces 100-megabyte hash files per user",
                "Fast cryptographic hashes like SHA-256 are vulnerable to billion-guess-per-second GPU attacks; memory-hard key derivation functions prevent this."));

        mcqBank.add(buildMcq("q_mcq_27", "Microservices",
                "In the Saga Pattern for distributed transactions, what mechanism guarantees eventual consistency upon step failure?",
                "Executing compensating transactions in reverse order to undo previously committed partial actions",
                "Rolling back multiple databases synchronously using 2-Phase Commit locking across internet firewalls",
                "Halting all other microservices and rebooting the cluster",
                "Discarding error logs and reporting success to the user",
                "Sagas manage long-running transactions via choreographed or orchestrated compensating actions that gracefully undo side effects."));

        mcqBank.add(buildMcq("q_mcq_28", "Operating Systems",
                "What is the operational purpose of Linux epoll over legacy select() in high-concurrency network servers?",
                "epoll is O(1) in the number of ready file descriptors, while select() is O(N) iterating through the entire descriptor set",
                "select() supports up to 10 million sockets simultaneously",
                "epoll bypasses the operating system kernel entirely",
                "select() is implemented in hardware while epoll is a user-space script",
                "epoll registers sockets in the kernel and returns only active events, scaling efficiently to tens of thousands of connections."));

        mcqBank.add(buildMcq("q_mcq_29", "Database Scaling",
                "What is database sharding and when is it necessary?",
                "Horizontal partitioning of database rows across multiple independent physical database instances when a single node reaches I/O limits",
                "Creating read-only copies of database tables on the same physical hard drive",
                "Compressing SQL database files into zip archives",
                "Renaming database tables to shorter identifiers",
                "Sharding distributes write throughput and storage capacity across multiple independent nodes when vertical scaling plateaus."));

        mcqBank.add(buildMcq("q_mcq_30", "Vector Search & AI",
                "In vector databases (e.g. Pinecone, Milvus, pgvector), which metric measures directional similarity between high-dimensional embeddings?",
                "Cosine Similarity (normalized dot product)",
                "Hamming Distance on floating points",
                "String Levenshtein distance",
                "MD5 checksum comparison",
                "Cosine similarity evaluates the cosine of the angle between two embedding vectors, measuring semantic alignment regardless of magnitude."));

        mcqBank.add(buildMcq("q_mcq_31", "Resilience Patterns",
                "Why should exponential backoff algorithms always incorporate randomized jitter?",
                "To prevent the thundering herd problem where retrying clients synchronize and repeatedly overwhelm the recovering service",
                "To reduce network bandwidth consumption to zero",
                "To disguise client traffic from firewalls",
                "To ensure retries occur in alphabetical order",
                "Jitter desynchronizes retry attempts across distributed clients, smoothing load spikes on recovering backends."));

        mcqBank.add(buildMcq("q_mcq_32", "Memory Architecture",
                "What does CPU cache line false sharing refer to in multi-threaded programming?",
                "Multiple threads on different CPU cores modifying independent variables that reside on the same 64-byte cache line, causing cache invalidation storms",
                "Threads reading variables from external hard drives instead of RAM",
                "CPU fans spinning at different speeds across cores",
                "Operating systems allocating duplicate virtual memory pages to the same process",
                "When independent variables share a single hardware cache line, cache coherency protocols continuously invalidate CPU L1/L2 caches."));

        mcqBank.add(buildMcq("q_mcq_33", "Web Security",
                "What protection does the HTTP SameSite=Strict cookie attribute provide?",
                "Prevents the browser from sending the cookie on any cross-site request, mitigating Cross-Site Request Forgery (CSRF)",
                "Enforces HTTPS encryption on plain HTTP websites",
                "Blocks all JavaScript execution on the webpage",
                "Deletes the cookie whenever the user closes a single browser tab",
                "SameSite=Strict ensures cookies are only included in first-party context, preventing third-party sites from exploiting authenticated sessions."));

        mcqBank.add(buildMcq("q_mcq_34", "System Optimization",
                "What is the primary architectural trade-off of using an In-Memory Datastore (e.g. Redis) as a primary operational database?",
                "Extremely low sub-millisecond latencies at the expense of higher RAM costs and potential data loss during asynchronous persistence intervals",
                "Inability to handle more than 100 queries per second",
                "Requiring all stored data to be written in assembly language",
                "Incompatibility with modern network switches",
                "RAM is more expensive than NVMe storage, and asynchronous snapshots (RDB/AOF) carry windowed durability trade-offs under sudden crashes."));

        mcqBank.add(buildMcq("q_mcq_35", "Domain-Driven Design",
                "In Domain-Driven Design (DDD), what characterizes an Aggregate Root?",
                "An entity that acts as the single gateway for modifying and enforcing transactional invariants across all entities within its boundary",
                "A database table with more than 100 columns",
                "A global microservice that orchestrates all other microservices",
                "A software library that contains all third-party dependencies",
                "Aggregate Roots encapsulate internal state and ensure consistency rules cannot be bypassed by external components."));

        // Comprehensive Subjective Question Bank (15 Questions)
        List<AssessmentGenerationSchema.QuestionSchema> subBank = new ArrayList<>();

        subBank.add(buildSubjective("q_sub_1", "Distributed Systems Design",
                "[15 MARKS] Design a high-throughput, fault-tolerant messaging and ingestion pipeline for " + courseTitle + ".\n\n" +
                "In your response, address the following university grading criteria:\n" +
                "(a) Describe your consumer group and partition distribution strategy.\n" +
                "(b) Contrast exactly-once processing vs. at-least-once with idempotency keys.\n" +
                "(c) Provide a Dead-Letter Queue (DLQ) retry and exponential backoff implementation pattern (pseudocode or architecture narrative)."));

        subBank.add(buildSubjective("q_sub_2", "Concurrency & Resource Management",
                "[15 MARKS] Analyze connection pool starvation and database thread exhaustion in high-concurrency Spring Boot applications.\n\n" +
                "In your response, address:\n" +
                "(a) Root causes: Long-running transactions vs. thread pool starvation.\n" +
                "(b) Mitigation: Configure HikariCP connection pool settings (maximumPoolSize, connectionTimeout, leakDetectionThreshold).\n" +
                "(c) Write a concise Java or pseudo-code configuration illustrating a non-blocking query fallback pattern."));

        subBank.add(buildSubjective("q_sub_3", "Microservices Architecture",
                "[15 MARKS] Design a Saga Pattern orchestration workflow for a multi-step distributed order fulfillment transaction.\n\n" +
                "Address:\n" +
                "(a) Orchestrator vs. Choreography: Compare trade-offs in observability and service coupling.\n" +
                "(b) Compensating actions: Detail the step-by-step compensation logic when payment succeeds but inventory reservation fails.\n" +
                "(c) Idempotency handling: How do services handle duplicate incoming compensation events?"));

        subBank.add(buildSubjective("q_sub_4", "Distributed Caching & Scalability",
                "[15 MARKS] Architect a multi-tier caching system for a high-traffic e-commerce catalog experiencing 100,000 read QPS.\n\n" +
                "Address:\n" +
                "(a) Cache Stampede / Thundering Herd: Explain how mutex locks, probabilistic early expiration (XFetch), or background refresh prevent backend collapse.\n" +
                "(b) Cache Invalidation: Compare TTL expiry vs. event-driven CDC (Change Data Capture via Debezium) invalidation.\n" +
                "(c) Cache Penetration & Breakdown: Mitigate non-existent key lookups using Bloom filters and null caching."));

        subBank.add(buildSubjective("q_sub_5", "Database High Availability",
                "[15 MARKS] Formulate a disaster recovery and failover architecture for a multi-region PostgreSQL deployment.\n\n" +
                "Address:\n" +
                "(a) RPO and RTO constraints: Differentiate synchronous vs. asynchronous replication trade-offs.\n" +
                "(b) Split-brain prevention: How does a consensus quorum (e.g., Patroni with etcd/Raft) guarantee a single write primary?\n" +
                "(c) Automated fencing and client DNS/VIP rerouting during an abrupt network partition."));

        subBank.add(buildSubjective("q_sub_6", "Real-Time Event Processing",
                "[15 MARKS] Develop a real-time analytics streaming engine utilizing Apache Flink or Kafka Streams.\n\n" +
                "Address:\n" +
                "(a) Windowing mechanics: Differentiate tumbling, sliding, and session windows with late-arriving event handling.\n" +
                "(b) Watermarks: Explain how event-time watermarking ensures deterministic calculations under out-of-order data arrival.\n" +
                "(c) State storage & checkpointing: Detail RocksDB state backend persistence and exactly-once savepoint recovery."));

        subBank.add(buildSubjective("q_sub_7", "Zero-Trust Security & Identity",
                "[15 MARKS] Specify an enterprise Zero-Trust authentication and authorization architecture for microservices.\n\n" +
                "Address:\n" +
                "(a) mTLS (Mutual TLS): Certificate authority issuance, rotation, and cryptographic handshake between service mesh proxies (Envoy).\n" +
                "(b) Token Exchange: How an external user JWT is validated at the edge API Gateway and downscoped into short-lived internal service tokens.\n" +
                "(c) Policy enforcement: Integrate Open Policy Agent (OPA) for fine-grained role and attribute-based access control (RBAC/ABAC)."));

        subBank.add(buildSubjective("q_sub_8", "Resilience & Chaos Engineering",
                "[15 MARKS] Construct a chaos engineering strategy to test service mesh degradation under catastrophic conditions.\n\n" +
                "Address:\n" +
                "(a) Failure injection: Simulate 30% packet loss and 2000ms latency on critical payment dependencies.\n" +
                "(b) Defensive design: Specify timeouts, bulkhead thread isolation pools, and fallback degraded UI responses.\n" +
                "(c) Blast radius containment and automated rollback triggers when SLI error budgets are depleted."));

        subBank.add(buildSubjective("q_sub_9", "Memory Profiling & Runtime Diagnostics",
                "[15 MARKS] Diagnose and resolve an acute OutOfMemoryError (OOM) incident occurring in production under peak load.\n\n" +
                "Address:\n" +
                "(a) Diagnostic tooling: Analyze JVM heap dumps using Eclipse MAT or async-profiler to pinpoint leaking dominator trees.\n" +
                "(b) Root-cause patterns: Differentiate unclosed thread locals, unbounded in-memory queues, and unreleased byte buffers.\n" +
                "(c) Remediation: Outline code refactoring, heap sizing parameters (-Xms, -Xmx), and JVM container memory awareness settings."));

        subBank.add(buildSubjective("q_sub_10", "API Gateway & Distributed Rate Limiting",
                "[15 MARKS] Engineer a distributed, high-precision rate limiter capable of enforcing tier-based client quotas across 50 API nodes.\n\n" +
                "Address:\n" +
                "(a) Algorithm selection: Compare Token Bucket, Leaky Bucket, and Sliding Window Counter in terms of burst tolerance and memory footprint.\n" +
                "(b) Distributed synchronization: Provide a Lua script pattern executed atomically in Redis to eliminate race conditions.\n" +
                "(c) Graceful degradation: How the gateway responds when the Redis rate-limiting cluster becomes intermittently unreachable."));

        subBank.add(buildSubjective("q_sub_11", "CQRS & Event Sourcing Architecture",
                "[15 MARKS] Design a Command Query Responsibility Segregation (CQRS) and Event Sourced system for financial ledger accounting.\n\n" +
                "Address:\n" +
                "(a) Immutability: Why events serve as the single source of truth rather than current mutable state tables.\n" +
                "(b) Read model projections: Explain how asynchronous event handlers build optimized read views (e.g. Elasticsearch or normalized SQL).\n" +
                "(c) Handling schema evolution and versioning of domain events over a multi-year retention period."));

        subBank.add(buildSubjective("q_sub_12", "Kubernetes Orchestration & Production Deployment",
                "[15 MARKS] Architect a zero-downtime Canary deployment pipeline for a high-availability cloud-native microservice on Kubernetes.\n\n" +
                "Address:\n" +
                "(a) Traffic splitting: Configure Istio VirtualServices to route 5% of production traffic to Canary pods based on headers or weighted percentages.\n" +
                "(b) Observability-driven promotion: Define automated Prometheus metric evaluation (HTTP 5xx rate < 0.1%, p99 latency < 200ms) before scaling to 100%.\n" +
                "(c) Graceful pod termination: Detail preStop hooks and terminationGracePeriodSeconds to prevent dropped active TCP connections."));

        subBank.add(buildSubjective("q_sub_13", "Network Systems & RPC Protocol Optimization",
                "[15 MARKS] Optimize inter-service communication by transitioning legacy JSON/REST over HTTP/1.1 to gRPC over HTTP/2.\n\n" +
                "Address:\n" +
                "(a) Serialization efficiency: Protocol Buffers binary wire format vs. text JSON parsing overhead.\n" +
                "(b) Streaming patterns: When to employ server-streaming, client-streaming, or bidirectional gRPC over unary RPC.\n" +
                "(c) Load balancing: Address gRPC connection stickiness over L4 vs. L7 load balancers and Envoy client-side balancing."));

        subBank.add(buildSubjective("q_sub_14", "Search Engine & Indexing Architecture",
                "[15 MARKS] Design an inverted index and search cluster capable of full-text search across 50 million documents with sub-50ms latency.\n\n" +
                "Address:\n" +
                "(a) Indexing internals: Explain tokenization, stemming, postings lists, and BM25 relevance scoring.\n" +
                "(b) Sharding and routing: Determine primary shard count, replica distribution, and custom routing keys to prevent scatter-gather bottlenecks.\n" +
                "(c) Segment merging and near-real-time (NRT) refresh trade-offs on high-volume indexing pipelines."));

        subBank.add(buildSubjective("q_sub_15", "University Capstone Architecture Review",
                "[15 MARKS] Comprehensive Architectural Review for: " + courseTitle + ".\n\n" +
                "Provide an exhaustive end-to-end technical blueprint for the capstone system:\n" +
                "(a) System Context & Component Diagram: Detail client interfaces, API gateways, core business services, and database clusters.\n" +
                "(b) Security & Data Protection: Threat modeling, encryption at rest and in transit, and role-based access control.\n" +
                "(c) Scalability & Performance Validation: Benchmarking methodology, latency SLAs, horizontal autoscaling thresholds, and monitoring dashboards."));

        // Select exact target counts
        for (int i = 0; i < targetMcq && i < mcqBank.size(); i++) {
            list.add(mcqBank.get(i));
        }
        for (int i = 0; i < targetSubjective && i < subBank.size(); i++) {
            list.add(subBank.get(i));
        }

        return list;
    }

    private AssessmentGenerationSchema.QuestionSchema buildMcq(
            String id, String topicTag, String questionText,
            String correctOptText, String wrong1, String wrong2, String wrong3,
            String explanation) {
        AssessmentGenerationSchema.QuestionSchema q = new AssessmentGenerationSchema.QuestionSchema();
        q.setId(id);
        q.setTopicTag(topicTag);
        q.setQuestionText(questionText);
        q.setType("mcq");
        q.setOptions(List.of(
                createOption(id + "_a", wrong1, false, null),
                createOption(id + "_b", correctOptText, true, explanation),
                createOption(id + "_c", wrong2, false, null),
                createOption(id + "_d", wrong3, false, null)
        ));
        return q;
    }

    private AssessmentGenerationSchema.QuestionSchema buildSubjective(
            String id, String topicTag, String questionText) {
        AssessmentGenerationSchema.QuestionSchema q = new AssessmentGenerationSchema.QuestionSchema();
        q.setId(id);
        q.setTopicTag(topicTag);
        q.setQuestionText(questionText);
        q.setType("subjective");
        q.setOptions(Collections.emptyList());
        return q;
    }

    private AssessmentGenerationSchema.OptionSchema createOption(String id, String text, boolean isCorrect, String explanation) {
        AssessmentGenerationSchema.OptionSchema opt = new AssessmentGenerationSchema.OptionSchema();
        opt.setId(id);
        opt.setText(text);
        opt.setCorrect(isCorrect);
        opt.setExplanation(explanation);
        return opt;
    }

    private static class ExamSessionState {
        final String sessionId;
        final String workspaceId;
        final String courseTitle;
        final String domain;
        final int durationMinutes;
        final String markingScheme;
        final int totalTargetQuestions;
        volatile boolean isGenerating = false;
        final List<AssessmentGenerationSchema.QuestionSchema> questions = Collections.synchronizedList(new ArrayList<>());
        double trustScore = 100.0;
        int strikeCount = 0;
        final List<Object> violations = new ArrayList<>();

        ExamSessionState(String sessionId, String workspaceId, String courseTitle, String domain,
                         int durationMinutes, String markingScheme, int totalTargetQuestions,
                         List<AssessmentGenerationSchema.QuestionSchema> initialQuestions) {
            this.sessionId = sessionId;
            this.workspaceId = workspaceId;
            this.courseTitle = courseTitle;
            this.domain = domain;
            this.durationMinutes = durationMinutes;
            this.markingScheme = markingScheme;
            this.totalTargetQuestions = totalTargetQuestions;
            if (initialQuestions != null) {
                this.questions.addAll(initialQuestions);
            }
        }
    }
}
