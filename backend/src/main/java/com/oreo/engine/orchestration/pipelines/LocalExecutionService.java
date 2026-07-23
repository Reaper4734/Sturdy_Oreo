package com.oreo.engine.orchestration.pipelines;

import org.springframework.stereotype.Service;

import java.io.File;
import java.nio.file.Files;
import java.util.concurrent.TimeUnit;

@Service
public class LocalExecutionService {

    public ExecutionResult executeCode(String language, String sourceCode) {
        if (!"python".equalsIgnoreCase(language)) {
            // ponytail: native python only for MVP hackathon. Add java/node later if needed.
            return new ExecutionResult(false, "", "Unsupported language for local MVP: " + language);
        }

        try {
            File tempScript = File.createTempFile("script", ".py");
            Files.writeString(tempScript.toPath(), sourceCode);

            ProcessBuilder pb = new ProcessBuilder("python", tempScript.getAbsolutePath());
            Process process = pb.start();

            boolean finished = process.waitFor(5, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                return new ExecutionResult(false, "", "Execution timed out.");
            }

            String stdout = new String(process.getInputStream().readAllBytes());
            String stderr = new String(process.getErrorStream().readAllBytes());
            tempScript.delete();

            return new ExecutionResult(process.exitValue() == 0, stdout, stderr);
        } catch (Exception e) {
            return new ExecutionResult(false, "", "Internal Error: " + e.getMessage());
        }
    }

    public static class ExecutionResult {
        public final boolean passed;
        public final String stdout;
        public final String stderr;

        public ExecutionResult(boolean passed, String stdout, String stderr) {
            this.passed = passed;
            this.stdout = stdout;
            this.stderr = stderr;
        }
    }
}
