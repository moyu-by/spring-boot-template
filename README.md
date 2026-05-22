# Spring Boot 项目通用样板

一套即拿即用的 Spring Boot 项目模板，消灭 80% 的固定流程代码。

## 技术栈

| 框架 | 版本 | 说明 |
|------|------|------|
| Spring Boot | 4.0.6 | ⚠️ 仅兼容 Spring Boot 4，见下方兼容说明 |
| Java | 25 | |
| MyBatis-Plus | 3.5.16 | 分页 + 自动填充 + 逻辑删除 |
| Redis (Spring Data) | 3.x | 限流、幂等、缓存 |
| JWT (jjwt) | 0.13.0 | 认证 |
| Hutool | 5.8.44 | 工具库（RSA、IP 提取等） |
| SpringDoc | 3.0.3 | Swagger UI |
| Lombok | 1.18.46 | |
| Configuration Processor | — | `@ConfigurationProperties` IDE 自动补全 |
| Jackson 3 | 3.1.2 | JSON 序列化（`tools.jackson`） |
| 数据库驱动 | — | ⚠️ 未引入依赖，见下方数据源说明 |

## 默认配置一览

### 服务

```yaml
server:
  port: 8080
```

### 数据源（必须改）

> ⚠️ pom.xml 中**未引入数据库驱动**，使用前请根据所选数据库自行添加对应依赖（如 SQLite → `sqlite-jdbc`、MySQL → `mysql-connector-j`、PostgreSQL → `postgresql`）。

```yaml
spring:
  datasource:
    url: ${env-database.url}               # 通过环境变量注入
    username: ${env-database.username}
    password: ${env-database.password}
    driver-class-name: org.sqlite.JDBC     # 默认 SQLite，可按需改 MySQL
```

推荐方式：创建 `application-dev.yml`（已被 `.gitignore` 忽略，不会提交到仓库）：

```yaml
env-database:
  url: jdbc:sqlite:./data/db.sqlite
  username:
  password:
```

### JWT

```yaml
jwt:
  secret-key: ${env-jwt.key}     # 无默认值，必须配置
  ttl: 604800000                 # 7 天（毫秒）
```

### 文件上传

```yaml
file:
  protocol: http
  host: localhost
  port: 8080
  sub-path: file
  store-path: ./upload            # 本地存储目录
```

### RSA 密钥

```yaml
key-path: classpath:key           # 从 resources/key/ 加载 private.pem / public.pem
```

### MyBatis-Plus

```yaml
mybatis-plus:
  mapper-locations: classpath*:/mapper/**/*.xml
  type-aliases-package: com.example.demo
  global-config:
    db-config:
      logic-delete-field: deleted    # 逻辑删除字段
      logic-delete-value: 1          # 已删除
      logic-not-delete-value: 0      # 未删除
```

### 异步线程池

```yaml
# 代码配置，无 yaml 项（在 ThreadPoolConfig 中硬编码）
# 核心 5 线程，最大 20，队列 100，拒绝策略 CallerRunsPolicy
```

## 新项目适配清单

从模板创建新项目需要改动以下内容：

### 必须改

| 步骤 | 改什么 | 说明 |
|------|--------|------|
| 1 | 包名/项目名 | 运行 `scripts/rename.sh com.yourcompany yourapp` |
| 2 | 数据库配置 | `application-dev.yml` 填入真实数据库连接 |
| 3 | JWT 密钥 | `application-dev.yml` 将 `env-jwt.key` 换成 `openssl rand -hex 32` |
| 4 | RSA 密钥 | `resources/key/` 下放入你自己的 `private.pem` / `public.pem` |

### 按需改

| 配置 | 默认值 | 什么时候改 |
|------|--------|-----------|
| `file.store-path` | `./upload` | 需要自定义文件存储目录 |
| `server.port` | `8080` | 端口冲突 |
| 线程池参数 | 核心5/最大20/队列100 | 高并发项目需要调大 |
| `jwt.ttl` | 7天 | 缩短 token 有效期 |
| 逻辑删除 | `deleted` 字段 / `1`=已删 / `0`=未删 | 如果你的表用不同字段名 |

### 删除模板示例

| 文件 | 说明 |
|------|------|
| `src/main/resources/mapper/SampleMapper.xml` | 样板 XML，按需删或改 |
| `src/main/resources/application-dev.yml.example` | 示例配置参考，用不到可删 |

## 与 Spring Boot 3 的兼容说明

**此模板基于 Spring Boot 4.0.6，不能直接降级到 Spring Boot 3。** 主要差异：

### 1. 起步依赖改名

```
Spring Boot 3           →   Spring Boot 4
─────────────────────────────────────────────────
spring-boot-starter-web      spring-boot-starter-webmvc
spring-boot-starter-test     spring-boot-starter-webmvc-test
```

### 2. Jackson 3（不兼容 Jackson 2）

Spring Boot 4 内置 Jackson 3，包名从 `com.fasterxml.jackson` 改为 `tools.jackson`：

```java
// Spring Boot 3 (Jackson 2)
import com.fasterxml.jackson.databind.ObjectMapper;

// Spring Boot 4 (Jackson 3)
import tools.jackson.databind.ObjectMapper;           // ← 本模板使用
```

如果降级到 Spring Boot 3，所有 `tools.jackson` 的 import 需要改回 `com.fasterxml.jackson`。

### 3. MyBatis-Plus 依赖不同

```
SB 3: mybatis-plus-spring-boot3-starter
SB 4: mybatis-plus-spring-boot4-starter  (本模板)
```

### 4. AOP 依赖

