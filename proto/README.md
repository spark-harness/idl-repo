# Proto

`.proto` 文件放在本目录下。

推荐按领域和版本组织：

```text
proto/
└── order/
    └── v1/
        └── order.proto
```

package、message、service、RPC、field number 的兼容性由 buf breaking 检查兜底。
