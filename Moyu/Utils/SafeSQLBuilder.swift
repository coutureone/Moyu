import Foundation
import SQLite3

// MARK: - Safe SQL Query Builder
class SafeSQLBuilder {
    private var db: OpaquePointer?

    init(db: OpaquePointer?) {
        self.db = db
    }

    /// 安全执行 SELECT 查询（使用参数绑定）
    func query<T>(
        sql: String,
        params: [Any] = [],
        transform: (OpaquePointer) -> T?
    ) -> [T] {
        var results: [T] = []
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            if let errMsg = sqlite3_errmsg(db) {
                print("❌ SQL准备失败: \(String(cString: errMsg))")
            }
            return results
        }

        // 绑定参数
        for (index, param) in params.enumerated() {
            bindParameter(stmt: stmt, index: Int32(index + 1), value: param)
        }

        // 执行查询
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let item = transform(stmt!) {
                results.append(item)
            }
        }

        sqlite3_finalize(stmt)
        return results
    }

    /// 安全执行单条查询
    func querySingle<T>(
        sql: String,
        params: [Any] = [],
        transform: (OpaquePointer) -> T?
    ) -> T? {
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return nil
        }

        for (index, param) in params.enumerated() {
            bindParameter(stmt: stmt, index: Int32(index + 1), value: param)
        }

        var result: T?
        if sqlite3_step(stmt) == SQLITE_ROW {
            result = transform(stmt!)
        }

        sqlite3_finalize(stmt)
        return result
    }

    /// 安全执行 INSERT/UPDATE/DELETE
    func execute(sql: String, params: [Any] = []) -> Bool {
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            if let errMsg = sqlite3_errmsg(db) {
                print("❌ SQL准备失败: \(String(cString: errMsg))")
            }
            return false
        }

        for (index, param) in params.enumerated() {
            bindParameter(stmt: stmt, index: Int32(index + 1), value: param)
        }

        let result = sqlite3_step(stmt) == SQLITE_DONE
        sqlite3_finalize(stmt)
        return result
    }

    private func bindParameter(stmt: OpaquePointer?, index: Int32, value: Any) {
        switch value {
        case let intValue as Int:
            sqlite3_bind_int(stmt, index, Int32(intValue))
        case let int32Value as Int32:
            sqlite3_bind_int(stmt, index, int32Value)
        case let int64Value as Int64:
            sqlite3_bind_int64(stmt, index, int64Value)
        case let doubleValue as Double:
            sqlite3_bind_double(stmt, index, doubleValue)
        case let stringValue as String:
            sqlite3_bind_text(stmt, index, (stringValue as NSString).utf8String, -1, nil)
        case is NSNull:
            sqlite3_bind_null(stmt, index)
        default:
            if let stringValue = "\(value)" as NSString? {
                sqlite3_bind_text(stmt, index, stringValue.utf8String, -1, nil)
            }
        }
    }
}

// MARK: - SQL Helper Extensions
extension SafeSQLBuilder {
    func count(table: String, where condition: String = "", params: [Any] = []) -> Int {
        let sql = condition.isEmpty
            ? "SELECT COUNT(*) FROM \(table)"
            : "SELECT COUNT(*) FROM \(table) WHERE \(condition)"

        return querySingle(sql: sql, params: params) { stmt in
            Int(sqlite3_column_int(stmt, 0))
        } ?? 0
    }

    func exists(table: String, where condition: String, params: [Any]) -> Bool {
        let sql = "SELECT EXISTS(SELECT 1 FROM \(table) WHERE \(condition))"
        return querySingle(sql: sql, params: params) { stmt in
            sqlite3_column_int(stmt, 0) == 1
        } ?? false
    }
}
