# 3.24.0 mutation-patterns 合成测试数据

`fixtures/` 是独立生成的 900 bp 工程 fixture，不是病毒数据，也不供科学解释。
参考由固定种子 324 生成；query 仅在零基位置 300、310、320、330 置换碱基。
`pathogen.json` 设置窗口 50、阈值 3 的全替换匹配 pattern；单根参考树用于
证明四个替换、四个匹配和一个 cluster。去掉参考树时，上游仍输出 pattern
记录，但匹配和 cluster 为零。该差别不能用宽松 grep 或删除测试来掩盖。

本 fixture 故意不含 CDS 注释；CLI 测试不等同于完整 Auspice Web 数据集。
浏览器树视图测试另给 `meta.genome_annotations.nuc` 添加 1..900 的 genome map，
不改变序列、突变或拓扑。完整浏览器验收证据在本次 Hub 更新回执中。

## 3.25.0 CDS 边界与起始密码子工程 fixture

`fixtures/cds/` 的短中心片段来自上游 MIT 源码 commit
`d415f3c396fabc7f792c676d60ac9b50236830c1` 的 `align.rs` / `SHORT_TIE` 单测。
两侧各加 450 bp 确定性合成序列（LCG 种子325、系数1664525/1013904223，
取高2 bit 映射 ACGT）；不是生产病毒数据或科学验证。CDS 为一基466..489。
保留原始缺口与碱基，不改上游算法。

默认参数与显式惩罚0的左对齐缺失为零基[458,466)，会破坏ATG；惩罚1时
应为[457,465)，不破坏ATG。另含完整ATG、ATA、NTG、ATR四条序列：只有ATA
应产生新起始密码子警告。JSON、NDJSON、TSV均检查；该测试仅在runtime执行，
不把完整分析/浏览器测试塞入Docker build。
