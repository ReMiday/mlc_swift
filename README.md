# mlc_swift

一个flutter plugin，用于将mlc-ai的mlc llm项目接入ios端使用

## tips

### 1、你得完整克隆mlc-ai的mlc llm项目，找到项目中的MLCSwift Package，该插件依赖这个SPM包

在flutter的主项目下的ios文件夹中按mlc llm官方文档进行配置（包括模型下载、编译模型等）

### 2、克隆本项目于你的flutter主项目下，并添加进yaml文件中作为插件依赖

选取模型类型参考mlc llm官方文档，插件中选取模型为Qwen2.5-0.5B-q4f16_1，因此下载其他模型请修改插件里面提供的模型下载方法中的相关变量
