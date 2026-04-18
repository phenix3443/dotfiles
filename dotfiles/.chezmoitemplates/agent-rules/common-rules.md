# Agent 通用规则

## Git 工作流

分支命名遵循 `type/short-description` 格式，type 取自 Conventional Commits：`feat`、`fix`、`chore`、`refactor`、`docs`、`test`。

Commit message 遵循 [Conventional Commits 1.0](https://www.conventionalcommits.org/en/v1.0.0/)：

```text
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

PR title 同样遵循 Conventional Commits 格式。每个 PR 只包含一个逻辑变更，不捆绑无关修改。

## 代码原则

- 改动最小化：只修改与当前任务直接相关的代码，不顺手重构
- 不添加未被要求的 fallback、错误处理或抽象
- 匹配现有代码风格，不引入新的模式
- 三处相似代码才考虑抽象，不提前设计

## 完成定义

任务完成前必须满足：

1. lint 和类型检查通过
2. 相关测试通过
3. 如果修改了架构或流程，文档同步更新

## 改动固化规则（Fix-to-Code Protocol）

任何通过手动命令修复的问题，都必须立即固化到源代码中。

每次手动修复后按顺序执行：

1. **修复** — 运行手动命令解决问题
2. **回写** — 立即将修复写入对应的脚本/配置/manifest
3. **验证** — 从更新后的源文件重新运行，确认修复有效
4. **更新文档** — 如果修复改变了架构、流程或前提条件，更新对应文档

禁止：只运行手动命令而不更新源文件；在对话结束时才"计划稍后更新"；认为"这只是临时修复"。
