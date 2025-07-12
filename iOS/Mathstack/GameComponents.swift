import SwiftUI

// MARK: - Collections View
struct CollectionsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(CardColor.allCases, id: \.self) { color in
                    CollectionStackView(
                        color: color,
                        numbers: gameState.collections[color] ?? [],
                        maxNumber: gameState.difficulty.maxNumber,
                        isSelected: gameState.selectedCollection?.color == color,
                        onTap: { 
                            // If there's a selected temp slot, try to move it to collection
                            if let selectedSlot = gameState.selectedTempSlot {
                                let _ = gameState.moveSlotStackToCollection(slotIndex: selectedSlot, color: color)
                            } else {
                                let collection = gameState.collections[color] ?? []
                                if !collection.isEmpty {
                                    // If collection has cards, select whole collection for movement
                                    gameState.selectCollection(color: color, index: -1)
                                } else {
                                    // Otherwise, just select this collection
                                    gameState.selectCollection(color: color, index: -1)
                                }
                            }
                        },
                        onNumberTap: { index in
                            // Add bounds checking before calling selectCollection
                            let collection = gameState.collections[color] ?? []
                            if index >= 0 && index < collection.count {
                                gameState.selectCollection(color: color, index: index)
                            }
                        },
                        gameState: gameState
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.12, blue: 0.22),
                                Color(red: 0.05, green: 0.08, blue: 0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
    }
}

struct CollectionStackView: View {
    let color: CardColor
    let numbers: [Int]
    let maxNumber: Int
    let isSelected: Bool
    let onTap: () -> Void
    let onNumberTap: (Int) -> Void
    @ObservedObject var gameState: GameState
    
    @State private var isDropTarget = false
    
    private var isCompleted: Bool {
        numbers.count == maxNumber
    }
    
    private var isHighlighted: Bool {
        gameState.highlightedDropZone == "collection_\(color.rawValue)"
    }
    
    private var canAcceptDrop: Bool? {
        guard let dragState = gameState.currentDragState else { return nil }
        let dragData = DragData(sourceType: dragState.sourceType, card: dragState.card, stackCards: dragState.stackCards)
        return canAcceptDrop(dragData: dragData)
    }
    
