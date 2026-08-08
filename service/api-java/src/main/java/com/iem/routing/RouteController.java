package com.iem.routing;

import com.iem.routing.dto.RouteResponse;
import com.iem.security.UserPrincipal;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/routes")
public class RouteController {

    private final RouteService routeService;

    public RouteController(RouteService routeService) {
        this.routeService = routeService;
    }

    @GetMapping("/my-route")
    @PreAuthorize("hasRole('COLLECTOR')")
    public ResponseEntity<RouteResponse> myRoute(@AuthenticationPrincipal UserPrincipal principal,
                                                 @RequestParam(required = false) String municipalityCode) {
        return ResponseEntity.ok(routeService.planFor(principal.getId(), municipalityCode));
    }
}
