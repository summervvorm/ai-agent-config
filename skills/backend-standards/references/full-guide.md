# 后端研发框架及规范最佳实践指南

**文档适用范围**：全体后端研发人员 **规范实施原则**：本规范内标注为 **\[强制\]** 的条款，在 Code Review 中将被作为基础准入标准严格执行；标注为 **\[推荐\]** 的条款，视具体业务场景择优采用。本规范旨在通过标准化约束降低研发协同成本，提高系统稳定性。

---

## 第一章 数据库与数据模型规约

### 1. 命名边界管控 (Naming Conventions)

**\[强制\]** 所有数据库对象命名采用**小写字母 + 下划线**（Snake Case），禁止使用驼峰命名法及大写字母。 **\[强制\]** 严禁使用 SQL 保留字（如 `order`, `desc`, `key`, `group` 等）。业务字段名称需要附加具有业务属性的前缀或后缀（如 `order_no`, `sort_desc`）。 **\[强制\]** 表示布尔状态或逻辑值的字段，必须以 `is_` 开头（如 `is_delete`, `is_active`）。但对应的 Java 实体类 (Entity) 中，该属性**严禁加** `is` 前缀，以避免 RPC 框架（如 Spring Cloud, Dubbo）反序列化时丢失状态值。

**表名前缀划分标准**：

| 前缀类型 | 业务场景 | 示例规范 |
| --- | --- | --- |
| `**scm_**`+模块 | SCM 核心业务主体表 | `scm_product_info`, `scm_warehouse_stock` |
| `**lx_**`+表名 | 从领星 ERP 同步的数据镜像流 | `lx_amazon_listing`, `lx_fba_shipment` |
| `**sys_**`+字典 | 系统基础配置与权限控制类 | `sys_user`, `sys_dict` |

### 2. 字段类型及强一致性设计

**\[强制\]** **上下游接口同步表一致性原则**：凡是接收领星（或第三方系统）的同步数据源表，其字段命名规范、数据类型及容量，**必须**与外部 API 返回契约保持绝对映射。禁止为兼容系统内部习惯擅自修改外部数据类型（如将第三方返回的 String 标识强制改为 Integer）。 **\[强制\]** **全局业务实体同源一致性**：在微服务各域间，如果表述为**相同业务含义**的字段组合，其命名与数据类型在不同表中必须完全一致（特殊场景除外）。

*   ❌ 反例：商品流水号在商品表叫 `sku_no (varchar 32)`，在订单明细表叫 `sku_code (varchar 64)`，库存表叫 `sku (varchar 128)`。
    
*   ✅ 正例：全库强制统一规范为： `sku_code (varchar 64)`。
    

**\[强制\]** **核心字段选型标准**：

*   **主键**：统一采用 `BIGINT(20) UNSIGNED`，禁止使用 `INT` 型以防整型溢出。
    
*   **金额/费率**：涉及财务敏感数据的，必须使用 `DECIMAL`，禁止使用 `FLOAT`/`DOUBLE`，以防产生浮点数精度误差损耗。如 `DECIMAL(18,2)`。
    
*   **时间戳**：统一采取 `DATETIME` 格式，规避 `TIMESTAMP` 导致的时间截断问题。
    

**\[强制\]** 基础存储环境配置：存储引擎统一为 **InnoDB**；字符集统一为 `utf8mb4`（禁止使用 `utf8`，防止客户端传入隐性 Emoji 时导致全链路落库雪崩）。

### 3. 公共基础字段约束

**\[强制\]** 所有业务承载表，必须默认添加并维护以下 6 个核心审计字段。可采用 MyBatis-Plus / 持久层切面 实现无感插入/更新（当前已支持），严防代码层面漏写。

```plaintext
  `is_delete`   tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '单据状态：0-正常, 1-删除 (禁止物理删除)',
  `create_by`   varchar(64)         NULL DEFAULT '' COMMENT '创建者(工号/姓名)',
  `create_time` datetime            NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by`   varchar(64)         NULL DEFAULT '' COMMENT '更新者(工号/姓名)',
  `update_time` datetime            NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `remark`      text                NULL COMMENT '备注'
