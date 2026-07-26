# Orca Loop 教学：从任务发布到修复重审

本文给其他 Agent 和第一次使用 Orca 的开发者阅读。目标是理解一件事：**发布任务不会自动产生 Loop；必须启动 coordinator，并明确阶段、验收条件、失败回路和停止条件。**

## 1. 你要启动的是什么

本教程使用一次“有限 Loop”：

```text
目标
  -> omp 分析
  -> pi 实现
  -> 运行验证
  -> kilo 独立审查
       | 通过
       v
     hermes 汇总 -> 成功
       | 不通过
       v
     pi 修复 -> 再验证 -> kilo 再审查
```

这不是无限循环。示例规定：最多修复 3 轮；本演示还要求第一次审查故意因为“输出不美观”打回，第二次审查才允许通过。这样可以观察真实的 **review -> repair -> re-review** 路径。

角色职责：

| Agent | 职责 |
|---|---|
| `omp` | coordinator；拆分任务、维护依赖、决定下一步 |
| `pi` | maker；修改代码和测试 |
| `kilo` | checker；独立审查，不替 pi 修改 |
| `opencode` | 需要仓库/API/数据收集时使用；本例不需要 |
| `hermes` | 汇总证据和最终状态 |

## 2. 运行演示

在本目录打开 PowerShell：

```powershell
cd D:\code\agent\GapScan\issue-4-orca

.\scripts\run-gapscan-loop.ps1 `
  -Worktree active `
  -Goal "在 examples/prime_checker.py 上完成素数判断演示。保留 is_prime(n) 的正确性；补充边界测试；将命令行输出改成美观、清晰的格式。必须经历一次 kilo 审查打回：第一次审查只因输出不美观而 FAIL；pi 修复格式后重新验证；第二次 kilo 审查 PASS。禁止 push、删除文件或发送外部通知。最终更新 progress.md。"
```


也可以直接运行专用演示启动器（它会固定注入“第一次审查因输出不美观而打回”的条件）：

```powershell
.\scripts\run-prime-loop-demo.ps1
```
脚本做的事情只有两件：

1. 把 `-Goal` 和标准 Loop 规则拼成 coordinator spec；
2. 执行 `orca orchestration run --spec ...`。

脚本**不直接修改 Python 文件，也不自行判断审查结果**。它要求 Orca coordinator 创建/派发阶段任务。

## 3. 预期流程

### Beat 1：分析和实现

`omp` 读取 `progress.md`、示例文件和测试，产生验收条件，例如：

- `is_prime(2)` 为真；
- `is_prime(1)`、`is_prime(0)`、负数为假；
- 合数为假；
- CLI 输出包含输入、结果和易读标签；
- 测试通过。

然后派发给 `pi`。`pi` 修改 `examples/prime_checker.py` 和测试。

### Beat 2：第一次验证和审查

运行类似：

```text
python examples/test_prime_checker.py
```

随后 `kilo` 只审查，不修改文件。第一次审查的预期结果是：

```text
REJECTED
reason: prime calculation is correct, but the CLI output is not sufficiently readable/beautiful
```

这次打回是演示条件，不代表算法错误。

### Beat 3：修复和再次审查

`omp` 把 kilo 的具体意见发给 `pi`：

```text
保留算法；只改善 CLI 输出。至少显示输入数字、Prime/Not prime 标签和明确的退出结果。
```

`pi` 修复后重新运行测试。`kilo` 第二次审查：

```text
APPROVED
- prime behavior verified
- CLI output is readable
- no unrelated files changed
```

### Beat 4：汇总和结束

`hermes` 汇总：修改文件、验证命令、两次审查结果和剩余风险，并更新 `progress.md`。满足全部条件后才是 `SUCCESS`。

## 4. 监督运行

查看任务：

```powershell
orca orchestration task-list --brief --json
```

等待 worker 完成、升级或决策门：

```powershell
orca orchestration check `
  --wait `
  --types "worker_done,escalation,decision_gate" `
  --timeout-ms 300000 `
  --json
```

查看 dispatch：

```powershell
orca orchestration dispatch-show --task <task-id> --json
```

如果出现 `decision_gate`，不要猜测。按问题人工回复；本例禁止 push、删除和外部通知，因此正常情况下不应产生决策门。

## 5. 新增任务怎么做

每个新任务重新执行一次脚本，把目标换成清楚的验收条件：

```powershell
.\scripts\run-gapscan-loop.ps1 `
  -Goal "目标：...；允许修改：...；验收：...；验证命令：...；禁止：...。失败时回到 pi 修复，最多 3 轮。"
```

同一个任务失败后再次执行时，要求它先读 `progress.md`：

```powershell
.\scripts\run-gapscan-loop.ps1 `
  -Goal "继续上一次任务。先读取 progress.md，从上次 BLOCKED 或 FAILED 的阶段继续；不要重复已通过的阶段。"
```

不同任务最好使用不同 worktree，避免共享代码和 `progress.md`：

```powershell
.\scripts\run-gapscan-loop.ps1 `
  -Worktree "path:D:\code\agent\GapScan\another-worktree" `
  -Goal "..."
```

## 6. 这是不是自动每天运行

不是。本教程演示的是“一次启动、有限重试、结束”。每天自动开始新一轮，需要另行配置 `orca automations` 作为触发器；Automation 负责唤醒，`orca orchestration run` 负责多 Agent 协调。

## 7. 如何判断演示成功

成功必须同时满足：

- 代码和测试由 maker 阶段完成；
- 第一次 kilo 审查确实因输出格式打回；
- pi 修复后重新运行验证；
- 第二次 kilo 审查通过；
- hermes 写出总结；
- `progress.md` 记录两次审查和最终证据；
- coordinator 返回 `SUCCESS`。

只看到“脚本启动成功”或“Agent 能回复”不算 Loop 成功。那只能证明启动器或连接可用。

## 8. 边界

`run-gapscan-loop.ps1` 是可复用启动器和规则模板。失败计数、任务依赖、消息等待和 worker 状态由 Orca orchestration runtime/coordinator 执行；如果需要确定性 CI 门禁，应另外写可执行测试和脚本，不能只依赖 prompt。
