# IDL Repo

这个仓库是 protobuf 契约仓骨架。

它负责保存：

- `.proto` 文件。
- `buf.yaml` v2 工作区配置。
- `buf.gen.yaml` v2 生成配置。
- `buf.gen.go.yaml` v2 Go 专用生成配置。
- `buf.lock`。

生成代码不提交到本仓库；消费者在各自构建流程中生成，或按 `buf.gen.yaml` 输出到仓库外目录。

## 目录

```text
idl-repo/
├── buf.yaml
├── buf.gen.yaml
├── buf.gen.go.yaml
└── vesta/
    ├── lendora/
    │   └── applicant/
    │       └── v1/
    │           └── auth.proto
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

- Go message / gRPC staging：`../.generated/idl-go`
- Java message：`../idl-java-repo/src/main/java`
- Java gRPC stub：`../idl-java-repo/src/main/grpc-java`

Java 生成物不进入 `business-repo`。Pipeline 在 `idl-repo` 执行 `buf generate`，编译 `../idl-java-repo`，再把 `idl-java-repo` 推送到指定远端仓库的指定分支。业务服务只依赖该生成物仓发布的 Maven artifact。

Go 生成物不直接写入 `idl-go-repo` 仓库根目录。Pipeline 使用 `buf.gen.go.yaml` 生成到 staging 目录，再同步生成文件到 `idl-go-repo`。这样可以保留生成仓的 `.git`、`go.mod`、`go.sum` 和 README，避免 `clean: true` 清理仓库元数据。

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

## Java 生成物发布

GitHub Actions 工作流：`.github/workflows/publish-java-idl.yml`。

发布规则：

- RC 发布通过 `workflow_dispatch` 输入冻结的 `idl_ref` 和目标 `java_version`，也可以通过推送符合格式的 RC tag 触发。
- formal 发布由 `idl-repo` SemVer tag push 触发。
- 发布前检查 `spark-harness/idl-java-repo` Maven package 中目标版本是否已存在；已存在则失败。
- RC version 最后一段 SHA 必须匹配解析后的 IDL commit 前缀；不匹配时发布失败。
- 发布流程先 checkout `idl-java-repo` 作为生成物 Maven 工程，再从 `idl-repo` 指定 ref 执行 `buf generate`，最后临时写入目标 Maven version 并执行 `mvn -B deploy`。
- 发布时会读取生成 Java 代码中的 protobuf gencode version，并确保发布 artifact 的 `protobuf-java` runtime 版本不低于 gencode version。

仓库需要配置 secret：

```text
IDL_JAVA_REPO_TOKEN
```

该 token 需要有 `spark-harness/idl-java-repo` 的读权限和 GitHub Packages 写权限。

## Go 生成物同步

GitHub Actions 工作流：`.github/workflows/sync-go-idl.yml`。

触发条件：

- 任意分支 push 修改 `.proto`、`buf.yaml`、`buf.gen.yaml`、`buf.gen.go.yaml` 或工作流自身。
- 手动 `workflow_dispatch`。

同步规则：

- 当前仓库：`spark-harness/idl-repo`
- Go 生成物仓：`spark-harness/idl-go-repo`
- 目标分支：与 `idl-repo` 触发分支同名
- 生成命令：`buf generate --template buf.gen.go.yaml`
- 校验命令：在 `idl-go-repo` 执行 `go mod tidy` 和 `go test ./...`
- 生成内容：Go message 与 Go gRPC stub

仓库需要配置 secret：

```text
IDL_GO_REPO_TOKEN
```

该 token 需要有 `spark-harness/idl-go-repo` 的写权限。`GITHUB_TOKEN` 默认只能写当前仓库，不能可靠地跨仓推送生成物仓。

## Go 生成物发布

GitHub Actions 工作流：`.github/workflows/publish-go-idl.yml`。

发布规则：

- RC 发布通过 `workflow_dispatch` 输入冻结的 `idl_ref` 和目标 `go_tag`，也可以通过推送符合格式的 RC tag 触发。
- formal 发布由 `idl-repo` SemVer tag push 触发。
- 发布前检查 `spark-harness/idl-go-repo` 远端 tag 是否已存在；已存在则失败。
- RC tag 最后一段 SHA 必须匹配解析后的 IDL commit 前缀；不匹配时发布失败。
- 发布流程使用 `buf.gen.go.yaml` 生成到 staging，随后同步到 `idl-go-repo`，执行 `go mod tidy` 和 `go test ./...`。
