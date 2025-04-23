import Foundation
import AppKit

/// Сервіс для аналізу взаємодій користувача з використанням OpenAI API
class AIAnalysisService {
    /// Синглтон для доступу до сервісу
    static let shared = AIAnalysisService()
    
    /// URL для OpenAI API
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    /// API ключ (у виробничому коді повинен бути захищений)
    private var apiKey: String?
    
    /// Назва моделі для використання
    private let modelName = "gpt-4-vision-preview"
    
    /// Максимальна кількість токенів у відповіді
    private let maxTokens = 500
    
    /// Приватний конструктор для синглтону
    private init() {}
    
    /// Встановлює API ключ для OpenAI
    /// - Parameter key: API ключ
    func setApiKey(_ key: String) {
        self.apiKey = key
    }
    
    /// Аналізує контекст взаємодії та повертає текстовий опис
    /// - Parameters:
    ///   - context: Контекст взаємодії (скріншоти до і після + інформація про дію)
    ///   - completion: Замикання-колбек, викликається після отримання результату
    func analyzeInteraction(_ context: InteractionContext, completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = apiKey else {
            completion(.failure(NSError(domain: "AIAnalysisError", code: 1, userInfo: [NSLocalizedDescriptionKey: "API ключ не налаштовано"])))
            return
        }
        
        // Конвертуємо зображення у Base64
        guard let beforeImageData = try? Data(contentsOf: context.beforeScreenshotURL),
              let afterImageData = try? Data(contentsOf: context.afterScreenshotURL) else {
            completion(.failure(NSError(domain: "AIAnalysisError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Помилка завантаження зображень"])))
            return
        }
        
        let beforeBase64 = beforeImageData.base64EncodedString()
        let afterBase64 = afterImageData.base64EncodedString()
        
        // Опис взаємодії для AI
        let interactionDescription = describeInteraction(context.interaction)
        
        // Створюємо запит до API
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Формуємо тіло запиту
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [
                [
                    "role": "system",
                    "content": "Ти - аналітик взаємодій користувача з інтерфейсом. Тобі буде надано два зображення: перед дією користувача і після, а також опис самої дії. Проаналізуй контекст та надай стислий опис того, що користувач намагався досягти, який був результат дії, та чому користувач міг виконати саме цю дію."
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Ось зображення екрану ПЕРЕД взаємодією:"
                        ],
                        [
                            "type": "image_url",
                            "image_url": ["url": "data:image/png;base64,\(beforeBase64)"]
                        ],
                        [
                            "type": "text",
                            "text": "Користувач виконав наступну дію: \(interactionDescription)"
                        ],
                        [
                            "type": "text",
                            "text": "Ось зображення екрану ПІСЛЯ взаємодії:"
                        ],
                        [
                            "type": "image_url",
                            "image_url": ["url": "data:image/png;base64,\(afterBase64)"]
                        ],
                        [
                            "type": "text",
                            "text": "Проаналізуй: що користувач намагався зробити, який був результат, і чому він міг виконати саме цю дію? Відповідай стисло, до 3 речень."
                        ]
                    ]
                ]
            ],
            "max_tokens": maxTokens
        ]
        
        // Конвертуємо тіло запиту в JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Виконуємо запит
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AIAnalysisError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Відсутні дані у відповіді"])))
                return
            }
            
            do {
                // Парсимо відповідь
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    completion(.success(content))
                } else {
                    // Якщо структура відповіді не відповідає очікуваній
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Unexpected API response: \(jsonString)")
                    }
                    completion(.failure(NSError(domain: "AIAnalysisError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Неочікувана структура відповіді"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    /// Створює текстовий опис взаємодії для AI
    /// - Parameter interaction: Взаємодія користувача
    /// - Returns: Текстовий опис взаємодії
    private func describeInteraction(_ interaction: UserInteraction) -> String {
        switch interaction.interactionType {
        case .mouseClick:
            if let clickInteraction = interaction as? MouseClickInteraction {
                return "Клік мишею в позиції X: \(clickInteraction.position.x), Y: \(clickInteraction.position.y) " +
                       "кнопкою \(clickInteraction.button.rawValue) " +
                       "\(clickInteraction.clickCount > 1 ? "(\(clickInteraction.clickCount) рази)" : "")"
            }
        case .mouseMove:
            if let moveInteraction = interaction as? MouseMoveInteraction {
                return "Переміщення миші з позиції X: \(moveInteraction.fromPosition.x), Y: \(moveInteraction.fromPosition.y) " +
                       "в позицію X: \(moveInteraction.toPosition.x), Y: \(moveInteraction.toPosition.y)"
            }
        case .mouseScroll:
            if let scrollInteraction = interaction as? MouseScrollInteraction {
                return "Прокрутка в позиції X: \(scrollInteraction.position.x), Y: \(scrollInteraction.position.y) " +
                       "з дельтою X: \(scrollInteraction.deltaX), Y: \(scrollInteraction.deltaY)"
            }
        case .keyDown, .keyUp:
            if let keyInteraction = interaction as? KeyInteraction {
                return "Натискання клавіші \(keyInteraction.keyCode) (\(keyInteraction.characters ?? "")) " +
                       "\(keyInteraction.interactionType == .keyDown ? "вниз" : "вгору")"
            }
        case .uiElement:
            if let elementInteraction = interaction as? UIElementInteraction {
                return "Взаємодія з UI елементом: \(elementInteraction.elementInfo.role) " +
                       "\(elementInteraction.elementInfo.title ?? "без назви") " +
                       "дія: \(elementInteraction.interactionAction.rawValue)"
            }
        case .screenshot:
            return "Знімок екрану було зроблено"
        }
        
        // Якщо кастинг до конкретного типу не вдався, повертаємо загальний опис
        return "Взаємодія типу \(interaction.interactionType.rawValue)"
    }
} 