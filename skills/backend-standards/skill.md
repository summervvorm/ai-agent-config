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
- 类级 `@Api(tags = "模块名")`，方法级 `@ApiOperation("接口含义")`

**接口返回与参数定义：**
- 普通接口返回 `Result<T>`，必须带泛型（如 `Result<SalesPlanChangeOrderVO>`）；无返回用 `Result<Void>`；用 `Result.success(data)` / `Result.success()` 构造
- 列表/分页接口返回 `TableDataInfo<T>` 或携带 `rows/total/(statusCount)` 的分页 VO；分页统一走 **PageDomain + IPage** 规范（见下方「分页规范」），新代码禁止 PageHelper `startPage()` 拦截式分页
- 同一分页语义返回同一 VO（如 `SalesPlanChangePageVO`），禁止同需求在列表/计数/导出各自返不同结构
- **禁止使用 `AjaxResult`**：其值域为 Object，会丢失泛型，前端无法类型推导
- 接收参数：简单单值用 `@RequestParam`/`@PathVariable`；对象参数统一命名 `XxxReq`（如 `SalesPlanChangeQueryReq`），并用 `@RequestBody @Validated` 接收，禁止直接收 Entity/DO
- 出参对象统一 `XxxVO`/`XxxResp`，与 Req 严格隔离，禁止返回 Entity

**入参命名（列表类型优先以 List 结尾）：**
- 前端入参（Req/DTO）中的列表/集合字段**优先**以 `List` 结尾：`prePrNoList`、`planNoList`、`opsGroupIdList`、`keywordList`、`storeIdList`、`statusList`
- 复数 `s` 结尾（`planNos`、`storeIds`、`skus` 等）**不强制禁止**：新增或改造接口优先用 `List` 结尾，存量命名按原样保留、不做批量重命名；同一 Req 内命名风格保持一致（同一语义不要一半 `xxxList` 一半 `xxxs`）
- 单值 + 批量成对出现时必须在同一 Req 内自解释（如 `prePrNo` 单值兼容 + `prePrNoList` 批量），并在 `@ApiModelProperty` 中写明「多选/集合 + 匹配方式（IN 精确 / 模糊 / OR）」
- 例外：纯内部字段（父行级分页临时入参等）可保留原命名，但必须 `@ApiModelProperty(hidden = true)`；`Map` 类型字段不受此约束

**分页规范（PageDomain + IPage，统一标准）：**
- 查询 Req 继承 `com.ct.common.core.web.page.PageDomain`（自带 pageNum/pageSize/orderByColumn/isAsc/orders），禁止自造 pageNum/pageSize 字段
- Service 层用 `req.getPage()` 构造 MP 分页对象（等价 `new Page<>(pageNum, pageSize)`），不要手工取 getpageNum/getPageSize 再 new
- Mapper 分页查询：第一个参数传 `Page<T>`/`IPage<T>`，返回 `IPage<T>`，由 `PaginationInnerInterceptor` 统一追加 LIMIT 并回填 total；非分页查询不传 page 参数、直接返回 `List<T>`（独立 XML 语句，如导出/详情）
- Controller 用 `page.getRecords()` / `page.getTotal()` 组装 `TableDataInfo<T>` 或分页 VO
- **total 语义必须与行粒度一致**：父子分组列表按"父行"分页时 total=父行数（先分组分页取父键，再按本页父键捞子行），禁止计划数与批次数混用
- 带 `GROUP BY` 的分页查询 total 由 MP 自动包装子查询统计（返回分组数而非行数）；**父行级分页的 order by 必须带唯一列兜底**（如 `batch_no desc`），避免同值排序导致翻页重复/丢行
- 排序直接写在 SQL 的 `order by` 中；导出等不分页全量场景复用同一查询主体（拆 `<sql id>` 片段共享 where），不传 page 参数

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
- **优先使用 `@ApiModel`/`@ApiModelProperty`**（`io.swagger.annotations`）：DTO/VO/Req 类级加 `@ApiModel("类业务含义")`，每个字段加 `@ApiModelProperty("字段含义")`
- Entity 类字段使用 Javadoc `/** 字段含义 */` 注释即可，无需 Swagger 注解
- 示例（仅作示范，字段注解与 `@Schema` 可选其一，全库保持一致）：
```java
@ApiModel("用户钉钉关联引用")
@TableName("sys_user")
public class SysUserDingRef {
    @TableField("dingtalk_user_id")
    @ApiModelProperty("钉钉用户ID")
    private String dingtalkUserId;

    @ApiModelProperty("帐号状态（0正常 1停用）")
    private String status;
}
```
- `description` 必须清晰描述业务含义，不能为空或与字段名相同
- 枚举类型字段应在 `description` 中标明各枚举值含义，如 `"启用状态：1=启用, 0=禁用"`
- 日期/时间字段加 `@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")` 或 `@JsonFormat(pattern = "yyyy-MM-dd")`
- List 嵌套泛型对象时，外层 List 属性需加 `@Valid` 触发递归校验
- 必填校验注解（`@NotBlank`/`@NotNull`/`@NotEmpty`）紧贴字段，随后是 `@ApiModelProperty`/`@JsonFormat`

