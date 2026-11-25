import Foundation

/// Lê e grava os dados no App Group, para que app, widget e extensão vejam a mesma coisa.
/// O registro de uso dos apps fica num arquivo separado: ele é escrito pelas automações
/// do app Atalhos, às vezes com o Milheiro fechado.
enum SharedStore {
    static var appGroupID: String? {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "MilheiroAppGroup") as? String,
              !id.isEmpty, !id.contains("$(") else { return nil }
        return id
    }

    static var directory: URL {
        #if canImport(Darwin)
        if let id = appGroupID,
           let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) {
            return url
        }
        #endif
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }

    static var dataURL: URL { directory.appendingPathComponent("milheiro.json") }
    static var usageURL: URL { directory.appendingPathComponent("milheiro-uso.json") }

    static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    static func load() -> AppData {
        guard let raw = try? Data(contentsOf: dataURL) else { return AppData() }
        if let data = try? decoder().decode(AppData.self, from: raw) { return data }
        // Arquivo ilegível: guarda uma cópia antes de recomeçar, para não perder nada.
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = directory.appendingPathComponent("milheiro-ilegivel-\(stamp).json")
        try? raw.write(to: backup, options: .atomic)
        return AppData()
    }

    static func save(_ data: AppData) {
        guard let raw = try? encoder().encode(data) else { return }
        try? raw.write(to: dataURL, options: .atomic)
    }

    static func decode(_ raw: Data) -> AppData? {
        try? decoder().decode(AppData.self, from: raw)
    }

    static func encode(_ data: AppData) -> Data? {
        try? encoder().encode(data)
    }

    // MARK: Uso dos apps

    static func usageLog() -> [String: [Date]] {
        guard let raw = try? Data(contentsOf: usageURL),
              let log = try? decoder().decode([String: [Date]].self, from: raw) else { return [:] }
        return log
    }

    static func recordUsage(_ serviceId: String, at date: Date = Date()) {
        var log = usageLog()
        let limit = date.addingTimeInterval(-90 * Engine.day)
        var list = (log[serviceId] ?? []).filter { $0 >= limit }
        // Ignora disparos repetidos em menos de 10 minutos (abrir e fechar o app várias vezes).
        if let last = list.last, date.timeIntervalSince(last) < 600 { return }
        list.append(date)
        log[serviceId] = list
        guard let raw = try? encoder().encode(log) else { return }
        try? raw.write(to: usageURL, options: .atomic)
    }
}
