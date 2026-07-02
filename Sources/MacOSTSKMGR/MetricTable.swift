import SwiftUI

/// A column descriptor for `MetricTable`. Each page supplies its own columns; the
/// table owns the scaffolding (width scaling, sortable headers, row striping,
/// selection highlight, cell separators) that used to be copy-pasted per page.
struct MetricColumn<Row: Identifiable>: Identifiable {
    let id: String
    let title: String
    let baseWidth: CGFloat
    var headerAlignment: Alignment = .leading
    var cellAlignment: Alignment = .leading
    var sortable: Bool = true
    /// Direction to use when this column first becomes the active sort column.
    var defaultAscending: Bool = true
    /// Ascending-order comparator; only consulted when `sortable`.
    var comparator: (Row, Row) -> Bool = { _, _ in false }
    /// Fully text/color-styled cell content. Width, padding and the trailing
    /// separator are applied uniformly by the table, not here.
    let cell: @MainActor (Row) -> AnyView
}

extension MetricColumn {
    /// Convenience for a plain text column.
    @MainActor
    static func text(
        id: String,
        title: String,
        baseWidth: CGFloat,
        headerAlignment: Alignment = .leading,
        cellAlignment: Alignment = .leading,
        sortable: Bool = true,
        defaultAscending: Bool = true,
        comparator: @escaping (Row, Row) -> Bool = { _, _ in false },
        value: @escaping (Row) -> String
    ) -> MetricColumn<Row> {
        MetricColumn(
            id: id,
            title: title,
            baseWidth: baseWidth,
            headerAlignment: headerAlignment,
            cellAlignment: cellAlignment,
            sortable: sortable,
            defaultAscending: defaultAscending,
            comparator: comparator,
            cell: { AnyView(MetricTableText(value($0))) }
        )
    }
}

/// Standard text-cell styling shared by every table.
struct MetricTableText: View {
    @Environment(\.colorScheme) private var colorScheme
    private let value: String
    init(_ value: String) { self.value = value }
    var body: some View {
        Text(value)
            .font(.system(size: 13))
            .lineLimit(1)
            .foregroundStyle(AppTheme.primaryText(colorScheme))
    }
}

/// Standard icon + name cell shared by every table.
struct MetricTableNameCell: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: NSImage?
    let name: String

    var body: some View {
        HStack(spacing: 8) {
            ProcessIconView(icon: icon)
            Text(name)
                .font(.system(size: 13))
                .lineLimit(1)
                .foregroundStyle(AppTheme.primaryText(colorScheme))
            Spacer(minLength: 0)
        }
    }
}

