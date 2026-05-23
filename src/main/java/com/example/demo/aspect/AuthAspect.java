package com.example.demo.aspect;

import com.example.demo.annotation.RoleRequired;
import com.example.demo.common.ContextUtil;
import com.example.demo.enums.RoleEnum;
import com.example.demo.exception.AuthException;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.springframework.stereotype.Component;

import java.util.Arrays;

/**
 * 权限校验切面。
 *
 * <p>检查方法上的 {@link RoleRequired} 注解，
 * 和 {@code JwtInterceptor} 职责分离：
 * <ul>
 *   <li>JwtInterceptor — token 校验，保证已登录</li>
 *   <li>AuthAspect — 角色检查，保证有权限</li>
 * </ul>
 */
@Slf4j
@Aspect
@Component
public class AuthAspect {

    @Before("@annotation(roleRequired)")
    public void checkRole(RoleRequired roleRequired) {
        RoleEnum current = ContextUtil.getRole();

        if (current == null) {
            log.warn("未登录用户尝试访问受保护接口");
            throw new AuthException(AuthException.Type.UNAUTHORIZED, "未登录");
        }

        boolean passed = Arrays.asList(roleRequired.value()).contains(current);
        if (!passed) {
            log.warn("角色不足: need={}, actual={}, userId={}",
                    Arrays.toString(roleRequired.value()), current, ContextUtil.getUserId());
            throw new AuthException(AuthException.Type.UNAUTHORIZED, "权限不足");
        }
    }
}
