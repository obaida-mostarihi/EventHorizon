import Foundation

// TODO:
// Get rid of unchecked sendable
// Inject logger
public final class APIClientTaskManager: APIClientTaskManagerProtocol, @unchecked Sendable {

    // MARK: - Properties -
    private let lock = NSLock()
    private var tasks: [String: Any] = [:]
    public var taskStatuses: [String: TaskStatus] = [:]
    public static let shared = APIClientTaskManager()

    // MARK: - Initialization -
    private init() {}

    // MARK: - Methods -
    public func addTask<T>(_ task: Task<T, any Error>, for id: String) {
        lock.lock()

        // Prevent adding tasks that are finished or canceled
        if taskStatuses[id] == .finished || taskStatuses[id] == .canceled {
            lock.unlock()
            return
        }

        tasks[id] = task
        taskStatuses[id] = .queued

        lock.unlock()
    }

    public func cancelTask(for id: String) {
        lock.lock()

        if let task = tasks[id] as? Task<Any, any Error>, taskStatuses[id] == .queued || taskStatuses[id] == .inProgress {
            task.cancel()
            tasks.removeValue(forKey: id)
            taskStatuses[id] = .canceled  // Mark the task as canceled
        } else {
            print("No task found for id \(id) or task is not in the correct state, state: \(String(describing: taskStatuses[id]))")
        }

        lock.unlock()
    }

    public func setTaskStatus(
        for id: String,
        status: TaskStatus
    ) {
        lock.lock()
        taskStatuses[id] = status
        lock.unlock()
    }

    public func cancelAllTasks() {
        lock.lock()
        defer { lock.unlock() }
        for id in tasks.keys {
            cancelTask(for: id)
        }
    }

    public func isTaskInProgress(_ id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return taskStatuses[id] == .inProgress
    }

    public func isTaskQueued(_ id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return taskStatuses[id] == .queued
    }

    public func isTaskFinished(_ id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return taskStatuses[id] == .finished
    }

    public func isTaskCanceled(_ id: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return taskStatuses[id] == .canceled
    }

}
