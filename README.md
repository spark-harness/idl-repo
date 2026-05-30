# IDL Repo

这个仓库是 protobuf 契约仓骨架。

它负责保存：

- `.proto` 文件。
- `buf.yaml` v2 工作区配置。
- `buf.gen.yaml` v2 生成配置。
- `buf.lock`。
- 生成代码输出目录。

## 目录

```text
idl-repo/
├── buf.yaml
├── buf.gen.yaml
├── proto/
└── gen/
```

## 基础命令

```text
buf lint
buf generate
buf breaking --against '.git#branch=main'
```

如果主干分支不是 `main`，门禁报告中应记录实际 breaking baseline。
