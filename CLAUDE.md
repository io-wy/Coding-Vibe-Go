# Go Backend Starter - 项目宪法

> L1 上下文，每次会话加载。编码约束 + 流程规则 + 路径约定。
> 新手先读 `claude.template.md`，定制本地环境用 `claude.local.md`。

## 本地覆盖

会话启动时检查根目录是否存在 `claude.local.md`。如果存在，Read 该文件并将其中的约束/偏好作为本文件的补充——local 覆盖 > 本文件默认值。
`claude.local.md` 不进 git（已在 .gitignore），按人定制。

---

## 编码约束（反例免疫格式）

### C-01：错误处理——禁止吞错误

```go
// WRONG: 吞掉错误
result, _ := db.Exec(query, args...)

// CORRECT: 显式处理并包装上下文
result, err := db.Exec(query, args...)
if err != nil {
    return fmt.Errorf("create record: %w", err)
}
```
Why: 吞错误会让故障定位从分钟级变成小时级。

### C-02：context 传递——禁止创建孤儿 context

```go
// WRONG: 忽略上游取消信号
ctx := context.Background()

// CORRECT: 传递上游 context
func (s *Service) Process(ctx context.Context) error {
    ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
    defer cancel()
    // ...
}
```
Why: 用户断开连接后必须立即停止下游请求。

### C-03：并发安全——禁止对共享状态裸读写

```go
// WRONG: 多 goroutine 裸读写 map
stats[name] = value

// CORRECT: 使用 sync.Mutex
s.mu.Lock()
stats[name] = value
s.mu.Unlock()
```
Why: 并发 bug 难复现难定位。

### C-04：资源释放——每个 Open/Close 必须配对

```go
// WRONG: 打开不关
resp, _ := http.Post(url, ct, body)

// CORRECT: defer 确保释放
resp, err := http.Post(url, ct, body)
if err != nil { return err }
defer resp.Body.Close()
```
Why: 后端长运行，资源泄漏随时间累积最终 OOM。

### C-05：外部数据——所有入参必须校验

```go
// WRONG: 直接拼接 SQL
query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID)

// CORRECT: 参数化查询 + 校验
if userID == "" { return ErrInvalidInput }
row := db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = ?", userID)
```
Why: OWASP Top 1 注入攻击。

### C-06：魔法数字——必须提取为命名常量或配置

```go
// WRONG: 硬编码
client := &http.Client{Timeout: 60 * time.Second}

// CORRECT: 常量或配置
const defaultTimeout = 60 * time.Second
```
Why: 3 个月后你不知道 60 是什么。

### C-07：日志——热路径只打 Warn/Error

```go
// WRONG: 每个请求都打 Debug
log.Printf("processing request: %v", req)

// CORRECT: 热路径只打 Warn/Error + requestID
if err != nil {
    slog.Error("request failed", "requestID", reqID, "error", err)
}
```
Why: 后端 QPS 高时，过多日志 I/O 成为性能瓶颈。

### C-08：依赖引入——标准库 > 已有依赖 > 新依赖

1. Go 标准库是否已有等价能力？
2. go.mod 中已有依赖是否已提供？
3. 必须引入时评估：维护活跃度、许可证、已知 CVE。

### C-09：测试——公共函数必须有测试

```go
// CORRECT: 先写测试
func TestCalculatePrice(t *testing.T) {
    got := CalculatePrice(100, 0.2)
    if got != 80 { t.Errorf("expected 80, got %f", got) }
}
```
Why: 没有测试的代码下次修改时无法确认行为。

### C-10：协议实现——必须对照参考文档，禁止漂移

逐字段从参考文档复制确认。协议漂移是最危险的 bug——上游/下游都按文档实现，你改了行为所有调用方都会出问题。
详见 `protocol-driven-development` Skill（plugins/）。

---

## 流程规则

### 阻塞顺序（不可跳过、不可并行）

```
功能实现 → 单元测试 → 代码审查 → 提交
```

- 功能 Task 完成前，不得开始测试 Task
- 测试未通过前，不得标记功能 Task 完成
- 代码审查未通过前，不得提交 commit
- io-wy 明确要求跳过时，记录原因后执行