```
---

## 第二章 分层架构体系设计

### 1. 表现层与传输对象 (DTO/VO)

**\[强制\]** **Entity（或 DO/PO）绝对禁止越级暴露**。 严禁将底层数据库 Entity 对象直接作为参数透传暴露给前端 RESTful 接口（不论是出参还是入参）。此举极易引发越权修改、敏感数据表结构外泄等严重安全隐患。**必须**针对应用层接口构建专门的 `DTO/Req` 和 `VO/Resp` 模型，保持严格物理隔离。 **\[强制\]** **多模业务数据隔离**：修改类（Update）、新增类（Insert）、查询类（Query）业务参数对象必须区分隔离创建，禁止复用单一聚合的巨大 Request 类。 **\[强制\]** 数据库原模型 `DO`、接口传输参数 `DTO`、返回视图模型 `VO` 这三层之间，相同属性命名与类型**必须**保持绝对一致，以确保在利用 `BeanUtils.copyProperties` / `MapStruct` 等拷贝工具时实现稳定映射。

### 2. 全链路状态枚举化传输体系

**\[强制\]** 目前平台底层架构（MyBatis-Plus `@EnumValue` / JSON序列化切面）已支持“**状态自解析描述语义输出**”的功能，必须废弃手写代码进行业务字段翻译（Code -> Desc）的过程，全链路推进枚举约束。

**实施基准：**

1.  严禁散落在业务逻辑中的“魔法数字”（如 `if (status == 1)`，该 1 无法溯源真实语义）。
    
2.  在 Entity / DTO / VO 中，直接使用 Enum 枚举类型接收入参或构建出参，系统会自动完成底层序列化与转换反序列化。
    

**✅ 标准的全链路枚举范例：**

```plaintext
// 1. 定义通用基础枚举层
@Getter
@AllArgsConstructor
public enum OrderStatusEnum {
    PENDING(0, "待处理"),
    SHIPPED(1, "已发货");

    @EnumValue // 持久化约束：代表数据库实际入库值为(0,1)
    private final Integer code;
    private final String desc; // 系统切面会自动附带其语义释义(xxxDesc)，输出为前端 JSON
}

// 2. 数据库实体层及表现视窗直接映射
@Data
public class OrderVo {
    // 强制直接映射，无需再定义 String statusDesc 等冗长废弃内容
    private OrderStatusEnum status; 
}
```

### 3. Controller 控制层规范

**\[强制\]** **瘦控制器（Fat Service, Skinny Controller）要求**：Controller 层的核心业务边界仅限：

*   参数的校验拦截映射（借助 `@Validated` 注解）。
    
*   服务发现分发与调用路由。
    
*   执行系统架构顶层视图包装。**\[强制\]** 响应前端架构协议强制统一为系统全局标准包装类（如 `AjaxResult`, `Result<T>` 或 `TableDataInfo<T>`），并且必须明确指明对应响应实体泛型 `<T>`，禁止使用原始通用类型 `Object`。
    

**🌟 团队最佳应用标杆案例（提取自现有代码）：**

✅ **业务单体及分页处理（案例一：**`LogisticsSupplierController`）： 规范点：严格控制接口全方位权限管理（`@RequiresPermissions`）、日志审计切面（`@Log`）、结合内部自动包装能力实现标准分页返回。

```plaintext
@RestController
@RequestMapping("/logisticsSupplier")
public class LogisticsSupplierController extends BaseController {

    @Autowired
    private ILogisticsSupplierService logisticsSupplierService;

    /** 查询物流商列表（严密的分页标准写法） */
    @RequiresPermissions("system:logisticsSupplier:list")
    @GetMapping("/list")
    public TableDataInfo list(LogisticsSupplier logisticsSupplier) {
        startPage(); // 开启 PageHelper 分页
        List<LogisticsSupplier> list = logisticsSupplierService.selectLogisticsSupplierList(logisticsSupplier);
        return getDataTable(list); // 包装成框架统一的 TableDataInfo 分页结构返回
    }

    /** 新增物流商（操作审计与返回态管理） */
    @RequiresPermissions("system:logisticsSupplier:add")
    @Log(title = "物流商管理", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody LogisticsSupplier logisticsSupplier) {
        // toAjax(int rows) 是框架底层便捷判断受影响行数的方法
        return toAjax(logisticsSupplierService.insertLogisticsSupplier(logisticsSupplier));
    }
}
```

✅ **基于 Result<T> 泛型隔离处理（案例二：**`SkuSalesConfigController`）：

```plaintext
@RestController
@RequestMapping("/sku/sales-config")
@Tag(name = "SKU销量配置管理")
public class SkuSalesConfigController {

