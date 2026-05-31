# IDL Repo

这个仓库是 protobuf 契约仓骨架。

它负责保存：

- `.proto` 文件。
- `buf.yaml` v2 工作区配置。
- `buf.gen.yaml` v2 生成配置。
- `buf.lock`。

生成代码不提交到本仓库；消费者在各自构建流程中生成，或按 `buf.gen.yaml` 输出到仓库外目录。

## 目录

```text
idl-repo/
├── buf.yaml
├── buf.gen.yaml
└── vesta/
    └── spark/
        └── user/
            └── v1/
                └── ping.proto
```

## 基础命令

```text
buf lint
buf generate
buf breaking --against '.git#branch=master'
```

门禁报告中的 breaking baseline 使用 `master`。

## 生成输出

- Go：`../.generated/idl/go`
- Java message：`../idl-java-repo/src/main/java`
- Java gRPC stub：`../idl-java-repo/src/main/grpc-java`

Java 生成物不进入 `business-repo`。Pipeline 在 `idl-repo` 执行 `buf generate`，编译 `../idl-java-repo`，再把 `idl-java-repo` 推送到指定远端仓库的指定分支。业务服务只依赖该生成物仓发布的 Maven artifact。

## Java 生成物同步

GitHub Actions 工作流：`.github/workflows/sync-java-idl.yml`。

触发条件：

- 任意分支 push 修改 `.proto`、`buf.yaml`、`buf.gen.yaml` 或工作流自身。
- 手动 `workflow_dispatch`。

同步规则：

- 当前仓库：`spark-harness/idl-repo`
- Java 生成物仓：`spark-harness/idl-java-repo`
- 目标分支：与 `idl-repo` 触发分支同名
- 生成命令：`buf generate`
- 编译命令：在 `idl-java-repo` 执行 `mvn -B test`

仓库需要配置 secret：

```text
IDL_JAVA_REPO_TOKEN
```

该 token 需要有 `spark-harness/idl-java-repo` 的写权限。`GITHUB_TOKEN` 默认只能写当前仓库，不能可靠地跨仓推送生成物仓。
