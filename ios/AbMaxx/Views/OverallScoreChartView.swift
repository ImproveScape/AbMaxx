import SwiftUI

nonisolated enum ChartTimeRange: String, CaseIterable {
    case ninetyDays = "90D"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "ALL"
}

struct OverallScoreChartView: View {
    let data: [(date: Date, score: Int)]
    @Binding var selectedPoint: Int?
    var expanded: Bool = false

    @State private var timeRange: ChartTimeRange = .all

    private var filteredData: [(date: Date, score: Int)] {
        guard !data.isEmpty else { return [] }
        let now = Date()
        let cutoff: Date
        switch timeRange {
        case .ninetyDays:
            cutoff = Calendar.current.date(byAdding: .day, value: -90, to: now) ?? now
        case .sixMonths:
            cutoff = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        case .oneYear:
            cutoff = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return data
        }
        let filtered = data.filter { $0.date >= cutoff }
        return filtered.isEmpty ? data : filtered
    }

    private var scores: [Int] { filteredData.map(\.score) }

    private var yMin: Int {
        let minScore = scores.min() ?? 30
        return max(((minScore - 5) / 5) * 5, 0)
    }

    private var yMax: Int {
        let maxScore = scores.max() ?? 100
        return min(((maxScore + 5) / 5) * 5 + 5, 100)
    }

    private var yRange: Int { max(yMax - yMin, 10) }

    private var ySteps: [Int] {
        let desiredSteps = expanded ? 5 : 4
        let rawInterval = yRange / desiredSteps
        let interval = max(((rawInterval + 4) / 5) * 5, 5)
        var steps: [Int] = []
        var val = yMin
        while val <= yMax {
            steps.append(val)
            val += interval
        }
        return steps
    }

    private var xLabels: [String] {
        guard filteredData.count > 1 else {
            if filteredData.first != nil {
                return ["Wk 1"]
            }
            return []
        }
        guard let firstDate = filteredData.first?.date else { return [] }
        let calendar = Calendar.current
        var labels: [String] = []
        var lastWeek = -1
        for item in filteredData {
            let days = calendar.dateComponents([.day], from: firstDate, to: item.date).day ?? 0
            let week = (days / 7) + 1
            if week != lastWeek {
                labels.append("Wk \(week)")
                lastWeek = week
            } else {
                labels.append("")
            }
        }
        return labels
    }

    private let yAxisWidth: CGFloat = 36
    private let xAxisHeight: CGFloat = 28
    private let chartPaddingTop: CGFloat = 24
    private let chartPaddingBottom: CGFloat = 4

    var body: some View {
        VStack(spacing: 0) {
            chartArea
            timeRangeSelector
        }
    }

