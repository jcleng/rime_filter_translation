### 使用本地模型翻译候选词(comment_font)

- 使用,在你的方案 default.custom.yaml(ice是: rime_ice.schema.yaml) 中添加：

```shell
# translation_filter.lua放到rime/lua/目录下
/bin/cp -rf ./translation_filter.lua ~/.local/share/fcitx5/rime/lua/
```

```lua
-- rime.lua 文件内添加
translation_filter = require("translation_filter")
```

```yaml
# 配置生效使用
engine:
  filters:
    - lua_filter@translation_filter
```

- 测试用

```shell
/bin/cp -rf ./rime.lua ~/.local/share/fcitx5/rime/rime.lua
/bin/cp -rf ./translation_filter.lua ~/.local/share/fcitx5/rime/lua/
```