---
name: backend-standards
description: 长泰云后端研发规范检查与执行技能。基于《后端研发框架及规范最佳实践指南》，在编写、审查或修改 Java/Spring Boot 后端代码、数据库建表语句、API 接口时，自动校验代码是否符合规范并给出修正建议。当用户编写或修改 Entity/DTO/VO/Controller/Service/Mapper 层代码、创建数据库表、定义 API 接口、使用 @Transactional/Lombok/枚举时，务必触发此技能。即使用户没有明确提及"规范"，只要涉及后端代码编写就应触发。
---

# 后端研发规范检查与执行

本技能基于项目《后端研发框架及规范最佳实践指南》，在后端代码编写、审查、修改过程中提供实时规范校验和修正指导。

## 触发时机

在以下场景中主动检查规范合规性：
- 编写或修改 Entity/DO/DTO/VO 类
- 编写或修改 Controller/Service/Mapper 层代码
- 创建数据库表或编写 DDL
- 定义 RESTful API 接口
- 使用 @Transactional、Lombok 注解、枚举类型
- Code Review 场景

## 规范检查清单

### 一、数据库与数据模型

**命名规范：**
- 所有数据库对象命名采用小写字母 + 下划线（Snake Case），禁止驼峰及大写
- 严禁使用 SQL 保留字（order, desc, key, group 等），需加业务前缀/后缀
- 布尔字段以 `is_` 开头（如 `is_delete`），但 Java Entity 中对应属性**严禁加** `is` 前缀
- 表名前缀：`scm_` 核心业务表、`lx_` 领星同步镜像表、`sys_` 系统配置权限表

**字段类型：**
- 主键统一 `BIGINT(20) UNSIGNED`，禁止 INT
- 金额/费率必须 `DECIMAL`，禁止 FLOAT/DOUBLE
- 时间统一 `DATETIME`，规避 TIMESTAMP
- 存储引擎 InnoDB，字符集 utf8mb4（禁止 utf8）

**一致性：**
- 第三方同步数据表的字段命名、类型、容量必须与外部 API 契约保持绝对映射
- 相同业务含义的字段在不同表中命名与类型必须完全一致

