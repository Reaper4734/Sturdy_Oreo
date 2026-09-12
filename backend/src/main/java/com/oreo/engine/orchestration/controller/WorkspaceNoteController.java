package com.oreo.engine.orchestration.controller;

import com.oreo.engine.orchestration.model.WorkspaceNoteBlock;
import com.oreo.engine.orchestration.model.WorkspaceNotePage;
import com.oreo.engine.orchestration.repository.WorkspaceNoteBlockRepository;
import com.oreo.engine.orchestration.repository.WorkspaceNotePageRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/v1/workspaces/{workspaceId}/notes")
public class WorkspaceNoteController {

    private final WorkspaceNotePageRepository pageRepository;
    private final WorkspaceNoteBlockRepository blockRepository;

    public WorkspaceNoteController(WorkspaceNotePageRepository pageRepository,
                                   WorkspaceNoteBlockRepository blockRepository) {
        this.pageRepository = pageRepository;
        this.blockRepository = blockRepository;
    }

    /**
     * List all note pages in a workspace.
     */
    @GetMapping("/pages")
    public ResponseEntity<List<Map<String, Object>>> getPages(@PathVariable String workspaceId) {
        List<WorkspaceNotePage> pages = pageRepository.findByWorkspaceIdOrderBySortOrderAscCreatedAtAsc(workspaceId);
        List<Map<String, Object>> response = new ArrayList<>();
        for (WorkspaceNotePage page : pages) {
            response.add(pageToMap(page, false));
        }
        return ResponseEntity.ok(response);
    }

    /**
     * Create a new note page in a workspace.
     */
    @PostMapping("/pages")
    @Transactional
    public ResponseEntity<Map<String, Object>> createPage(
            @PathVariable String workspaceId,
            @RequestBody(required = false) Map<String, Object> payload) {

        String pageId = payload != null && payload.containsKey("id") && payload.get("id") != null
                ? (String) payload.get("id")
                : "page_" + UUID.randomUUID().toString().substring(0, 8);

        String title = payload != null && payload.containsKey("title") && payload.get("title") != null
                ? (String) payload.get("title")
                : "Untitled";

        String parentPageId = payload != null && payload.containsKey("parentPageId")
                ? (String) payload.get("parentPageId")
                : null;

        String icon = payload != null && payload.containsKey("icon")
                ? (String) payload.get("icon")
                : null;

        int sortOrder = payload != null && payload.containsKey("sortOrder") && payload.get("sortOrder") instanceof Number
                ? ((Number) payload.get("sortOrder")).intValue()
                : 0;

        WorkspaceNotePage page = new WorkspaceNotePage();
        page.setId(pageId);
        page.setWorkspaceId(workspaceId);
        page.setTitle(title);
        page.setParentPageId(parentPageId);
        page.setIcon(icon);
        page.setSortOrder(sortOrder);
        page = pageRepository.save(page);

        // Check if initial blocks provided or seed a default paragraph block
        List<WorkspaceNoteBlock> blocks = new ArrayList<>();
        if (payload != null && payload.containsKey("blocks") && payload.get("blocks") instanceof List) {
            List<?> rawBlocks = (List<?>) payload.get("blocks");
            int order = 0;
            for (Object item : rawBlocks) {
                if (item instanceof Map) {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> bMap = (Map<String, Object>) item;
                    WorkspaceNoteBlock block = mapToBlock(bMap, page.getId(), order++);
                    blocks.add(blockRepository.save(block));
                }
            }
        } else {
            WorkspaceNoteBlock defaultBlock = new WorkspaceNoteBlock();
            defaultBlock.setId("block_" + UUID.randomUUID().toString().substring(0, 8));
            defaultBlock.setPageId(page.getId());
            defaultBlock.setType("paragraph");
            defaultBlock.setContent("");
            defaultBlock.setSortOrder(0);
            blocks.add(blockRepository.save(defaultBlock));
        }

        Map<String, Object> result = pageToMap(page, true);
        result.put("blocks", blocksToMaps(blocks));
        return ResponseEntity.ok(result);
    }

