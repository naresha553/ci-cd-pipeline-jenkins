package com.lab.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String hello() {
        return "Hello from CI/CD lab!";
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}