    var body: some View {
        // Pre-calculate complex expressions to avoid compiler timeout
        let strokeColor: Color = {
            if isHighlighted {
                return canAcceptDrop == true ? Color.green.opacity(0.8) : Color.red.opacity(0.8)
            } else if isCompleted {
                return color.uiColor
            } else if isSelected {
                return Color.white.opacity(0.8)
            } else {
                return color.uiColor.opacity(0.6)
            }
        }()
        
        let shadowColor: Color = {
            if isHighlighted {
                return canAcceptDrop == true ? Color.green.opacity(0.4) : Color.red.opacity(0.4)
            } else if isCompleted {
                return color.uiColor.opacity(0.5)
            } else if isSelected {
                return Color.white.opacity(0.3)
            } else {
                return Color.clear
            }
        }()
        
        let shadowRadius: CGFloat = isHighlighted ? 12 : (isCompleted ? 8 : (isSelected ? 6 : 0))
        let strokeWidth: CGFloat = isHighlighted ? 3 : 2
        
        return VStack(spacing: 2) {
            ZStack {
                // Main collection box with color-specific styling
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        strokeColor,
                        style: StrokeStyle(lineWidth: strokeWidth, dash: isCompleted ? [] : [5])
                    )
                    .frame(width: 60.0, height: 80.0)
                    .background(
                        Group {
                            if isHighlighted {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(canAcceptDrop == true ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            } else if isCompleted {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(
                                        colors: [color.uiColor.opacity(0.3), color.uiColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            } else if isSelected {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(
                                        colors: [color.uiColor.opacity(0.15), color.uiColor.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            }
                        }
                    )
                    .shadow(
                        color: shadowColor,
                        radius: shadowRadius
                    )
                
                // Collection content or color indicator
                if !numbers.isEmpty {
                    collectionContent
                } else {
                    // Empty collection - show helpful hint
                    VStack(spacing: 6) {
                        // Color name
                        Text(color.rawValue.capitalized)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(color.uiColor)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        // Hint about what to collect
                        VStack(spacing: 2) {
                            Text("1→\(maxNumber)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(color.uiColor.opacity(0.8))
                            
                            Text("or")
                                .font(.system(size: 8, weight: .light))
                                .foregroundColor(.gray)
                            
                            Text("\(maxNumber)→1")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(color.uiColor.opacity(0.8))
                        }
                    }
                }
            }
            
            // Progress indicator only
            if !isCompleted {
                Text("\(numbers.count)/\(maxNumber)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color.uiColor.opacity(0.8))
                    .padding(.top, 2)
            } else {
                // Completion indicator
                Text("✓")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color.uiColor)
                    .padding(.top, 2)
            }
        }
        .onTapGesture {
            // Always allow tapping on collection area
            onTap()
        }
        .overlay(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    // Register this drop zone
                    let frame = geometry.frame(in: .global)
                    gameState.registerDropZone(
                        id: "collection_\(color.rawValue)",
                        frame: frame,
                        canAccept: { dragData in canAcceptDrop(dragData: dragData) },
                        handler: { dragData in handleDrop(dragData: dragData) }
                    )
                }
            }
        )
    }
    
    @ViewBuilder
    private var collectionContent: some View {
        VStack(spacing: 2) {
            if numbers.count == 1 {
                // Single card
                DraggableCollectionCardView(
                    number: numbers[0],
                    color: color,
                    size: .normal,
                    dragData: DragData(
                        sourceType: .collection(color: color, index: -1),
                        card: Card(number: numbers[0], color: color),
                        stackCards: numbers.map { Card(number: $0, color: color) }
                    ),
                    onTap: { onNumberTap(0) },
                    gameState: gameState
                )
            } else if numbers.count == 2 {
                // Two cards stacked
                ForEach(numbers.indices, id: \.self) { index in
                    if index == numbers.count - 1 {
                        // Only last card is draggable
                        DraggableCollectionCardView(
                            number: numbers[index],
                            color: color,
                            size: .medium,
                            dragData: DragData(
                                sourceType: .collection(color: color, index: -1),
                                card: Card(number: numbers[index], color: color),
                                stackCards: numbers.map { Card(number: $0, color: color) }
                            ),
                            onTap: { onNumberTap(index) },
                            gameState: gameState
                        )
                    } else {
                        CollectionCardView(
                            number: numbers[index],
                            color: color,
                            size: .medium,
                            onTap: { onNumberTap(index) }
                        )
                    }
                }
            } else if numbers.count >= 3 {
                // 3+ cards: show first, visual stack, last (only last is draggable)
                if let firstCard = numbers.first,
                   let lastCard = numbers.last {
                    let middleCount = numbers.count - 2
                    
                    // First card (not draggable)
                    CollectionCardView(
                        number: firstCard,
                        color: color,
                        size: .medium,
                        onTap: { onNumberTap(0) }
                    )
                    
                    // Visual stack indicator
                    StackIndicatorView(
                        cardCount: middleCount,
                        color: color,
                        onTap: { 
                            // Tap middle of stack - select middle card (with bounds check)
                            let middleIndex = min(numbers.count / 2, numbers.count - 1)
                            onNumberTap(middleIndex)
                        }
                    )
                    
                    // Last card (draggable)
                    DraggableCollectionCardView(
                        number: lastCard,
                        color: color,
                        size: .medium,
                        dragData: DragData(
                            sourceType: .collection(color: color, index: -1),
                            card: Card(number: lastCard, color: color),
                            stackCards: numbers.map { Card(number: $0, color: color) }
                        ),
                        onTap: { onNumberTap(numbers.count - 1) },
                        gameState: gameState
                    )
                }
            }
        }
        .padding(.horizontal, 6)
    }
    
    private func canAcceptDrop(dragData: DragData) -> Bool {
        guard !isCompleted else { 
            return false 
        }
        
        // Check if all cards in the stack are the right color
        let allSameColor = dragData.stackCards.allSatisfy { $0.color == color }
        guard allSameColor else { return false }
        
        // For stacks, check if the sequence can be added to collection
        return gameState.canAddSlotStackToCollection(dragData.stackCards, color: color)
    }
    
    private func handleDrop(dragData: DragData) -> Bool {
        guard canAcceptDrop(dragData: dragData) else { return false }
        
        // Move the stack to this collection
        switch dragData.sourceType {
        case .gridCell(let sourceRow, let sourceCol):
            return gameState.moveCardFromGridToCollection(from: (sourceRow, sourceCol), color: color)
        case .tempSlot(let slotIndex):
            return gameState.moveSlotStackToCollection(slotIndex: slotIndex, color: color)
        case .collection:
            return false // Can't move between collections
        }
    }
}

struct StackIndicatorView: View {
    let cardCount: Int
    let color: CardColor
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0.5) {
                // Visual representation of stacked cards - show up to 5 lines
                let linesToShow = min(cardCount, 5)
                
                ForEach(0..<linesToShow, id: \.self) { index in
                    HStack(spacing: 0) {
                        // Left edge
                        Rectangle()
                            .fill(color.uiColor.opacity(0.8))
                            .frame(width: 1, height: 3)
                        
                        // Card body
                        Rectangle()
                            .fill(color.uiColor.opacity(0.9 - Double(index) * 0.1))
                            .frame(width: 28, height: 3)
                        
                        // Right edge
                        Rectangle()
                            .fill(color.uiColor.opacity(0.6))
                            .frame(width: 1, height: 3)
                    }
                    .cornerRadius(0.5)
                    .offset(x: CGFloat(index) * 0.5, y: CGFloat(index) * 0.2)
                }
            }
            .frame(height: 12)
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CollectionCardView: View {
    let number: Int
    let color: CardColor
    let size: CardSize
    let onTap: () -> Void
    
    enum CardSize {
        case small, medium, normal
        
        var dimensions: (width: CGFloat, height: CGFloat) {
            switch self {
            case .small: return (32, 14)
            case .medium: return (36, 16)
            case .normal: return (40, 18)
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 9
            case .medium: return 10
            case .normal: return 12
            }
        }
    }
    
    var body: some View {
        let (width, height) = size.dimensions
        
        Button(action: onTap) {
            Text("\(number)")
                .font(.system(size: size.fontSize, weight: .bold))
                .foregroundColor(.white)
                .frame(width: width, height: height)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.uiColor)
                        .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Game Grid View
struct GameGridView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        let (rows, cols) = gameState.difficulty.gridSize
        
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: cols),
            spacing: 4
        ) {
            ForEach(0..<(rows * cols), id: \.self) { index in
                let row = index / cols
                let col = index % cols
                
                GridCellView(
                    cell: gameState.grid[row][col],
                    row: row,
                    col: col,
                    isSelected: gameState.selectedGridPosition?.row == row && gameState.selectedGridPosition?.col == col,
                    gameState: gameState
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.05, green: 0.08, blue: 0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.3, green: 0.8, blue: 0.76).opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct GridCellView: View {
    let cell: GridCell
    let row: Int
    let col: Int
    let isSelected: Bool
    @ObservedObject var gameState: GameState
    
    @State private var isDropTarget = false
    
    private var isHighlighted: Bool {
        gameState.highlightedDropZone == "gridCell_\(row)_\(col)"
    }
    
    private var canAcceptDrop: Bool? {
        guard let dragState = gameState.currentDragState else { return nil }
        let dragData = DragData(sourceType: dragState.sourceType, card: dragState.card, stackCards: dragState.stackCards)
        return canAcceptDrop(dragData: dragData)
    }
    
    var body: some View {
        let strokeColor: Color = {
            if isHighlighted {
                return canAcceptDrop == true ? Color.green.opacity(0.8) : Color.red.opacity(0.8)
            } else if cell.isEmpty {
                return Color.white.opacity(0.3)
            } else if isSelected {
                return Color(red: 1.0, green: 0.85, blue: 0.59)
            } else {
                return Color.clear
            }
        }()
        
        let fillColor: Color = {
            if isHighlighted {
                return canAcceptDrop == true ? Color.green.opacity(0.15) : Color.red.opacity(0.15)
            } else {
                return Color.clear
            }
        }()
        
        let shadowColor: Color = {
            if isHighlighted {
                return canAcceptDrop == true ? Color.green.opacity(0.4) : Color.red.opacity(0.4)
            } else if isSelected {
                return Color(red: 1.0, green: 0.85, blue: 0.59).opacity(0.6)
            } else {
                return Color.clear
            }
        }()
        
        let shadowRadius: CGFloat = isHighlighted ? 12 : (isSelected ? 10 : 0)
        let strokeWidth: CGFloat = isHighlighted ? 3 : 2
        
        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(cell.isEmpty ? Color.white.opacity(0.1) : Color.clear)
                .frame(height: 55.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            strokeColor,
                            style: StrokeStyle(lineWidth: strokeWidth, dash: cell.isEmpty ? [5] : [])
                        )
                )
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(fillColor)
                )
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius
                )
            
            if let topCard = cell.topCard {
                DraggableCardView(
                    card: topCard,
                    isUnlocked: cell.isUnlocked,
                    stackCount: cell.stack.count,
                    dragData: DragData(
                        sourceType: .gridCell(row: row, col: col),
                        card: topCard,
                        stackCards: [topCard] // Grid cells only move single cards
                    ),
                    gameState: gameState,
                    onTap: { handleCellTap() }
                )
                .frame(height: 50.0)
                .opacity(cell.isUnlocked ? 1.0 : 0.6)
            }
        }
        .onTapGesture {
            handleCellTap()
        }
        .overlay(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    // Register this drop zone
                    let frame = geometry.frame(in: .global)
                    gameState.registerDropZone(
                        id: "gridCell_\(row)_\(col)",
                        frame: frame,
                        canAccept: { dragData in canAcceptDrop(dragData: dragData) },
                        handler: { dragData in handleDrop(dragData: dragData) }
                    )
                }
            }
        )
    }
    
    private func handleCellTap() {
        if cell.isEmpty {
            // Handle tap on empty cell - try to move selected card here
            if gameState.selectedGridPosition != nil {
                gameState.moveToEmptyCell(targetRow: row, targetCol: col)
            } else if gameState.selectedTempSlot != nil {
                gameState.moveFromTempToEmptyCell(targetRow: row, targetCol: col)
            } else if gameState.selectedCollection != nil {
                gameState.moveFromCollectionToEmptyCell(targetRow: row, targetCol: col)
            }
        } else {
            // Handle tap on non-empty cell
            guard cell.isUnlocked else { return }
            
            if let topCard = cell.topCard,
               gameState.canAddToCollection(topCard.number, color: topCard.color) {
                gameState.collectCard(from: row, col: col)
            } else {
                gameState.selectGridCell(row: row, col: col)
            }
        }
    }
    
    private func canAcceptDrop(dragData: DragData) -> Bool {
        // Check current state directly from gameState instead of local cell variable
        let currentCell = gameState.grid[row][col]
        let isEmpty = currentCell.isEmpty
        
        switch dragData.sourceType {
        case .tempSlot(let slotIndex):
            // For temp slots, allow dropping entire stack
            let tempSlotCards = gameState.tempSlots[slotIndex]
            return isEmpty && !tempSlotCards.isEmpty
            
        case .collection(let color, let index):
            // For collections, allow dropping entire collection or last card
            let collection = gameState.collections[color] ?? []
            if index == -1 {
                // Entire collection
                return isEmpty && !collection.isEmpty
            } else {
                // Single card
                let isLastCard = !collection.isEmpty && index == collection.count - 1
                return isEmpty && isLastCard
            }
            
        case .gridCell(let sourceRow, let sourceCol):
            // For grid cells, check if source is unlocked
            let sourceCell = gameState.grid[sourceRow][sourceCol]
            let isSourceUnlocked = sourceCell.isUnlocked
            let isSourceNotEmpty = !sourceCell.isEmpty
            return isEmpty && isSourceUnlocked && isSourceNotEmpty
        }
    }
    
    private func handleDrop(dragData: DragData) -> Bool {
        guard canAcceptDrop(dragData: dragData) else { return false }
        
        switch dragData.sourceType {
        case .gridCell(let sourceRow, let sourceCol):
            return gameState.moveCardFromGrid(from: (sourceRow, sourceCol), to: (row, col))
        case .tempSlot(let slotIndex):
            return gameState.moveCardFromTempSlot(slotIndex: slotIndex, to: (row, col))
        case .collection(let color, let index):
            return gameState.moveCardFromCollection(color: color, index: index, to: (row, col))
        }
    }
}

