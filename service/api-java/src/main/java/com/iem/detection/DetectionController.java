package com.iem.detection;

import com.iem.detection.dto.DetectionHistoryResponse;
import com.iem.detection.dto.DetectionResponse;
import com.iem.security.UserPrincipal;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/detections")
public class DetectionController {

    private final DetectionService detectionService;

    public DetectionController(DetectionService detectionService) {
        this.detectionService = detectionService;
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<DetectionResponse> scan(@AuthenticationPrincipal UserPrincipal principal,
                                                  @RequestPart("image") MultipartFile image) {
        return ResponseEntity.ok(detectionService.scan(principal.getId(), image));
    }

    @GetMapping
    public ResponseEntity<DetectionHistoryResponse> history(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(detectionService.history(principal.getId(), page, size));
    }
}