**公共审计字段**（所有业务表必须包含）：
```sql
`is_delete`   tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '单据状态：0-正常, 1-删除',
`create_by`   varchar(64)         NULL DEFAULT '' COMMENT '创建者',
`create_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
`update_by`   varchar(64)         NULL DEFAULT '' COMMENT '更新者',
`update_time` datetime            NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
`remark`      text                NULL COMMENT '备注'
```

### 二、分层架构

**Entity 隔离：**
- Entity/DO 严禁直接暴露给前端 RESTful 接口（不论出参还是入参）
- 必须构建专门的 DTO/Req 和 VO/Resp 模型
- 修改类（Update）、新增类（Insert）、查询类（Query）参数对象必须隔离，禁止复用单一聚合 Request 类
- DO、DTO、VO 三层之间相同属性命名与类型必须保持一致，确保 BeanUtils/MapStruct 稳定映射

**枚举化传输：**
- 严禁业务逻辑中的"魔法数字"（如 `if (status == 1)`）
- 在 Entity/DTO/VO 中直接使用 Enum 枚举类型，配合 `@EnumValue` 实现自动序列化
- 废弃手写 Code→Desc 翻译代码，由系统切面自动附带语义释义

**Controller 规范：**
- 瘦控制器：仅负责参数校验（`@Validated`）、服务调用路由、响应包装
- 响应统一使用 `Result<T>` / `AjaxResult` / `TableDataInfo<T>`，必须声明泛型 `<T>`，禁止用 Object
- 无特定返回类型使用 `Result<Void>`

**Service 隔离：**
- AServiceImpl 只允许注入 AMapper，跨模块必须通过注入 IBService，使用 IBService时可以直接使用baseMapper而不用再注入AMapper
- 禁止直插其他模块的 Mapper 破坏自治边界

### 三、防御性编程

**参数校验：**
- 杜绝 if-else 判空堆砌，使用 `jakarta.validation` 注解体系
- `@NotBlank` 仅修饰 String，`@NotNull` 修饰非字符串包装类，`@NotEmpty` 修饰 Collection/List/Set
- List 内嵌套泛型对象时，外层 List 属性须加 `@Valid` 触发递归校验

**事务管理：**
- 非幂等写操作必须声明 `@Transactional(rollbackFor = Exception.class)`，如果是大事务可使用编程式事务管理
- 前置强检验（Fail-Fast），异常时抛出 ServiceException 终结 AOP
- 禁止隐性捕获异常"私吞"导致事务不回滚

**日志规范：**
- 严禁 `System.out.println` 和 `e.printStackTrace()`
- 使用占位符 `{}` 延迟计算，异常对象 e 放在日志尾端保留堆栈
- 禁止字符串拼接取 `cause.getMessage()` 导致堆栈丢失

**Lombok 规范：**
- DTO/VO/Entity 必须使用 Lombok（@Data, @Getter, @Setter, @Builder），禁止手写 get/set
- 继承 BaseEntity/BaseDTO 时必须声明 `@EqualsAndHashCode(callSuper = true)`
- 带默认值的字段使用 Builder 时必须加 `@Builder.Default`，否则默认值会被吞没变 null

**文件作者规范：**
- 所有新建或修改的 Java 类（Entity/DTO/VO/Controller/Service/Mapper），Javadoc 中 `@author` 统一填写 `raolongxiang`，禁止使用其他作者名
- 修改已有文件时不改动原有的 `@author`

**DTO/VO Swagger 注解规范：**
- 所有 DTO/VO/Request 类的类级别必须添加 `@Schema(description = "类业务含义")` 注解（使用 `io.swagger.v3.oas.annotations.media.Schema`）
- 所有 DTO/VO/Request 类的每个字段必须添加 `@Schema(description = "字段含义")` 注解
- Entity 类字段使用 Javadoc `/** 字段含义 */` 注释即可，无需 Swagger 注解
- `@Schema` 的 `description` 必须清晰描述该字段的业务含义，不能为空或与字段名相同
- 枚举类型字段应在 `description` 中标明各枚举值含义，如 `"启用状态：1=启用, 0=禁用"`
- 日期/时间类型字段应额外添加 `@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")` 或 `@JsonFormat(pattern = "yyyy-MM-dd")` 标明格式
- List 类型字段若嵌套泛型对象，外层必须额外加 `@Valid` 触发递归校验
- 必填字段注解与 `@Schema` 的顺序：优先 `@NotBlank`/`@NotNull`/`@NotEmpty` 紧贴字段，然后 `@Schema`、`@JsonFormat` 等注解在下方

### 四、Code Review 准入检查

每次 MR/PR 审查必须校验以下 5 条防线：

1. **一致性安全**：第三方同步 DTO 及表实体字段是否与外部 API 契约保持一致
2. **架构穿透**：是否在 Service 中直插其他模块的 Mapper
3. **API 透明度**：DO 是否暴露给前端；Result<T> 泛型是否精确声明
4. **事务兜底**：写操作是否有 `@Transactional(rollbackFor = Exception.class)`，异常是否被隐性吞没
5. **对象比较**：包装类型（Integer, Long 等）比较是否使用 `equals()` 而非 `==`

## 执行方式

当编写或审查后端代码时，按以下步骤执行：

1. **识别上下文**：判断当前代码属于哪一层（Entity/DTO/VO/Controller/Service/Mapper/DDL）
2. **对照检查**：根据上述规范逐条校验，标注违反项
3. **给出修正**：对每个违规项提供具体的修正代码，说明修正原因
4. **优先级排序**：[强制] 项为必须修正，[推荐] 项为建议修正

## 输出格式

发现违规时，按如下格式输出：

```
### 规范违规检查结果

**[强制] 违规项 N：** 简述违规内容
- 位置：文件路径:行号
- 规范：对应的规范条款
- 当前代码：`违规代码片段`
- 修正建议：`修正后代码片段`
- 原因：为什么这样改

**[推荐] 建议项 N：** 简述建议内容
- ...
```

如果代码完全合规，简要确认即可，无需逐条列出通过项。