// MARK: - Temp Slots View
struct TempSlotsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 8) {
            // Title for temp slots
            Text("Temporary Stacks")
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(1)
            
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    TempSlotView(
                        cards: gameState.tempSlots[index],
                        slotIndex: index,
                        isSelected: gameState.selectedTempSlot == index,
                        gameState: gameState
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.05, green: 0.08, blue: 0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
    }
}

struct TempSlotView: View {
    let cards: [Card]
    let slotIndex: Int
    let isSelected: Bool
    @ObservedObject var gameState: GameState
    
    @State private var isDropTarget = false
    
    private var isHighlighted: Bool {
        gameState.highlightedDropZone == "tempSlot_\(slotIndex)"
    }
    
    private var canAcceptDrop: Bool? {
        guard let dragState = gameState.currentDragState else { return nil }
        let dragData = DragData(sourceType: dragState.sourceType, card: dragState.card, stackCards: dragState.stackCards)
        return canAcceptDrop(dragData: dragData)
    }
    
    var body: some View {
        // Determine the slot color based on cards
        let slotColor: CardColor? = cards.isEmpty ? nil : cards.first?.color
        
        let strokeColor: Color = {
            if isHighlighted {
                return canAcceptDrop == true ? Color.green.opacity(0.8) : Color.red.opacity(0.8)
            } else if isSelected {
                return Color(red: 1.0, green: 0.85, blue: 0.59)
            } else if let color = slotColor {
                return color.uiColor.opacity(0.8)
            } else {
                return Color.gray.opacity(0.6)
            }
        }()
        
        let fillColor: Color = {
            if isHighlighted {
                return canAcceptDrop == true ? Color.green.opacity(0.15) : Color.red.opacity(0.15)
            } else if isSelected {
                return Color(red: 1.0, green: 0.85, blue: 0.59).opacity(0.2)
            } else if let color = slotColor {
                return color.uiColor.opacity(0.15)
            } else {
                return Color.white.opacity(0.05)
            }
        }()
        
        let shadowColor: Color = {
            if isHighlighted {
                return canAcceptDrop == true ? Color.green.opacity(0.4) : Color.red.opacity(0.4)
            } else if isSelected {
                return Color(red: 1.0, green: 0.85, blue: 0.59).opacity(0.3)
            } else if let color = slotColor {
                return color.uiColor.opacity(0.3)
            } else {
                return Color.clear
            }
        }()
        
        let shadowRadius: CGFloat = {
            if isHighlighted {
                return 12
            } else if isSelected {
                return 8
            } else if slotColor != nil {
                return 6
            } else {
                return 0
            }
        }()
        
        let strokeWidth: CGFloat = isHighlighted ? 3 : 2
        let dashPattern: [CGFloat] = {
            if slotColor != nil {
                return [] // Solid line for filled slots
            } else {
                return [5] // Dashed line for empty slots
            }
        }()
        
        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    strokeColor,
                    style: StrokeStyle(lineWidth: strokeWidth, dash: dashPattern)
                )
                .frame(height: 75.0)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(fillColor)
                )
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius
                )
            
            if cards.isEmpty {
                // Empty slot hint
                Text("STACK \(slotIndex + 1)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                    .tracking(0.5)
            } else {
                tempSlotContent
            }
        }
        .onTapGesture {
            handleTapGesture()
        }
        .overlay(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    // Register this drop zone
                    let frame = geometry.frame(in: .global)
                    gameState.registerDropZone(
                        id: "tempSlot_\(slotIndex)",
                        frame: frame,
                        canAccept: { dragData in canAcceptDrop(dragData: dragData) },
                        handler: { dragData in handleDrop(dragData: dragData) }
                    )
                }
            }
        )
    }
    
    @ViewBuilder
    private var tempSlotContent: some View {
        HStack(spacing: 3) {
            if cards.count == 1 {
                // Single card
                DraggableTempSlotCardView(
                    card: cards[0], 
                    size: .normal,
                    dragData: DragData(
                        sourceType: .tempSlot(slotIndex: slotIndex),
                        card: cards[0],
                        stackCards: cards
                    ),
                    gameState: gameState
                )
            } else if cards.count == 2 {
                // Two cards - only last one is draggable
                TempSlotCardView(card: cards[0], size: .medium)
                
                DraggableTempSlotCardView(
                    card: cards[1], 
                    size: .medium,
                    dragData: DragData(
                        sourceType: .tempSlot(slotIndex: slotIndex),
                        card: cards[1],
                        stackCards: cards
                    ),
                    gameState: gameState
                )
            } else {
                // 3+ cards: show first, visual stack, last (only last is draggable)
                let firstCard = cards.first!
                let lastCard = cards.last!
                let middleCount = cards.count - 2
                
                // First card (not draggable)
                TempSlotCardView(card: firstCard, size: .medium)
                
                // Vertical stack indicator
                VerticalStackIndicatorView(
                    cardCount: middleCount,
                    color: firstCard.color
                )
                
                // Last card (draggable)
                DraggableTempSlotCardView(
                    card: lastCard, 
                    size: .medium,
                    dragData: DragData(
                        sourceType: .tempSlot(slotIndex: slotIndex),
                        card: lastCard,
                        stackCards: cards
                    ),
                    gameState: gameState
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func handleTapGesture() {
        if gameState.selectedGridPosition != nil || gameState.selectedCollection != nil {
            gameState.moveToTempSlot(slotIndex: slotIndex)
        } else if !cards.isEmpty {
            gameState.selectTempSlot(slotIndex)
        }
    }
    
    private func canAcceptDrop(dragData: DragData) -> Bool {
        // Check if we can accept the entire stack
        switch dragData.sourceType {
        case .tempSlot(let sourceSlot):
            // Allow moving between temp slots
            return sourceSlot != slotIndex
            
        case .collection(let color, let index):
            if index == -1 {
                // Entire collection - only allow if this slot is empty
                return cards.isEmpty
            } else {
                // Single card - use existing logic
                return gameState.canAddToTempSlot(dragData.card, slotIndex: slotIndex)
            }
            
        case .gridCell:
            // Single card from grid - use existing logic
            return gameState.canAddToTempSlot(dragData.card, slotIndex: slotIndex)
        }
    }
    
    private func handleDrop(dragData: DragData) -> Bool {
        guard canAcceptDrop(dragData: dragData) else { return false }
        
        switch dragData.sourceType {
        case .gridCell(let sourceRow, let sourceCol):
            return gameState.moveCardFromGridToTempSlot(from: (sourceRow, sourceCol), slotIndex: slotIndex)
        case .tempSlot(let sourceSlotIndex):
            return sourceSlotIndex != slotIndex && gameState.moveCardBetweenTempSlots(from: sourceSlotIndex, to: slotIndex)
        case .collection(let color, let index):
            return gameState.moveCardFromCollectionToTempSlot(color: color, index: index, slotIndex: slotIndex)
        }
    }
}

struct TempSlotCardView: View {
    let card: Card
    let size: TempCardSize
    
    var body: some View {
        let (width, height) = size.dimensions
        
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(card.color.uiColor)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Text("\(card.number)")
                .font(.system(size: size.fontSize, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: width, height: height)
    }
}

enum TempCardSize {
    case small, medium, normal
    
    var dimensions: (width: CGFloat, height: CGFloat) {
        switch self {
        case .small: return (24, 36)
        case .medium: return (28, 42)
        case .normal: return (32, 45)
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .normal: return 14
        }
    }
}

struct DraggableTempSlotCardView: View {
    let card: Card
    let size: TempCardSize
    let dragData: DragData
    @ObservedObject var gameState: GameState
    
    @State private var isDragging = false
    @State private var dragStarted = false
    
    var body: some View {
        let (width, height) = size.dimensions
        
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(card.color.uiColor)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Text("\(card.number)")
                .font(.system(size: size.fontSize, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: width, height: height)
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .opacity(isDragging ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .gesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .global)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        dragStarted = true
                        let adjustedPosition = CGPoint(
                            x: value.location.x,
                            y: value.location.y - 50 // Increased offset for temp slot cards
                        )
                        gameState.startDrag(card: card, sourceType: dragData.sourceType, position: adjustedPosition, stackCards: dragData.stackCards)
                    } else {
                        let adjustedPosition = CGPoint(
                            x: value.location.x,
                            y: value.location.y - 50
                        )
                        gameState.updateDragPosition(adjustedPosition)
                    }
                    // Update drop zone highlighting - use finger position for hit testing
                    gameState.updateDropZoneHighlight(at: value.location)
                }
                .onEnded { value in
                    if isDragging {
                        // Use finger position for drop detection, not adjusted position
                        let _ = handleDrop(at: value.location)
                        isDragging = false
                        gameState.endDrag()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        dragStarted = false
                    }
                }
        )
        .onAppear {
            isDragging = false
            dragStarted = false
        }
    }
    
    private func handleDrop(at location: CGPoint) {
        let _ = gameState.handleDrop(at: location)
    }
}

struct VerticalStackIndicatorView: View {
    let cardCount: Int
    let color: CardColor
    
    var body: some View {
        HStack(spacing: 0.5) {
            // Visual representation of vertically stacked cards
            ForEach(0..<min(cardCount, 4), id: \.self) { index in
                VStack(spacing: 0) {
                    // Top edge
                    Rectangle()
                        .fill(color.uiColor.opacity(0.8))
                        .frame(width: 3, height: 1)
                    
                    // Card body
                    Rectangle()
                        .fill(color.uiColor.opacity(0.9 - Double(index) * 0.1))
                        .frame(width: 3, height: 38)
                    
                    // Bottom edge
                    Rectangle()
                        .fill(color.uiColor.opacity(0.6))
                        .frame(width: 3, height: 1)
                }
                .cornerRadius(0.5)
                .offset(x: CGFloat(index) * 0.2, y: CGFloat(index) * 0.5)
            }
            
            // Count indicator if more than 4 cards
            if cardCount > 4 {
                Text("×\(cardCount)")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(.leading, 1)
            }
        }
        .frame(width: 20, height: 40)
    }
}

// MARK: - Controls View
struct ControlsView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { gameState.undoMove() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Undo")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .disabled(!gameState.canUndo)
            .buttonStyle(GlassButtonStyle(
                accentColor: Color(red: 1.0, green: 0.4, blue: 0.0), // Orange
                isEnabled: gameState.canUndo
            ))
            
            Button(action: { gameState.shuffleCards() }) {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Shuffle")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .buttonStyle(GlassButtonStyle(
                accentColor: Color(red: 1.0, green: 0.17, blue: 0.58), // Pink
                isEnabled: true
            ))
        }
    }
}

