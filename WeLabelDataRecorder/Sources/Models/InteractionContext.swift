import Foundation

/// Структура, що представляє повний контекст взаємодії користувача з інтерфейсом
struct InteractionContext: Codable {
    /// URL скріншоту перед взаємодією
    let beforeScreenshotURL: URL
    
    /// Користувацька взаємодія (клік, рух миші, введення тексту тощо)
    let interaction: UserInteraction
    
    /// URL скріншоту після взаємодії
    let afterScreenshotURL: URL
    
    /// Аналіз взаємодії від OpenAI API, якщо доступний
    var aiAnalysis: String?
    
    /// Створює новий контекст взаємодії
    /// - Parameters:
    ///   - beforeScreenshotURL: URL скріншоту перед взаємодією
    ///   - interaction: Взаємодія користувача
    ///   - afterScreenshotURL: URL скріншоту після взаємодії
    init(beforeScreenshotURL: URL, interaction: UserInteraction, afterScreenshotURL: URL) {
        self.beforeScreenshotURL = beforeScreenshotURL
        self.interaction = interaction
        self.afterScreenshotURL = afterScreenshotURL
        self.aiAnalysis = nil
    }
    
    /// Оновлює аналіз AI
    /// - Parameter analysis: Текст аналізу від AI
    mutating func updateAnalysis(_ analysis: String) {
        self.aiAnalysis = analysis
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case beforeScreenshotURL
        case interaction
        case interactionType
        case afterScreenshotURL
        case aiAnalysis
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        beforeScreenshotURL = try container.decode(URL.self, forKey: .beforeScreenshotURL)
        afterScreenshotURL = try container.decode(URL.self, forKey: .afterScreenshotURL)
        aiAnalysis = try container.decodeIfPresent(String.self, forKey: .aiAnalysis)
        
        // Декодуємо тип взаємодії
        let interactionType = try container.decode(InteractionType.self, forKey: .interactionType)
        
        // В залежності від типу, декодуємо відповідний клас
        switch interactionType {
        case .mouseClick:
            interaction = try container.decode(MouseClickInteraction.self, forKey: .interaction)
        case .mouseMove:
            interaction = try container.decode(MouseMoveInteraction.self, forKey: .interaction)
        case .mouseScroll:
            interaction = try container.decode(MouseScrollInteraction.self, forKey: .interaction)
        case .keyDown, .keyUp:
            interaction = try container.decode(KeyInteraction.self, forKey: .interaction)
        case .screenshot:
            interaction = try container.decode(ScreenshotInteraction.self, forKey: .interaction)
        case .uiElement:
            interaction = try container.decode(UIElementInteraction.self, forKey: .interaction)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(beforeScreenshotURL, forKey: .beforeScreenshotURL)
        try container.encode(afterScreenshotURL, forKey: .afterScreenshotURL)
        try container.encodeIfPresent(aiAnalysis, forKey: .aiAnalysis)
        
        // Зберігаємо тип взаємодії окремо для використання при декодуванні
        try container.encode(interaction.interactionType, forKey: .interactionType)
        
        // Кодуємо саму взаємодію
        switch interaction {
        case let click as MouseClickInteraction:
            try container.encode(click, forKey: .interaction)
        case let move as MouseMoveInteraction:
            try container.encode(move, forKey: .interaction)
        case let scroll as MouseScrollInteraction:
            try container.encode(scroll, forKey: .interaction)
        case let key as KeyInteraction:
            try container.encode(key, forKey: .interaction)
        case let screenshot as ScreenshotInteraction:
            try container.encode(screenshot, forKey: .interaction)
        case let uiElement as UIElementInteraction:
            try container.encode(uiElement, forKey: .interaction)
        default:
            throw EncodingError.invalidValue(interaction, EncodingError.Context(
                codingPath: [CodingKeys.interaction],
                debugDescription: "Невідомий тип взаємодії: \(type(of: interaction))"
            ))
        }
    }
} 