/// A generic, sortable, single-section metric table. Used by the Details,
/// Services, Startup and App-history pages. (Processes and Users keep bespoke
/// layouts because they add collapsible sections, summary rows and live
/// metric-value headers.)
struct MetricTable<Row: Identifiable & Equatable, Menu: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    private let rows: [Row]
    private let columns: [MetricColumn<Row>]
    private let insetLeading: CGFloat
    private let insetTrailing: CGFloat
    private let scrollBarReserve: CGFloat
    private let minUsableWidth: CGFloat
    private let rowHeight: CGFloat
    private let headerHeight: CGFloat
    private let topPadding: CGFloat
    private let showsInactiveSortArrow: Bool
    private let isSelected: (Row) -> Bool
    private let onSelect: (Row) -> Void
    private let rowMenu: (Row) -> Menu

    @State private var sortColumnID: String
    @State private var ascending: Bool
    // Sort output is cached and recomputed only when the rows or sort state
    // change, not on every body evaluation.
    @State private var displayedRows: [Row] = []

    init(
        rows: [Row],
        columns: [MetricColumn<Row>],
        initialSortColumnID: String,
        initialAscending: Bool,
        insetLeading: CGFloat = 8,
        insetTrailing: CGFloat = 14,
        scrollBarReserve: CGFloat = 18,
        minUsableWidth: CGFloat = 600,
        rowHeight: CGFloat = 34,
        headerHeight: CGFloat = 44,
        topPadding: CGFloat = 18,
        showsInactiveSortArrow: Bool = false,
        isSelected: @escaping (Row) -> Bool,
        onSelect: @escaping (Row) -> Void,
        @ViewBuilder rowMenu: @escaping (Row) -> Menu
    ) {
        self.rows = rows
        self.columns = columns
        self.insetLeading = insetLeading
        self.insetTrailing = insetTrailing
        self.scrollBarReserve = scrollBarReserve
        self.minUsableWidth = minUsableWidth
        self.rowHeight = rowHeight
        self.headerHeight = headerHeight
        self.topPadding = topPadding
        self.showsInactiveSortArrow = showsInactiveSortArrow
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.rowMenu = rowMenu
        _sortColumnID = State(initialValue: initialSortColumnID)
        _ascending = State(initialValue: initialAscending)
    }

    private var totalBaseWidth: CGFloat {
        columns.reduce(0) { $0 + $1.baseWidth }
    }

    private func resortRows() {
        guard let column = columns.first(where: { $0.id == sortColumnID }), column.sortable else {
            displayedRows = rows
            return
        }
        displayedRows = rows.sorted { lhs, rhs in
            let result = column.comparator(lhs, rhs)
            return ascending ? result : !result
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let usable = max(minUsableWidth, proxy.size.width - insetLeading - insetTrailing - scrollBarReserve)
            let scale = usable / max(totalBaseWidth, 1)
            let total = totalBaseWidth * scale

            VStack(alignment: .leading, spacing: 0) {
                headerRow(scale: scale, total: total)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(displayedRows.enumerated()), id: \.element.id) { index, row in
                            rowView(row, index: index, scale: scale)
                        }
                    }
                    .frame(width: total, alignment: .leading)
                    .padding(.bottom, 16)
                }
            }
            .padding(.top, topPadding)
            .padding(.leading, insetLeading)
            .padding(.trailing, insetTrailing)
        }
        .onAppear {
            resortRows()
        }
        .onChange(of: rows) { _, _ in
            resortRows()
        }
    }

    private func headerRow(scale: CGFloat, total: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(columns) { column in
                headerCell(column, width: column.baseWidth * scale)
            }
        }
        .frame(width: total, height: headerHeight, alignment: .leading)
        .background(AppTheme.tableHeader(colorScheme))
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppTheme.strongSeparator(colorScheme)).frame(height: 1)
        }
    }

    private func headerCell(_ column: MetricColumn<Row>, width: CGFloat) -> some View {
        Button {
            guard column.sortable else { return }
            if sortColumnID == column.id {
                ascending.toggle()
            } else {
                sortColumnID = column.id
                ascending = column.defaultAscending
            }
            resortRows()
        } label: {
            HStack(spacing: 4) {
                Text(column.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                if sortColumnID == column.id {
                    Image(systemName: ascending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                } else if showsInactiveSortArrow && column.sortable {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary.opacity(0.45))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(width: width, height: headerHeight, alignment: column.headerAlignment)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            Rectangle().fill(AppTheme.separator(colorScheme)).frame(width: 1)
        }
    }

    private func rowView(_ row: Row, index: Int, scale: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(columns) { column in
                column.cell(row)
                    .padding(.horizontal, 10)
                    .frame(width: column.baseWidth * scale, height: rowHeight, alignment: column.cellAlignment)
                    .overlay(alignment: .trailing) {
                        Rectangle().fill(AppTheme.separator(colorScheme)).frame(width: 1)
                    }
            }
        }
        .frame(height: rowHeight)
        .background(rowBackground(row, index: index))
        .contentShape(Rectangle())
        .onTapGesture { onSelect(row) }
        .contextMenu { rowMenu(row) }
    }

    private func rowBackground(_ row: Row, index: Int) -> Color {
        if isSelected(row) {
            return AppTheme.selectedRow(colorScheme)
        }
        return index.isMultiple(of: 2) ? AppTheme.rowEven(colorScheme) : AppTheme.rowOdd(colorScheme)
    }
}
