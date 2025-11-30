import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LoanStatusPieChart extends StatelessWidget {
  final int onTime;
  final int overdue;
  final int reserved;

  const LoanStatusPieChart({
    super.key,
    required this.onTime,
    required this.overdue,
    required this.reserved,
  });

  @override
  Widget build(BuildContext context) {
    final total = onTime + overdue + reserved;
    if (total == 0) {
      return const Center(child: Text('Sem dados de empréstimos'));
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: _showingSections(),
                ),
              ),
            ),
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Indicator(color: Colors.green, text: 'Em Dia', isSquare: true),
              SizedBox(height: 4),
              _Indicator(color: Colors.red, text: 'Atrasados', isSquare: true),
              SizedBox(height: 4),
              _Indicator(color: Colors.amber, text: 'Reservados', isSquare: true),
            ],
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    final total = (onTime + overdue + reserved).toDouble();
    
    return List.generate(3, (i) {
      final isTouched = false;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      
      switch (i) {
        case 0:
          final percent = (onTime / total) * 100;
          return PieChartSectionData(
            color: Colors.green,
            value: onTime.toDouble(),
            title: '${percent.toStringAsFixed(0)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 1:
          final percent = (overdue / total) * 100;
          return PieChartSectionData(
            color: Colors.red,
            value: overdue.toDouble(),
            title: '${percent.toStringAsFixed(0)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        case 2:
          final percent = (reserved / total) * 100;
          return PieChartSectionData(
            color: Colors.amber,
            value: reserved.toDouble(),
            title: '${percent.toStringAsFixed(0)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: shadows,
            ),
          );
        default:
          throw Error();
      }
    });
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;

  const _Indicator({
    required this.color,
    required this.text,
    required this.isSquare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        )
      ],
    );
  }
}