    /**
     * Get a specific note page and all its blocks.
     */
    @GetMapping("/pages/{pageId}")
    public ResponseEntity<Map<String, Object>> getPage(
            @PathVariable String workspaceId,
            @PathVariable String pageId) {

        return pageRepository.findByIdAndWorkspaceId(pageId, workspaceId)
                .map(page -> {
                    List<WorkspaceNoteBlock> blocks = blockRepository.findByPageIdOrderBySortOrderAscCreatedAtAsc(pageId);
                    Map<String, Object> map = pageToMap(page, true);
                    map.put("blocks", blocksToMaps(blocks));
                    return ResponseEntity.ok(map);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Update page metadata (title, parentPageId, icon, sortOrder).
     */
    @PutMapping("/pages/{pageId}")
    public ResponseEntity<Map<String, Object>> updatePage(
            @PathVariable String workspaceId,
            @PathVariable String pageId,
            @RequestBody Map<String, Object> payload) {

        return pageRepository.findByIdAndWorkspaceId(pageId, workspaceId)
                .map(page -> {
                    if (payload.containsKey("title") && payload.get("title") != null) {
                        page.setTitle((String) payload.get("title"));
                    }
                    if (payload.containsKey("parentPageId")) {
                        String newParent = (String) payload.get("parentPageId");
                        // Prevent self-parenting
                        if (!pageId.equals(newParent)) {
                            page.setParentPageId(newParent);
                        }
                    }
                    if (payload.containsKey("icon")) {
                        page.setIcon((String) payload.get("icon"));
                    }
                    if (payload.containsKey("sortOrder") && payload.get("sortOrder") instanceof Number) {
                        page.setSortOrder(((Number) payload.get("sortOrder")).intValue());
                    }
                    page = pageRepository.save(page);
                    return ResponseEntity.ok(pageToMap(page, false));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Delete a note page and cascade delete its blocks and child pages.
     */
    @DeleteMapping("/pages/{pageId}")
    @Transactional
    public ResponseEntity<Void> deletePage(
            @PathVariable String workspaceId,
            @PathVariable String pageId) {

        return pageRepository.findByIdAndWorkspaceId(pageId, workspaceId)
                .map(page -> {
                    blockRepository.deleteByPageId(pageId);
                    pageRepository.delete(page);
                    return ResponseEntity.ok().<Void>build();
                })
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Bulk save / update blocks for a note page.
     */
    @PutMapping("/pages/{pageId}/blocks")
    @Transactional
    public ResponseEntity<Map<String, Object>> updateBlocks(
            @PathVariable String workspaceId,
            @PathVariable String pageId,
            @RequestBody Map<String, Object> payload) {

        Optional<WorkspaceNotePage> pageOpt = pageRepository.findByIdAndWorkspaceId(pageId, workspaceId);
        if (pageOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        WorkspaceNotePage page = pageOpt.get();

        // Delete existing blocks and insert new ordered blocks
        blockRepository.deleteByPageId(pageId);

        List<WorkspaceNoteBlock> savedBlocks = new ArrayList<>();
        if (payload.containsKey("blocks") && payload.get("blocks") instanceof List) {
            List<?> rawBlocks = (List<?>) payload.get("blocks");
            int order = 0;
            for (Object item : rawBlocks) {
                if (item instanceof Map) {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> bMap = (Map<String, Object>) item;
                    WorkspaceNoteBlock block = mapToBlock(bMap, pageId, order++);
                    savedBlocks.add(blockRepository.save(block));
                }
            }
        }

        // Update page's updatedAt timestamp
        page = pageRepository.save(page);

        Map<String, Object> map = pageToMap(page, true);
        map.put("blocks", blocksToMaps(savedBlocks));
        return ResponseEntity.ok(map);
    }

    // Helper conversions
    private Map<String, Object> pageToMap(WorkspaceNotePage page, boolean includeTimestamps) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", page.getId());
        map.put("workspaceId", page.getWorkspaceId());
        map.put("title", page.getTitle());
        map.put("parentPageId", page.getParentPageId());
        map.put("icon", page.getIcon());
        map.put("sortOrder", page.getSortOrder());
        if (includeTimestamps) {
            map.put("createdAt", page.getCreatedAt() != null ? page.getCreatedAt().toString() : null);
            map.put("updatedAt", page.getUpdatedAt() != null ? page.getUpdatedAt().toString() : null);
        }
        return map;
    }

    private WorkspaceNoteBlock mapToBlock(Map<String, Object> map, String pageId, int sortOrder) {
        WorkspaceNoteBlock block = new WorkspaceNoteBlock();
        String id = map.containsKey("id") && map.get("id") != null
                ? (String) map.get("id")
                : "block_" + UUID.randomUUID().toString().substring(0, 8);
        block.setId(id);
        block.setPageId(pageId);
        block.setType((String) map.getOrDefault("type", "paragraph"));
        block.setContent((String) map.getOrDefault("content", ""));
        block.setSortOrder(map.containsKey("sortOrder") && map.get("sortOrder") instanceof Number
                ? ((Number) map.get("sortOrder")).intValue()
                : sortOrder);

        if (map.containsKey("metadata") && map.get("metadata") instanceof Map) {
            @SuppressWarnings("unchecked")
            Map<String, Object> meta = (Map<String, Object>) map.get("metadata");
            block.setMetadata(meta);
        }
        return block;
    }

    private List<Map<String, Object>> blocksToMaps(List<WorkspaceNoteBlock> blocks) {
        List<Map<String, Object>> list = new ArrayList<>();
        for (WorkspaceNoteBlock block : blocks) {
            Map<String, Object> bMap = new LinkedHashMap<>();
            bMap.put("id", block.getId());
            bMap.put("pageId", block.getPageId());
            bMap.put("type", block.getType());
            bMap.put("content", block.getContent());
            bMap.put("sortOrder", block.getSortOrder());
            bMap.put("metadata", block.getMetadata() != null ? block.getMetadata() : new HashMap<>());
            bMap.put("createdAt", block.getCreatedAt() != null ? block.getCreatedAt().toString() : null);
            bMap.put("updatedAt", block.getUpdatedAt() != null ? block.getUpdatedAt().toString() : null);
            list.add(bMap);
        }
        return list;
    }
}
