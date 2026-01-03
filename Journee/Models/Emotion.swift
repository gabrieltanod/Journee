import Foundation

enum Emotion: String, CaseIterable, Codable, Identifiable {
    case happy = "😄"
    case neutral = "😐"
    case sad = "😫"
    case angry = "😡"
    case excited = "🤩"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .happy: return "Happy"
        case .neutral: return "Neutral"
        case .sad: return "Sad"
        case .angry: return "Angry"
        case .excited: return "Excited"
        }
    }
}