### 改不全预防（每次修改后检查）

1. 修改函数签名/接口 → Grep 所有调用点
2. 新增 Open/Create/Insert → 确认有 Close/Destroy/Delete
3. 修改配置项 → 检查 config struct + YAML + docs
4. 修改实现逻辑 → 检查测试是否需要更新
5. 修改公共接口 → 检查 API 文档、README
6. 修改数据模型 → 检查是否需要 migration

单文件自主检查，多文件列影响范围，接口变更走 Plan 模式。

### 不确定性声明

以下情况必须告知 io-wy「不知道」：API 签名无法查证、Go 版本兼容性不确定、框架行为无法确认、无实测性能数据、安全判断不明确。禁止编造函数签名/标准库行为/benchmark 数据。

---

## Harness —— 架构机械执法

每次结构性操作（创建新文件/目录、添加跨包 import、修改公共接口）前后必须跑 harness 验证：

**操作前：预验证（`pre-verify` Skill in plugins/）**
创建文件/import 前检查层级方向是否合法。

**操作后：影响扫描（`change-impact-scan` Skill in core/）**
Grep 所有调用点，防改不全。

**定期：健康度审计**
```bash
make lint-arch     # lint-deps + lint-quality
make harness-audit # 0-100 分健康度
```

架构层级规则：L0 (types) → L1 (utils) → L2 (config) → L3 (core/service) → L4 (handler/api/cmd)。高层可 import 低层，反方向禁止。详见 `harness-go` Skill（plugins/）和 `harness.json`。

---

## 测试约束

- 回归口径：`go test ./...`
- 新增公共函数必须有对应测试
- HTTP handler：`httptest.NewRecorder`
- 数据库：SQLite in-memory 或 mock
- 外部服务：mock 测试
- 代码审查前必须 `go test ./...` 通过
- 覆盖率门禁：核心业务逻辑 >= 80%

---

## 目录与输出路径约定

| 目录 | 用途 | 进 git? |
|------|------|---------|
| `docs/` | 项目自有产出文档 | ✅ |
| `docs-ref/` | 跨项目规范参考 | ✅ |
| `docs-tmp/` | 临时缓存（Skill 自动写入） | ❌ |
| `docs/specs/` | 规格工件（spec 体系） | ✅ |
| `.claude/skills/core/` | 核心 Skill（8 个，始终加载） | ✅ |
| `.claude/skills/plugins/` | 插件 Skill（11 个，按需触发） | ✅ |
| `templates/init/` | 项目骨架模板（make init-* 展开） | ✅ |
| `templates/global-skills/` | 全局 Skill（建议装到 ~/.claude/skills/） | ✅ |

### Skill 输出物默认路径

| 输出类型 | 默认路径 |
|---------|----------|
| 协议/三方 API 文档 | `docs-tmp/protocols/<api-name>.md` |
| 调研报告/竞品分析 | `docs-tmp/research/<topic>-<YYYY-MM-DD>.md` |
| 代码审查/影响分析报告 | `docs-tmp/analysis/<task-id>-<YYYY-MM-DD>.md` |
| 架构决策(ADR) | `docs/architecture/<topic>.md` |
| API 契约 | `docs/api/<service>.md` |
| 运维手册 | `docs/runbook/<service>.md` |
| 规格工件 | `docs/specs/<YYYYMMDD-slug>/` |
| 通用规范 | `docs-ref/<topic>.md` |
| 踩坑日志 | `.claude/skills/core/pitfall-journal.md` |

禁止自创目录或写到表外路径。发现违规 → 记 PIT。

---

## Skill 体系

本项目的 Skill 分三层：

| 层 | 位置 | 数量 | 加载 |
|----|------|------|------|
| Core | `.claude/skills/core/` | 8 | 始终 |
| Plugins | `.claude/skills/plugins/` | 11 | 按需 |
| Global | `templates/global-skills/` | 6 | 全局安装一次 |

Skills 索引见 `.claude/skills/README.md`，工作流选择见 `docs-ref/workflow-bridge.md`。
新手教程见 `claude.template.md`。
