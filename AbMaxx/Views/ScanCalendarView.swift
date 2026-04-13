import SwiftUI

struct ScanCalendarView: View {
    @Bindable var vm: AppViewModel
    @State private var isMonthly: Bool = false
    @State private var weekOffset: Int = 0
    @State private var monthOffset: Int = 0

    private let calendar = Calendar.current
    private let daySymbols = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    var body: some View {
        VStack(spacing: 16) {
            headerRow
            dayHeaders

            if isMonthly {
                monthlyGrid
            } else {
                weeklyStrip
            }
        }
        .padding(18)
        .background(AppTheme.cardSurface)
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .strokeBorder(AppTheme.border.opacity(0.6), lineWidth: 1)
        )
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Scan Calendar")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Text(displayedPeriodLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }

            Spacer()

            HStack(spacing: 4) {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        isMonthly = false
                        weekOffset = 0
                        monthOffset = 0
                    }
                } label: {
                    Text("Week")
                        .font(.caption.bold())
                        .foregroundStyle(!isMonthly ? .white : AppTheme.muted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(!isMonthly ? AppTheme.primaryAccent : Color.clear)
                        .clipShape(.capsule)
                }

                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        isMonthly = true
                        weekOffset = 0
                        monthOffset = 0
                    }
                } label: {
                    Text("Month")
                        .font(.caption.bold())
                        .foregroundStyle(isMonthly ? .white : AppTheme.muted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isMonthly ? AppTheme.primaryAccent : Color.clear)
                        .clipShape(.capsule)
                }
            }
            .padding(3)
            .background(AppTheme.cardSurfaceElevated)
            .clipShape(.capsule)
        }
    }

    private var displayedPeriodLabel: String {
        let formatter = DateFormatter()
        if isMonthly {
            let date = calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        } else {
            let weekDays = currentWeekDays
            guard let first = weekDays.first, let last = weekDays.last else { return "" }
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: first)
            let end = formatter.string(from: last)
            return "\(start) - \(end)"
        }
    }

    private var dayHeaders: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 0) {
            ForEach(daySymbols, id: \.self) { day in
                Text(day)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var currentWeekDays: [Date] {
        let today = Date()
        let shifted = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today) ?? today
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: shifted) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }

    private var weeklyStrip: some View {
        VStack(spacing: 0) {
            TabView(selection: $weekOffset) {
                ForEach(-12...0, id: \.self) { offset in
                    weekRow(for: offset)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 70)
        }
    }

    private func weekRow(for offset: Int) -> some View {
        let today = Date()
        let shifted = calendar.date(byAdding: .weekOfYear, value: offset, to: today) ?? today
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: shifted)?.start ?? today
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 0) {
            ForEach(days, id: \.timeIntervalSince1970) { date in
                dayCell(for: date)
            }
        }
    }

    private var monthlyGrid: some View {
        VStack(spacing: 0) {
            TabView(selection: $monthOffset) {
                ForEach(-6...0, id: \.self) { offset in
                    monthGrid(for: offset)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: monthGridHeight)
        }
    }

    private var monthGridHeight: CGFloat {
        let refDate = calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        let weeks = weeksInMonth(for: refDate)
        return CGFloat(weeks) * 70
    }

    private func weeksInMonth(for date: Date) -> Int {
        guard let range = calendar.range(of: .weekOfMonth, in: .month, for: date) else { return 5 }
        return range.count
    }

    private func monthGrid(for offset: Int) -> some View {
        let refDate = calendar.date(byAdding: .month, value: offset, to: Date()) ?? Date()
        let days = daysInMonthGrid(for: refDate)

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
            ForEach(days, id: \.timeIntervalSince1970) { date in
                if calendar.isDate(date, equalTo: refDate, toGranularity: .month) {
                    dayCell(for: date)
                } else {
                    Color.clear.frame(height: 56)
                }
            }
        }
    }

    private func daysInMonthGrid(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        let firstDay = monthInterval.start
        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingEmpty = weekday - calendar.firstWeekday
        let startDate = calendar.date(byAdding: .day, value: -leadingEmpty, to: firstDay) ?? firstDay

        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        let totalCells = leadingEmpty + daysInMonth
        let rows = Int(ceil(Double(totalCells) / 7.0))
        let totalSlots = rows * 7

        return (0..<totalSlots).compactMap { calendar.date(byAdding: .day, value: $0, to: startDate) }
    }

    private func scanForDate(_ date: Date) -> ScanResult? {
        vm.scanResults.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func dayCell(for date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let scan = scanForDate(date)
        let hasScan = scan != nil
        let isFuture = date > Date()

        return VStack(spacing: 3) {
            Text("\(day)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isToday ? AppTheme.primaryAccent : (isFuture ? AppTheme.muted.opacity(0.4) : AppTheme.muted))

            ZStack {
                if hasScan, let uiImage = scan?.loadImage() {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 42, height: 42)
                        .overlay {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        }
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isToday ? .white : AppTheme.primaryAccent,
                                    lineWidth: isToday ? 2 : 1.5
                                )
                        )
                } else if hasScan {
                    Circle()
                        .fill(AppTheme.accentGradient)
                        .frame(width: 42, height: 42)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isToday ? .white : Color.clear,
                                    lineWidth: 2
                                )
                        )
                } else {
                    Circle()
                        .fill(isFuture ? Color.clear : AppTheme.cardSurfaceElevated)
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isToday ? AppTheme.primaryAccent.opacity(0.6) : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                }
            }
        }
        .frame(height: 56)
    }
}