```
SB 3: spring-boot-starter-aop  (parent 管理)
SB 4: aspectjweaver → pom.xml 中直接引入（starter-aop 已不存在）
```

### 5. Jackson 自动配置类

SB 4 中部分 Jackson 自动配置类路径变化，如 `Jackson2ObjectMapperBuilderCustomizer` 所在包可能有变动。本模板采用直接注入 `ObjectMapper` + `@PostConstruct` 的方式（见 `JacksonConfig.java`），不依赖自动配置类。

### 6. Java 版本

| | 最低要求 | 推荐 |
|--|---------|------|
| Spring Boot 3 | Java 17 | Java 21 |
| Spring Boot 4 | Java 24 | **Java 25**（本模板） |

### 如果想用 Spring Boot 3

将以下依赖替换：

```xml
<!-- 起步依赖 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>   <!-- 不是 webmvc -->
</dependency>

<!-- MyBatis-Plus -->
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-spring-boot3-starter</artifactId>  <!-- boot3 不是 boot4 -->
</dependency>

<!-- AOP -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>  <!-- SB 3 有这个 starter -->
</dependency>
```

同时所有 `tools.jackson` 的 import 改为 `com.fasterxml.jackson`。

## 功能清单

### 认证与授权

| 功能 | 实现 |
|------|------|
| JWT 登录/校验 | `JwtUtil` + `JwtInterceptor` |
| 注解式跳过认证 | `@NoLoginRequired` — 标记公开接口 |
| 角色权限检查 | `@AdminRequired` — 管理员接口 |
| 当前用户上下文 | `ContextUtil.getUserId()` / `ContextUtil.getRole()` — 任意层获取 |

### 接口防护

| 功能 | 实现 |
|------|------|
| 接口限流 | `@RateLimit` — 令牌桶 + Redis Lua 原子操作 |
| 幂等校验 | `@Idempotent` — Redis DEL 原子判重 |
| 参数校验 | `@Valid` / `@Validated` — Jakarta Bean Validation |
| 全局异常处理 | `GlobalExceptionHandler` — 统一 HTTP 状态码 + 业务码 |

### 通用 CRUD

```java
@RestController
@RequestMapping("/users")
public class UserController extends BaseController<UserService, User> {
    // 自动继承 6 个接口，一行不写
}
```

| 方法 | 路径 | 说明 |
|------|------|------|
| `page` | `GET /page?current=1&size=20` | 分页查询 |
| `get` | `GET /{id}` | 查单个 |
| `save` | `POST /` | 新增 |
| `update` | `PUT /` | 修改 |
| `delete` | `DELETE /{id}` | 删除 |
| `list` | `GET /list` | 全量列表 |

### 配置中心

| 配置类 | 说明 |
|--------|------|
| `JacksonConfig` | Long→String 防精度丢失，日期格式化，时区 |
| `RedisConfig` | JSON 序列化，自动存对象（含 `@class` 类型信息） |
| `ThreadPoolConfig` | 异步任务线程池 |
| `WebMvcConfig` | CORS、拦截器、文件静态资源映射 |
| `JwtProperties` | JWT 配置集中管理（`@ConfigurationProperties`） |
| `FileProperties` | 文件上传配置集中管理 |

### 工具类

| 工具 | 说明 |
|------|------|
| `JwtUtil` | JWT 签发/解析，支持 userId + role |
| `RsaUtil` | RSA 加密/解密（PEM 密钥文件） |
| `FileUploadUtil` | 文件上传 + 校验 + 原子写入 |

## 文件结构

```
src/main/java/com/example/demo
├── annotation/        # @NoLoginRequired, @AdminRequired, @RateLimit, @Idempotent
├── aspect/            # AuthAspect, RateLimitAspect, IdempotentAspect
├── common/            # Result, PageResult, BaseController, ContextUtil, UserContext
├── config/            # MybatisPlusConfig, RedisConfig, JacksonConfig, WebMvcConfig, ...

├── controller/        # TokenController（获取幂等 token）
├── enums/             # RoleEnum
├── exception/         # JwtException, AuthException, RateLimitException, FileUploadException
│                      # + GlobalExceptionHandler（全局统一异常处理）
├── interceptor/       # JwtInterceptor
└── utils/             # JwtUtil, RsaUtil, FileUploadUtil

src/main/resources
├── mapper/
│   └── SampleMapper.xml       # 样板 XML 映射文件（可删）
├── key/
│   ├── private.pem            # RSA 私钥（已 gitignore）
│   └── public.pem             # RSA 公钥（已 gitignore）
├── application.yml            # 公共配置
├── application-dev.yml        # 开发环境配置（已 gitignore）
└── application-dev.yml.example # 配置参考示例
```

## 重命名脚本

使用 `scripts/` 下的脚本将项目重命名为你自己的项目，支持：

| 脚本 | 平台 |
|------|------|
| `rename.sh` | Linux / macOS / Git Bash |
| `rename.ps1` | Windows PowerShell / PowerShell Core |

自动替换：包名、目录结构、pom.xml 的 groupId/artifactId、application.yml 的应用名、主启动类名。

```bash
cd scripts && chmod +x rename.sh && ./rename.sh com.yourcompany yourapp
```

## 敏感文件说明

以下文件已被 `.gitignore` 忽略，不会提交到 GitHub，**本地保留不影响开发**：

| 文件 | 原因 |
|------|------|
| `application-dev.yml` | 含 JWT 密钥等敏感信息 |
| `key/*.pem` | RSA 私钥不应公开 |

新用户搭建时需自行创建 `application-dev.yml`（可参考 `application-dev.yml.example`）并生成 RSA 密钥。

## 许可证

MIT