struct GlassButtonStyle: ButtonStyle {
    let accentColor: Color
    let isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background {
                ZStack {
                    // Base glass background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    
                    // Accent color overlay
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(isEnabled ? 0.15 : 0.05),
                                    accentColor.opacity(isEnabled ? 0.08 : 0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Top highlight
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isEnabled ? 0.3 : 0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(isEnabled ? 0.6 : 0.2),
                                    accentColor.opacity(isEnabled ? 0.2 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .shadow(
                color: accentColor.opacity(isEnabled ? 0.3 : 0.1),
                radius: isEnabled ? 8 : 4,
                x: 0,
                y: isEnabled ? 4 : 2
            )
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct GameButtonStyle: ButtonStyle {
    let color: LinearGradient
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(15)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Animations
extension AnyTransition {
    static var slideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
}

extension Animation {
    static func slideUp(delay: Double = 0) -> Animation {
        .easeOut(duration: 0.3).delay(delay)
    }
}

// MARK: - Drag and Drop Infrastructure
struct DragData: Transferable {
    let sourceType: SourceType
    let card: Card
    let stackCards: [Card] // All cards in the stack being dragged
    
    enum SourceType {
        case gridCell(row: Int, col: Int)
        case tempSlot(slotIndex: Int)
        case collection(color: CardColor, index: Int)
    }
    
    init(sourceType: SourceType, card: Card, stackCards: [Card] = []) {
        self.sourceType = sourceType
        self.card = card
        self.stackCards = stackCards.isEmpty ? [card] : stackCards
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .data) { dragData in
            // Convert to a simple data structure for transfer
            let data = DragDataTransfer(
                sourceType: dragData.sourceType,
                cardNumber: dragData.card.number,
                cardColor: dragData.card.color,
                stackCards: dragData.stackCards
            )
            return try JSONEncoder().encode(data)
        } importing: { data in
            let transfer = try JSONDecoder().decode(DragDataTransfer.self, from: data)
            let stackCards = transfer.stackCards.map { Card(number: $0.number, color: $0.color) }
            return DragData(
                sourceType: transfer.dragDataSourceType,
                card: Card(number: transfer.cardNumber, color: transfer.cardColor),
                stackCards: stackCards
            )
        }
    }
}

private struct CardData: Codable {
    let number: Int
    let color: CardColor
}

private struct DragDataTransfer: Codable {
    let sourceType: SourceTypeTransfer
    let cardNumber: Int
    let cardColor: CardColor
    let stackCards: [CardData] // Stack as array of card data
    
    enum SourceTypeTransfer: Codable {
        case gridCell(row: Int, col: Int)
        case tempSlot(slotIndex: Int)
        case collection(color: CardColor, index: Int)
    }
    
    init(sourceType: DragData.SourceType, cardNumber: Int, cardColor: CardColor, stackCards: [Card]) {
        self.cardNumber = cardNumber
        self.cardColor = cardColor
        self.stackCards = stackCards.map { CardData(number: $0.number, color: $0.color) }
        
        switch sourceType {
        case .gridCell(let row, let col):
            self.sourceType = .gridCell(row: row, col: col)
        case .tempSlot(let slotIndex):
            self.sourceType = .tempSlot(slotIndex: slotIndex)
        case .collection(let color, let index):
            self.sourceType = .collection(color: color, index: index)
        }
    }
    
    var dragDataSourceType: DragData.SourceType {
        switch sourceType {
        case .gridCell(let row, let col):
            return .gridCell(row: row, col: col)
        case .tempSlot(let slotIndex):
            return .tempSlot(slotIndex: slotIndex)
        case .collection(let color, let index):
            return .collection(color: color, index: index)
        }
    }
}

// MARK: - Draggable Card View
struct DraggableCardView: View {
    let card: Card
    let isUnlocked: Bool
    let stackCount: Int
    let dragData: DragData
    @ObservedObject var gameState: GameState
    let onTap: () -> Void
    
    @State private var isDragging = false
    @State private var dragStarted = false
    @State private var tapGestureActive = false
    
    var body: some View {
        ZStack {
            // Stack visualization - show background cards first (only for unlocked cards)
            if stackCount > 1 && isUnlocked {
                ForEach(0..<min(stackCount - 1, 3), id: \.self) { index in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.3 - Double(index) * 0.08))
                        .frame(width: 50, height: 50)
                        .offset(
                            x: CGFloat(index + 1) * 2,
                            y: -CGFloat(index + 1) * 2
                        )
                }
            }
            
            // Main card on top
            RoundedRectangle(cornerRadius: 10)
                .fill(card.color.uiColor)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                .frame(width: 50, height: 50)
                .opacity(isUnlocked ? 1.0 : 0.5)
            
            // Card number
            Text("\(card.number)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .opacity(isUnlocked ? 1.0 : 0.5)
        }
        .scaleEffect(isUnlocked ? (isDragging ? 1.02 : 1.0) : 0.9)
        .opacity(isDragging ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .onTapGesture {
            if isUnlocked && !dragStarted {
                onTap()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 5, coordinateSpace: .global)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        dragStarted = true
                        // Position the drag preview above the finger (more offset)
                        let adjustedPosition = CGPoint(
                            x: value.location.x,
                            y: value.location.y - 50 // 50 points above finger
                        )
                                                    gameState.startDrag(card: card, sourceType: dragData.sourceType, position: adjustedPosition, stackCards: dragData.stackCards)
                    } else {
                        let adjustedPosition = CGPoint(
                            x: value.location.x,
                            y: value.location.y - 50
                        )
                        gameState.updateDragPosition(adjustedPosition)
                    }
                    // Update drop zone highlighting - use finger position for hit testing
                    gameState.updateDropZoneHighlight(at: value.location)
                }
                .onEnded { value in
                    if isDragging {
                        // Use finger position for drop detection, not adjusted position
                        let _ = handleDrop(at: value.location)
                        isDragging = false
                        gameState.endDrag()
                    }
                    // Reset drag started after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        dragStarted = false
                    }
                }
        )
        .onAppear {
            isDragging = false
            dragStarted = false
        }
    }
    
    private func handleDrop(at location: CGPoint) {
        gameState.handleDrop(at: location)
    }
}

struct DraggableCollectionCardView: View {
    let number: Int
    let color: CardColor
    let size: CardSize
    let dragData: DragData
    let onTap: () -> Void
    @ObservedObject var gameState: GameState
    
    @State private var isDragging = false
    @State private var dragStarted = false
    
    enum CardSize {
        case small, medium, normal
        
        var dimensions: (width: CGFloat, height: CGFloat) {
            switch self {
            case .small: return (32, 14)
            case .medium: return (36, 16)
            case .normal: return (40, 18)
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 9
            case .medium: return 10
            case .normal: return 12
            }
        }
    }
    
    var body: some View {
        let (width, height) = size.dimensions
        
        Text("\(number)")
            .font(.system(size: size.fontSize, weight: .bold))
            .foregroundColor(.white)
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.uiColor)
                    .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
            )
            .scaleEffect(isDragging ? 1.02 : 1.0)
            .opacity(isDragging ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
            .onTapGesture {
                if !dragStarted {
                    onTap()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 4, coordinateSpace: .global)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStarted = true
                            let card = Card(number: number, color: color)
                            let adjustedPosition = CGPoint(
                                x: value.location.x,
                                y: value.location.y - 40 // Increased offset for collection cards
                            )
                            gameState.startDrag(card: card, sourceType: dragData.sourceType, position: adjustedPosition, stackCards: dragData.stackCards)
                        } else {
                            let adjustedPosition = CGPoint(
                                x: value.location.x,
                                y: value.location.y - 40
                            )
                            gameState.updateDragPosition(adjustedPosition)
                        }
                        // Update drop zone highlighting - use finger position for hit testing
                        gameState.updateDropZoneHighlight(at: value.location)
                    }
                    .onEnded { value in
                        if isDragging {
                            // Use finger position for drop detection, not adjusted position
                            let _ = handleDrop(at: value.location)
                            isDragging = false
                            gameState.endDrag()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            dragStarted = false
                        }
                    }
            )
            .onAppear {
                isDragging = false
                dragStarted = false
            }
    }
    
    private func handleDrop(at location: CGPoint) {
        let _ = gameState.handleDrop(at: location)
    }
} 