    private var chartArea: some View {
        GeometryReader { geo in
            let chartLeft = yAxisWidth + 8
            let chartRight: CGFloat = 16
            let chartWidth = geo.size.width - chartLeft - chartRight
            let chartHeight = geo.size.height - chartPaddingTop - chartPaddingBottom - xAxisHeight

            ZStack(alignment: .topLeading) {
                gridLines(geo: geo, chartLeft: chartLeft, chartWidth: chartWidth, chartHeight: chartHeight)

                if filteredData.count > 1 {
                    let points = chartPoints(chartLeft: chartLeft, chartWidth: chartWidth, chartHeight: chartHeight)

                    gradientFill(points: points, chartLeft: chartLeft, chartHeight: chartHeight)
                    curveLine(points: points)
                    selectedIndicator(points: points, chartHeight: chartHeight)
                    dotPoints(points: points)
                    tooltipBubble(points: points)

                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x
                                    let closest = closestPointIndex(x: x, chartLeft: chartLeft, chartWidth: chartWidth)
                                    if selectedPoint != closest {
                                        selectedPoint = closest
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        selectedPoint = nil
                                    }
                                }
                        )
                } else if filteredData.count == 1 {
                    singlePoint(chartLeft: chartLeft, chartWidth: chartWidth, chartHeight: chartHeight)
                }

                xAxisLabels(chartLeft: chartLeft, chartWidth: chartWidth, chartHeight: chartHeight, totalHeight: geo.size.height)
            }
        }
    }

    private func gridLines(geo: GeometryProxy, chartLeft: CGFloat, chartWidth: CGFloat, chartHeight: CGFloat) -> some View {
        ForEach(ySteps, id: \.self) { step in
            let yFraction = CGFloat(step - yMin) / CGFloat(yRange)
            let yPos = chartPaddingTop + chartHeight * (1 - yFraction)

            HStack(spacing: 6) {
                Text("\(step)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.muted.opacity(0.6))
                    .frame(width: yAxisWidth, alignment: .trailing)

                Rectangle()
                    .fill(AppTheme.border.opacity(0.15))
                    .frame(height: 0.5)
            }
            .position(x: geo.size.width / 2, y: yPos)
        }
    }

    private func gradientFill(points: [CGPoint], chartLeft: CGFloat, chartHeight: CGFloat) -> some View {
        Path { path in
            drawCurvedPath(path: &path, points: points)
            if let last = points.last {
                path.addLine(to: CGPoint(x: last.x, y: chartPaddingTop + chartHeight))
            }
            path.addLine(to: CGPoint(x: points.first?.x ?? chartLeft, y: chartPaddingTop + chartHeight))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    AppTheme.primaryAccent.opacity(0.2),
                    AppTheme.primaryAccent.opacity(0.05),
                    AppTheme.primaryAccent.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func curveLine(points: [CGPoint]) -> some View {
        Path { path in
            drawCurvedPath(path: &path, points: points)
        }
        .stroke(
            AppTheme.primaryAccent,
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        )
    }

    @ViewBuilder
    private func selectedIndicator(points: [CGPoint], chartHeight: CGFloat) -> some View {
        if let idx = selectedPoint, idx < points.count {
            let point = points[idx]
            Rectangle()
                .fill(AppTheme.primaryAccent.opacity(0.3))
                .frame(width: 1)
                .frame(height: chartPaddingTop + chartHeight - point.y + chartPaddingBottom)
                .position(x: point.x, y: (point.y + chartPaddingTop + chartHeight + chartPaddingBottom) / 2)

            LinearGradient(
                colors: [AppTheme.primaryAccent.opacity(0.15), AppTheme.primaryAccent.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 1)
            .frame(height: chartPaddingTop + chartHeight - point.y + chartPaddingBottom)
            .position(x: point.x, y: (point.y + chartPaddingTop + chartHeight + chartPaddingBottom) / 2)
        }
    }

    private func dotPoints(points: [CGPoint]) -> some View {
        ForEach(Array(points.enumerated()), id: \.offset) { index, point in
            let isSelected = selectedPoint == index

            Circle()
                .fill(isSelected ? .white : AppTheme.primaryAccent)
                .frame(width: isSelected ? 10 : 0, height: isSelected ? 10 : 0)
                .overlay(
                    Circle()
                        .strokeBorder(AppTheme.primaryAccent, lineWidth: isSelected ? 3 : 0)
                        .frame(width: isSelected ? 16 : 0, height: isSelected ? 16 : 0)
                )
                .position(point)
                .animation(.spring(duration: 0.2), value: isSelected)
        }
    }

    @ViewBuilder
    private func tooltipBubble(points: [CGPoint]) -> some View {
        if let idx = selectedPoint, idx < filteredData.count, idx < points.count {
            let point = points[idx]
            let item = filteredData[idx]
            let dateFormatter: DateFormatter = {
                let f = DateFormatter()
                f.dateFormat = "MMM d, yyyy"
                return f
            }()

            VStack(spacing: 3) {
                Text("\(item.score)")
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                Text(dateFormatter.string(from: item.date))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.primaryAccent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.cardSurfaceElevated)
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
            )
            .position(x: point.x, y: point.y - 40)
            .transition(.opacity.combined(with: .scale(scale: 0.85)))
        }
    }

    private func singlePoint(chartLeft: CGFloat, chartWidth: CGFloat, chartHeight: CGFloat) -> some View {
        let x = chartLeft + chartWidth / 2
        let yFraction = CGFloat(filteredData[0].score - yMin) / CGFloat(yRange)
        let y = chartPaddingTop + chartHeight * (1 - yFraction)

        return ZStack {
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .strokeBorder(AppTheme.primaryAccent, lineWidth: 3)
                        .frame(width: 14, height: 14)
                )
                .position(x: x, y: y)

            VStack(spacing: 3) {
                Text("\(filteredData[0].score)")
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.cardSurfaceElevated)
            )
            .position(x: x, y: y - 32)
        }
    }

    private func xAxisLabels(chartLeft: CGFloat, chartWidth: CGFloat, chartHeight: CGFloat, totalHeight: CGFloat) -> some View {
        let labels = xLabels
        let uniqueLabels: [(index: Int, label: String)] = {
            var result: [(Int, String)] = []
            for (i, lbl) in labels.enumerated() {
                if !lbl.isEmpty {
                    result.append((i, lbl))
                }
            }
            return result
        }()

        return ForEach(uniqueLabels, id: \.index) { item in
            let x: CGFloat = {
                if filteredData.count <= 1 {
                    return chartLeft + chartWidth / 2
                }
                return chartLeft + chartWidth * CGFloat(item.index) / CGFloat(max(filteredData.count - 1, 1))
            }()

            Text(item.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.muted.opacity(0.7))
                .position(x: x, y: totalHeight - xAxisHeight / 2)
        }
    }

    private var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(ChartTimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        timeRange = range
                        selectedPoint = nil
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 13, weight: timeRange == range ? .bold : .medium))
                        .foregroundStyle(timeRange == range ? .white : AppTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if timeRange == range {
                                    Capsule()
                                        .fill(AppTheme.primaryAccent.opacity(0.2))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(AppTheme.primaryAccent.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        )
                }
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(AppTheme.cardSurfaceElevated)
                .overlay(
                    Capsule()
                        .strokeBorder(AppTheme.border.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    private func chartPoints(chartLeft: CGFloat, chartWidth: CGFloat, chartHeight: CGFloat) -> [CGPoint] {
        guard filteredData.count > 1 else { return [] }
        return filteredData.enumerated().map { index, item in
            let x = chartLeft + chartWidth * CGFloat(index) / CGFloat(filteredData.count - 1)
            let yFraction = CGFloat(item.score - yMin) / CGFloat(yRange)
            let y = chartPaddingTop + chartHeight * (1 - yFraction)
            return CGPoint(x: x, y: y)
        }
    }

    private func drawCurvedPath(path: inout Path, points: [CGPoint]) {
        guard points.count >= 2 else { return }
        path.move(to: points[0])

        if points.count == 2 {
            path.addLine(to: points[1])
            return
        }

        for i in 0..<(points.count - 1) {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : points[i + 1]

            let tension: CGFloat = 0.3

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension,
                y: p1.y + (p2.y - p0.y) * tension
            )
            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension,
                y: p2.y - (p3.y - p1.y) * tension
            )

            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
    }

    private func closestPointIndex(x: CGFloat, chartLeft: CGFloat, chartWidth: CGFloat) -> Int {
        guard filteredData.count > 1 else { return 0 }
        let fraction = (x - chartLeft) / chartWidth
        let index = Int(round(fraction * CGFloat(filteredData.count - 1)))
        return max(0, min(index, filteredData.count - 1))
    }
}
