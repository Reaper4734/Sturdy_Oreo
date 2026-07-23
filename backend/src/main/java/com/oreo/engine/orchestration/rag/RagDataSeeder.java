package com.oreo.engine.orchestration.rag;

import dev.langchain4j.data.segment.TextSegment;
import dev.langchain4j.model.embedding.EmbeddingModel;
import dev.langchain4j.store.embedding.EmbeddingStore;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class RagDataSeeder implements CommandLineRunner {

    private final EmbeddingStore<TextSegment> embeddingStore;
    private final EmbeddingModel embeddingModel;
    private final JdbcTemplate jdbcTemplate;

    public RagDataSeeder(EmbeddingStore<TextSegment> embeddingStore, EmbeddingModel embeddingModel, JdbcTemplate jdbcTemplate) {
        this.embeddingStore = embeddingStore;
        this.embeddingModel = embeddingModel;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) throws Exception {
        Integer count = jdbcTemplate.queryForObject("SELECT count(*) FROM document_embeddings", Integer.class);
        if (count != null && count > 0) {
            System.out.println("RAG Data already seeded. Count: " + count);
            return;
        }

        System.out.println("Seeding RAG data for Python OOP...");

        List<String> documents = List.of(
            "In Python, a class is like a blueprint for creating objects. It defines the initial state (attributes) and behavior (methods) of the objects.",
            "An object in Python is an instance of a class. When you create an object, you are baking a cookie using the class cookie cutter.",
            "The __init__ method in Python is the initializer. It is automatically called when a new object is created to set up its initial attributes.",
            "The 'self' parameter in Python refers to the instance of the object calling the method. It allows access to the attributes and methods of the class.",
            "Inheritance in Python allows a class (child) to inherit attributes and methods from another class (parent), promoting code reuse.",
            "Polymorphism in Python means 'many forms'. It allows methods with the same name to behave differently depending on the object they are called on.",
            "Encapsulation in Python is the bundling of data and methods that operate on that data within one unit, often restricting direct access to some of the object's components.",
            "Abstraction in Python hides complex implementation details and exposes only the essential features of an object."
        );

        try {
            for (String docText : documents) {
                TextSegment segment = TextSegment.from(docText);
                dev.langchain4j.data.embedding.Embedding embedding = embeddingModel.embed(segment).content();
                embeddingStore.add(embedding, segment);
            }
            System.out.println("Successfully seeded " + documents.size() + " documents into RAG store.");
        } catch (Exception e) {
            System.err.println("Failed to seed RAG data: " + e.getMessage());
        }
    }
}
