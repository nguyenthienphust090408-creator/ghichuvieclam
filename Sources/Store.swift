import Foundation
import UserNotifications

struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var done = false
    var createdAt = Date()
    var doneAt: Date? = nil
}

enum Notifier {
    static let category = "TODO_CATEGORY"
    static let doneAction = "DONE_ACTION"

    static func setup() {
        let done = UNNotificationAction(identifier: doneAction, title: "✅ Hoàn thành", options: [])
        let cat = UNNotificationCategory(identifier: category, actions: [done],
                                         intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([cat])
    }

    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func post(_ item: TodoItem) {
        let c = UNMutableNotificationContent()
        c.title = "☐  " + item.title
        c.body = "Nhấn giữ để chọn “Hoàn thành”"
        c.categoryIdentifier = category
        c.threadIdentifier = "todos"
        let req = UNNotificationRequest(
            identifier: item.id.uuidString, content: c,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(req)
    }

    static func remove(_ id: UUID) {
        let n = UNUserNotificationCenter.current()
        n.removeDeliveredNotifications(withIdentifiers: [id.uuidString])
        n.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    static func deliveredIDs(_ completion: @escaping (Set<String>) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { list in
            completion(Set(list.map { $0.request.identifier }))
        }
    }
}

final class TodoStore: ObservableObject {
    static let shared = TodoStore()
    @Published var items: [TodoItem] = []
    private let key = "todo_items_v1"

    init() { load() }

    func load() {
        if let d = UserDefaults.standard.data(forKey: key),
           let v = try? JSONDecoder().decode([TodoItem].self, from: d) {
            items = v
        }
    }

    private func save() {
        if let d = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }

    func add(_ title: String) {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let item = TodoItem(title: t)
        items.insert(item, at: 0)
        save()
        Notifier.post(item)
    }

    func setDone(_ id: UUID, _ done: Bool) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].done = done
        items[i].doneAt = done ? Date() : nil
        save()
        if done { Notifier.remove(id) } else { Notifier.post(items[i]) }
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
        Notifier.remove(id)
    }

    func clearCompleted() {
        items.removeAll { $0.done }
        save()
    }

    /// Ghim lại thông báo của các việc chưa xong nếu bị vuốt mất.
    func repostMissing() {
        Notifier.deliveredIDs { ids in
            DispatchQueue.main.async {
                for item in self.items where !item.done && !ids.contains(item.id.uuidString) {
                    Notifier.post(item)
                }
            }
        }
    }
}
