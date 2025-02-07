import Flutter
import UIKit
import MLCSwift

public class MlcSwiftPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var engine = MLCEngine()
    private var historyMessages: [ChatCompletionMessage] = []
    private var currentTask: Task<Void, Error>?
    private static var binaryMessenger: FlutterBinaryMessenger?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        binaryMessenger = registrar.messenger()
        let channel = FlutterMethodChannel(name: "mlc_swift", binaryMessenger: binaryMessenger!)
        let instance = MlcSwiftPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init_chat":
            handleInitChat(call, result: result)
            
        case "request_generate":
            handleRequestGenerate(call, result: result)
            
        case "reset":
            mainResetChat()
            
        case "terminate":
            mainTerminate()
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
// 管理模组
    // 初始化聊天引擎
    private func handleInitChat(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let modelPath = args["model_path"] as? String,
              let modelLib = args["model_lib"] as? String else {
            sendErrorResult(result, code: "INVALID_ARGUMENT", message: "Missing model parameters")
            return
        }
        
        mainReloadChat(modelPath: modelPath, modelLib: modelLib) { error in
            if let error = error  {
                self.sendErrorResult(result, code: "INIT_ERROR", message: error.localizedDescription)
            } else {
                result(true)
            }
        }
    }
    
    // 请求生成处理
    private func handleRequestGenerate(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let requestId = args["request_id"] as? String,
              let prompt = args["prompt"] as? String else {
            sendErrorResult(result, code: "INVALID_ARGUMENT", message: "Missing parameters")
            return
        }
        
        guard let messenger = Self.binaryMessenger else {
            sendErrorResult(result, code: "PLUGIN_ERROR", message: "BinaryMessenger is not available")
            return
        }
        
        // 设置事件通道
        let eventChannel = FlutterEventChannel(
            name: requestId,
            binaryMessenger: messenger
        )
        
        //设置流处理器
        eventChannel.setStreamHandler(self)
        
        //启动生成任务
        currentTask = Task {
            await processGeneration(prompt: prompt)
        }
        
        result(true)
    }
    
    // 设置流监听
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // 保存事件发送器
        self.eventSink = events
        return nil
    }
    
    //设置流取消
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // 清空事件发送器
        eventSink = nil
        
        // 取消正在进行的任务
        currentTask?.cancel()
        return nil
    }
    
// 核心功能
    // 加载聊天
    private func mainReloadChat(
        modelPath: String,
        modelLib: String,
        completion: @escaping (Error?) -> Void
    ) {
        Task {
            do {
                try await engine.unload()
                try await engine.reload(modelPath: modelPath, modelLib: modelLib)
                historyMessages.removeAll()
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    
    // 生成任务
    private func processGeneration(prompt: String) async {
        // 添加信息到历史记录
        let userMessage = ChatCompletionMessage(role: .user, content: prompt)
        historyMessages.append(userMessage)
        
        // 创建生成流
        let stream = await engine.chat.completions.create(
            messages: historyMessages,
            stream_options: StreamOptions(include_usage: true)
        )
        
        var streamingText = ""
        var finishReasonLength = false
        // 处理流式响应
        for await response in stream {
            
            // 解析增量内容
            if let delta = response.choices.first?.delta.content {
                streamingText += delta.asText()
                sendUpdate(streamingText)
            }
            
            // 处理上下文截断
            if response.choices.first?.finish_reason == "length" {
                finishReasonLength = true
                streamingText += " [output truncated due to context length limit...]"
                sendUpdate(streamingText)
                break
            }
        }
        
        // 完成处理
        if !streamingText.isEmpty {
            let assistantMessage = ChatCompletionMessage(
                role: .assistant,
                content: streamingText
            )
            historyMessages.append(assistantMessage)
        } else {
            historyMessages.removeLast()
        }
        sendEnd()
    }
    
    // 辅助方法
    private func sendUpdate(_ text: String) {
        DispatchQueue.main.async {
            self.eventSink?(text)
        }
    }
    
    private func sendEnd() {
        DispatchQueue.main.async {
            self.eventSink?(FlutterEndOfEventStream)
        }
    }
    
    // 重置聊天
    private func mainResetChat() {
        Task {
            await engine.reset()
            historyMessages.removeAll()
        }
    }
    
    // 终止引擎
    private func mainTerminate() {
        currentTask?.cancel()
        Task {
            await engine.unload()
            historyMessages.removeAll()
        }
    }
    
    // 发送错误信息
    private func sendErrorResult(_ result: FlutterResult, code: String, message: String) {
        result(FlutterError(code: code, message: message, details: nil))
    }
    
    
}
