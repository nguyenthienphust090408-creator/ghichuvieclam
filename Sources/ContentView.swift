import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TodoStore
    @State private var text = ""
    @FocusState private var focused: Bool

    private var pending: [TodoItem] { store.items.filter { !$0.done } }
    private var completed: [TodoItem] { store.items.filter { $0.done } }
    private var progress: Double {
        store.items.isEmpty ? 0 : Double(completed.count) / Double(store.items.count)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            LinearGradient(colors: [Color.indigo.opacity(0.18), Color.purple.opacity(0.08), .clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                header
                if store.items.isEmpty { emptyState } else { list }
                inputBar
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Việc cần làm")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(pending.isEmpty && !store.items.isEmpty
                 ? "Tuyệt vời, bạn đã xong hết 🎉"
                 : "Còn \(pending.count) việc chưa xong")
                .font(.subheadline).foregroundStyle(.secondary)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.indigo.opacity(0.15))
                    Capsule()
                        .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: g.size.width * progress)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 8)
    }

    private var list: some View {
        List {
            if !pending.isEmpty {
                Section {
                    ForEach(pending) { row($0) }
                }
            }
            if !completed.isEmpty {
                Section {
                    ForEach(completed) { row($0) }
                } header: {
                    HStack {
                        Text("Đã hoàn thành").font(.footnote.weight(.semibold))
                        Spacer()
                        Button("Xoá hết") { withAnimation { store.clearCompleted() } }
                            .font(.footnote)
                    }
                    .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private func row(_ item: TodoItem) -> some View {
        HStack(spacing: 14) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring()) { store.setDone(item.id, !item.done) }
            } label: {
                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundStyle(item.done ? Color.green : Color.indigo)
            }
            .buttonStyle(.plain)
            Text(item.title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .strikethrough(item.done)
                .foregroundStyle(item.done ? Color.secondary : Color.primary)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation { store.delete(item.id) }
            } label: { Label("Xoá", systemImage: "trash") }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checklist").font(.system(size: 56)).foregroundStyle(Color.indigo.opacity(0.6))
            Text("Chưa có việc nào").font(.headline)
            Text("Thêm việc bên dưới, nó sẽ hiện trên màn hình khoá.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(40)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Thêm việc mới…", text: $text)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(add)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
            Button(action: add) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(LinearGradient(colors: [.indigo, .purple],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing)))
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func add() {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring()) { store.add(text) }
        text = ""
    }
}
