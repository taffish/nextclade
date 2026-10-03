# 3.24.0 mutation-patterns 合成测试数据

`fixtures/` 是独立生成的 900 bp 工程 fixture，不是病毒数据，也不供科学解释。
参考由固定种子 324 生成；query 仅在零基位置 300、310、320、330 置换碱基。
`pathogen.json` 设置窗口 50、阈值 3 的全替换匹配 pattern；单根参考树用于
证明四个替换、四个匹配和一个 cluster。去掉参考树时，上游仍输出 pattern
记录，但匹配和 cluster 为零。该差别不能用宽松 grep 或删除测试来掩盖。

本 fixture 故意不含 CDS 注释；CLI 测试不等同于完整 Auspice Web 数据集。
浏览器树视图测试另给 `meta.genome_annotations.nuc` 添加 1..900 的 genome map，
不改变序列、突变或拓扑。完整浏览器验收证据在本次 Hub 更新回执中。
