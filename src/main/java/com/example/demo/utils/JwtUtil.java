package com.example.demo.utils;

import com.example.demo.common.UserContext;
import com.example.demo.config.JwtProperties;
import com.example.demo.enums.RoleEnum;
import com.example.demo.exception.JwtException;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class JwtUtil {

    private final JwtProperties jwtProperties;

    @PostConstruct
    public void init() {
        String secretKey = jwtProperties.getSecretKey();
        if (secretKey == null || secretKey.isBlank()) {
            log.warn("JWT secret-key 未配置，使用临时密钥（仅用于测试）");
            jwtProperties.setSecretKey("test-only-temporary-key-do-not-use-in-production");
        }
        long ttl = jwtProperties.getTtl();
        if (ttl <= 0) {
            log.warn("JWT ttl 配置不合法 ({}), 使用默认值 7 天", ttl);
            jwtProperties.setTtl(7 * 24 * 60 * 60 * 1000L);
        }
        log.info("JwtUtil 初始化完成, ttl={}ms", jwtProperties.getTtl());
    }

    private SecretKey getSecretKey() {
        return Keys.hmacShaKeyFor(jwtProperties.getSecretKey().getBytes(StandardCharsets.UTF_8));
    }

    public String generateToken(Map<String, Object> claims) {
        if (claims == null || claims.isEmpty()) {
            throw new JwtException(JwtException.Type.INVALID, new IllegalArgumentException("claims 不能为空"));
        }
        return Jwts.builder()
                .claims(claims)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + jwtProperties.getTtl()))
                .signWith(getSecretKey())
                .compact();
    }

    public Claims parseToken(String token) {
        if (token == null || token.isBlank()) {
            throw new JwtException(JwtException.Type.EMPTY);
        }
        try {
            return Jwts.parser()
                    .verifyWith(getSecretKey())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (ExpiredJwtException e) {
            throw new JwtException(JwtException.Type.EXPIRED, e);
        } catch (MalformedJwtException | UnsupportedJwtException | SecurityException e) {
            throw new JwtException(JwtException.Type.INVALID, e);
        } catch (Exception e) {
            log.error("JWT 解析异常", e);
            throw new JwtException(JwtException.Type.CONFIG_ERROR, e);
        }
    }

    public boolean validateToken(String token) {
        parseToken(token);
        return true;
    }

    /**
     * 生成 token（附带角色信息）。
     */
    public String generateToken(Long userId, RoleEnum role) {
        return generateToken(Map.of("userId", userId, "role", role.name()));
    }

    /**
     * 从 token 中提取 userId。
     */
    public Long getUserId(String token) {
        Claims claims = parseToken(token);
        return claims.get("userId", Long.class);
    }

    /**
     * 从 token 中提取角色。
     */
    public RoleEnum getRole(String token) {
        Claims claims = parseToken(token);
        String roleStr = claims.get("role", String.class);
        return roleStr != null ? RoleEnum.valueOf(roleStr) : null;
    }

    /**
     * 从 token 中提取完整用户上下文（userId + role）。
     */
    public UserContext getUserContext(String token) {
        Claims claims = parseToken(token);
        Long userId = claims.get("userId", Long.class);
        String roleStr = claims.get("role", String.class);
        RoleEnum role = roleStr != null ? RoleEnum.valueOf(roleStr) : null;
        return new UserContext(userId, role);
    }
}
