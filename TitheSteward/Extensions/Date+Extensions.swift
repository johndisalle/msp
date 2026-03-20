import Foundation

extension Date {
    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    var endOfMonth: Date {
        guard let interval = Calendar.current.dateInterval(of: .month, for: self) else { return self }
        return Calendar.current.date(byAdding: .second, value: -1, to: interval.end) ?? self
    }

    var startOfYear: Date {
        Calendar.current.dateInterval(of: .year, for: self)?.start ?? self
    }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }

    var daysRemainingInMonth: Int {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: self) else { return 0 }
        let currentDay = calendar.component(.day, from: self)
        return range.count - currentDay
    }

    func isSameMonth(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .month)
    }
}
