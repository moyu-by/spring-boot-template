package com.example.demo.controller;

import com.example.demo.annotation.NoLoginRequired;
import com.example.demo.annotation.RateLimit;
import com.example.demo.common.Result;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/test")
public class TestController {

    @NoLoginRequired
    @RateLimit(ratePerSecond = 2, maxCapacity = 3)
    @GetMapping("/rate-limit")
    public Result<String> testRateLimit() {
        return Result.ok("请求通过，当前时间: " + System.currentTimeMillis());
    }

    @NoLoginRequired
    @GetMapping("/ping")
    public Result<String> ping() {
        return Result.ok("pong");
    }
}
