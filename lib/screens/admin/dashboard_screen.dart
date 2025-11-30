import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/dashboard/loan_status_pie_chart.dart';
import '../../widgets/dashboard/category_bar_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = Provider.of<DashboardProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Gerencial')),
      body: dashboard.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => dashboard.fetchDashboardData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard('Livros', dashboard.totalBooks.toString(), Icons.book, Colors.blue)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildSummaryCard('Usuários', dashboard.totalUsers.toString(), Icons.people, Colors.orange)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildSummaryCard('Empréstimos', dashboard.totalActiveLoans.toString(), Icons.bookmark, Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pie Chart Section
                    const Text('Saúde dos Empréstimos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LoanStatusPieChart(
                          onTime: dashboard.onTimeLoans,
                          overdue: dashboard.overdueLoans,
                          reserved: dashboard.reservedLoans,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bar Chart Section
                    const Text('Top Categorias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CategoryBarChart(
                          data: dashboard.categoryLoanCounts,
                          maxY: dashboard.maxCategoryCount,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
