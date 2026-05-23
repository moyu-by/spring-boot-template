package com.example.demo.annotation;

import com.example.demo.enums.RoleEnum;

import java.lang.annotation.*;

/**
 * 角色权限注解。
 *
 * <p>标注接口需要的角色。可指定单个或多个角色，满足其一即可。
 * 后续增加新角色只需在 {@link RoleEnum} 中加值，不需要加注解。</p>
 *
 * <pre>{@code
 * @RoleRequired(RoleEnum.ADMIN)
 * @DeleteMapping("/user/{id}")
 * public Result<Void> deleteUser(@PathVariable Long id) { ... }
 *
 * @RoleRequired({RoleEnum.ADMIN, RoleEnum.EDITOR})
 * @PutMapping("/article/{id}")
 * public Result<Void> updateArticle(@PathVariable Long id, @RequestBody ArticleReq req) { ... }
 * }</pre>
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RoleRequired {

    /** 需要的角色（多个之间是 OR 关系，满足其一即可） */
    RoleEnum[] value();
}
