import Foundation
import PencilKit

//BreathingSession
struct BreathingSession: Codable {
    var id: UUID = UUID()
    var userId: UUID
    var cyclesCompleted: Int
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case cyclesCompleted = "cycles_completed"
        case durationSeconds = "duration_seconds"
        case pointsEarned = "points_earned"
        case completedAt = "completed_at"
    }
}

//JpmrSession
struct JpmrSession: Codable {
    var id: UUID = UUID()
    var userId: UUID
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case durationSeconds = "duration_seconds"
        case pointsEarned = "points_earned"
        case completedAt = "completed_at"
    }
}

//JpmrVideo
struct JpmrVideo: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var videoUrl: String

    enum CodingKeys: String, CodingKey {
        case id, title
        case videoUrl = "video_url"
    }
}

//GuidedMeditationSession
struct GuidedMeditationSession: Codable {
    var id: UUID = UUID()
    var userId: UUID
    var meditationName: String
    var durationSeconds: Int
    var pointsEarned: Int
    var completedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case meditationName = "meditation_name"
        case durationSeconds = "duration_seconds"
        case pointsEarned = "points_earned"
        case completedAt = "completed_at"
    }
}

//AsmrSound
struct AsmrSound: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var description: String
    var category: String
    var audioUrl: String
    var imageUrl: String
    var durationSeconds: Int

    init(name: String, description: String, category: String, audioUrl: String, imageUrl: String, durationSeconds: Int) {
        self.id = AsmrSound.stableId(for: name)
        self.name = name
        self.description = description
        self.category = category
        self.audioUrl = audioUrl
        self.imageUrl = imageUrl
        self.durationSeconds = durationSeconds
    }

    /// Produces the same UUID for the same name on every launch.
    private static func stableId(for name: String) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        for (i, byte) in name.utf8.enumerated() {
            bytes[i % 16] = bytes[i % 16] &+ byte
        }
        // Mark as UUID v5 (name-based) for spec correctness
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (bytes[0],  bytes[1],  bytes[2],  bytes[3],
                           bytes[4],  bytes[5],  bytes[6],  bytes[7],
                           bytes[8],  bytes[9],  bytes[10], bytes[11],
                           bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}

//UserFavouriteAsmrSound
struct UserFavouriteAsmrSound: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var soundId: UUID
    var savedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case soundId = "sound_id"
        case savedAt = "saved_at"
    }
}

//BrainDumpFolder
struct BrainDumpFolder: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var name: String
    var entryCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case entryCount = "entry_count"
    }
}

//BrainDumpEntry
struct BrainDumpEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var folderId: UUID?
    var title: String?
    var content: String
    var drawingData: Data?
    var pointsEarned: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        folderId: UUID? = nil,
        title: String? = nil,
        content: String,
        drawingData: Data? = nil,
        pointsEarned: Int = 10,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.folderId = folderId
        self.title = title
        self.content = content
        self.drawingData = drawingData
        self.pointsEarned = pointsEarned
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case folderId = "folder_id"
        case title, content
        case drawingData = "drawing_data"
        case pointsEarned = "points_earned"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.folderId = try container.decodeIfPresent(UUID.self, forKey: .folderId)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.content = (try? container.decode(String.self, forKey: .content)) ?? ""
        self.pointsEarned = (try? container.decode(Int.self, forKey: .pointsEarned)) ?? 0

        // Handle date decoding gracefully (ISO8601 or string fallback)
        if let date = try? container.decode(Date.self, forKey: .createdAt) {
            self.createdAt = date
        } else if let dateStr = try? container.decode(String.self, forKey: .createdAt),
                  let parsedDate = ISO8601DateFormatter().date(from: dateStr) {
            self.createdAt = parsedDate
        } else {
            self.createdAt = Date()
        }

        // Handle Postgres bytea \x hex-encoded string or base64 or raw Data
        if let rawString = try? container.decodeIfPresent(String.self, forKey: .drawingData) {
            if rawString.hasPrefix("\\x") {
                let hex = String(rawString.dropFirst(2))
                var rawBytes = Data()
                var asciiChars = ""
                var index = hex.startIndex
                while index < hex.endIndex {
                    let nextIndex = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
                    if let byte = UInt8(hex[index..<nextIndex], radix: 16) {
                        rawBytes.append(byte)
                        asciiChars.append(Character(UnicodeScalar(byte)))
                    }
                    index = nextIndex
                }
                
                // Check if the hex bytes represent an ASCII base64 string
                if let base64Decoded = Data(base64Encoded: asciiChars),
                   (try? PKDrawing(data: base64Decoded)) != nil {
                    self.drawingData = base64Decoded
                } else if (try? PKDrawing(data: rawBytes)) != nil {
                    self.drawingData = rawBytes
                } else {
                    self.drawingData = rawBytes
                }
            } else if let base64Data = Data(base64Encoded: rawString) {
                self.drawingData = base64Data
            } else {
                self.drawingData = rawString.data(using: .utf8)
            }
        } else if let rawData = try? container.decodeIfPresent(Data.self, forKey: .drawingData) {
            self.drawingData = rawData
        } else {
            self.drawingData = nil
        }
    }
}

//ASMRPlaylist
struct ASMRPlaylist: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var subtitle: String
    var purpose: String
    var coverImageName: String
    var placeholderColorHex: String
    var sounds: [AsmrSound]
}
