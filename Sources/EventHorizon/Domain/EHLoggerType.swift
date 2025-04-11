/// Represents the type or severity of a log message.
public enum EHLoggerType {
    /// Informational messages that highlight the progress of the application.
    case info

    /// Error messages indicating a failure or issue within the application.
    case error

    /// Debug messages used during development for debugging purposes.
    case debug
}
