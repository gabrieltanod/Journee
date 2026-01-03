import SwiftUI
import Charts

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month Navigation Header
                HStack {
                    Button(action: {
                        viewModel.previousMonth()
                    }) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(viewModel.monthYearString)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.nextMonth()
                    }) {
                        Image(systemName: "chevron.right")
                            .padding()
                    }
                }
                .padding(.horizontal)
                
                if !viewModel.filteredTransactions.isEmpty {
                    VStack {
                        Text(String(format: "Total: Rp.%.2f", viewModel.totalAmount))
                            .font(.title2)
                        
                        Chart(viewModel.categoryBreakdown.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { category, amount in
                            SectorMark(
                                angle: .value("Amount", amount),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .cornerRadius(5)
                            .foregroundStyle(by: .value("Category", category.rawValue))
                        }
                        .frame(height: 200)
                        .padding()
                    }
                    .padding(.bottom)
                }
                
                List {
                    if viewModel.filteredTransactions.isEmpty {
                        Text("No transactions in \(viewModel.monthYearString)")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(viewModel.filteredTransactions) { transaction in
                            HStack {
                                Text(transaction.emotion.rawValue)
                                    .font(.largeTitle)
                                
                                VStack(alignment: .leading) {
                                    Text(transaction.memo)
                                        .font(.headline)
                                    Text(transaction.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(String(format: "Rp.%.2f", transaction.amount))
                                    .font(.headline)
                            }
                        }
                    }
                }
                .onAppear {
                    viewModel.loadTransactions()
                }
            }
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
