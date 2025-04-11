import Foundation

/// A protocol for managing and tracking the status of tasks in the `APIClient`.
/// This protocol provides methods for adding, canceling, and checking the status of tasks,
/// as well as setting their status within the task manager.
///
/// Conforms to `Sendable` to ensure thread-safety when accessing or modifying tasks in concurrent environments.
public protocol APIClientTaskManagerProtocol: Sendable {

    /// Adds a new task to the manager.
    ///
    /// This method adds a task to the task manager for tracking. The task status is set to `.queued` by default.
    ///
    /// - Parameters:
    ///   - task: The task to be added to the manager.
    ///   - id: A unique identifier for the task.
    ///
    /// - Important: The task will only be added if its status is not `.finished` or `.canceled`.
    func addTask<T>(_ task: Task<T, any Error>, for id: String)

    /// Cancels a task with the given identifier.
    ///
    /// This method cancels the task if it is either `.queued` or `.inProgress`. The task status will be updated to `.canceled` after cancellation.
    ///
    /// - Parameter id: The unique identifier for the task to be canceled.
    func cancelTask(for id: String)

    /// Cancels all tasks that are currently in progress or queued.
    ///
    /// This method will cancel every task in the `tasks` dictionary, and each task's status will be updated to `.canceled`.
    func cancelAllTasks()

    /// Checks whether a task is currently in progress.
    ///
    /// - Parameter id: The unique identifier for the task to check.
    ///
    /// - Returns: `true` if the task is in progress, otherwise `false`.
    func isTaskInProgress(_ id: String) -> Bool

    /// Checks whether a task is queued for execution.
    ///
    /// - Parameter id: The unique identifier for the task to check.
    ///
    /// - Returns: `true` if the task is queued, otherwise `false`.
    func isTaskQueued(_ id: String) -> Bool

    /// Checks whether a task has finished execution.
    ///
    /// - Parameter id: The unique identifier for the task to check.
    ///
    /// - Returns: `true` if the task has finished, otherwise `false`.
    func isTaskFinished(_ id: String) -> Bool

    /// Checks whether a task has been canceled.
    ///
    /// - Parameter id: The unique identifier for the task to check.
    ///
    /// - Returns: `true` if the task has been canceled, otherwise `false`.
    func isTaskCanceled(_ id: String) -> Bool

    /// Sets the status for a specific task.
    ///
    /// This method allows updating the status of a task, such as marking it as queued, in-progress, finished, or canceled.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the task.
    ///   - status: The status to set for the task.
    func setTaskStatus(for id: String, status: TaskStatus)
}
