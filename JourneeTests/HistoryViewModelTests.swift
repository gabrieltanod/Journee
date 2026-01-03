import Testing
@testable import Journee
import Foundation

struct HistoryViewModelTests {

    @Test func testInitialState() async throws {
        let viewModel = HistoryViewModel(repository: MockTransactionRepository())
        #expect(viewModel.transactions.isEmpty)
        
        // Initial selected date should be "today" (roughly, verifying month match)
        let calendar = Calendar.current
        #expect(calendar.isDate(viewModel.selectedDate, equalTo: Date(), toGranularity: .month))
    }

    @Test func testFilteredTransactions() async throws {
        let mockRepo = MockTransactionRepository()
        let viewModel = HistoryViewModel(repository: mockRepo)
        
        let date1 = Date() // Current month
        let date2 = Calendar.current.date(byAdding: .month, value: -1, to: Date())! // Previous month
        
        let t1 = Transaction(amount: 100, memo: "Test 1", emotion: .happy, category: .wants, date: date1)
        let t2 = Transaction(amount: 200, memo: "Test 2", emotion: .sad, category: .needs, date: date2)
        
        mockRepo.transactions = [t1, t2]
        viewModel.loadTransactions()
        
        // Should only show t1
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.id == t1.id)
        #expect(viewModel.totalAmount == 100)
    }

    @Test func testCategoryBreakdown() async throws {
        let mockRepo = MockTransactionRepository()
        let viewModel = HistoryViewModel(repository: mockRepo)
        
        let date1 = Date() // Current month
        
        // 2 Wants, 1 Needs
        let t1 = Transaction(amount: 50, memo: "Want 1", emotion: .happy, category: .wants, date: date1)
        let t2 = Transaction(amount: 50, memo: "Want 2", emotion: .happy, category: .wants, date: date1)
        let t3 = Transaction(amount: 200, memo: "Need 1", emotion: .neutral, category: .needs, date: date1)
        
        mockRepo.transactions = [t1, t2, t3]
        viewModel.loadTransactions()
        
        let breakdown = viewModel.categoryBreakdown
        
        #expect(breakdown[.wants] == 100)
        #expect(breakdown[.needs] == 200)
    }

    @Test func testNavigation() async throws {
        let viewModel = HistoryViewModel(repository: MockTransactionRepository())
        let initialDate = viewModel.selectedDate
        
        viewModel.previousMonth()
        let prevDate = viewModel.selectedDate
        #expect(prevDate < initialDate)
        
        viewModel.nextMonth()
        let nextDate = viewModel.selectedDate
        #expect(nextDate > prevDate)
        
        // Verify it's back to roughly the same month
        let calendar = Calendar.current
        #expect(calendar.isDate(nextDate, equalTo: initialDate, toGranularity: .month))
    }
}

class MockTransactionRepository: TransactionRepositoryProtocol {
    var transactions: [Transaction] = []
    
    func fetchTransactions() -> [Transaction] {
        return transactions
    }
    
    func save(transaction: Transaction) {
        transactions.append(transaction)
    }
    

    
    // Add other protocol requirements if any, assuming minimal protocol based on usage
}