    @Resource
    private ISkuSalesConfigService skuSalesConfigService;

    @Operation(summary = "新增配置规则")
    @PostMapping("/add")
    // 强制声明泛型：请求时带好入参隔离 DTO，无特定返回类型强制采用 Result<Void>
    public Result<Void> add(@RequestBody @Validated SkuSalesConfigAddReq req) {
        skuSalesConfigService.addConfig(req);
        return Result.success();
    }
}
```

### 4. Service 服务编排层隔离

**\[强制\]** **垂直 Mapper 注入禁令**：Service 中必须严格遵循职责内聚原则。`AServiceImpl` 下只允许注入调用原生的 `AMapper`。如果在 A 域涉及跨模块 B 数据处理，必须通过注入 `IBService` 实现逻辑协同处理。禁止绕过对方业务边界前置拦截验证，直插对方底层数据库 `Mapper` 破坏微服务底层逻辑自治。

---

## 第三章 微服务防御规范与常用框架陷阱指南

### 1. 参数与防御性校验 (Validator)

**\[强制\]** 杜绝在业务流中大量采用 `if-else` 做判空及常规越界堆砌。一律采用 `jakarta.validation` 或类 Hibernate 参数校验注解体系。

*   `@NotBlank` 仅修饰于 String 字符串。
    
*   `@NotNull` 修饰于非字符串包装类对象及内部嵌套实体。
    
*   `@NotEmpty` 专用于约束 Collection、List、Set 必须非空且含有底层元素。
    
*   **\[防范陷阱\]** 处理针对 List 集合内嵌套泛型对象的深层次字段扫描时，外层 List 属性上方必须配置 `@Valid` 注解以令下级验证规则递归生效。
    

### 2. 数据库事务强一致与快照回退 (`@Transactional`)

**\[强制\]** 事务保护生命线：Spring 默认仅拦截并在运行期异常内（`RuntimeException`）触发回滚。凡涉任何非幂等的写操作（Insert/Update/Delete）或者由外界驱动的逻辑落库流转，必须显式声明 `@Transactional(rollbackFor = Exception.class)`，保障应用遭遇不确定的外部受检异常（如 IO 数据流折断）时保障快照安全一致回滚。

**🌟 核心链路全覆盖最佳实践机制**： 规范点：对于涉及多表联络的聚合业务修改动作，严格使用 `rollbackFor = Exception.class` 进行全局隔离。并通过前置强检验（Fail-Fast 思想）在发生操作或计算前抛出可捕获控制的内部业务异常终结整个 AOP。

```plaintext
@Override
@Transactional(rollbackFor = Exception.class) // 强制配置兜底范围
public int reducePlanAndLclQuantity(Long id, Long planQuantity, Long lclQuantity) {
    ShipmentPlanInfo shipmentPlanInfo = getOne(id);
    
    // [规约执行点] 前置进行数据完整性验证，若发现异常直接阻断操作
    if (shipmentPlanInfo == null) {
        throw new ServiceException(ScmCode.NO_DATA_FOUND_SHIPMENT_PLAN);
    }

    if (shipmentPlanInfo.getPlanQuantity() - planQuantity == 0) {
        return deleteShipmentPlanInfoByShipmentPlanInfoId(id);
    }
    
    ShipmentPlanInfo info = new ShipmentPlanInfo();
    info.setId(id);
    info.setPlanQuantity(shipmentPlanInfo.getPlanQuantity() - planQuantity);
    info.setLclQuantity(shipmentPlanInfo.getLclQuantity() - lclQuantity);
    return shipmentPlanInfoMapper.updateById(info);
}
```

### 3. 日志追踪脱敏设计管理

**\[强制\]** 线上所有服务严禁采用 `System.out.println` 及 `e.printStackTrace()`。高配发量压力下产生同步 I/O 中断锁定，最终会导致服务器僵死。 **\[强制\]** 处理异构错误时，必须进行规范化完整堆栈下放。

**🌟 团队日志记录红黑榜（反面教训与正确打开方式）：**

❌ **\[黑榜\] 反面教训案例分析（提取自现有代码库** `RemoteLxBatchDetailFallbackFactory`）：

```plaintext
// 错误写法导致隐患：通过字符串 + 号拼接强行取消息。不仅由于字符串重创建引发内存垃圾产生，
// 且 .getMessage() 后丢失所有异常源堆栈 (StackTrace)，线上仅打出一行类似于空指针的错，无法精确定位。
@Override
public R settlementLxBatchAge() {
    log.error("settlementLxBatchAge()，结算领星批次库龄异常:" + cause.getMessage()); 
    // 隐患连带：此处私吞异常，未抛出特定阻断外包装 Result 假象，上游事务无法感知。
    return R.fail("调用失败");
}
```

✅ **\[红榜\] 优秀排查模版典范（提取自现有代码库** `MultiPlatformOrderServiceImpl`）：

```plaintext
// 规范：引入占位符 `{}` 执行延迟计算降低并发能耗；核心要求在于：
// 被捕获的 e 本身放置在重截函数的尾端不参与解析，由底层 Logback 自动提取堆栈并持久化到硬盘中支持跟踪。
log.error("Init site time error: orderNo={}, error={}", order.getGlobalOrderNo(), e.getMessage(), e);
```

### 4. Lombok 规范体系与开发陷阱规避

**\[强制\]** 所有的 `DTO / VO / Entity` 等数据载体对象，**必须**使用 Lombok（如 `@Data`, `@Getter`, `@Setter`, `@Builder`等）自动生成样板代码。严禁在类中手动编写冗长重复的 `get/set`、`toString` 或构造方法，强制维持类文件主体的语义极简。 **\[强制\]** `**@Data**` 继承塌陷问题防空：当类属性继承自 `BaseEntity` 或是 `BaseDTO` 结构体之上时，必须在子类注解之上显式声明 `@EqualsAndHashCode(callSuper = true)`。如果遗漏该项指示并在后续涉及集合判重、数据覆盖比对（`equals`）等环节中，默认逻辑将直接忽视所有由父表注入的共有字段，继发衍生潜在的安全盲区。 **\[强制\]** `**@Builder**` 默认属性吞没预警：针对带有预备装载初始值的局部变量字段（例如 `private Integer status = 1;`），倘若采用 Builder 设计模式搭建环境而并未附加标明 `@Builder.Default` 注解。那么一旦实例化进行中没有介入干预赋值行为，被初始定义的默认态将会被篡改剥除变异为 `null` 终结点。

---

## 第四章 核心合规审计与 Review 准入防线清单 (Checklist)

> 在代码提交流水线合并合规检查（Merge Request Review）之前，各一线研发同事与组内负责人应对所有 MR/PR 变动提交者严格问责以下 5 个防线，守好每一寸代码护城河：

1.  **\[一致性安全扫描\]** 从第三方系统源抽取的底层交互 DTO 及 表实体字段，其映射是否与第三方接口契约的返回表意及数据类型维持长效一致性？全局模块中有关联的业务字典字段是否已完成一致化梳理？（防范反序列化抛出并脱钩阻断）
    
2.  **\[架构穿透隐患\]** 在当前模块变更范围内（诸如 `AxxServiceImpl` 中），是否发生了非合规路径并直接拉取甚至操作其他服务域（甚至是别人封装好的 `BxxMapper`）？
    
3.  **\[API 透明度与隔离\]** 数据层原表 DO 实体是否已被暴露给前端接口调用者？新提交公开的控制器 Controller 结构协议下（`Result<T>` 响应泛型定义是否精准清晰配置指向，而非 `Object` 模糊囊括）？
    
4.  **\[弱网事务兜底防线\]** 含有写/改变动属性的状态转移路径首站，是否有配备囊盖 `@Transactional(rollbackFor = Exception.class)`，及其是否有发生过对异常的任意隐性捕获甚至埋葬（私吞拦截从而诱骗上一层回流失败）？
    
5.  **\[对象指针安全比对\]** 对于包装基类封装体字段比较上运算判断时（不仅限于包装整型 `Integer`, `Long` 数字类型之间），是否保证应用了规范的 `equals()` 系统函数来对其实质表征状态比较，杜绝对照地址池中随机的引用栈指向而运用 `==` 进行比较引发偶现生产级事故？