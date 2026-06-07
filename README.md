# Go Backend Starter

AI 辅助 Go 后端开发 template。骨架极简——复制后按需生长。

## 快速开始

```bash
cp -r go_backend_starter my-project && cd my-project
rm -rf .git && git init

# 按需展开所需内容
make init-internal    # Go 标准目录骨架 (cmd/ internal/ configs/)
make init-docker      # Dockerfile + docker-compose.yml
make init-cicd        # .github/workflows/ci.yml
make init-docs        # docs/ 文档模板

# 需要全部？一步到位
make init-all

# 安装全局 Skills（一次，所有项目共享）
make init-global-skills
```

## 目录结构

```
.
├── CLAUDE.md                    # L1: 项目宪法（编码约束 + 流程规则）
├── Makefile                     # 构建入口（含 init-* target）
├── go.mod
├── harness.json                 # 层级映射
├── .gitignore
├── templates/                   # 按需展开的模板
│   ├── init/                    # make init-* 展开源
│   │   ├── docker/              #   Dockerfile + docker-compose.yml
│   │   ├── ci/                  #   .github/workflows/ci.yml
│   │   ├── cmd/                 #   cmd/server/main.go
│   │   ├── internal/            #   标准目录骨架
│   │   ├── configs/             #   config.example.yaml
│   │   ├── docs/                #   文档模板
│   │   └── scripts/             #   verify 脚本
│   └── global-skills/           # 全局安装的 Skills
│       ├── deep-thinking.md
│       ├── prompt-engineering.md
│       ├── technical_writing.md
│       ├── devex-tooling.md
│       ├── coordinator-delegation.md
│       └── competitive-analysis.md
├── docs-ref/                    # 跨项目规范参考
│   └── workflow-bridge.md       # v1/v2 工作流选择指南
├── docs-tmp/                    # 临时缓存（gitignore）
└── .claude/
    └── skills/
        ├── core/                # 8 个核心 Skill（始终加载）
        │   ├── brainstorming-with-context.md   # 需求澄清 + 方案设计
        │   ├── plan-to-tasks.md                # 拆解为 7 要素 Task
        │   ├── execute-with-review.md           # 9 步执行流程
        │   ├── adversarial-review.md           # 双模型交叉审查
        │   ├── change-impact-scan.md           # 变更影响扫描
        │   ├── pitfall-journal.md              # 踩坑记录 + 进化
        │   ├── knowledge-snapshot.md           # 查阅优先级链
        │   └── test-strategy.md                # 测试分层策略
        └── plugins/             # 11 个插件 Skill（按需触发）
            ├── spec.md                          # L1/L2/L3 规格管理
            ├── spec-check.md                    # 规格 lint + review
            ├── spec-do.md                       # 规格实现 + Evidence
            ├── spec-checkpoint.md               # 7 阶段质量门禁
            ├── pre-verify.md                    # 结构性操作预验证
            ├── e2e-verify.md                    # 端到端验证管道
            ├── protocol-driven-development.md   # 协议驱动开发
            ├── project-delivery.md              # 部署/CI/Docker
            ├── false-positive-tracking.md       # 误报追踪
            ├── knowledge-loop.md                # 五级进化闭环
            └── harness-go/                      # Go Harness（层级检查/lint/审计）
```

## Skill 体系

| 层级 | 数量 | 说明 |
|------|------|------|
| **Core** | 8 | 始终加载，日常工作流 |
| **Plugins** | 11 | `.claude/skills/plugins/`，任务匹配时自动触发 |
| **Global** | 6 | 跨项目通用，建议装到 `~/.claude/skills/` |

详细索引见 `.claude/skills/README.md`。

## 编码约束

| 编号 | 规则 | Why |
|------|------|-----|
| C-01 | 禁止吞错误 | 隐藏的错误会累积成线上事故 |
| C-02 | 禁止创建孤儿 context | 必须传递上游取消信号 |
| C-03 | 禁止对共享状态裸读写 | 并发 bug 难复现难定位 |
| C-04 | 每个 Open 必须配 Close | 资源泄漏随时间累积 OOM |
| C-05 | 所有外部输入必须校验 | OWASP Top 1 注入攻击 |
| C-06 | 魔法数字必须提取常量 | 3 个月后你不知道 60 是什么 |
| C-07 | 热路径只打 Warn/Error | 过多日志 I/O 成为性能瓶颈 |
| C-08 | 标准库 > 已有依赖 > 新依赖 | 最小化依赖面 |
| C-09 | 公共函数必须有测试 | 没有测试的代码无法安全修改 |
| C-10 | 协议实现必须对照参考文档 | 协议漂移是最危险的 bug |

## Workflow

```
brainstorming → plan → execute → review（按需）
     ↓           ↓        ↓         ↓
  探索代码    拆 Task   9 步执行   双模型审查
```

大型功能/Epic 用 v2 spec 体系：`spec → spec-check → spec-do`。详见 `docs-ref/workflow-bridge.md`。

## License

MIT
