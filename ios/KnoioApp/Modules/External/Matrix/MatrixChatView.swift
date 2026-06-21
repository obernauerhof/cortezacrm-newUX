import SwiftUI

// MARK: - Raumliste

/// Native Chat-Oberfläche: Liste der Räume → Raumdetail. Wird innerhalb des
/// `NavigationStack` von `ModuleHostView` dargestellt.
struct MatrixChatView: View {
    let homeserver: URL
    @StateObject private var model: RoomListModel

    init(homeserver: URL) {
        self.homeserver = homeserver
        _model = StateObject(wrappedValue: RoomListModel(homeserver: homeserver))
    }

    var body: some View {
        List(model.rooms) { room in
            NavigationLink(value: room) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(room.name).font(.headline)
                    Text(room.id).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if model.rooms.isEmpty {
                if model.isLoading {
                    ProgressView()
                } else if let error = model.error {
                    ContentUnavailableView("Chat nicht verfügbar",
                                           systemImage: "message.badge.waveform",
                                           description: Text(error))
                } else {
                    ContentUnavailableView("Keine Räume", systemImage: "message")
                }
            }
        }
        .navigationDestination(for: MatrixRoom.self) { room in
            RoomView(homeserver: homeserver, room: room)
        }
        .task { await model.load() }
    }
}

@MainActor
final class RoomListModel: ObservableObject {
    @Published private(set) var rooms: [MatrixRoom] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let backend: ChatBackend

    init(homeserver: URL) {
        backend = ChatBackendFactory.make(homeserver: homeserver)
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            rooms = try await backend.rooms()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Raumdetail

struct RoomView: View {
    @StateObject private var model: RoomModel

    init(homeserver: URL, room: MatrixRoom) {
        _model = StateObject(wrappedValue: RoomModel(homeserver: homeserver, room: room))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(model.messages) { MessageBubble(message: $0) }
                }
                .padding()
            }
            composer
        }
        .navigationTitle(model.room.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Nachricht", text: $model.draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            Button {
                Task { await model.send() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
            }
            .disabled(model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.bar)
    }
}

@MainActor
final class RoomModel: ObservableObject {
    @Published private(set) var messages: [MatrixMessage] = []
    @Published var draft = ""
    @Published private(set) var error: String?

    let room: MatrixRoom
    private let backend: ChatBackend

    init(homeserver: URL, room: MatrixRoom) {
        self.room = room
        backend = ChatBackendFactory.make(homeserver: homeserver)
    }

    func load() async {
        do {
            messages = try await backend.messages(in: room.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        do {
            let message = try await backend.send(text, to: room.id)
            messages.append(message)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Bubble

private struct MessageBubble: View {
    let message: MatrixMessage

    var body: some View {
        HStack {
            if message.isMine { Spacer(minLength: 40) }
            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 2) {
                if !message.isMine {
                    Text(message.sender)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(message.body)
                    .padding(10)
                    .background(message.isMine ? Color.accentColor : Color(.secondarySystemBackground))
                    .foregroundStyle(message.isMine ? Color.white : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            if !message.isMine { Spacer(minLength: 40) }
        }
    }
}