### 四、Code Review 准入检查

每次 MR/PR 审查必须校验以下 5 条防线：

1. **一致性安全**：第三方同步 DTO 及表实体字段是否与外部 API 契约保持一致
2. **架构穿透**：是否在 Service 中直插其他模块的 Mapper
3. **API 透明度**：DO 是否暴露给前端；接口返回是否 `Result<T>`/`TableDataInfo<T>` 且泛型精确，是否误用 `AjaxResult` 丢泛型；入参对象是否统一 `XxxReq`
4. **事务兜底**：写操作是否有 `@Transactional(rollbackFor = Exception.class)`，异常是否被隐性吞没
5. **对象比较**：包装类型（Integer, Long 等）比较是否使用 `equals()` 而非 `==`
6. **入参命名**：前端入参中的列表/集合字段是否**优先**以 `List` 结尾（复数 `s` 结尾不强制，但同一 Req 内风格应一致，新增/改造接口优先 `List`）

### 五、Excel 导入导出规范

**统一工具：**
- 后端 Excel 导入、导出、导入模板统一使用 `com.ct.common.core.utils.poi.ExcelUtil`，禁止新增同类 Excel 工具类。
- 多 Sheet 模板使用 `ExcelUtil.exportMultipleSheets(HttpServletResponse, List<ExcelSheet<?>>)`。
- 导入模板实体使用 `com.ct.common.core.annotation.Excel` 定义列名和顺序。

**必填列标识（仅星号标红，需显式开启）：**
- 需要标红时在 `@Excel` 上开启 `requiredMark`，位置不限：`@Excel(name = "*SKU", requiredMark = true)`、`@Excel(name = "店铺*", requiredMark = true)` 均可。
- `requiredMark` **默认 false**；不开启时表头按原样式输出，其它导出行为完全不变。
- 开启后 `ExcelUtil` 只把表头中的 `*` 渲染为红色，其余字符**显式继承表头样式字体与颜色**（不会回落成黑色），业务侧无需写 POI 富文本后处理。
- 注意：表头样式必须在写值之前设置（`ExcelUtil` 内部已保证该顺序），否则富文本取不到表头字体。
- **不要再用** `headerColor = IndexedColors.RED` 把整列表头染红（整格红是旧约定，仅存量导出保留）。
- 实现位置：`ExcelUtil#setHeadCellValue` + `ExcelUtil#needRichTextHead` + `Excel#requiredMark`；开启且表头含 `*` 时自动改用 XSSF 工作薄（SXSSF 会丢失富文本），未开启的导出仍走流式 SXSSF。
- 参考实现：`PrimeStockAlertSkuImportRow`。

**导入结果类：**
- 导入接口直接使用公用 `com.ct.common.core.web.domain.ImportResult<T>`，禁止新建自定义导入结果类（不继承、不复制字段）。
- 该类已提供 `successCount`、`failCount`、`failList`、`downloadKey`；失败明细元素类型作为泛型传入，例如 `ImportResult<XxxImportFailVO>`。
- 成功/失败判断用 `failCount`；新增数、覆盖数、重复数等导入统计写入 `operation_log` 的 `detail`，不额外扩展返回结构。
- 参考实现：`PlanConfigWarehouseServiceImpl#importFile`、`PlanAggregateWarehouseBackupController#importExcel`、`PrimeStockAlertServiceImpl#importSku`。

**导入失败与失败明细下载：**
- 导入必须支持返回行级失败明细 `failList`，包含行号、业务标识和失败原因。
- 只要存在失败行，必须同步生成 `downloadKey`，并通过 Redis 暂存失败明细，建议有效期 2 小时。
- 导入结果至少包含：`failCount`、`failList`、`downloadKey`。
- 必须提供失败明细下载接口，使用 `ExcelUtil` 导出失败列表，不允许只返回失败数量。
- 参考实现：`SalesPlanChangeOrderServiceImpl#buildImportResult`、`SalesPlanChangeOrderServiceImpl#exportImportResult`。
- Redis key 必须带业务前缀，例如 `upload_result:xxx_import:`，禁止裸 key。

**接口权限注解：**
- `@RequiresPermissions` 不写在接口方法或 Controller 上。
- 权限控制由统一网关、菜单按钮权限或既有权限框架处理，不在新接口代码中重复声明。

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
